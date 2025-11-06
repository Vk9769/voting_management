import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;

const String kGoogleApiKey = 'AIzaSyBojqJ6_267UQvj91USf91lqCjegNGIy08';

enum RideStep { pickup, destination, review, finding, assigned }
enum MapSelectMode { none, pickup, destination }
enum PaymentMethod { cash, card, wallet, upi }

class RideRequestPage extends StatefulWidget {
  const RideRequestPage({Key? key}) : super(key: key);

  @override
  State<RideRequestPage> createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage> with TickerProviderStateMixin {
  // Map
  GoogleMapController? _map;
  LatLng? _current;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Steps
  RideStep _step = RideStep.pickup;
  MapSelectMode _mapSelect = MapSelectMode.none;

  // Location data
  LatLng? _pickupLatLng;
  String? _pickupAddress;
  LatLng? _destLatLng;
  String? _destAddress;

  // Route meta
  String _distanceText = '';
  String _durationText = '';
  int _estimatedPrice = 150;

  // Search state
  final TextEditingController _pickupCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  List<_Suggestion> _pickupSugs = [];
  List<_Suggestion> _destSugs = [];
  Timer? _debounce;

  // Premium features
  String _selectedProduct = 'Book Any';
  PaymentMethod _paymentMethod = PaymentMethod.wallet;
  String _promoCode = '';
  bool _hasPromoCode = false;
  int _discountAmount = 0;
  DateTime? _scheduledTime;
  List<FavoriteLocation> _favorites = [
    FavoriteLocation('Home', 'Your home address', Icons.home),
    FavoriteLocation('Work', 'Your workplace', Icons.work),
  ];

  // Animations
  late AnimationController _sheetAnimController;
  late AnimationController _driverAnimController;
  late Animation<double> _driverPulseAnim;

  // Mock driver tracking
  LatLng? _driverLocation;
  double _driverToPickupDistance = 5.2;

  @override
  void initState() {
    super.initState();
    _sheetAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _driverAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _driverPulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _driverAnimController, curve: Curves.easeInOut),
    );
    _ensureLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    _sheetAnimController.dispose();
    _driverAnimController.dispose();
    super.dispose();
  }

  Future<void> _ensureLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enable location services.'),
          backgroundColor: Colors.red,
        ));
      }
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permission permanently denied'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    try {
      final pos =
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final here = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _current = here;
          _pickupLatLng ??= here;
          _pickupAddress ??= 'Current location';
          _markers.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: here,
              infoWindow: const InfoWindow(title: 'Pick-up'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        });
        _moveCamera(here, zoom: 15);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _moveCamera(LatLng target, {double zoom = 15}) async {
    if (_map == null) return;
    await _map!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: zoom),
    ));
  }

  void _onPickupChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (v.trim().isEmpty) {
        setState(() => _pickupSugs = []);
        return;
      }
      final sugs = await _autocomplete(v);
      if (mounted) setState(() => _pickupSugs = sugs);
    });
  }

  void _onDestChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (v.trim().isEmpty) {
        setState(() => _destSugs = []);
        return;
      }
      final sugs = await _autocomplete(v);
      if (mounted) setState(() => _destSugs = sugs);
    });
  }

  Future<List<_Suggestion>> _autocomplete(String input) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$kGoogleApiKey&components=country:in';
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      if (data['status'] == 'OK') {
        return (data['predictions'] as List)
            .map((e) => _Suggestion(
          e['description'],
          e['place_id'],
        ))
            .toList();
      }
    } catch (e) {
      print('Autocomplete error: $e');
    }
    return [];
  }

  Future<_PlaceDetails?> _placeDetails(String placeId) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey';
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      if (data['status'] == 'OK') {
        final loc = data['result']['geometry']['location'];
        final addr = data['result']['formatted_address'];
        return _PlaceDetails(
          LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()),
          addr,
        );
      }
    } catch (e) {
      print('Place details error: $e');
    }
    return null;
  }

  Future<void> _loadRoute() async {
    if (_pickupLatLng == null || _destLatLng == null) return;
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}&destination=${_destLatLng!.latitude},${_destLatLng!.longitude}&key=$kGoogleApiKey';
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final distanceText = leg['distance']['text'];
        final durationText = leg['duration']['text'];
        final encoded = route['overview_polyline']['points'];
        final pts = _decodePolyline(encoded).map((p) => LatLng(p.$1, p.$2)).toList();

        // Calculate estimated price dynamically
        final distance = leg['distance']['value'] as int;
        _estimatedPrice = ((distance / 1000) * 15 + 30).toInt();

        if (mounted) {
          setState(() {
            _distanceText = distanceText;
            _durationText = durationText;
            _polylines
              ..clear()
              ..add(Polyline(
                polylineId: const PolylineId('route'),
                width: 5,
                color: const Color(0xFF2196F3),
                points: pts,
              ));
            _markers
              ..removeWhere((m) =>
              m.markerId.value == 'pickup' || m.markerId.value == 'dest')
              ..add(Marker(
                markerId: const MarkerId('pickup'),
                position: _pickupLatLng!,
                infoWindow: const InfoWindow(title: 'Pick-up'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ))
              ..add(Marker(
                markerId: const MarkerId('dest'),
                position: _destLatLng!,
                infoWindow: const InfoWindow(title: 'Destination'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ));
          });
        }

        await Future.delayed(const Duration(milliseconds: 300));
        _fitBounds(pts);
      }
    } catch (e) {
      print('Route loading error: $e');
    }
  }

  void _fitBounds(List<LatLng> pts) {
    if (_map == null || pts.isEmpty) return;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }
    _map!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      100,
    ));
  }

  List<(double, double)> _decodePolyline(String encoded) {
    List<(double, double)> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add((lat / 1e5, lng / 1e5));
    }
    return points;
  }

  LatLng _center = const LatLng(0, 0);

  void _enterMapSelect(MapSelectMode mode) {
    if (_current == null) return;

    setState(() {
      _mapSelect = mode;

      // Clear markers so only the pin icon is visible
      _markers.removeWhere((m) => m.markerId.value == 'pickup' || m.markerId.value == 'dest');

      // Center map from previous location
      _center = mode == MapSelectMode.pickup
          ? (_pickupLatLng ?? _current!)
          : (_destLatLng ?? _current!);
    });

    _moveCamera(_center, zoom: 16);
    _sheetAnimController.forward();
  }

  Future<void> _updateCenterAddress() async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${_center.latitude},${_center.longitude}&key=$kGoogleApiKey";

    try {
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);

      if (data["status"] == "OK") {
        final addr = data["results"][0]["formatted_address"];

        setState(() {
          if (_mapSelect == MapSelectMode.pickup) {
            _pickupCtrl.text = addr;      // ✅ Update UI
            _pickupAddress = addr;        // ✅ Store value
          } else if (_mapSelect == MapSelectMode.destination) {
            _destCtrl.text = addr;        // ✅ Update UI
            _destAddress = addr;          // ✅ Store value
          }
        });
      }
    } catch (_) {}
  }

  void _confirmCenter() {
    if (_mapSelect == MapSelectMode.pickup) {
      setState(() {
        _pickupLatLng = _center;
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
        _mapSelect = MapSelectMode.none;
        _step = RideStep.destination;
      });
    } else if (_mapSelect == MapSelectMode.destination) {
      setState(() {
        _destLatLng = _center;

        _markers.add(
          Marker(
            markerId: const MarkerId('dest'),
            position: _destLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        _mapSelect = MapSelectMode.none;
        _sheetAnimController.reverse();
      });

      _goToReview();
    }
  }

  Future<void> _selectPickupFromSuggestion(_Suggestion s) async {
    final det = await _placeDetails(s.placeId);
    if (det != null) {
      setState(() {
        _pickupLatLng = det.latLng;
        _pickupAddress = det.address;
        _pickupSugs = [];
        _pickupCtrl.text = det.address;
      });
      _moveCamera(det.latLng);
    }
  }

  Future<void> _selectDestFromSuggestion(_Suggestion s) async {
    final det = await _placeDetails(s.placeId);
    if (det != null) {
      setState(() {
        _destLatLng = det.latLng;
        _destAddress = det.address;
        _destSugs = [];
        _destCtrl.text = det.address;
      });
      _moveCamera(det.latLng);
    }
  }

  void _confirmPickup() {
    if (_pickupLatLng == null) return;

    setState(() {
      // ✅ Remove old pickup marker if exists
      _markers.removeWhere((m) => m.markerId.value == 'pickup');

      // ✅ Drop new green pickup pin
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // ✅ Move to destination page
      _step = RideStep.destination;
    });

    // ✅ Center map on pickup
    _moveCamera(_pickupLatLng!, zoom: 16);
  }

  void _goToReview() async {
    if (_pickupLatLng == null || _destLatLng == null) return;
    setState(() => _step = RideStep.review);
    await _loadRoute();
  }

  void _confirmDestination() {
    if (_destLatLng == null) return;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'dest');
      _markers.add(
        Marker(
          markerId: const MarkerId('dest'),
          position: _destLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    _goToReview();
  }

  void _book(String product) {
    _driverLocation = LatLng(
      _pickupLatLng!.latitude + (Random().nextDouble() - 0.5) * 0.1,
      _pickupLatLng!.longitude + (Random().nextDouble() - 0.5) * 0.1,
    );

    setState(() {
      _selectedProduct = product;
      _step = RideStep.finding;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _step = RideStep.assigned);
      _driverAnimController.repeat();
    });
  }

  void _applyPromoCode() {
    if (_promoCode.isEmpty) return;
    if (_promoCode.toUpperCase() == 'SAVE50') {
      setState(() {
        _hasPromoCode = true;
        _discountAmount = min(50, _estimatedPrice ~/ 2);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied! ₹50 discount'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setFavoritePickup(FavoriteLocation fav) {
    setState(() {
      _pickupAddress = fav.address;
      _pickupLatLng = LatLng(19.0760 + Random().nextDouble() * 0.1,
          72.8777 + Random().nextDouble() * 0.1);
      _step = RideStep.destination;
    });
    _moveCamera(_pickupLatLng!);
  }

  @override
  Widget build(BuildContext context) {
    final cam = CameraPosition(target: _current ?? const LatLng(19.0760, 72.8777), zoom: 14);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_titleForStep(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        leading: _step != RideStep.pickup
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              if (_step == RideStep.destination) {
                _step = RideStep.pickup;
              } else if (_step == RideStep.review) {
                _step = RideStep.destination;
              }
            });
          },
        )
            : null,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: cam,
            onMapCreated: (c) => _map = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,

            // ✅ NEW: Drop pin when tapped
            onTap: (LatLng pos) {
              if (_mapSelect != MapSelectMode.none) {
                setState(() {
                  _center = pos;
                });
                _moveCamera(pos, zoom: 16);
                _updateCenterAddress();
              }
            },

            // Keep these (only update when dragging map)
            onCameraMove: (pos) {
              if (_mapSelect != MapSelectMode.none) {
                _center = pos.target;
              }
            },
            onCameraIdle: () {
              if (_mapSelect != MapSelectMode.none) {
                _updateCenterAddress();
              }
            },
          ),

          // Enhanced crosshair with animations for map selection
          if (_mapSelect != MapSelectMode.none) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _driverPulseAnim,
                    child: const Icon(Icons.location_pin, size: 50, color: Colors.red),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _sheetAnimController, curve: Curves.easeOut)),
                child: FilledButton(
                  onPressed: _confirmCenter,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2196F3),
                  ),
                  child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],

          // Enhanced draggable sheet with smooth animations
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.15,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.28, 0.9],
            builder: (context, scroll) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: _buildSheetContent(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _titleForStep() {
    switch (_step) {
      case RideStep.pickup:
        return 'Pick-up Location';
      case RideStep.destination:
        return 'Destination';
      case RideStep.review:
        return 'Confirm Ride';
      case RideStep.finding:
        return 'Finding Driver...';
      case RideStep.assigned:
        return 'Driver Assigned';
    }
  }

  Widget _buildSheetContent() {
    switch (_step) {
      case RideStep.pickup:
        return _buildPickupSection();
      case RideStep.destination:
        return _buildDestinationSection();
      case RideStep.review:
        return _buildReviewSection();
      case RideStep.finding:
        return _buildFindingSection();
      case RideStep.assigned:
        return _buildAssignedSection();
    }
  }

  Widget _handle() => Center(
    child: Container(
      width: 50,
      height: 5,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );

  Widget _buildPickupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        Text(
          'Choose pick-up location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pickupCtrl,
          onChanged: _onPickupChanged,
          decoration: InputDecoration(
            hintText: 'Search pick-up location',
            prefixIcon: const Icon(Icons.search, color: Colors.blue),
            suffixIcon: _pickupCtrl.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _pickupCtrl.clear()),
            )
                : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (_pickupSugs.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._pickupSugs.map((s) => _suggestionTile(s, () => _selectPickupFromSuggestion(s))).toList(),
        ],
        const SizedBox(height: 16),
        Text('Quick pick-up', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _favorites
                .map((fav) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _setFavoritePickup(fav),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(fav.icon, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(fav.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _enterMapSelect(MapSelectMode.pickup),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Locate on Map'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _confirmPickup,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF2196F3),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
        if (_pickupAddress != null) ...[
          const SizedBox(height: 12),
          _infoTile('Selected', _pickupAddress!, Icons.check_circle, Colors.green),
        ],
      ],
    );
  }

  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        Text(
          'Where are you going?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _infoTile('From', _pickupAddress ?? 'Pick-up', Icons.location_on, Colors.green),
        const SizedBox(height: 16),
        TextField(
          controller: _destCtrl,
          onChanged: _onDestChanged,
          decoration: InputDecoration(
            hintText: 'Enter destination',
            prefixIcon: const Icon(Icons.search, color: Colors.red),
            suffixIcon: _destCtrl.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _destCtrl.clear()),
            )
                : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (_destSugs.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._destSugs.map((s) => _suggestionTile(s, () => _selectDestFromSuggestion(s))).toList(),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _enterMapSelect(MapSelectMode.destination),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Locate on Map'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _confirmDestination,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF2196F3),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    final finalPrice = max(0, _estimatedPrice - _discountAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pick-up', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _pickupAddress ?? 'Pick-up',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Destination', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _destAddress ?? 'Destination',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(Icons.access_time, _durationText.isEmpty ? '—' : _durationText, 'Duration'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(Icons.straighten, _distanceText.isEmpty ? '—' : _distanceText, 'Distance'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Choose ride type',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _rideOption('Book Any', 'Mini, Prime Sedan', '4 min', '₹${_estimatedPrice}'),
        _rideOption('Auto', 'Quickest auto', '2 min', '₹${(_estimatedPrice * 0.5).toInt()}'),
        _rideOption('Bike', 'Quick bike ride', '4 min', '₹${(_estimatedPrice * 0.35).toInt()}'),
        _rideOption('Mini', 'Comfy cars', '5 min', '₹${_estimatedPrice}'),

        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _promoCode = v),
          decoration: InputDecoration(
            hintText: 'Enter promo code (try SAVE50)',
            prefixIcon: const Icon(Icons.local_offer_outlined, color: Colors.blue),
            suffixIcon: _promoCode.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: _applyPromoCode,
            )
                : null,
            filled: true,
            fillColor: Colors.amber[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),
        Card(
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Base fare', style: TextStyle(fontSize: 14)),
                    Text('₹${_estimatedPrice}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (_hasPromoCode) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.green)),
                      Text('-₹$_discountAmount', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('₹$finalPrice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _step = RideStep.destination);
          },
          icon: const Icon(Icons.edit_location_alt),
          label: const Text('Change route'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        )
      ],
    );
  }

  Widget _buildFindingSection() {
    return Column(
      children: [
        _handle(),
        const SizedBox(height: 20),
        ListTile(
          leading: ScaleTransition(
            scale: _driverPulseAnim,
            child: const Icon(Icons.local_taxi, color: Colors.blue, size: 32),
          ),
          title: Text('Booking $_selectedProduct', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${_pickupAddress ?? 'Pick-up'} → ${_destAddress ?? 'Destination'}'),
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
            ),
            ScaleTransition(
              scale: _driverPulseAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              strokeWidth: 3,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Finding your driver...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please wait while we connect you with a nearby driver',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAssignedSection() {
    const driverName = 'Rahul S.';
    const car = 'WagonR - MH03 AB 1234';
    const rating = 4.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: _driverPulseAnim,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.blue, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Verified driver', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              const Text('$rating', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Online', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.blue),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vehicle', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(car, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ETA: ${_durationText.isEmpty ? "—" : _durationText}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Text('Driver is arriving soon', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_pickupAddress ?? 'Pick-up', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_destAddress ?? 'Destination', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ride booked successfully!'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Ride Confirmed'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionTile(_Suggestion s, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.place_outlined, color: Colors.blue, size: 20),
      title: Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
      hoverColor: Colors.blue[50],
    );
  }

  Widget _rideOption(String title, String subtitle, String eta, String price) {
    return GestureDetector(
      onTap: () => _book(title),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const Icon(Icons.directions_car_filled, color: Colors.blue),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2196F3))),
              Text(eta, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(IconData icon, String value, String label) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _Suggestion {
  final String description;
  final String placeId;
  _Suggestion(this.description, this.placeId);
}

class _PlaceDetails {
  final LatLng latLng;
  final String address;
  _PlaceDetails(this.latLng, this.address);
}

class FavoriteLocation {
  final String label;
  final String address;
  final IconData icon;
  FavoriteLocation(this.label, this.address, this.icon);
}
