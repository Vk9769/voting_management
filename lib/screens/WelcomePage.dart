import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_page.dart';

class Slide {
  final String image;
  final String title;
  final String description;

  Slide({required this.image, required this.title, required this.description});
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  bool _hover = false;

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

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

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: -50, end: 50).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void nextSlide() {
    if (_currentIndex < slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void goToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget buildSlide(Slide slide, double sw, double sh) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(slide.image, width: sw * 0.55, height: sw * 0.55),
        SizedBox(height: sh * 0.04),
        Text(slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: sw * 0.07, fontWeight: FontWeight.bold)),
        SizedBox(height: sh * 0.015),
        Text(slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: sw * 0.045)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWeb = width >= 900;

    return Scaffold(
      body: isWeb
          ? Stack(
        children: [
          _buildIndianFlagBackground(),
          _buildWebHero(),
        ],
      )
          : _buildMobileSlider(),
    );
  }

  // ✅ Mobile slider layout (UNCHANGED)
  Widget _buildMobileSlider() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
              child: buildSlide(slides[i], sw, sh),
            ),
          ),

          Positioned(
            left: sw * 0.06,
            right: sw * 0.06,
            bottom: sh * 0.04,
            child: SizedBox(
              height: sh * 0.065,
              child: ElevatedButton(
                onPressed: nextSlide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,      // ✅ Your requested color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_currentIndex == slides.length - 1 ? 'Get Started' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndianFlagBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/india_bg.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildWebHero() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 80),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LEFT TEXT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Digital Voting\nManagement System",
                    style: const TextStyle(
                      fontSize: 58,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    "Secure. Verified. Transparent.\n\n"
                        "A modern platform designed to simplify and protect the voting process. "
                        "Ensure fairness, privacy, and trust with every vote cast.",
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 55),

                  // HOVER BUTTON
                  MouseRegion(
                    onEnter: (_) => setState(() => _hover = true),
                    onExit: (_) => setState(() => _hover = false),
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_hover ? 1.07 : 1.0),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          if (_hover)
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                      child: GestureDetector(
                        onTap: goToLogin,
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 90),

            // RIGHT : HOVER IMAGE
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _hover = true),
                onExit: (_) => setState(() => _hover = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()..translate(0.0, _hover ? -12 : 0),
                  child: Image.asset(
                    "assets/home3.png",
                    height: 420,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurredCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: const SizedBox()),
    );
  }
}
