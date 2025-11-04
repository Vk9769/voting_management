import 'package:flutter/material.dart';

class VoterChatPage extends StatefulWidget {
  const VoterChatPage({super.key});

  @override
  State<VoterChatPage> createState() => _VoterChatPageState();
}

class _VoterChatPageState extends State<VoterChatPage> {
  final TextEditingController _messageController = TextEditingController();

  // Dummy chat messages (you can replace this with real data)
  final List<Map<String, dynamic>> _messages = [
    {
      "sender": "agent",
      "text": "Hello! I’m your local booth agent. How can I help you today?",
      "time": "10:30 AM"
    },
    {
      "sender": "voter",
      "text": "Hi! I just wanted to confirm my booth location.",
      "time": "10:32 AM"
    },
    {
      "sender": "agent",
      "text": "Sure! Your booth is at Shivaji School, Ward 12.",
      "time": "10:33 AM"
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        "sender": "voter",
        "text": _messageController.text.trim(),
        "time":
        "${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}"
      });
      _messageController.clear();
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isVoter = message["sender"] == "voter";
    return Align(
      alignment: isVoter ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isVoter ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isVoter ? 12 : 0),
            bottomRight: Radius.circular(isVoter ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isVoter ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message["text"],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              message["time"],
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Agent"),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
