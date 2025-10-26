import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPollingBoothPage extends StatefulWidget {
  const AddPollingBoothPage({super.key});

  @override
  State<AddPollingBoothPage> createState() => _AddPollingBoothPageState();
}

class Booth {
  final String name;
  String address;
  final LatLng location;
  final double radius;

  Booth({
    required this.name,
    required this.address,
    required this.location,
    required this.radius,
  });
}

// <CHANGE> Added StateDistrict model to parse JSON data
class StateDistrict {
  final String state;
  final List<String> districts;

  StateDistrict({
    required this.state,
    required this.districts,
  });

  factory StateDistrict.fromJson(Map<String, dynamic> json) {
    return StateDistrict(
      state: json['state'] as String,
      districts: List<String>.from(json['districts'] as List),
    );
  }
}

class LocationData {
  // <CHANGE> Replaced hardcoded data with JSON-loaded data
  static List<StateDistrict> stateDistrictList = [];

  static Future<void> loadFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      stateDistrictList = jsonData
          .map((item) => StateDistrict.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading JSON: $e');
    }
  }

  static List<String> getStates() {
    return stateDistrictList.map((sd) => sd.state).toList();
  }

  static List<String> getDistricts(String state) {
    final stateData = stateDistrictList.firstWhere(
          (sd) => sd.state == state,
      orElse: () => StateDistrict(state: '', districts: []),
    );
    return stateData.districts;
  }
}

