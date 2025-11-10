import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_management/screens/add_candidate_page.dart';
import 'package:voting_management/screens/add_polling_booth_page.dart';
import 'package:voting_management/screens/candidate_dashboard.dart';
import 'package:voting_management/screens/view_all_booth.dart';
import 'package:voting_management/screens/view_all_voters.dart';
import 'package:voting_management/screens/view_candidate.dart';
import 'package:voting_management/screens/voter_home.dart';
import 'login_page.dart';
import 'add_agent_page.dart';
import 'view_all_agents.dart';
import 'admin_profile_page.dart';
import 'master_message_center_page.dart';
import 'travel_page.dart';

String formatNumber(int number) {
  if (number >= 1000000000) return '${(number / 1000000000).toStringAsFixed(2)}B';
  else if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(2)}M';
  else if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
  return number.toString();
}

class MasterDashboard extends StatefulWidget {
  const MasterDashboard({super.key});

  @override
  State<MasterDashboard> createState() => _MasterDashboardState();
}

class _MasterDashboardState extends State<MasterDashboard> {
  int polls = 25;
  int agents = 30;
  int voters = 1000000000;
  int reports = 18;

  int admins = 15;
  int superAdmins = 3;
  int superAgents = 12;
  int candidates = 8;

  bool isLoading = false;
  int _currentIndex = 0;
  int refreshTick = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      refreshTick++;
    });

    // Small delay to show refresh spinner nicely
    await Future.delayed(const Duration(milliseconds: 600));
  }

  AppBar _buildAppBar() {
    String title = _currentIndex == 1 ? 'Message Center' :
    _currentIndex == 2 ? 'Travel' :
    'Master Dashboard';

    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blue,
      centerTitle: true,
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 1: return const MasterMessageCenterPage();
      case 2: return const TravelPage();
      default: return _dashboardBody();
    }
  }

  Widget _dashboardBody() {
    final Color primary = Colors.blue;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Builder(
              builder: (context) {
                // ✅ Detect device width here (safe place)
                final width = MediaQuery.of(context).size.width;
                final bool isWeb = width >= 1000;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Responsive Grid
                    GridView(
                      gridDelegate: isWeb
                          ? const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      )
                          : const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        StatCard(title: 'Polling', value: polls, icon: Icons.how_to_vote, color: primary, background: Colors.white, refreshTick: refreshTick),
                        StatCard(title: 'Voters', value: voters, icon: Icons.people, color: Colors.orange, background: Colors.white, refreshTick: refreshTick),
                        StatCard(title: 'Agents', value: agents, icon: Icons.group, color: Colors.teal, background: Colors.white, refreshTick: refreshTick),
                        StatCard(title: 'Super Agents', value: superAgents, icon: Icons.verified_user, color: Colors.blueGrey, background: Colors.white, refreshTick: refreshTick),
                        StatCard(title: 'Admins', value: admins, icon: Icons.account_circle, color: Colors.deepPurple, background: Colors.white, refreshTick: refreshTick),
                        StatCard(title: 'Super Admins', value: superAdmins, icon: Icons.security, color: Colors.redAccent, background: Colors.white, refreshTick: refreshTick),
                        StatCard(title: 'Candidates', value: candidates, icon: Icons.how_to_vote, color: Colors.green, background: Colors.white, refreshTick: refreshTick),
                        StatCard(title: 'Reports', value: reports, icon: Icons.bar_chart, color: Colors.blueGrey, background: Colors.white, refreshTick: refreshTick),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _ActionsRowMaster(primary: primary),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      drawer: isWeb ? null : _buildDrawer(context),
      appBar: _buildAppBar(),
      body: Row(
        children: [
          if (isWeb)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(Icons.account_circle, size: 46, color: Colors.blue),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.message),
                  label: Text('Message Center'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.travel_explore),
                  label: Text('Travel'),
                ),
              ],
            ),

          Expanded(child: _getBody()),
        ],
      ),

      bottomNavigationBar: isWeb ? null : BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.blue,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message Center'),
          BottomNavigationBarItem(icon: Icon(Icons.travel_explore), label: 'Travel'),
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
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Colors.blue)),
                SizedBox(height: 10),
                Text('Master Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                SizedBox(height: 4),
                Text('master@example.com', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfilePage())),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionsRowMaster extends StatelessWidget {
  const _ActionsRowMaster({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 1000;

    final List<_ActionItem> items = [
      _ActionItem("Add Admin/Agent", Icons.admin_panel_settings, const AddAgentPage()),
      _ActionItem("View All Admins", Icons.supervised_user_circle, const ViewAllAgentsPage()),

      // ✅ Removed Add Agent
      _ActionItem("View All Agents", Icons.group, const ViewAllAgentsPage()),

      _ActionItem("Add Candidate", Icons.how_to_vote, const AddCandidatePage()),
      _ActionItem("View All Candidates", Icons.people, const AdminCandidatesPage()),

      _ActionItem("Add Polling Booth", Icons.add_location_alt, const AddPollingBoothPage()),
      _ActionItem("View All Polling Booths", Icons.location_on, const ViewAllBoothsPage()),

      _ActionItem("Add Voters", Icons.person_add_alt_1, const VoterHomePage()),
      _ActionItem("View All Voters", Icons.people_alt, const ViewAllVotersPage()),
    ];

    if (!isWeb) {
      return Column(
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;

          bool isFilled = index % 2 == 0; // Even index → Filled, Odd → Outlined

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(              // ✅ Makes button full width
              width: double.infinity,
              child: isFilled
                  ? FilledButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => item.page)),
                icon: Icon(item.icon),
                label: Text(item.title),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
                  : OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => item.page)),
                icon: Icon(item.icon, color: Colors.blue),
                label: Text(
                  item.title,
                  style: const TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 1.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }


    // ✅ Web UI → Material 3 Card Grid
    // ✅ Web UI → Section Card containing Action Cards Grid
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Management Actions",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.8,
                crossAxisSpacing: 24,
                mainAxisSpacing: 22,
              ),
              itemBuilder: (context, i) => _ActionCard(item: items[i]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final Widget page;
  _ActionItem(this.title, this.icon, this.page);
}

// ✅ Modern Material 3 Web Card
class _ActionCard extends StatefulWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: hovered ? Colors.blue.withOpacity(0.25) : Colors.black12,
              blurRadius: hovered ? 18 : 8,
              offset: hovered ? const Offset(0, 8) : const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.blue.withOpacity(0.22)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => widget.item.page)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.item.icon, size: 24, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                widget.item.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ✅ Animated Counter Widget
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle style;

  const AnimatedCounter({super.key, required this.value, required this.style});

  @override
  _AnimatedCounterState createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  late int _oldValue;

  @override
  void initState() {
    super.initState();
    _oldValue = 0;
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _oldValue = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(
          begin: _oldValue.toDouble(), end: widget.value.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Text(
          formatNumber(value.toInt()), // ✅ shows K / M / B format
          style: widget.style,
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.refreshTick,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;
  final int refreshTick;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background,
            background.withOpacity(0.80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing Icon Badge Circle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.28),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 30),
          ),

          const SizedBox(height: 14),

          // Animated Value (with refresh animation)
          AnimatedCounter(
            key: ValueKey(refreshTick),
            value: value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),

          const SizedBox(height: 6),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
