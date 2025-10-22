import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgentMessagesPage extends StatefulWidget {
  const AgentMessagesPage({super.key});

  @override
  State<AgentMessagesPage> createState() => _AgentMessagesPageState();
}

class _AgentMessagesPageState extends State<AgentMessagesPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Chat threads with unread count
  List<ChatThread> threads = [
    ChatThread(
      voterName: 'Voter 1',
      lastMessage: 'Hello, I have a question',
      lastTime: '10:15 AM',
      unreadCount: 2,
    ),
    ChatThread(
      voterName: 'Voter 2',
      lastMessage: 'Can you help me?',
      lastTime: '9:50 AM',
      unreadCount: 0,
    ),
    ChatThread(
      voterName: 'Voter 3',
      lastMessage: 'Thanks for your help!',
      lastTime: 'Yesterday',
      unreadCount: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void updateThread(ChatThread updatedThread) {
    setState(() {
      final index = threads.indexWhere((t) => t.voterName == updatedThread.voterName);
      if (index != -1) {
        threads[index] = updatedThread;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          final animation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: _controller, curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut)));

          return SlideTransition(
            position: animation,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(thread.voterName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(thread.lastMessage),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(thread.lastTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (thread.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          thread.unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () async {
                  // Navigate to conversation page and update unread count on return
                  final updatedThread = await Navigator.push<ChatThread>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatConversationPage(thread: thread),
                    ),
                  );
                  if (updatedThread != null) updateThread(updatedThread);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// Thread model with unread count
class ChatThread {
  final String voterName;
  String lastMessage;
  final String lastTime;
  int unreadCount;

  ChatThread({
    required this.voterName,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
  });
}

// Chat conversation page
class ChatConversationPage extends StatefulWidget {
  final ChatThread thread;
  const ChatConversationPage({super.key, required this.thread});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  late List<Message> messages;

  @override
  void initState() {
    super.initState();
    // Dummy messages
    messages = [
      Message(
        text: 'Hello, I need help.',
        isSentByAgent: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Message(
        text: 'Sure, how can I assist?',
        isSentByAgent: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 55)),
      ),
    ];

    // Reset unread count when conversation opens
    widget.thread.unreadCount = 0;
  }

  void _sendMessage() {
    if (_messageCtrl.text.trim().isEmpty) return;
    setState(() {
      messages.add(Message(
        text: _messageCtrl.text.trim(),
        isSentByAgent: true,
        timestamp: DateTime.now(),
      ));
      _messageCtrl.clear();
    });
  }

  String formatDateTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return "Today, ${DateFormat.Hm().format(dt)}";
    } else if (dt.day == now.subtract(const Duration(days: 1)).day &&
        dt.month == now.month &&
        dt.year == now.year) {
      return "Yesterday, ${DateFormat.Hm().format(dt)}";
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(dt);
    }
  }

  @override
  void dispose() {
    // Return updated thread with unread count to previous page
    Navigator.pop(
        context,
        widget.thread..lastMessage = messages.isNotEmpty ? messages.last.text : widget.thread.lastMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.voterName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isSentByAgent ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: msg.isSentByAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: msg.isSentByAgent ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(color: msg.isSentByAgent ? Colors.white : Colors.black87),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
                        child: Text(
                          formatDateTime(msg.timestamp),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
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

class Message {
  final String text;
  final bool isSentByAgent;
  final DateTime timestamp;

  Message({required this.text, required this.isSentByAgent, required this.timestamp});
}