class _AddPollingBoothPageState extends State<AddPollingBoothPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  String? selectedState;
  String? selectedDistrict;

  LatLng? selectedLocation;
  GoogleMapController? _mapController;

  double radius = 50;
  final List<Booth> savedBooths = [];

  bool _initializing = true;
  bool _geocoding = false;
  bool _loadingJson = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadJsonData().then((_) {
      _setInitialLocation().then((_) {
        _fetchSavedBooths();
      });
    });
  }

  // <CHANGE> Added method to load JSON from assets
  Future<void> _loadJsonData() async {
    try {
      final String jsonString =
      await DefaultAssetBundle.of(context).loadString('assets/states_districts.json');
      await LocationData.loadFromJson(jsonString);
      if (!mounted) return;
      setState(() {
        _loadingJson = false;
      });
    } catch (e) {
      print('Error loading JSON: $e');
      if (!mounted) return;
      setState(() {
        _loadingJson = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load location data')),
      );
    }
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

      await _fetchAddress(ll.latitude, ll.longitude);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: ll, zoom: 16)),
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
        String address = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country,
        ].where((e) => (e ?? '').toString().trim().isNotEmpty).join(', ');

        if (!mounted) return;
        setState(() {
          _addressCtrl.text = address.isNotEmpty
              ? address
              : "Address not found";
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
          CameraUpdate.newCameraPosition(CameraPosition(target: ll, zoom: 16)),
        );

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
      selectedState = null;
      selectedDistrict = null;
    });
    if (selectedLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: selectedLocation!, zoom: 16),
        ),
      );
    }
  }

  Future<void> _saveBooth() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedLocation == null) {
      Fluttertoast.showToast(msg: 'Please pick a location on the map');
      return;
    }

    final name = _nameCtrl.text.trim();
    final lat = selectedLocation!.latitude;
    final lng = selectedLocation!.longitude;

    print('Saving booth: name=$name, lat=$lat, lng=$lng, radius=$radius');

    if (name.isEmpty || lat == null || lng == null) {
      Fluttertoast.showToast(msg: "Name, latitude, and longitude are required");
      return;
    }

    final boothData = {
      'name': _nameCtrl.text.trim(),
      'lat': selectedLocation!.latitude,
      'lng': selectedLocation!.longitude,
      'radius': radius,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Fluttertoast.showToast(msg: "Please log in first");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://voting-backend-6px8.onrender.com/api/admin/booths'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(boothData),
      );

      print('Response: ${response.statusCode} ${response.body}');

      final jsonResp = jsonDecode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          jsonResp['success'] == true) {
        Fluttertoast.showToast(msg: "Polling Booth Added!");
        _fetchSavedBooths();
      } else {
        Fluttertoast.showToast(
          msg: jsonResp['message'] ?? "Failed to add booth",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error connecting to server");
    }
  }

  Future<void> _fetchSavedBooths() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Fluttertoast.showToast(msg: "Please log in first");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://voting-backend-6px8.onrender.com/api/admin/booths'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['booths'] != null) {
          final List<dynamic> boothsJson = data['booths'];

          final List<Booth> booths = boothsJson.map((b) {
            final loc = LatLng(
              (b['latitude'] ?? 0).toDouble(),
              (b['longitude'] ?? 0).toDouble(),
            );
            return Booth(
              name: b['name'] ?? '',
              address: '',
              location: loc,
              radius: (b['radius_meters'] ?? 50).toDouble(),
            );
          }).toList();

          await Future.wait(
            booths.map((b) async {
              try {
                final placemarks = await placemarkFromCoordinates(
                  b.location.latitude,
                  b.location.longitude,
                );
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  b.address = [
                    place.street,
                    place.locality,
                    place.postalCode,
                    place.country,
                  ].where((e) => e != null && e.isNotEmpty).join(', ');
                } else {
                  b.address = "Address not found";
                }
              } catch (e) {
                b.address = "Failed to fetch address";
              }
            }),
          );

          if (!mounted) return;
          setState(() {
            savedBooths.clear();
            savedBooths.addAll(booths);
          });
        } else {
          Fluttertoast.showToast(msg: "No booths found");
        }
      } else {
        Fluttertoast.showToast(msg: "Failed to fetch booths");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching booths");
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Colors.blue;

    // <CHANGE> Added loading state for JSON data
    if (_loadingJson) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Polling Booth'),
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 1.5,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: blue),
        ),
      );
    }

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
                        // <CHANGE> Updated State dropdown to use JSON data
                        DropdownButtonFormField<String>(
                          value: selectedState,
                          decoration: InputDecoration(
                            labelText: 'State',
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: blue,
                            ),
                            labelStyle: const TextStyle(color: blue),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: blue),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: blue, width: 2),
                            ),
                          ),
                          items: LocationData.getStates()
                              .map(
                                (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedState = value;
                              selectedDistrict = null;
                            });
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please select a state';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // <CHANGE> Updated District dropdown to use JSON data
                        if (selectedState != null)
                          DropdownButtonFormField<String>(
                            value: selectedDistrict,
                            decoration: InputDecoration(
                              labelText: 'District',
                              prefixIcon: const Icon(
                                Icons.location_city,
                                color: blue,
                              ),
                              labelStyle: const TextStyle(color: blue),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: blue),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: blue, width: 2),
                              ),
                            ),
                            items: LocationData.getDistricts(selectedState!)
                                .map(
                                  (district) => DropdownMenuItem(
                                value: district,
                                child: Text(district),
                              ),
                            )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDistrict = value;
                              });
                            },
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please select a district';
                              }
                              return null;
                            },
                          ),
                        if (selectedDistrict != null)
                          const SizedBox(height: 16),

                        // <CHANGE> Removed City and Area dropdowns

                        // Booth Name
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Booth Name',
                            prefixIcon: const Icon(
                              Icons.how_to_vote,
                              color: blue,
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
                                  onPressed: _geocoding
                                      ? null
                                      : _forwardGeocodeAndMove,
                                  icon: _geocoding
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: blue,
                                    ),
                                  )
                                      : const Icon(Icons.search, color: blue),
                                ),
                                IconButton(
                                  tooltip: 'Use current location',
                                  onPressed: _recenterToCurrent,
                                  icon: const Icon(
                                    Icons.my_location,
                                    color: blue,
                                  ),
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
                          if (selectedLocation != null)
                            Marker(
                              markerId: const MarkerId('current'),
                              position: selectedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                              infoWindow: InfoWindow(
                                title: _nameCtrl.text.isEmpty
                                    ? 'Selected Location'
                                    : _nameCtrl.text,
                                snippet: _addressCtrl.text,
                              ),
                            ),
                          ...savedBooths.map(
                                (b) => Marker(
                              markerId: MarkerId(b.name),
                              position: b.location,
                              infoWindow: InfoWindow(
                                title: b.name,
                                snippet: b.address,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                          ),
                        },
                        circles: {
                          if (selectedLocation != null)
                            Circle(
                              circleId: const CircleId('currentRadius'),
                              center: selectedLocation!,
                              radius: radius,
                              fillColor: Colors.blueAccent.withOpacity(
                                0.2,
                              ),
                              strokeColor: blue,
                              strokeWidth: 2,
                            ),
                          ...savedBooths.map(
                                (b) => Circle(
                              circleId: CircleId(b.name),
                              center: b.location,
                              radius: b.radius,
                              fillColor: Colors.greenAccent.withOpacity(
                                0.2,
                              ),
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
                        gestureRecognizers:
                        <Factory<OneSequenceGestureRecognizer>>{
                          Factory<PanGestureRecognizer>(
                                () => PanGestureRecognizer(),
                          ),
                          Factory<ScaleGestureRecognizer>(
                                () => ScaleGestureRecognizer(),
                          ),
                          Factory<TapGestureRecognizer>(
                                () => TapGestureRecognizer(),
                          ),
                          Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer(),
                          ),
                          Factory<HorizontalDragGestureRecognizer>(
                                () => HorizontalDragGestureRecognizer(),
                          ),
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
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: _saveBooth,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Booth',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: blue, width: 1.25),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: blue,
                      ),
                      onPressed: _resetForm,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Reset',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Saved booths list
              if (savedBooths.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                              leading: const Icon(
                                Icons.how_to_vote,
                                color: blue,
                              ),
                              title: Text(
                                b.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                b.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                                      CameraPosition(
                                        target: b.location,
                                        zoom: 16,
                                      ),
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