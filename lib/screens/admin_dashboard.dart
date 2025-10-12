// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'add_polling_booth_page.dart';
import 'view_all_booth.dart';
import 'add_agent_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int polls = 0;
  int agents = 0;
  int voters = 0;
  int reports = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('https://voting-backend-6px8.onrender.com/api/admin/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Dashboard API Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);

        if (resBody['success'] == true && resBody['data'] != null) {
          final data = resBody['data'];

          setState(() {
            polls = int.tryParse(data['polls'].toString()) ?? 0;
            agents = int.tryParse(data['agents'].toString()) ?? 0;
            voters = int.tryParse(data['voters'].toString()) ?? 0;
            reports = int.tryParse(data['reports'].toString()) ?? 0;
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      print('⚠️ Error fetching dashboard stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color foreground = Colors.black87;
    final Color cardBg = Colors.white;

    return Scaffold(
      drawer: _buildDrawer(context, primary),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final int columns = constraints.maxWidth >= 1200
              ? 4
              : constraints.maxWidth >= 900
              ? 3
              : 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Overview',
                  style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 16),

                // KPI Grid
                GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      title: 'Polling',
                      value: polls.toString(),
                      icon: Icons.how_to_vote,
                      color: primary,
                      background: cardBg,
                    ),
                    StatCard(
                      title: 'Agents',
                      value: agents.toString(),
                      icon: Icons.group,
                      color: Colors.teal,
                      background: cardBg,
                    ),
                    StatCard(
                      title: 'Voters',
                      value: voters.toString(),
                      icon: Icons.people,
                      color: Colors.orange,
                      background: cardBg,
                    ),
                    StatCard(
                      title: 'Reports',
                      value: reports.toString(),
                      icon: Icons.bar_chart,
                      color: Colors.blueGrey,
                      background: cardBg,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Primary actions
                _ActionsRow(primary: primary),

                const SizedBox(height: 24),

                // Recent Activity section
                Card(
                  color: cardBg,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Recent Activity',
                          icon: Icons.history,
                          color: primary,
                        ),
                        const SizedBox(height: 8),
                        _ActivityTile(
                          icon: Icons.add_location_alt,
                          color: primary,
                          title: 'New polling booth added',
                          subtitle: 'Booth #13 - Ward 4',
                          time: '2h ago',
                        ),
                        const Divider(height: 16),
                        const _ActivityTile(
                          icon: Icons.group_add,
                          color: Colors.teal,
                          title: '2 agents onboarded',
                          subtitle: 'Assigned to Booth #5 & #8',
                          time: 'Yesterday',
                        ),
                        const Divider(height: 16),
                        const _ActivityTile(
                          icon: Icons.report,
                          color: Colors.blueGrey,
                          title: 'Report reviewed',
                          subtitle: 'Queue length trends updated',
                          time: '2 days ago',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Drawer
  Drawer _buildDrawer(BuildContext context, Color primary) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // center vertically
              crossAxisAlignment: CrossAxisAlignment.center,
              // center horizontally
              children: const [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'admin@example.com',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // 🔥 clears login session/token

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// Compact section header
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// KPI Card
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBadge(icon: icon, color: color),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Rounded icon chip
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: Colors.blue, size: 24),
    );
  }
}

// Actions row with primary buttons
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width >= 700;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Add Polling Booth
        // Add Polling Booth
        SizedBox(
          width: wide ? 260 : double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddPollingBoothPage()),
              );
            },
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add Polling Booth'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // View Polling Booths
        SizedBox(
          width: wide ? 260 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ViewAllBoothsPage()),
            );
            },
            icon: const Icon(Icons.location_on),
            label: const Text('View Polling Booths'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // Add Agent
        SizedBox(
          width: wide ? 260 : double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAgentPage()),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Agent'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              // custom color
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // View Agent List
        SizedBox(
          width: wide ? 260 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.group),
            label: const Text('View Agent List'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              // same accent color
              side: BorderSide(color: Colors.blue, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// Activity list tile
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _IconBadge(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Text(time, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

// Optional: simple profile screen to keep drawer navigation working
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(radius: 50, child: Icon(Icons.person, size: 48)),
            SizedBox(height: 16),
            Text(
              'Admin Name',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'admin@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}