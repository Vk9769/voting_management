import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class IndiaBoothsMap extends StatefulWidget {
  const IndiaBoothsMap({Key? key}) : super(key: key);

  @override
  State<IndiaBoothsMap> createState() => _IndiaBoothsMapState();
}

class _IndiaBoothsMapState extends State<IndiaBoothsMap> {
  late GoogleMapController mapController;
  String? selectedState;
  Set<Polygon> polygons = {};
  Set<Marker> markers = {};

  final Map<String, int> stateBoothData = {
    'Andhra Pradesh': 12450,
    'Arunachal Pradesh': 1850,
    'Assam': 15200,
    'Bihar': 24300,
    'Chhattisgarh': 10500,
    'Delhi': 8900,
    'Goa': 1200,
    'Gujarat': 18500,
    'Haryana': 9800,
    'Himachal Pradesh': 4500,
    'Jharkhand': 11200,
    'Karnataka': 16700,
    'Kerala': 9300,
    'Madhya Pradesh': 21000,
    'Maharashtra': 27800,
    'Manipur': 2100,
    'Meghalaya': 3400,
    'Mizoram': 1050,
    'Nagaland': 1850,
    'Odisha': 14200,
    'Punjab': 10900,
    'Rajasthan': 19400,
    'Sikkim': 780,
    'Tamil Nadu': 18900,
    'Telangana': 11200,
    'Tripura': 2800,
    'Uttar Pradesh': 40500,
    'Uttarakhand': 6200,
    'West Bengal': 20100,
  };

