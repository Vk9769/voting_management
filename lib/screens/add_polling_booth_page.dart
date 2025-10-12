import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';

class AddPollingBoothPage extends StatefulWidget {
  const AddPollingBoothPage({super.key});

  @override
  State<AddPollingBoothPage> createState() => _AddPollingBoothPageState();
}

class Booth {
  final String name;
  final String address;
  final LatLng location;
  final double radius;

  Booth({
    required this.name,
    required this.address,
    required this.location,
    required this.radius,
  });
}

class _AddPollingBoothPageState extends State<AddPollingBoothPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  LatLng? selectedLocation;
  GoogleMapController? _mapController;

  double radius = 50; // default radius
  final List<Booth> savedBooths = [];

  bool _initializing = true;
  bool _geocoding = false;
  Timer? _debounce; // debounce for forward geocoding (optional, on-demand)

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission permanently denied. Please enable it in Settings.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      await _ensurePermissions();

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        selectedLocation = ll;
        _initializing = false;
      });

      // Reverse geocode initial position
      await _fetchAddress(ll.latitude, ll.longitude);

      // Animate camera if map already ready
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: ll, zoom: 16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // filter out null/empty parts
        String address = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country
        ].where((e) => (e ?? '').toString().trim().isNotEmpty).join(', ');

        if (!mounted) return;
        setState(() {
          _addressCtrl.text = address.isNotEmpty ? address : "Address not found";
        });
      } else {
        if (!mounted) return;
        setState(() {
          _addressCtrl.text = "Address not found";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addressCtrl.text = "Failed to fetch address";
      });
    }
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      selectedLocation = position;
    });
    await _fetchAddress(position.latitude, position.longitude);
  }

  Future<void> _forwardGeocodeAndMove() async {
    final query = _addressCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an address to locate')),
      );
      return;
    }

    setState(() {
      _geocoding = true;
    });

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final first = locations.first;
        final ll = LatLng(first.latitude, first.longitude);
        if (!mounted) return;
        setState(() {
          selectedLocation = ll;
        });

        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: ll, zoom: 16),
          ),
        );

        // Keep address field consistent with reverse geocoding
        await _fetchAddress(ll.latitude, ll.longitude);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found for that address')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to locate that address')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _geocoding = false;
      });
    }
  }

  Future<void> _recenterToCurrent() async {
    await _setInitialLocation();
  }

  void _resetForm() {
    setState(() {
      _nameCtrl.clear();
      _addressCtrl.clear();
      radius = 50;
    });
    if (selectedLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: selectedLocation!, zoom: 16),
        ),
      );
    }
  }

  void _saveBooth() {
    if (!_formKey.currentState!.validate()) return;
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on the map')),
      );
      return;
    }

    final newBooth = Booth(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      location: selectedLocation!,
      radius: radius,
    );

    setState(() {
      savedBooths.add(newBooth);
      _nameCtrl.clear();
      _addressCtrl.clear();
      radius = 50;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Polling Booth Added!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Polling Booth'),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 1.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Form Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Booth Name
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Booth Name',
                            prefixIcon: const Icon(Icons.how_to_vote, color: blue),
                            labelStyle: const TextStyle(color: blue),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: blue),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: blue, width: 2),
                            ),
                          ),
                          cursorColor: blue,
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) {
                              return 'Booth name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Address with actions
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            prefixIcon: const Icon(Icons.place, color: blue),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Locate this address',
                                  onPressed: _geocoding ? null : _forwardGeocodeAndMove,
                                  icon: _geocoding
                                      ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: blue),
                                  )
                                      : const Icon(Icons.search, color: blue),
                                ),
                                IconButton(
                                  tooltip: 'Use current location',
                                  onPressed: _recenterToCurrent,
                                  icon: const Icon(Icons.my_location, color: blue),
                                ),
                              ],
                            ),
                            labelStyle: const TextStyle(color: blue),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: blue),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: blue, width: 2),
                            ),
                          ),
                          cursorColor: blue,
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) {
                              return 'Address is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Radius slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Radius: ${radius.toInt()} meters',
                              style: const TextStyle(
                                color: blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              min: 10,
                              max: 500,
                              divisions: 49,
                              value: radius,
                              activeColor: blue,
                              inactiveColor: Colors.blue.shade100,
                              label: '${radius.toInt()} m',
                              onChanged: (value) {
                                setState(() {
                                  radius = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Map Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 360,
                    child: _initializing
                        ? const Center(
                      child: CircularProgressIndicator(color: blue),
                    )
                        : selectedLocation == null
                        ? const Center(
                      child: Text('Tap the map or use current location'),
                    )
                        : RepaintBoundary(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: selectedLocation!,
                          zoom: 16,
                        ),
                        onMapCreated: (c) => _mapController = c,
                        onTap: _onMapTap,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                        markers: {
                          // Current booth (blue)
                          if (selectedLocation != null)
                            Marker(
                              markerId: const MarkerId('current'),
                              position: selectedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                              infoWindow: InfoWindow(
                                title: _nameCtrl.text.isEmpty ? 'Selected Location' : _nameCtrl.text,
                                snippet: _addressCtrl.text,
                              ),
                            ),
                          // Saved booths (green)
                          ...savedBooths.map(
                                (b) => Marker(
                              markerId: MarkerId(b.name),
                              position: b.location,
                              infoWindow: InfoWindow(title: b.name, snippet: b.address),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                          ),
                        },
                        circles: {
                          // Current booth radius (blue)
                          if (selectedLocation != null)
                            Circle(
                              circleId: const CircleId('currentRadius'),
                              center: selectedLocation!,
                              radius: radius,
                              fillColor: Colors.blueAccent.withOpacity(0.2),
                              strokeColor: blue,
                              strokeWidth: 2,
                            ),
                          // Saved booths radius (green)
                          ...savedBooths.map(
                                (b) => Circle(
                              circleId: CircleId(b.name),
                              center: b.location,
                              radius: b.radius,
                              fillColor: Colors.greenAccent.withOpacity(0.2),
                              strokeColor: Colors.green,
                              strokeWidth: 2,
                            ),
                          ),
                        },
                        zoomControlsEnabled: true,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                          Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                          Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                          Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                          Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                          Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(blue),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      onPressed: _saveBooth,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Booth', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: blue, width: 1.25),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: blue,
                      ),
                      onPressed: _resetForm,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Optional: Saved booths list (keeps original features and adds helpful review)
              if (savedBooths.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: const Icon(Icons.list_alt, color: blue),
                      title: const Text(
                        'Saved Booths',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: [
                        const Divider(height: 1),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedBooths.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final b = savedBooths[i];
                            return ListTile(
                              leading: const Icon(Icons.how_to_vote, color: blue),
                              title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(b.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                tooltip: 'View on map',
                                icon: const Icon(Icons.map, color: blue),
                                onPressed: () async {
                                  setState(() {
                                    selectedLocation = b.location;
                                    radius = b.radius;
                                    _nameCtrl.text = b.name;
                                    _addressCtrl.text = b.address;
                                  });
                                  await _mapController?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(target: b.location, zoom: 16),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
