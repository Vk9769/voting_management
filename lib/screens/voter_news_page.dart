import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VoterNewsPage extends StatefulWidget {
  const VoterNewsPage({super.key});

  @override
  State<VoterNewsPage> createState() => _VoterNewsPageState();
}

class _VoterNewsPageState extends State<VoterNewsPage> {
  // Dummy Indian news posts
  final List<Map<String, dynamic>> _newsPosts = [
    {
      "agent": "Agent Rahul",
      "title": "Massive Voter Turnout in Mumbai Suburbs",
      "description":
      "Mumbai witnessed record voter turnout this morning as citizens queued up since early hours to cast their votes peacefully.",
      "imageUrl":
      "https://static.toiimg.com/thumb/msid-117518360,imgsize-99331,width-400,height-225,resizemode-72/119-voters-in-one-house-cong-alleges-vote-theft.jpg", // ✅ working
      "postedAt": DateTime.now().subtract(const Duration(hours: 2)),
      "likes": 45,
      "comments": 6,
    },
    {
      "agent": "Agent Priya",
      "title": "Booth Level Awareness Campaign in Pune",
      "description":
      "Volunteers conducted door-to-door campaigns encouraging people to verify their voter details and participate actively.",
      "imageUrl":
      "https://images.unsplash.com/photo-1521791055366-0d553872125f?auto=format&fit=crop&w=800&q=60", // ✅ already working
      "postedAt": DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      "likes": 82,
      "comments": 12,
    },
    {
      "agent": "Agent Arjun",
      "title": "Security Tightened Around Polling Booths",
      "description":
      "Local authorities in Delhi have increased police deployment to ensure safe and smooth voting across all constituencies.",
      "imageUrl":
      "https://img.youtube.com/vi/3x-0qF8cxqo/maxresdefault.jpg", // ✅ working
      "postedAt": DateTime.now().subtract(const Duration(days: 2)),
      "likes": 120,
      "comments": 23,
    },
  ];


  // To store likes locally for dummy interaction
  void _toggleLike(int index) {
    setState(() {
      if (_newsPosts[index]['liked'] == true) {
        _newsPosts[index]['liked'] = false;
        _newsPosts[index]['likes'] -= 1;
      } else {
        _newsPosts[index]['liked'] = true;
        _newsPosts[index]['likes'] += 1;
      }
    });
  }

  // Add dummy comment
  void _addComment(int index) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _commentController =
        TextEditingController();
        return AlertDialog(
          title: const Text("Add Comment"),
          content: TextField(
            controller: _commentController,
            decoration: const InputDecoration(hintText: "Write a comment..."),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _newsPosts[index]['comments'] += 1;
                });
                Navigator.pop(context);
              },
              child: const Text("Post"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voter News Feed"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _newsPosts.length,
        itemBuilder: (context, index) {
          final post = _newsPosts[index];
          final formattedDate =
          DateFormat('dd MMM yyyy, hh:mm a').format(post['postedAt']);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent & Time
                ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: AssetImage('assets/user_avatar.png'),
                  ),
                  title: Text(post['agent'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(formattedDate,
                      style: const TextStyle(color: Colors.grey)),
                ),

                // News Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.zero,
                    bottom: Radius.circular(0),
                  ),
                  child: Image.network(
                    post['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // News Title & Description
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['description'],
                        style:
                        const TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Like and Comment Section
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              post['liked'] == true
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_alt_outlined,
                              color: post['liked'] == true
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleLike(index),
                          ),
                          Text("${post['likes']} Likes"),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.comment_outlined,
                                color: Colors.grey),
                            onPressed: () => _addComment(index),
                          ),
                          Text("${post['comments']} Comments"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
