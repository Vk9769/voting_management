import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SuperAdminMessageDetail extends StatefulWidget {
  final String name;
  final String constituency;
  final String messageText;

  const SuperAdminMessageDetail({
    Key? key,
    required this.name,
    required this.constituency,
    required this.messageText,
  }) : super(key: key);

  @override
  State<SuperAdminMessageDetail> createState() => _SuperAdminMessageDetailState();
}

class _SuperAdminMessageDetailState extends State<SuperAdminMessageDetail> {
  TextEditingController replyController = TextEditingController();

  // Chat list structure: sender, text, time(DateTime)
  List<Map<String, dynamic>> chatMessages = [];

  String getFormattedTime(DateTime time) {
    return DateFormat('hh:mm a').format(time); // Example: 09:42 PM
  }

  @override
  void initState() {
    super.initState();

    // First message from Super Agent
    chatMessages.add({
      "sender": "super_agent",
      "text": widget.messageText,
      "time": DateTime.now(),
    });
  }

  void sendReply() {
    String text = replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      chatMessages.add({
        "sender": "master_admin",
        "text": text,
        "time": DateTime.now(),
      });
    });

    replyController.clear();
  }

  Widget chatBubble(String text, bool isSender, DateTime time) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isSender ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSender ? 16 : 4),
                topRight: Radius.circular(isSender ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isSender ? Colors.white : Colors.black,
              ),
            ),
          ),
          Text(
            getFormattedTime(time),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.name} (${widget.constituency})"),
        backgroundColor: Colors.blue,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                var msg = chatMessages[index];
                bool isSender = msg["sender"] == "master_admin";
                return chatBubble(msg["text"], isSender, msg["time"]);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendReply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
