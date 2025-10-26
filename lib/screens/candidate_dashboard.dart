import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class CandidateDashboard extends StatefulWidget {
  const CandidateDashboard({super.key});

  @override
  State<CandidateDashboard> createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  int polls = 0;
  int votesCasted = 0;
  int votesPending = 0;
  bool isLoading = true;

  int _currentIndex = 0;

  String candidateName = "Candidate";
  String candidateEmail = "candidate@example.com";
  String candidateVoterId = "VOTER0000";

  @override
  void initState() {
    super.initState();
    _loadCandidateData();
    _loadDummyDashboardData();
  }

  Future<void> _loadCandidateData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      candidateName = prefs.getString('candidate_name') ?? "Candidate";
      candidateEmail = prefs.getString('candidate_email') ?? "candidate@example.com";
      candidateVoterId = prefs.getString('candidate_voter_id') ?? "VOTER0000";
    });
  }

  void _loadDummyDashboardData() {
    setState(() {
      polls = 12; // dummy polling booths
      votesCasted = 3500; // dummy votes casted
      votesPending = 1200; // dummy votes pending
      isLoading = false;
    });
  }

  AppBar _buildAppBar() {
    String title = '';
    switch (_currentIndex) {
      case 0:
        title = 'Candidate Dashboard';
        break;
      case 1:
        title = 'Message Center';
        break;
      case 2:
        title = 'Profile';
        break;
      default:
        title = 'Candidate Dashboard';
    }
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blue,
      centerTitle: true,
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _dashboardBody();
      case 1:
        return const Center(child: Text("Message Center Page"));
      case 2:
        return _profilePage();
      default:
        return _dashboardBody();
    }
  }

  Widget _dashboardBody() {
    final Color primary = Theme.of(context).colorScheme.primary;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          // KPI Grid
          GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                title: 'Polling Booths',
                value: polls.toString(),
                icon: Icons.how_to_vote,
                color: primary,
                background: Colors.white,
              ),
              StatCard(
                title: 'Votes Casted',
                value: formatNumber(votesCasted),
                icon: Icons.done_all,
                color: Colors.green,
                background: Colors.white,
              ),
              StatCard(
                title: 'Votes Pending',
                value: formatNumber(votesPending),
                icon: Icons.pending_actions,
                color: Colors.redAccent,
                background: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Buttons like Admin Dashboard
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Add Super Agent"),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.manage_accounts),
                label: const Text("Manage Super Agent"),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add),
                label: const Text("Add Agent"),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.group),
                label: const Text("Manage Agent"),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.people),
                label: const Text("View Voters"),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.location_city),
                label: const Text("View Polling Booths"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Voting Status Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.how_to_reg, color: Colors.blueAccent),
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
                    children: [
                      Expanded(
                        child: _VotingStatusCard(
                          title: "Votes Casted",
                          value: formatNumber(votesCasted),
                          color: Colors.green,
                          icon: Icons.done_all,
                          progress: votesCasted / (votesCasted + votesPending),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VotingStatusCard(
                          title: "Votes Pending",
                          value: formatNumber(votesPending),
                          color: Colors.redAccent,
                          icon: Icons.pending_actions,
                          progress: votesPending / (votesCasted + votesPending),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          Text(candidateName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(candidateEmail, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 6),
          Text("Voter ID: $candidateVoterId", style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
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
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    candidateName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    candidateEmail,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Voter ID: $candidateVoterId",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

// Voting Status Card
class _VotingStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final double progress;

  const _VotingStatusCard(
      {required this.title, required this.value, required this.color, required this.icon, this.progress = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              decoration:
              BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                  Text(title,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
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
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color, required this.background});

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
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
