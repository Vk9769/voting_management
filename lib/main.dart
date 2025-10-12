import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_page.dart';
import 'screens/admin_dashboard.dart'; // Example dashboard
import 'screens/agent_dashboard.dart'; // Example agent dashboard

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
    final token = prefs.getString('token'); // token saved after login
    // You can also store role, e.g., 'admin' or 'agent'
    final role = prefs.getString('role');

    Timer(const Duration(seconds: 1), () {
      if (token != null && token.isNotEmpty) {
        // Auto-login: Navigate to dashboard based on role
        Widget dashboard;
        if (role == 'admin') {
          dashboard = const AdminDashboard();
        } else if (role == 'agent') {
          dashboard = const AgentDashboard();
        } else {
          dashboard = const WelcomePage(); // fallback
        }
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => dashboard,
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        // First-time user -> WelcomePage
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WelcomePage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: screenWidth * 0.25,
              height: screenWidth * 0.25,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Votely",
              style: TextStyle(
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}


// Slide model
class Slide {
  final String image;
  final String title;
  final String description;

  Slide({required this.image, required this.title, required this.description});
}

// Welcome page with 3 slides and button at bottom
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Slide> slides = [
    Slide(
      image: 'assets/home1.png',
      title: 'Welcome to Votely',
      description: 'The online voting application\nCreate your account and stay tuned',
    ),
    Slide(
      image: 'assets/home2.png',
      title: 'Stay Tuned',
      description: 'Participate in elections\nYour vote matters',
    ),
    Slide(
      image: 'assets/home3.png',
      title: 'Make Your Choice',
      description: 'Choose candidates wisely\nYour decision shapes the future',
    ),
  ];

  void nextSlide() {
    if (_currentIndex < slides.length - 1) {
      _controller.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      goToLogin();
    }
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()), // navigate to login_page.dart
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildSlide(Slide slide, double screenWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          slide.image,
          width: screenWidth * 0.5,
          height: screenWidth * 0.5,
        ),
        SizedBox(height: screenHeight * 0.05),
        Text(
          slide.title,
          style: TextStyle(
            fontSize: screenWidth * 0.07,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: screenHeight * 0.02),
        Text(
          slide.description,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (_, index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: buildSlide(slides[index], screenWidth, screenHeight),
              ),
            ),
            Positioned(
              left: screenWidth * 0.06,
              right: screenWidth * 0.06,
              bottom: screenHeight * 0.03,
              child: SizedBox(
                height: screenHeight * 0.07,
                child: ElevatedButton(
                  onPressed: nextSlide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _currentIndex == slides.length - 1 ? 'Get Started' : 'Next',
                    style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                      (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.012),
                    width: _currentIndex == index ? screenWidth * 0.03 : screenWidth * 0.02,
                    height: _currentIndex == index ? screenWidth * 0.03 : screenWidth * 0.02,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? Colors.blue : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
