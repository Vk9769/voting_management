import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PollingBoothMapPagee extends StatefulWidget {
  final String boothName;
  final double boothLat;
  final double boothLng;
  final String? agentName; // 👈 nullable
  final String? agentId;

  const PollingBoothMapPagee({
    super.key,
    required this.boothName,
    required this.boothLat,
    required this.boothLng,
    this.agentName, // 👈 made optional
    this.agentId,   // 👈 made optional
  });

  @override
  State<PollingBoothMapPagee> createState() => _PollingBoothMapPageeState();
}

class _PollingBoothMapPageeState extends State<PollingBoothMapPagee> {
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? _controller;
  Position? _currentPosition;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isInsideRadius = false;
  double? _distanceMeters;
  String _distanceText = 'Calculating...';
  String _durationText = '';
  bool _loading = true;

  final double boothRadius = 100.0; // meters
  final String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await _getCurrentLocation();
    if (_currentPosition != null) {
      await _getDirections();
    }
    setState(() => _loading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required.')),
            );
          }
          return;
        }
      }

      final position =
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.boothLat,
        widget.boothLng,
      );

      setState(() {
        _currentPosition = position;
        _distanceMeters = distance;
        _isInsideRadius = distance <= boothRadius;

        _markers = {
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
          Marker(
            markerId: const MarkerId('booth'),
            position: LatLng(widget.boothLat, widget.boothLng),
            infoWindow: InfoWindow(title: widget.boothName),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _getDirections() async {
    if (_currentPosition == null) return;
    final origin =
        '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final destination = '${widget.boothLat},${widget.boothLng}';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if ((data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final points = _decodePolyline(route['overview_polyline']['points']);

        setState(() {
          _distanceText = leg['distance']['text'];
          _durationText = leg['duration']['text'];
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points:
              points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            ),
          };
        });
      } else {
        setState(() {
          _distanceText = 'No route found';
          _durationText = '';
        });
      }
    } catch (e) {
      setState(() {
        _distanceText = 'Error fetching route';
        _durationText = '';
      });
    }
  }

  List<PointLatLng> _decodePolyline(String encoded) {
    List<PointLatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(PointLatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  Future<void> _openDirections() async {
    if (_currentPosition == null) return;
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${widget.boothLat},${widget.boothLng}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _centerOnBooth() async {
    if (_controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(widget.boothLat, widget.boothLng), 16),
    );
  }

  Future<void> _centerOnMe() async {
    if (_controller == null || _currentPosition == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16,
      ),
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '—';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocated Polling Booth'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.blue.withOpacity(0.12),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // children: [
                              //   Text('Agent: ${widget.agentName}',
                              //       style: const TextStyle(fontWeight: FontWeight.w700)),
                              //   Text('ID: ${widget.agentId}'),
                              //   Text('Booth: ${widget.boothName}',
                              //       style: const TextStyle(fontSize: 16)),
                              // ],
                              children: [
                                Text('Agent: ABC',
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('ID: MH/2025/56725'),
                                Text('Booth: ${widget.boothName}',
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _StatusChip(isInside: _isInsideRadius),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Distance: $_distanceText'),
                          Text('Duration: $_durationText'),
                          TextButton.icon(
                            onPressed: _initLocation,
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            label: const Text('Refresh', style: TextStyle(color: Colors.blue)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.boothLat, widget.boothLng),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) {
                      _controller = controller;
                      if (!_mapController.isCompleted) _mapController.complete(controller);
                    },
                    markers: _markers,
                    polylines: _polylines,
                    circles: {
                      Circle(
                        circleId: const CircleId('radius'),
                        center: LatLng(widget.boothLat, widget.boothLng),
                        radius: boothRadius,
                        fillColor: Colors.blue.withOpacity(0.12),
                        strokeColor: Colors.blue,
                        strokeWidth: 2,
                      ),
                    },
                    myLocationEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _centerOnBooth,
                      icon: const Icon(Icons.place),
                      label: const Text('Center Booth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _centerOnMe,
                      icon: const Icon(Icons.my_location, color: Colors.blue),
                      label: const Text('Center Me', style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isInside;
  const _StatusChip({required this.isInside});

  @override
  Widget build(BuildContext context) {
    final color = isInside ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isInside ? Icons.check_circle : Icons.error_outline, size: 16, color: color),
          const SizedBox(width: 6),
          Text(isInside ? 'Inside Booth Area' : 'Outside Booth Area',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class PointLatLng {
  final double latitude;
  final double longitude;
  PointLatLng(this.latitude, this.longitude);
}
