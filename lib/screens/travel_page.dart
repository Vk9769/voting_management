import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ride_request_page.dart';


class TravelPage extends StatefulWidget {
  const TravelPage({Key? key}) : super(key: key);

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> with TickerProviderStateMixin {
  String? _userName;
  String? _userEmail;
  String _selectedService = 'ride_request';
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookingHistory = [];
  double _walletBalance = 45.75;
  int _loyaltyPoints = 2450;
  double _userRating = 4.9;
  int _totalRides = 127;
  double _totalDistance = 856.3;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadUserData();
    _loadBookingHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('admin_name') ?? 'Traveler';
        _userEmail = prefs.getString('user_email') ?? 'user@example.com';
        _walletBalance = prefs.getDouble('wallet_balance') ?? 45.75;
        _loyaltyPoints = prefs.getInt('loyalty_points') ?? 2450;
        _userRating = prefs.getDouble('user_rating') ?? 4.9;
        _totalRides = prefs.getInt('total_rides') ?? 127;
        _totalDistance = prefs.getDouble('total_distance') ?? 856.3;
      });
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _userName = 'Traveler';
        _userEmail = 'user@example.com';
      });
    }
  }

  Future<void> _loadBookingHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString('booking_history');
      if (data != null) {
        setState(() {
          _bookingHistory = List<Map<String, dynamic>>.from(json.decode(data));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading booking history: $e');
    }
  }

  Future<void> _saveBooking(Map<String, dynamic> booking) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _bookingHistory.insert(0, booking);
      _totalRides += 1;
      _totalDistance += double.parse(booking['distance']?.toString().split(' ')[0] ?? '2.5');

      await prefs.setString('booking_history', json.encode(_bookingHistory));
      await prefs.setInt('total_rides', _totalRides);
      await prefs.setDouble('total_distance', _totalDistance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking confirmed! Enjoy your ride'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error saving booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error confirming booking'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _requestRide() {
    final booking = {
      'type': 'Ride Request',
      'timestamp': DateTime.now().toString(),
      'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      'time': '${DateTime.now().hour}:${DateTime.now().minute}',
      'pickupLocation': 'Current Location',
      'dropoffLocation': 'Destination',
      'distance': '5.2 km',
      'duration': '18 mins',
      'fare': '\$12.50',
      'status': 'Completed',
      'driver': 'John Doe',
      'carModel': 'Toyota Camry',
      'plate': 'ABC 1234',
    };
    _saveBooking(booking);
    _showBookingDetails('Ride Request', 'Your ride has been confirmed! Driver arriving in 5 minutes', Icons.directions_car, Colors.blue.shade700);
  }

  void _requestPooling() {
    final booking = {
      'type': 'Ride Pooling',
      'timestamp': DateTime.now().toString(),
      'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      'time': '${DateTime.now().hour}:${DateTime.now().minute}',
      'pickupLocation': 'Meeting Point',
      'dropoffLocation': 'Shared Destination',
      'distance': '4.8 km',
      'duration': '22 mins',
      'fare': '\$6.75',
      'passengers': '3 passengers',
      'savings': 'You saved \$5.75!',
      'status': 'Completed',
    };
    _saveBooking(booking);
    _showBookingDetails('Ride Pooling', 'Matched with 2 other passengers! You saved \$5.75', Icons.people, Colors.purple.shade700);
  }

  void _requestWalkMode() {
    final booking = {
      'type': 'Walk Mode',
      'timestamp': DateTime.now().toString(),
      'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      'time': '${DateTime.now().hour}:${DateTime.now().minute}',
      'pickupLocation': 'Current Location',
      'dropoffLocation': 'Destination',
      'distance': '2.5 km',
      'duration': '32 mins',
      'fare': 'Free',
      'status': 'Completed',
      'caloriesBurned': '145 cal',
    };
    _saveBooking(booking);
    _showBookingDetails('Walk Mode', 'Route optimized for walking! You\'ll burn approx 145 calories', Icons.directions_walk, Colors.amber.shade700);
  }

  void _showBookingDetails(String title, String message, IconData icon, Color color) {
    _scaleController.forward(from: 0.0);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ScaleTransition(
        scale: _scaleController,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 8,
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 48),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Track Booking',
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
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String serviceId,
    String? priceTag,
  }) {
    bool isSelected = _selectedService == serviceId;

    return GestureDetector(
      onTap: () {
        _bounceController.forward(from: 0.0);
        setState(() => _selectedService = serviceId);
        onTap();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.02).animate(_bounceController),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [color.withOpacity(0.85), color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isSelected ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                if (priceTag != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    priceTag,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingHistoryCard(Map<String, dynamic> booking) {
    Color statusColor = Colors.green.shade700;
    IconData serviceIcon = Icons.directions_car;
    String subtitleText = '';

    if (booking['type'] == 'Ride Pooling') {
      serviceIcon = Icons.people;
      statusColor = Colors.purple.shade700;
      subtitleText = booking['passengers'] ?? 'Shared ride';
    } else if (booking['type'] == 'Walk Mode') {
      serviceIcon = Icons.directions_walk;
      statusColor = Colors.amber.shade700;
      subtitleText = booking['caloriesBurned'] ?? 'Walking route';
    } else {
      subtitleText = booking['driver'] ?? 'Private ride';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(serviceIcon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['type'] ?? 'Booking',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking['date']} at ${booking['time']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    booking['fare'] ?? 'N/A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${booking['pickupLocation']} → ${booking['dropoffLocation']}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  subtitleText,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const Spacer(),
                Text(
                  '${booking['distance'] ?? '2.5 km'} • ${booking['duration'] ?? '30 mins'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade500,
                      Colors.cyan.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: FadeTransition(
                          opacity: _fadeController,
                          child: SlideTransition(
                            position: _slideController.drive(
                              Tween(begin: const Offset(-0.3, 0), end: Offset.zero)
                                  .chain(CurveTween(curve: Curves.easeInOutCubic)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Hello, ',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      _userName ?? 'Traveler',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ready for your next adventure?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      children: [
                        // Wallet section removed - starts directly with stats grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _buildStatCard(
                              label: 'Total Rides',
                              value: _totalRides.toString(),
                              icon: Icons.directions_car,
                              color: Colors.blue,
                            ),
                            _buildStatCard(
                              label: 'Distance',
                              value: '${_totalDistance.toStringAsFixed(1)} km',
                              icon: Icons.map,
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              label: 'Rating',
                              value: _userRating.toString(),
                              icon: Icons.star,
                              color: Colors.amber,
                            ),
                            _buildStatCard(
                              label: 'Points',
                              value: _loyaltyPoints.toString(),
                              icon: Icons.loyalty,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Choose Our Service',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.local_offer, color: Colors.blue.shade700, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildServiceCard(
                          title: 'Ride Request',
                          description: 'Book a private ride with dedicated driver',
                          icon: Icons.directions_car,
                          color: Colors.blue.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RideRequestPage()),
                            );
                          },
                          serviceId: 'ride_request',
                        ),
                        const SizedBox(height: 12),
                        _buildServiceCard(
                          title: 'Ride Pooling',
                          description: 'Share a ride and save up to 50% on fare',
                          icon: Icons.people,
                          color: Colors.purple.shade700,
                          onTap: _requestPooling,
                          serviceId: 'ride_pooling',
                          priceTag: 'From \$6.75',
                        ),
                        const SizedBox(height: 12),
                        _buildServiceCard(
                          title: 'Walk Mode',
                          description: 'Get optimized walking routes & navigation',
                          icon: Icons.directions_walk,
                          color: Colors.amber.shade700,
                          onTap: _requestWalkMode,
                          serviceId: 'walk_mode',
                          priceTag: 'Completely Free',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Offers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade50,
                                Colors.orange.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.local_offer, color: Colors.red.shade700, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Get 20% Off on Your Next Ride',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Use code: SAVE20',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.red.shade700),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Bookings',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_bookingHistory.isNotEmpty)
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'View All →',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue.shade700,
                              strokeWidth: 3,
                            ),
                          )
                        else if (_bookingHistory.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.history,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Bookings Yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Start your journey by booking a ride today',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _bookingHistory.length > 5 ? 5 : _bookingHistory.length,
                            itemBuilder: (context, index) =>
                                _buildBookingHistoryCard(_bookingHistory[index]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade50,
                            Colors.blue.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.card_membership, color: Colors.blue.shade700, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upgrade to Premium',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Get exclusive benefits & rewards',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Learn More',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade50,
                            Colors.orange.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.red.shade700, size: 32),
                              const SizedBox(width: 12),
                              Text(
                                'Safety & Support',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Emergency'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.help),
                                  label: const Text('Support'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.info),
                                  label: const Text('Report'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
