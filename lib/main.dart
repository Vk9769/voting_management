import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/agent_dashboard.dart';
import 'screens/WelcomePage.dart'; // ✅ Use the new WelcomePage file
import 'screens/master_dashboard.dart';
import 'screens/candidate_dashboard.dart';
import 'screens/voter_home.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Votely',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // ✅ Correct key
    final role = prefs.getString('role');        // ✅ This matches login storage

    Timer(const Duration(seconds: 1), () {
      if (token != null && token.isNotEmpty) {
        Widget dashboard;

        switch (role) {
          case 'master_admin':
            dashboard = const MasterDashboard();
            break;

          case 'super_admin':
          case 'admin':
            dashboard = const AdminDashboard();
            break;

          case 'candidate':
            dashboard = const CandidateDashboard();
            break;

          case 'blo':
          case 'super_agent':
          case 'agent':
            dashboard = const AgentDashboard();
            break;

          case 'voter':
            dashboard = const VoterHomePage();
            break;

          default:
            dashboard = const WelcomePage();
        }

        _goTo(dashboard);
      } else {
        _goTo(const WelcomePage());
      }
    });
  }


  void _goTo(Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: sw * 0.25,
              height: sw * 0.25,
            ),
            SizedBox(height: sh * 0.02),
            Text(
              "Votely",
              style: TextStyle(
                fontSize: sw * 0.08,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
