import 'package:flutter/material.dart';
import 'super_admin_message_list.dart';

class MasterMessageCenterPage extends StatelessWidget {
  const MasterMessageCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (width >= 1100) {
      crossAxisCount = 3; // Web Layout
    } else if (width >= 700) {
      crossAxisCount = 2; // Tablet Layout
    } else {
      crossAxisCount = 1; // Mobile Layout
    }

    final List<_MessageItem> messages = [
      _MessageItem('Super Admin Messages', Icons.security, Colors.redAccent, Colors.pinkAccent, 'View and manage messages.'),
      _MessageItem('Admin Messages', Icons.admin_panel_settings, Colors.blue, Colors.indigoAccent, 'Review communications from Admins.'),
      _MessageItem('Super Agent Messages', Icons.verified_user, Colors.teal, Colors.cyan, 'Messages from Super Agents.'),
      _MessageItem('Agent Messages', Icons.person, Colors.green, Colors.lightGreen, 'Messages sent by Agents.'),
      _MessageItem('Voter Messages', Icons.people, Colors.orange, Colors.deepOrangeAccent, 'Read messages from voters.'),
      _MessageItem('Campaign Messages', Icons.campaign, Colors.purple, Colors.purpleAccent, 'Manage campaign communication.'),
      _MessageItem('Daily News', Icons.newspaper, Colors.grey, Colors.black87, 'Daily news & important updates.'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: GridView.builder(
              itemCount: messages.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: width >= 1100 ? 28 : 16,
                mainAxisSpacing: width >= 1100 ? 28 : 16,
                childAspectRatio: width >= 1100 ? 1.65 : 1.4,
              ),
              itemBuilder: (context, index) => _MessageCard(item: messages[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageItem {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final String description;

  _MessageItem(this.title, this.icon, this.color1, this.color2, this.description);
}

class _MessageCard extends StatefulWidget {
  final _MessageItem item;
  const _MessageCard({required this.item});

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Transform.scale(
        scale: hovered ? 1.03 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.item.color1, widget.item.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.25), // subtle outer edge
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.item.color1.withOpacity(hovered ? 0.40 : 0.18),
                blurRadius: hovered ? 26 : 12,
                spreadRadius: hovered ? 1.5 : 0.5,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: GestureDetector(
            onTap: () {
              if (widget.item.title == "Super Admin Messages") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuperAdminMessageList()),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.item.icon, size: 42, color: Colors.white),
                const SizedBox(height: 14),
                Text(
                  widget.item.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.description,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
