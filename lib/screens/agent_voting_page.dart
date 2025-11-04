import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'polling_booth_map_page.dart';
import 'report_page.dart';
import 'agent_profile_page.dart'; // create this similar to VoterProfilePage

class AgentVotingPage extends StatefulWidget {
  const AgentVotingPage({super.key});

  @override
  State<AgentVotingPage> createState() => _AgentVotingPageState();
}

class _AgentVotingPageState extends State<AgentVotingPage> {
  String agentName = '';
  String agentEmail = '';
  String agentId = '';
  bool hasVoted = false;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      agentName = prefs.getString('user_name') ?? 'Amit';
      agentEmail = prefs.getString('user_email') ?? 'Not Available';
      agentId = prefs.getString('1000') ?? '1000';
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _loadAgentData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Agent Info Card
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
                            Text(agentName,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(agentEmail,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text("Agent ID: $agentId"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Voting Status Card
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

              // Action List
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
                              boothName: "100-MADHYA VIDHYALA MADHURA ANUSUCHIT DAKSHIN BHAG, BIHAR",
                              boothLat: 26.145685863730833,
                              boothLng: 84.29060636137021,
                              agentName: agentName, // ✅ Pass the agent name here
                              agentId: agentId,     // ✅ Pass the agent ID here
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.newspaper,
                      title: "Daily News",
                      onTap: () =>
                          Fluttertoast.showToast(msg: "Daily news coming soon"),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.message,
                      title: "Messages",
                      onTap: () =>
                          Fluttertoast.showToast(msg: "Messages coming soon"),
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
}
