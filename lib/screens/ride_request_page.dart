import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

// ============================================================================
// ENUMS & MODELS
// ============================================================================

enum RideStep {
  pickupLocation,
  destinationLocation,
  rideReview,
  findingDriver,
  driverAssigned,
  rideInProgress,
}

enum RideType {
  auto,
  bike,
  mini,
  comfort,
  premium,
}

class LocationModel {
  final String name;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class RideTypeModel {
  final RideType type;
  final String displayName;
  final String icon;
  final double basePrice;
  final double pricePerKm;
  final double pricePerMinute;
  final int capacity;

  RideTypeModel({
    required this.type,
    required this.displayName,
    required this.icon,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerMinute,
    required this.capacity,
  });
}

class DriverModel {
  final String id;
  final String name;
  final double rating;
  final int totalRides;
  final String vehicleModel;
  final String licensePlate;
  final String vehicleColor;
  final int eta;

  DriverModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalRides,
    required this.vehicleModel,
    required this.licensePlate,
    required this.vehicleColor,
    required this.eta,
  });
}

// ============================================================================
// MAIN PAGE
// ============================================================================

class RideRequestPage extends StatefulWidget {
  const RideRequestPage({Key? key}) : super(key: key);

  @override
  State<RideRequestPage> createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage>
    with TickerProviderStateMixin {

  bool _locationLoaded = false;

  late gmap.GoogleMapController _mapController;
  late AnimationController _pulseAnimationController;
  late AnimationController _driverSearchAnimationController;
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  late TextEditingController _promoCodeController;

  gmap.LatLng _centerPosition = const gmap.LatLng(0, 0);

  RideStep currentStep = RideStep.pickupLocation;
  LocationModel? pickupLocation;
  LocationModel? destinationLocation;
  RideType? selectedRideType = RideType.auto;
  double? estimatedFare;
  double? distanceInKm;
  int? estimatedDuration;
  String? appliedPromoCode;
  double discountPercent = 0;
  DriverModel? assignedDriver;
  Set<gmap.Marker> markers = {};
  Set<gmap.Polyline> polylines = {};
  double sheetHeight = 0.4;

  // Quick locations
  final List<LocationModel> quickLocations = [
    LocationModel(name: "🏠 Home", latitude: 37.7749, longitude: -122.4194),
    LocationModel(name: "💼 Work", latitude: 37.7849, longitude: -122.4094),
    LocationModel(name: "☕ Cafe", latitude: 37.7649, longitude: -122.4294),
    LocationModel(name: "🏥 Hospital", latitude: 37.7549, longitude: -122.4394),
  ];

  // Promo codes
  final Map<String, double> promoCodes = {
    "RIDE50": 0.10,
    "WELCOME": 0.15,
    "SAVE20": 0.20,
  };

  // Ride types
  final List<RideTypeModel> rideTypes = [
    RideTypeModel(
      type: RideType.bike,
      displayName: "Bike",
      icon: "🏍️",
      basePrice: 30,
      pricePerKm: 5,
      pricePerMinute: 1,
      capacity: 1,
    ),
    RideTypeModel(
      type: RideType.auto,
      displayName: "Auto",
      icon: "🚗",
      basePrice: 50,
      pricePerKm: 8,
      pricePerMinute: 1.5,
      capacity: 4,
    ),
    RideTypeModel(
      type: RideType.mini,
      displayName: "Mini",
      icon: "🚙",
      basePrice: 40,
      pricePerKm: 7,
      pricePerMinute: 1.2,
      capacity: 4,
    ),
    RideTypeModel(
      type: RideType.comfort,
      displayName: "Comfort",
      icon: "🚕",
      basePrice: 70,
      pricePerKm: 12,
      pricePerMinute: 2,
      capacity: 4,
    ),
    RideTypeModel(
      type: RideType.premium,
      displayName: "Premium",
      icon: "🚓",
      basePrice: 100,
      pricePerKm: 15,
      pricePerMinute: 2.5,
      capacity: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController();
    _destinationController = TextEditingController();
    _promoCodeController = TextEditingController();
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _driverSearchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _calculateInitialFare();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _promoCodeController.dispose();
    _pulseAnimationController.dispose();
    _driverSearchAnimationController.dispose();
    super.dispose();
  }

  void _onMapCreated(gmap.GoogleMapController controller) {
    _mapController = controller;
    _setDarkMapStyle();
    _getCurrentLocation();
  }

  void _setDarkMapStyle() {
    _mapController.setMapStyle('''
      [
        {
          "elementType": "geometry",
          "stylers": [{"color": "#242f3e"}]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#242f3e"}]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#746855"}]
        },
        {
          "featureType": "administrative.locality",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#d59563"}]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#d59563"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [{"color": "#263c3f"}]
        },
        {
          "featureType": "road",
          "elementType": "geometry",
          "stylers": [{"color": "#38414e"}]
        },
        {
          "featureType": "road",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#212a37"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry",
          "stylers": [{"color": "#746855"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#1f2835"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#f3791a"}]
        },
        {
          "featureType": "transit",
          "elementType": "geometry",
          "stylers": [{"color": "#2f3948"}]
        },
        {
          "featureType": "transit.station",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#d59563"}]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [{"color": "#17263c"}]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#515c6d"}]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#17263c"}]
        }
      ]
    ''');
  }

  List<LocationModel> getLocationSuggestions(String input) {
    if (input.isEmpty) return quickLocations;
    return [
      LocationModel(
        name: input,
        latitude: 37.7749 + (input.length * 0.001),
        longitude: -122.4194 + (input.length * 0.001),
      ),
    ];
  }

  void _selectPickupLocation(LocationModel location) {
    setState(() {
      pickupLocation = location;
      _pickupController.text = location.name;
      _addMarker(location, "Pickup");
      currentStep = RideStep.destinationLocation;
    });
  }

  void _selectDestinationLocation(LocationModel location) {
    setState(() {
      destinationLocation = location;
      _destinationController.text = location.name;
      _addMarker(location, "Destination");
      _drawRoute();
      _calculateFare();
      currentStep = RideStep.rideReview;
    });
  }

  void _addMarker(LocationModel location, String label) {
    setState(() {
      markers.add(
        gmap.Marker(
          markerId: gmap.MarkerId(label),
          position: gmap.LatLng(location.latitude, location.longitude),
          infoWindow: gmap.InfoWindow(title: label, snippet: location.name),
          icon: label == "Pickup"
              ? gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueBlue)
              : gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _drawRoute() async {
    if (pickupLocation == null || destinationLocation == null) return;

    PolylinePoints polylinePoints = PolylinePoints(apiKey: 'YOUR_GOOGLE_MAPS_API_KEY');

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(pickupLocation!.latitude, pickupLocation!.longitude),
        destination: PointLatLng(destinationLocation!.latitude, destinationLocation!.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        polylines.add(
          gmap.Polyline(
            polylineId: const gmap.PolylineId("route"),
            width: 5,
            color: const Color(0xFFFF6B35),
            points: result.points
                .map((p) => gmap.LatLng(p.latitude, p.longitude))
                .toList(),
          ),
        );
      });

      _animateCamera();
    }
  }


  void _animateCamera() {
    if (pickupLocation == null || destinationLocation == null) return;

    gmap.LatLngBounds bounds = gmap.LatLngBounds(
      southwest: gmap.LatLng(
        min(pickupLocation!.latitude, destinationLocation!.latitude),
        min(pickupLocation!.longitude, destinationLocation!.longitude),
      ),
      northeast: gmap.LatLng(
        max(pickupLocation!.latitude, destinationLocation!.latitude),
        max(pickupLocation!.longitude, destinationLocation!.longitude),
      ),
    );

    _mapController.animateCamera(
      gmap.CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _calculateFare() {
    if (pickupLocation != null && destinationLocation != null) {
      double distance = _calculateDistance(
        pickupLocation!.latitude,
        pickupLocation!.longitude,
        destinationLocation!.latitude,
        destinationLocation!.longitude,
      );
      distanceInKm = distance;
      estimatedDuration = (distance / 40 * 60).toInt();

      RideTypeModel rideType =
      rideTypes.firstWhere((r) => r.type == selectedRideType);
      double baseFare = rideType.basePrice;
      double distanceFare = distance * rideType.pricePerKm;
      double timeFare = (estimatedDuration! * rideType.pricePerMinute);
      estimatedFare = baseFare + distanceFare + timeFare;
    }
  }

  void _calculateInitialFare() {
    selectedRideType = RideType.auto;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _applyPromoCode(String code) {
    if (promoCodes.containsKey(code.toUpperCase())) {
      setState(() {
        appliedPromoCode = code.toUpperCase();
        discountPercent = promoCodes[code.toUpperCase()]!;
        _promoCodeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo code "$code" applied! ${(discountPercent * 100).toInt()}% off'),
          backgroundColor: const Color(0xFFFF6B35),
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

  void _findDriver() {
    setState(() => currentStep = RideStep.findingDriver);
    _driverSearchAnimationController.repeat();

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        assignedDriver = DriverModel(
          id: "DRV${Random().nextInt(9999)}",
          name: ["John Smith", "Sarah Johnson", "Mike Wilson", "Priya Sharma"].randomItem,
          rating: 4.5 + (Random().nextDouble() * 0.5),
          totalRides: 800 + Random().nextInt(500),
          vehicleModel: ["Toyota Prius", "Honda City", "Maruti Swift", "Hyundai i20"].randomItem,
          licensePlate: "ABC ${Random().nextInt(9999)}",
          vehicleColor: ["Silver", "Black", "White", "Blue"].randomItem,
          eta: 3 + Random().nextInt(8),
        );
        currentStep = RideStep.driverAssigned;
      });
      _driverSearchAnimationController.stop();
    });
  }

  Future<void> _updateAddressFromPin() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _centerPosition.latitude,
        _centerPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode
        ].where((e) => e != null && e.isNotEmpty).join(", ");

        setState(() {
          if (currentStep == RideStep.pickupLocation) {
            // ✅ Update Pickup
            _pickupController.text = address;
            pickupLocation = LocationModel(
              name: address,
              latitude: _centerPosition.latitude,
              longitude: _centerPosition.longitude,
            );
          } else if (currentStep == RideStep.destinationLocation) {
            // ✅ Update Destination
            _destinationController.text = address;
            destinationLocation = LocationModel(
              name: address,
              latitude: _centerPosition.latitude,
              longitude: _centerPosition.longitude,
            );
          }
        });
      }
    } catch (e) {
      print("Reverse Geocode Failed: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final currentLocation = await location.getLocation();

    setState(() {
      pickupLocation = LocationModel(
        name: "Current Location",
        latitude: currentLocation.latitude!,
        longitude: currentLocation.longitude!,
      );
      _centerPosition = gmap.LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _locationLoaded = true;   // ✅ now we have location
    });

    _mapController.animateCamera(
      gmap.CameraUpdate.newCameraPosition(
        gmap.CameraPosition(
          target: _centerPosition,
          zoom: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          gmap.GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: gmap.CameraPosition(
              target: _centerPosition,
              zoom: _locationLoaded ? 16 : 2, // zoomed out until location arrives
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (position) {
              _centerPosition = position.target;
            },
            onCameraIdle: _updateAddressFromPin,      // ✅ Called when user stop dragging map
          ),

          // Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                        onPressed: () {
                          if (currentStep == RideStep.pickupLocation) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              if (currentStep == RideStep.destinationLocation) {
                                currentStep = RideStep.pickupLocation;
                                _pickupController.clear();
                              } else if (currentStep == RideStep.rideReview) {
                                currentStep = RideStep.destinationLocation;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    Text(
                      _getStepTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.info_outline, color: Color(0xFF1A1A1A)),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (currentStep == RideStep.pickupLocation ||
              currentStep == RideStep.destinationLocation)
            Center(
              child: IgnorePointer(
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),

          // Bottom Sheet with Drag Handle
          DraggableScrollableSheet(
            initialChildSize: 0.32,   // starting height (32% of screen)
            minChildSize: 0.20,       // minimum height when collapsed
            maxChildSize: 0.90,       // maximum height when expanded
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,   // ✅ KEY PART
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildStepContent(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (currentStep) {
      case RideStep.pickupLocation:
        return "Pickup Location";
      case RideStep.destinationLocation:
        return "Destination";
      case RideStep.rideReview:
        return "Review Ride";
      case RideStep.findingDriver:
        return "Finding Driver";
      case RideStep.driverAssigned:
        return "Driver Assigned";
      case RideStep.rideInProgress:
        return "Ride in Progress";
    }
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStepContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case RideStep.pickupLocation:
        return _buildPickupLocationStep();
      case RideStep.destinationLocation:
        return _buildDestinationLocationStep();
      case RideStep.rideReview:
        return _buildRideReviewStep();
      case RideStep.findingDriver:
        return _buildFindingDriverStep();
      case RideStep.driverAssigned:
        return _buildDriverAssignedStep();
      case RideStep.rideInProgress:
        return _buildRideInProgressStep();
    }
  }

  Widget _buildPickupLocationStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Where to go?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose your pickup location",
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 20),
        TypeAheadField<LocationModel>(
          suggestionsCallback: (pattern) async {
            return getLocationSuggestions(pattern);
          },
          builder: (context, controller, focusNode) {
            controller.text = _pickupController.text; // keep sync
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: "Enter pickup location",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 22),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            );
          },
          itemBuilder: (context, LocationModel suggestion) {
            return Container(
              color: const Color(0xFF2A2A2A),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
                title: Text(
                  suggestion.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  "${suggestion.latitude.toStringAsFixed(3)}, ${suggestion.longitude.toStringAsFixed(3)}",
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            );
          },
          onSelected: (LocationModel selection) {
            _selectPickupLocation(selection);
          },
          hideOnEmpty: true,
          hideOnLoading: false,
          debounceDuration: const Duration(milliseconds: 400),
          listBuilder: (context, animatedChildren) {
            return Container(
              color: const Color(0xFF2A2A2A),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: animatedChildren,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          "Quick Suggestions",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickLocations.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _selectPickupLocation(quickLocations[index]),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(quickLocations[index].name.split(" ").first, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        quickLocations[index].name.split(" ").last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms);
            },
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (pickupLocation != null) {
                setState(() {
                  currentStep = RideStep.destinationLocation;
                  _addMarker(pickupLocation!, "Pickup");
                });
              }
            },
            child: const Text(
              "Confirm Pickup",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationLocationStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Where to?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "From: ${pickupLocation?.name ?? 'Pickup'}",
          style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        TypeAheadField<LocationModel>(
          suggestionsCallback: (pattern) async {
            return getLocationSuggestions(pattern);
          },
          builder: (context, controller, focusNode) {
            _destinationController = controller;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: "Enter destination",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 22),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            );
          },
          itemBuilder: (context, LocationModel suggestion) {
            return Container(
              color: const Color(0xFF2A2A2A),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
                title: Text(
                  suggestion.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            );
          },
          onSelected: (LocationModel selection) {
            _selectDestinationLocation(selection);
          },
          hideOnEmpty: true,
          hideOnLoading: false,
          debounceDuration: const Duration(milliseconds: 400),
          listBuilder: (context, animatedChildren) {
            return Container(
              color: const Color(0xFF2A2A2A),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: animatedChildren,
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (destinationLocation != null) {
                setState(() {
                  _addMarker(destinationLocation!, "Destination");
                  _drawRoute();
                  _calculateFare();
                  currentStep = RideStep.rideReview;  // ✅ Go to review page
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select destination first"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "Confirm Destination",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideReviewStep() {
    double finalFare = estimatedFare ?? 0;
    if (appliedPromoCode != null) {
      finalFare = finalFare * (1 - discountPercent);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review Your Ride",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        // Route Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("From", style: TextStyle(color: Colors.white60, fontSize: 11)),
                        Text(
                          pickupLocation?.name ?? "Pickup",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("To", style: TextStyle(color: Colors.white60, fontSize: 11)),
                        Text(
                          destinationLocation?.name ?? "Destination",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Trip Details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDetailCard("Distance", "${distanceInKm?.toStringAsFixed(1) ?? "0"} km", Icons.route),
            _buildDetailCard("Duration", "${estimatedDuration ?? "0"} min", Icons.schedule),
            _buildDetailCard("Fare", "₹${estimatedFare?.toStringAsFixed(0) ?? "0"}", Icons.currency_rupee),
          ],
        ),
        const SizedBox(height: 20),
        // Ride Type Selector
        const Text(
          "Choose Ride Type",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rideTypes.length,
            itemBuilder: (context, index) {
              RideTypeModel ride = rideTypes[index];
              bool isSelected = selectedRideType == ride.type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRideType = ride.type;
                    _calculateFare();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF6B35) : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ride.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        ride.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₹${ride.basePrice}",
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Promo Code
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoCodeController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: "Promo code (e.g., RIDE50)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                  prefixIcon: const Icon(Icons.local_offer, color: Color(0xFFFF6B35), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _applyPromoCode(_promoCodeController.text),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        if (appliedPromoCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
              ),
              child: Text(
                "✓ $appliedPromoCode applied (${(discountPercent * 100).toInt()}% off)",
                style: const TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        // Final Fare & Confirm
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Fare",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${finalFare.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 140,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _findDriver,
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFindingDriverStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Finding Your Driver",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        ScaleTransition(
          scale: Tween(begin: 0.7, end: 1.3).animate(
            CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.local_taxi, color: Colors.white, size: 60),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          "Searching for the best driver nearby...",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLoadingDot(0),
            _buildLoadingDot(1),
            _buildLoadingDot(2),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLoadingDot(int index) {
    return ScaleTransition(
      scale: Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _pulseAnimationController,
          curve: Interval(index * 0.15, 1.0, curve: Curves.ease),
        ),
      ),
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          color: Color(0xFFFF6B35),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildDriverAssignedStep() {
    if (assignedDriver == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Driver Assigned",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        // Driver Profile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignedDriver!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFF6B35), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${assignedDriver!.rating.toStringAsFixed(1)} (${assignedDriver!.totalRides} rides)",
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms),
        const SizedBox(height: 14),
        // Vehicle Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Vehicle", style: TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        assignedDriver!.vehicleModel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Color", style: TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        assignedDriver!.vehicleColor,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 12),
              const Text("License Plate", style: TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assignedDriver!.licensePlate,
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ETA & Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule, color: Color(0xFFFF6B35), size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Arriving in",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        "${assignedDriver!.eta} minutes",
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.phone, "Call"),
                  _buildActionButton(Icons.message, "Message"),
                  _buildActionButton(Icons.share, "Share"),
                  _buildActionButton(Icons.close, "Cancel"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRideInProgressStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Ride in Progress",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Text(
                "You're on your way!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                  value: 0.65,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Thank you for riding with us!",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: const Text(
              "Share Ride Status",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF6B35), size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Extension helper for random list items
extension RandomElement<T> on List<T> {
  T get randomItem => this[Random().nextInt(length)];
}