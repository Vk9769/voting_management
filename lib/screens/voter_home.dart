import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  void _markVote() async {
    if (hasVoted) {
      Fluttertoast.showToast(
        msg: "You have already voted.",
        backgroundColor: Colors.orange,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_voted', true);

    setState(() {
      hasVoted = true;
    });

    Fluttertoast.showToast(
      msg: "Vote successfully recorded!",
      backgroundColor: Colors.green,
    );
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
      appBar: AppBar(
        title: const Text("Voter Dashboard"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVoterData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Card
              Card(
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
                            Text(
                              voterEmail,
                              style: const TextStyle(color: Colors.grey),
                            ),
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
                color: hasVoted ? Colors.green[50] : Colors.red[50],
                elevation: 3,
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
                        : "Please cast your vote below.",
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Vote Button
              ElevatedButton.icon(
                onPressed: hasVoted ? null : _markVote,
                icon: const Icon(Icons.how_to_vote),
                label: const Text(
                  "Cast Your Vote",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Other Features
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_search, color: Colors.blue),
                      title: const Text("View Candidate List"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Fluttertoast.showToast(
                            msg: "Candidate list coming soon");
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.blue),
                      title: const Text("Voting History"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Fluttertoast.showToast(msg: "Voting history coming soon");
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.blue),
                      title: const Text("Settings"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Fluttertoast.showToast(msg: "Settings coming soon");
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
}
