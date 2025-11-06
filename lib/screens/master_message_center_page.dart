import 'package:flutter/material.dart';
import 'super_admin_message_list.dart';

class MasterMessageCenterPage extends StatelessWidget {
  const MasterMessageCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width >= 700;

    final List<_MessageItem> messages = [
      _MessageItem(
        title: 'Super Admin Messages',
        icon: Icons.security,
        color1: Colors.redAccent,
        color2: Colors.pinkAccent,
        description: 'View and manage messages from Super Admins.',
      ),
      _MessageItem(
        title: 'Admin Messages',
        icon: Icons.admin_panel_settings,
        color1: Colors.blue,
        color2: Colors.indigoAccent,
        description: 'Review communications from all Admins.',
      ),
      _MessageItem(
        title: 'Super Agent Messages',
        icon: Icons.verified_user,
        color1: Colors.teal,
        color2: Colors.cyan,
        description: 'Messages from Super Agents.',
      ),
      _MessageItem(
        title: 'Agent Messages',
        icon: Icons.person,
        color1: Colors.green,
        color2: Colors.lightGreen,
        description: 'Messages sent by agents.',
      ),
      _MessageItem(
        title: 'Voter Messages',
        icon: Icons.people,
        color1: Colors.orange,
        color2: Colors.deepOrangeAccent,
        description: 'Read messages from voters.',
      ),
      _MessageItem(
        title: 'Campaign Messages',
        icon: Icons.campaign,
        color1: Colors.purple,
        color2: Colors.purpleAccent,
        description: 'Manage campaign communication.',
      ),
      _MessageItem(
        title: 'Daily News',
        icon: Icons.newspaper,
        color1: Colors.grey,
        color2: Colors.black87,
        description: 'Daily news & important updates.',
      ),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: messages
                .map((msg) => _MessageCard(item: msg, wide: wide))
                .toList(),
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

  _MessageItem({
    required this.title,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.description,
  });
}

class _MessageCard extends StatelessWidget {
  final _MessageItem item;
  final bool wide;

  const _MessageCard({required this.item, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 260 : double.infinity,
      child: GestureDetector(
        onTap: () {
          if (item.title == "Super Admin Messages") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuperAdminMessageList()),
            );
          }
          // You can add other navigation cases later
        },

        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [item.color1, item.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: item.color1.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 42, color: Colors.white),
              const SizedBox(height: 14),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
