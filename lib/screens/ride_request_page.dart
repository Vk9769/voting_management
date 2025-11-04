// 📄 ride_request_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RideRequestPage extends StatefulWidget {
  const RideRequestPage({Key? key}) : super(key: key);

  @override
  State<RideRequestPage> createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  String _pickup = 'Your location';
  String _destination = '';
  bool _isSelectingDestination = false;

  String _currentStep = 'selectVehicle'; // selectVehicle → searching → driverFound

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });
  }

  Future<void> _goToMyLocation() async {
    if (_currentPosition == null) return;
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
  }

  void _onRequestRide() {
    setState(() => _currentStep = 'searching');
    Future.delayed(const Duration(seconds: 3), () {
      setState(() => _currentStep = 'driverFound');
    });
  }

  Widget _buildTopSearchBar() {
    return Positioned(
      top: 50,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _isSelectingDestination = false);
                _showLocationSearchDialog(isPickup: true);
              },
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_pickup,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const Divider(height: 15),
            GestureDetector(
              onTap: () {
                setState(() => _isSelectingDestination = true);
                _showLocationSearchDialog(isPickup: false);
              },
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _destination.isEmpty ? "Enter destination" : _destination,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _destination.isEmpty ? Colors.grey : Colors.black,
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

  void _showLocationSearchDialog({required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: isPickup ? "Enter pickup location" : "Enter destination",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(isPickup ? Icons.my_location : Icons.location_on),
              ),
              onSubmitted: (value) {
                setState(() {
                  if (isPickup) {
                    _pickup = value;
                  } else {
                    _destination = value;
                  }
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 15),
            const Text("Recent locations (mock):",
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ...["Home", "Office", "Mall Road", "Airport"].map((e) => ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(e),
              onTap: () {
                setState(() {
                  if (isPickup) {
                    _pickup = e;
                  } else {
                    _destination = e;
                  }
                });
                Navigator.pop(context);
              },
            ))
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    if (_currentStep == 'searching') {
      return _buildSearchingSheet();
    } else if (_currentStep == 'driverFound') {
      return _buildDriverFoundSheet();
    }
    return _buildSelectVehicleSheet();
  }

  Widget _buildSelectVehicleSheet() {
    final vehicles = [
      {"name": "Bike", "price": "₹45", "time": "3 min", "icon": Icons.pedal_bike},
      {"name": "Auto", "price": "₹70", "time": "5 min", "icon": Icons.electric_rickshaw},
      {"name": "Prime", "price": "₹120", "time": "7 min", "icon": Icons.directions_car},
      {"name": "Sedan", "price": "₹180", "time": "8 min", "icon": Icons.local_taxi},
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 10),
          const Text("Choose your ride", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...vehicles.map((v) => Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Icon(v["icon"] as IconData, color: Colors.indigo),
              title: Text(v["name"] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("Arrival: ${v["time"]}"),
              trailing: Text(v["price"] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: _onRequestRide,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSearchingSheet() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Colors.indigo),
          SizedBox(height: 15),
          Text("Looking for drivers nearby...", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDriverFoundSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 15),
          const Text("Driver Found!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 10),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage("https://cdn-icons-png.flaticon.com/512/2922/2922510.png"),
              radius: 28,
            ),
            title: const Text("Amit Sharma", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("KA03 AB 4567 • Prime Sedan"),
            trailing: IconButton(
              icon: const Icon(Icons.call, color: Colors.indigo),
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride started (mock)!")));
            },
            icon: const Icon(Icons.navigation),
            label: const Text("Start Ride"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(20.5937, 78.9629),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          _buildTopSearchBar(),
          Positioned(
            bottom: 10,
            right: 15,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location, color: Colors.indigo),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildBottomSheet(),
            ),
          ),
        ],
      ),
    );
  }
}