  // Detailed state boundary coordinates (more accurate state shapes)
  final Map<String, List<LatLng>> stateCoordinates = {
    'Andhra Pradesh': [
      LatLng(13.0, 79.5),
      LatLng(13.5, 80.0),
      LatLng(14.5, 79.8),
      LatLng(15.9, 78.6),
      LatLng(16.0, 78.0),
      LatLng(15.5, 77.5),
      LatLng(14.0, 78.0),
    ],
    'Arunachal Pradesh': [
      LatLng(27.5, 94.0),
      LatLng(29.0, 93.5),
      LatLng(29.5, 95.5),
      LatLng(28.0, 96.5),
      LatLng(26.0, 95.0),
    ],
    'Assam': [
      LatLng(24.0, 90.0),
      LatLng(26.0, 91.0),
      LatLng(28.0, 91.0),
      LatLng(28.5, 95.0),
      LatLng(26.0, 96.0),
      LatLng(24.5, 93.0),
    ],
    'Bihar': [
      LatLng(24.0, 84.0),
      LatLng(25.5, 84.5),
      LatLng(27.5, 84.5),
      LatLng(28.0, 87.0),
      LatLng(26.5, 87.5),
      LatLng(25.0, 86.0),
    ],
    'Chhattisgarh': [
      LatLng(19.0, 80.0),
      LatLng(21.5, 80.0),
      LatLng(23.0, 80.5),
      LatLng(23.5, 84.0),
      LatLng(21.0, 84.5),
      LatLng(20.0, 82.0),
    ],
    'Delhi': [
      LatLng(28.4, 77.0),
      LatLng(28.8, 77.0),
      LatLng(28.9, 77.3),
      LatLng(28.5, 77.3),
    ],
    'Goa': [
      LatLng(14.8, 73.7),
      LatLng(15.8, 73.7),
      LatLng(15.8, 74.3),
      LatLng(14.8, 74.3),
    ],
    'Gujarat': [
      LatLng(20.0, 70.0),
      LatLng(22.5, 70.0),
      LatLng(24.5, 71.5),
      LatLng(24.5, 73.5),
      LatLng(20.5, 73.5),
    ],
    'Haryana': [
      LatLng(27.5, 77.0),
      LatLng(29.5, 77.0),
      LatLng(30.5, 77.5),
      LatLng(29.0, 78.0),
    ],
    'Himachal Pradesh': [
      LatLng(30.0, 77.0),
      LatLng(32.0, 77.0),
      LatLng(33.0, 78.5),
      LatLng(31.0, 79.0),
    ],
    'Jharkhand': [
      LatLng(22.0, 84.0),
      LatLng(24.0, 84.0),
      LatLng(25.5, 85.5),
      LatLng(24.0, 86.5),
      LatLng(22.5, 85.5),
    ],
    'Karnataka': [
      LatLng(11.5, 74.0),
      LatLng(15.0, 74.0),
      LatLng(18.5, 77.0),
      LatLng(18.5, 78.0),
      LatLng(12.5, 77.5),
    ],
    'Kerala': [
      LatLng(8.5, 76.0),
      LatLng(12.5, 76.0),
      LatLng(12.5, 77.5),
      LatLng(8.5, 77.5),
    ],
    'Madhya Pradesh': [
      LatLng(20.0, 77.0),
      LatLng(23.0, 77.0),
      LatLng(24.5, 82.5),
      LatLng(21.0, 82.5),
    ],
    'Maharashtra': [
      LatLng(16.0, 72.0),
      LatLng(19.5, 72.0),
      LatLng(22.5, 77.0),
      LatLng(22.5, 78.0),
      LatLng(16.5, 74.0),
    ],
    'Manipur': [
      LatLng(24.0, 93.5),
      LatLng(25.5, 93.5),
      LatLng(25.5, 94.5),
      LatLng(24.0, 94.5),
    ],
    'Meghalaya': [
      LatLng(24.5, 90.5),
      LatLng(26.0, 90.5),
      LatLng(26.0, 92.5),
      LatLng(24.5, 92.5),
    ],
    'Mizoram': [
      LatLng(21.5, 92.0),
      LatLng(24.5, 92.0),
      LatLng(24.5, 93.5),
      LatLng(21.5, 93.5),
    ],
    'Nagaland': [
      LatLng(25.5, 93.5),
      LatLng(27.0, 93.5),
      LatLng(27.0, 95.5),
      LatLng(25.5, 95.5),
    ],
    'Odisha': [
      LatLng(17.5, 84.0),
      LatLng(20.5, 84.0),
      LatLng(22.5, 87.5),
      LatLng(19.0, 87.5),
    ],
    'Punjab': [
      LatLng(29.5, 74.0),
      LatLng(32.5, 74.0),
      LatLng(32.5, 76.5),
      LatLng(29.5, 76.5),
    ],
    'Rajasthan': [
      LatLng(23.0, 70.0),
      LatLng(27.0, 70.0),
      LatLng(30.0, 75.0),
      LatLng(30.0, 78.0),
      LatLng(23.0, 76.0),
    ],
    'Sikkim': [
      LatLng(27.0, 88.0),
      LatLng(28.5, 88.0),
      LatLng(28.5, 89.0),
      LatLng(27.0, 89.0),
    ],
    'Tamil Nadu': [
      LatLng(8.0, 77.0),
      LatLng(13.5, 77.0),
      LatLng(13.5, 80.0),
      LatLng(8.0, 80.0),
    ],
    'Telangana': [
      LatLng(16.0, 78.0),
      LatLng(18.5, 78.0),
      LatLng(20.0, 80.5),
      LatLng(17.0, 80.5),
    ],
    'Tripura': [
      LatLng(22.5, 91.0),
      LatLng(24.5, 91.0),
      LatLng(24.5, 92.5),
      LatLng(22.5, 92.5),
    ],
    'Uttar Pradesh': [
      LatLng(24.0, 78.0),
      LatLng(26.0, 78.0),
      LatLng(29.5, 82.0),
      LatLng(29.5, 84.0),
      LatLng(26.0, 84.0),
    ],
    'Uttarakhand': [
      LatLng(29.0, 78.5),
      LatLng(31.5, 78.5),
      LatLng(31.5, 81.0),
      LatLng(29.0, 81.0),
    ],
    'West Bengal': [
      LatLng(21.5, 87.0),
      LatLng(27.5, 87.0),
      LatLng(27.5, 89.0),
      LatLng(21.5, 89.0),
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Only create markers at state centers
    stateCoordinates.forEach((state, coordinates) {
      // Add markers at state centers
      var centerLat = coordinates.fold(0.0, (sum, p) => sum + p.latitude) / coordinates.length;
      var centerLng = coordinates.fold(0.0, (sum, p) => sum + p.longitude) / coordinates.length;

      markers.add(
        Marker(
          markerId: MarkerId(state),
          position: LatLng(centerLat, centerLng),
          infoWindow: InfoWindow(
            title: state,
            snippet: '${stateBoothData[state]} booths',
          ),
          onTap: () {
            debugPrint('[v0] Tapped on marker: $state');
            _onStateTapped(state);
          },
        ),
      );
    });

    setState(() {});
  }

  void _onStateTapped(String state) {
    setState(() {
      selectedState = state;
    });
    _showBoothDialog(state);
  }

  void _showBoothDialog(String state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          state,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Polling Booths:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stateBoothData[state] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This represents the number of polling stations available in this state for elections.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(20.5937, 78.9629), // India center
          zoom: 4.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('India Polling Booths Map'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(20.5937, 78.9629),
                zoom: 4.8,
              ),
              minMaxZoomPreference: const MinMaxZoomPreference(4.0, 8.0),
              cameraTargetBounds: CameraTargetBounds(
                LatLngBounds(
                  southwest: const LatLng(6.0, 68.0), // India's SW corner
                  northeast: const LatLng(37.0, 97.0), // India's NE corner
                ),
              ),
              markers: markers,
              onTap: (LatLng tappedPoint) {
                _checkStateTap(tappedPoint);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue[50],
            child: selectedState != null
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected State: $selectedState',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Polling Booths: ${stateBoothData[selectedState] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            )
                : const Text(
              'Tap on any state to view polling booth information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Point-in-polygon detection method
  void _checkStateTap(LatLng tappedPoint) {
    for (var entry in stateCoordinates.entries) {
      if (_isPointInPolygon(tappedPoint, entry.value)) {
        debugPrint('[v0] Point in polygon for: ${entry.key}');
        _onStateTapped(entry.key);
        return;
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int n = polygon.length;
    bool inside = false;

    double p1lat = polygon[0].latitude;
    double p1lng = polygon[0].longitude;
    for (int i = 1; i <= n; i++) {
      double p2lat = polygon[i % n].latitude;
      double p2lng = polygon[i % n].longitude;
      if (point.latitude > (p1lat < p2lat ? p1lat : p2lat)) {
        if (point.latitude <= (p1lat > p2lat ? p1lat : p2lat)) {
          if (point.longitude <= (p1lng > p2lng ? p1lng : p2lng)) {
            if (p1lat != p2lat) {
              double xinters = (point.latitude - p1lat) * (p2lng - p1lng) / (p2lat - p1lat) + p1lng;
              if (p1lng == p2lng || point.longitude <= xinters) {
                inside = !inside;
              }
            }
          }
        }
      }
      p1lat = p2lat;
      p1lng = p2lng;
    }
    return inside;
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
