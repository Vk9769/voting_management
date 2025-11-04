import 'package:flutter/material.dart';
import 'login_page.dart';
import 'add_polling_booth_page.dart';
import 'view_all_booth.dart';
import 'add_agent_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'view_all_agents.dart';
import 'all_voting_status_page.dart';
import 'admin_profile_page.dart';
import 'admin_message_center_page.dart';
import 'view_all_voters.dart';
import 'view_candidate.dart';
import 'travel_page.dart';


/// Utility to format large numbers
String formatNumber(int number) {
  if (number >= 1000000000) {
    return '${(number / 1000000000).toStringAsFixed(2)}B';
  } else if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(2)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  } else {
    return number.toString();
  }
}

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
  int votesCasted = 0;
  int votesPending = 0;

  bool isLoading = true;

  int _currentIndex = 0; // For bottom navigation

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
        Uri.parse(
          'https://voting-backend-6px8.onrender.com/api/admin/dashboard',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Dashboard API Response: ${response.body}');

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);

        if (resBody['success'] == true && resBody['data'] != null) {
          final data = resBody['data'];

          setState(() {
            polls = int.tryParse(data['polls'].toString()) ?? 0;
            agents = int.tryParse(data['agents'].toString()) ?? 0;
            voters = int.tryParse(data['voters'].toString()) ?? 0;
            reports = int.tryParse(data['reports'].toString()) ?? 0;

            const int indiaPopulation = 1430000000;

            // Simulated vote percentages
            double castedPercent = 0.70;
            double pendingPercent = 0.30;

            votesCasted = (indiaPopulation * castedPercent).toInt();
            votesPending = (indiaPopulation * pendingPercent).toInt();

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

  AppBar _buildAppBar() {
    String title = '';
    switch (_currentIndex) {
      case 0:
        title = 'Admin Dashboard';
        break;
      case 1:
        title = 'Message Center';
        break;
      case 2:
        title = 'Travel';
        break;
      default:
        title = 'Admin Dashboard';
    }

    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blue,
      centerTitle: true,
    );
  }

  // Pages for bottom navigation
  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _dashboardBody();
      case 1:
        return const AdminMessageCenterPage(); // <-- use your page here
      case 2:
        return const TravelPage();
      default:
        return _dashboardBody();
    }
  }

  Widget _dashboardBody() {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color foreground = Colors.black87;
    final Color cardBg = Colors.white;

    return isLoading
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
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(
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

              // Voting Status Card with progress bars
              Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.how_to_reg,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Voting Status",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AllVotingStatusPage(
                                          statusType: "casted",
                                        ),
                                  ),
                                );
                              },
                              child: _VotingStatusCard(
                                title: "Votes Casted",
                                value: formatNumber(votesCasted),
                                color: Colors.green,
                                icon: Icons.done_all,
                                progress: (votesCasted + votesPending) > 0
                                    ? votesCasted / (votesCasted + votesPending)
                                    : 0.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AllVotingStatusPage(
                                          statusType: "pending",
                                        ),
                                  ),
                                );
                              },
                              child: _VotingStatusCard(
                                title: "Votes Pending",
                                value: formatNumber(votesPending),
                                color: Colors.redAccent,
                                icon: Icons.pending_actions,
                                progress: (votesCasted + votesPending) > 0
                                    ? votesPending / (votesCasted + votesPending)
                                    : 0.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Primary actions
              _ActionsRow(primary: primary),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message Center',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'Travel',
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                MaterialPageRoute(builder: (_) => const AdminProfilePage()),
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
                await prefs.clear();

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

// 🎯 Voting Status Subcards with progress bars
class _VotingStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final double progress;

  const _VotingStatusCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            color: color,
            minHeight: 6,
          ),
        ],
      ),
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

// Actions row
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
        // View Candidate List
        SizedBox(
          width: wide ? 260 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminCandidatesPage()),
              );
            },
            icon: const Icon(Icons.location_on),
            label: const Text('View Candidate List'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewAllBoothsPage()),
              );
            },
            icon: const Icon(Icons.location_on),
            label: const Text('View Polling Booths'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue, width: 1.25),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewAllAgentsPage()),
              );
            },
            icon: const Icon(Icons.group),
            label: const Text('View Agent List'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        SizedBox(
          width: wide ? 260 : double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewAllVotersPage()),
              );
            },
            icon: const Icon(Icons.people_alt),
            label: const Text('View All Voters'),
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
      ],
    );
  }
}

// Optional: simple profile screen
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
