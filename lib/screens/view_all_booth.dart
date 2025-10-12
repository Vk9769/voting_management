import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

// Booth model
class Booth {
  final String name;
  String address; // mutable to store reverse geocoded address
  final LatLng location;
  final double radius;

  Booth({
    required this.name,
    required this.address,
    required this.location,
    required this.radius,
  });
}

// Page showing all booths
class ViewAllBoothsPage extends StatefulWidget {
  const ViewAllBoothsPage({super.key});

  @override
  State<ViewAllBoothsPage> createState() => _ViewAllBoothsPageState();
}

class _ViewAllBoothsPageState extends State<ViewAllBoothsPage> {
  List<Booth> booths = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooths();
  }

  Future<void> _fetchBooths() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Fluttertoast.showToast(msg: "Please log in first");
      setState(() => loading = false);
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

          final List<Booth> fetchedBooths = boothsJson.map((b) {
            final loc = LatLng(
              (b['latitude'] ?? 0).toDouble(),
              (b['longitude'] ?? 0).toDouble(),
            );
            return Booth(
              name: b['name'] ?? '',
              address: '', // will fill with reverse geocoding
              location: loc,
              radius: (b['radius_meters'] ?? 50).toDouble(),
            );
          }).toList();

          // Reverse geocode to get addresses
          await Future.wait(fetchedBooths.map((b) async {
            try {
              final placemarks = await placemarkFromCoordinates(
                  b.location.latitude, b.location.longitude);
              if (placemarks.isNotEmpty) {
                final place = placemarks.first;
                b.address = [
                  place.street,
                  place.locality,
                  place.postalCode,
                  place.country
                ].where((e) => e != null && e.isNotEmpty).join(', ');
              } else {
                b.address = "Address not found";
              }
            } catch (_) {
              b.address = "Failed to fetch address";
            }
          }));

          if (!mounted) return;
          setState(() {
            booths = fetchedBooths;
          });
        } else {
          Fluttertoast.showToast(msg: "No booths found");
        }
      } else {
        Fluttertoast.showToast(msg: "Failed to fetch booths");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching booths");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

// Inside _ViewAllBoothsPageState's build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Polling Booths'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 2,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
        color: Colors.blue,
        onRefresh: _fetchBooths, // pull-to-refresh triggers fetch
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const _IconBadge(icon: Icons.how_to_vote),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select a booth to view details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Text(
                          '${booths.length} total',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(), // ensures pull works even if list is short
                  itemCount: booths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final booth = booths[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        leading: const _IconBadge(icon: Icons.place),
                        title: Text(
                          booth.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          booth.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.blue),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BoothDetailPage(booth: booth),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Booth details page (unchanged)
class BoothDetailPage extends StatelessWidget {
  final Booth booth;
  const BoothDetailPage({super.key, required this.booth});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(booth.name),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: 'Booth Details', icon: Icons.info),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.how_to_vote,
                      label: 'Booth Name',
                      value: booth.name,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.home,
                      label: 'Address',
                      value: booth.address,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.radar,
                      label: 'Radius',
                      value: '${booth.radius.toInt()} meters',
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(title: 'Location', icon: Icons.map),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 300,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: booth.location,
                            zoom: 16,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(booth.name),
                              position: booth.location,
                              infoWindow: InfoWindow(title: booth.name),
                            ),
                          },
                          circles: {
                            Circle(
                              circleId: CircleId(booth.name),
                              center: booth.location,
                              radius: booth.radius,
                              fillColor: Colors.blue.withOpacity(0.18),
                              strokeColor: Colors.blue,
                              strokeWidth: 2,
                            ),
                          },
                          zoomControlsEnabled: true,
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          myLocationButtonEnabled: false,
                          myLocationEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const _LegendDot(color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Booth radius shown on map',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable components
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: Colors.blue, size: 22),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
