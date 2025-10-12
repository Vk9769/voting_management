// Uses consistent Colors.blue accents, card-based layout, better spacing and typography, rounded map, no new functionality added.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Booth model
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

// Demo booths (unchanged feature)
final List<Booth> demoBooths = [
  Booth(
    name: "Booth 1",
    address: "Ward 1, Street 5, City",
    location: LatLng(12.9716, 77.5946),
    radius: 50,
  ),
  Booth(
    name: "Booth 2",
    address: "Ward 2, Street 9, City",
    location: LatLng(12.9726, 77.5956),
    radius: 60,
  ),
  Booth(
    name: "Booth 3",
    address: "Ward 3, Street 12, City",
    location: LatLng(12.9736, 77.5966),
    radius: 70,
  ),
];

// Page showing all booths
class ViewAllBoothsPage extends StatelessWidget {
  const ViewAllBoothsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Polling Booths'),
        backgroundColor: Colors.blue, // keep blue theme
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtle header card for context
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    _IconBadge(icon: Icons.how_to_vote),
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
                        '${demoBooths.length} total',
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

            // Booth list (features unchanged)
            Expanded(
              child: ListView.separated(
                itemCount: demoBooths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final booth = demoBooths[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      leading: _IconBadge(icon: Icons.place),
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
    );
  }
}

// Booth details page
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
        backgroundColor: Colors.blue, // keep blue theme
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Booth info card (features unchanged; UI improved)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Booth Details', icon: Icons.info),
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

            // Map card with marker + circle (unchanged functionality)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(title: 'Location', icon: Icons.map),
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
                          // Keep controls minimal; these do not change the features
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
                        _LegendDot(color: Colors.blue),
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

// Small reusable pieces

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
              Text(label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  )),
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
