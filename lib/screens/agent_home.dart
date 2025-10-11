import 'package:flutter/material.dart';

class AgentHomePage extends StatelessWidget {
  const AgentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agent Home")),
      body: const Center(
        child: Text("Welcome, Agent!", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
