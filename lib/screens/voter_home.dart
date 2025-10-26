import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'polling_booth_map_page.dart';
import 'report_page.dart';
import 'voter_profile_page.dart';

class VoterHomePage extends StatefulWidget {
  const VoterHomePage({super.key});

  @override
  State<VoterHomePage> createState() => _VoterHomePageState();
}

class _VoterHomePageState extends State<VoterHomePage> {
  String voterName = '';
  String voterEmail = '';
  String voterId = '';
  bool hasVoted = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVoterData();
  }

  Future<void> _loadVoterData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      voterName = prefs.getString('user_name') ?? 'Unknown Voter';
      voterEmail = prefs.getString('user_email') ?? 'Not Available';
      voterId = prefs.getString('user_id') ?? 'N/A';
      hasVoted = prefs.getBool('has_voted') ?? false;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _votingTab(),
      _travelTab(),
      _profileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Voter Dashboard"),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.white,
            onPressed: () {
              Fluttertoast.showToast(msg: "Notification center coming soon");
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            // Navigate only when Profile tab is tapped
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VoterProfilePage()),
            );
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: "Voting",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: "Travel",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // 🔹 Voting Tab
  Widget _votingTab() {
    return RefreshIndicator(
      onRefresh: _loadVoterData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/user_avatar.png'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voterName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(voterEmail,
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("Voter ID: $voterId"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Voting Status
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Icon(
                  hasVoted ? Icons.check_circle : Icons.cancel,
                  color: hasVoted ? Colors.green : Colors.red,
                  size: 35,
                ),
                title: Text(
                  hasVoted
                      ? "You have already voted"
                      : "You have not voted yet",
                  style: TextStyle(
                    fontSize: 18,
                    color: hasVoted ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  hasVoted
                      ? "Your vote has been successfully submitted."
                      : "Please wait for the voting session.",
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Emergency Services",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _buildEmergencyCard(
                      title: "Nearest Hospital",
                      icon: Icons.local_hospital,
                      color: Colors.green,
                      onTap: () async {
                        final url = Uri.parse(
                            "https://www.google.com/maps/search/hospital+near+me");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          Fluttertoast.showToast(msg: "Could not open maps");
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _buildEmergencyCard(
                      title: "Nearest Police Station",
                      icon: Icons.local_police,
                      color: Colors.blue,
                      onTap: () async {
                        final url = Uri.parse(
                            "https://www.google.com/maps/search/police+station+near+me");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          Fluttertoast.showToast(msg: "Could not open maps");
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _buildEmergencyCard(
                      title: "Kitchen and Tiffins",
                      icon: Icons.restaurant,
                      color: Colors.orange,
                      onTap: () async {
                        final url = Uri.parse(
                            "https://www.google.com/maps/search/restaurant+near+me");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          Fluttertoast.showToast(msg: "Could not open maps");
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.location_on,
                    title: "View Polling Booth Location",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PollingBoothMapPagee(
                            boothName: "Booth 12, KanjurMarg",
                            boothLat: 19.128917,
                            boothLng: 72.926611,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.newspaper,
                    title: "Daily News",
                    onTap: () => Fluttertoast.showToast(
                        msg: "Daily news coming soon"),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.message,
                    title: "Messages",
                    onTap: () => Fluttertoast.showToast(
                        msg: "Messages feature coming soon"),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.report,
                    title: "Report",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReportPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 0);

  Widget _buildEmergencyCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _travelTab() {
    return Center(
      key: const ValueKey('travel'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.travel_explore, size: 80, color: Colors.blue),
          SizedBox(height: 20),
          Text("Travel Information Coming Soon",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _profileTab() {
    // Just a placeholder
    return const Center(
      key: ValueKey('profile'),
      child: Text(
        "Profile Page",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
