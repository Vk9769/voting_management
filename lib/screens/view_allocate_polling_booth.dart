import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ViewAllocatePollingBoothPage extends StatefulWidget {
  const ViewAllocatePollingBoothPage({super.key});

  @override
  State<ViewAllocatePollingBoothPage> createState() => _ViewAllocatePollingBoothPageState();
}

class _ViewAllocatePollingBoothPageState extends State<ViewAllocatePollingBoothPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? _controller;
  Position? _currentPosition;
  bool _isInsideRadius = false;
  double? _distanceMeters;

  // Demo agent & booth info (features unchanged)
  final String agentName = 'ABC';
  final String agentId = 'AGT-0013';
  final String boothName = 'Booth 100';
  final double boothLat = 26.145685863730833;
  final double boothLng = 84.29060636137021;
  final double boothRadius = 100.0; // meters

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required to show your position.')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        boothLat,
        boothLng,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _distanceMeters = distance;
        _isInsideRadius = distance <= boothRadius;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _centerOnBooth() async {
    if (_controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(boothLat, boothLng), zoom: 16),
      ),
    );
  }

  Future<void> _centerOnMe() async {
    if (_currentPosition == null || _controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 16,
        ),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocated Polling Booth'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SafeArea(
        child: Column(
          children: [
            // Header card with agent & booth info + status chip
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              children: [
                                Text(
                                  'Agent: $agentName',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text('ID: $agentId', style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
                                const SizedBox(height: 6),
                                Text(
                                  'Allocated Booth: $boothName',
                                  style: theme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _StatusChip(isInside: _isInsideRadius),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Distance: ${_formatDistance(_distanceMeters)}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location, color: Colors.blue, size: 18),
                            label: const Text('Refresh', style: TextStyle(color: Colors.blue)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Map area inside an elevated card with rounded corners and controls
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: RepaintBoundary(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(boothLat, boothLng),
                              zoom: 16,
                            ),
                            onMapCreated: (controller) {
                              _controller = controller;
                              if (!_mapController.isCompleted) {
                                _mapController.complete(controller);
                              }
                            },
                            zoomControlsEnabled: true,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: false,
                            rotateGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            markers: {
                              Marker(
                                markerId: const MarkerId('agent'),
                                position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                infoWindow: const InfoWindow(title: 'Your Location'),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                              ),
                              Marker(
                                markerId: const MarkerId('booth'),
                                position: LatLng(boothLat, boothLng),
                                infoWindow: InfoWindow(title: boothName),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            },
                            circles: {
                              Circle(
                                circleId: const CircleId('radius'),
                                center: LatLng(boothLat, boothLng),
                                radius: boothRadius,
                                fillColor: Colors.blue.withOpacity(0.12),
                                strokeColor: Colors.blue,
                                strokeWidth: 2,
                              ),
                            },
                          ),
                        ),
                        // Top-right legend
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                _LegendDot(color: Colors.blue),
                                SizedBox(width: 6),
                                Text('You'),
                                SizedBox(width: 10),
                                _LegendDot(color: Colors.red),
                                SizedBox(width: 6),
                                Text('Booth'),
                              ],
                            ),
                          ),
                        ),
                        // Bottom controls: recenter to booth / me
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _centerOnBooth,
                                  icon: const Icon(Icons.place),
                                  label: const Text('Center on Booth'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _centerOnMe,
                                  icon: const Icon(Icons.person_pin_circle, color: Colors.blue),
                                  label: const Text('Center on Me', style: TextStyle(color: Colors.blue)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.blue, width: 1.25),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isInside});
  final bool isInside;

  @override
  Widget build(BuildContext context) {
    final bool inside = isInside;
    final Color fg = inside ? Colors.green : Colors.red;
    final Color bg = fg.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(inside ? Icons.check_circle : Icons.error_outline, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            inside ? 'Inside Polling Booth Area' : 'Outside Polling Booth Area',
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
