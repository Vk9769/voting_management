import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class PollingBoothCardPage extends StatefulWidget {
  final String boothName;
  final double boothLat;
  final double boothLng;

  const PollingBoothCardPage({
    super.key,
    required this.boothName,
    required this.boothLat,
    required this.boothLng,
  });

  @override
  State<PollingBoothCardPage> createState() => _PollingBoothCardPageState();
}

class _PollingBoothCardPageState extends State<PollingBoothCardPage> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _distance = "Calculating...";
  String _duration = "";

  final String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: "Location permissions are permanently denied. Enable from settings.");
      return;
    }

    Position position =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    _currentPosition = LatLng(position.latitude, position.longitude);

    _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentPosition!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));

    _markers.add(Marker(
        markerId: const MarkerId('pollingBooth'),
        position: LatLng(widget.boothLat, widget.boothLng),
        infoWindow: InfoWindow(title: widget.boothName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));

    await _getDirections();
  }

  Future<void> _getDirections() async {
    if (_currentPosition == null) return;

    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${widget.boothLat},${widget.boothLng}&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if ((data['routes'] as List).isNotEmpty) {
          var route = data['routes'][0];
          String distanceText = route['legs'][0]['distance']['text'];
          String durationText = route['legs'][0]['duration']['text'];

          List<PointLatLng> points =
          _decodePolyline(route['overview_polyline']['points']);
          Set<Polyline> polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
              color: Colors.blue,
              width: 5,
            ),
          };

          setState(() {
            _distance = distanceText;
            _duration = durationText;
            _polylines = polylines;
          });
        } else {
          setState(() {
            _distance = "Route not found";
            _duration = "";
          });
        }
      } else {
        setState(() {
          _distance = "Error fetching route";
          _duration = "";
        });
      }
    } catch (e) {
      setState(() {
        _distance = "Error: $e";
        _duration = "";
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

  void _openFullMap() {
    if (_currentPosition == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FullPollingBoothMapPage(
              boothName: widget.boothName,
              boothLat: widget.boothLat,
              boothLng: widget.boothLng,
              currentPosition: _currentPosition!,
              markers: _markers,
              polylines: _polylines,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Polling Booth"), backgroundColor: Colors.blue),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Booth info & distance
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.boothName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_distance,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                        Text(_duration,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
              // Embedded Map
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                      target: _currentPosition!, zoom: 14),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _controller.complete(controller);
                  },
                ),
              ),
              // Open full map
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  onPressed: _openFullMap,
                  icon: const Icon(Icons.map),
                  label: const Text("Open Full Map"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FullPollingBoothMapPage extends StatelessWidget {
  final String boothName;
  final double boothLat;
  final double boothLng;
  final LatLng currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const FullPollingBoothMapPage({
    super.key,
    required this.boothName,
    required this.boothLat,
    required this.boothLng,
    required this.currentPosition,
    required this.markers,
    required this.polylines,
  });

  @override
  Widget build(BuildContext context) {
    Completer<GoogleMapController> controller = Completer();

    return Scaffold(
      appBar: AppBar(title: const Text("Full Map"), backgroundColor: Colors.blue),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: currentPosition, zoom: 14),
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (c) => controller.complete(c),
      ),
    );
  }
}

class PointLatLng {
  final double latitude;
  final double longitude;
  PointLatLng(this.latitude, this.longitude);
}
