import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final String metroImage = 'lib/assets/welcomecircle.jpeg';
  final String logo1 = 'lib/assets/logo.svg';

  // Animation controllers
  late AnimationController _imageController;
  late AnimationController _textController;
  late AnimationController _logoController;
  late AnimationController _buttonController;

  // Animations
  late Animation<double> _imageOpacity;
  late Animation<Offset> _imageSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _loginButtonOpacity;
  late Animation<Offset> _loginButtonSlide;
  late Animation<double> _signupButtonOpacity;
  late Animation<Offset> _signupButtonSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Image animation controller (0.8 seconds)
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Text animation controller (1.2 seconds, starts after 400ms)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo animation controller (1 second, starts after 800ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Button animation controller (1 second, starts after 1200ms)
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Image animations
    _imageOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.easeInOut,
    ));

    _imageSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.easeOutCubic,
    ));

    // Text animations
    _titleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _subtitleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    // Logo animations
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    // Button animations
    _loginButtonOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _loginButtonSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _signupButtonOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _signupButtonSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() async {
    // Start image animation immediately
    _imageController.forward();
    
    // Start text animation after 400ms
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _textController.forward();
    
    // Start logo animation after 800ms total
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _logoController.forward();
    
    // Start button animations after 1200ms total
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _buttonController.forward();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode ? Colors.white : Colors.black;
    final metroColor = isDarkMode ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 255, 255, 255);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background image
          AnimatedBuilder(
            animation: _imageController,
            builder: (context, child) {
              return SlideTransition(
                position: _imageSlide,
                child: FadeTransition(
                  opacity: _imageOpacity,
                  child: ClipPath(
                    clipper: BottomCurveClipper(),
                    child: Image.asset(
                      metroImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 450,
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: Column(
              children: [
                const SizedBox(height: 120),
                // Animated welcome text
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: Text(
                              'Welcome To',
                              style: TextStyle(
                                fontFamily: 'Arial',
                                fontSize: 26,
                                color: metroColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SlideTransition(
                          position: _subtitleSlide,
                          child: FadeTransition(
                            opacity: _subtitleOpacity,
                            child: Text(
                              'Kolkata Metro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 46,
                                color: metroColor,
                                fontFamily: 'Arial',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 60),
                // Animated logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoOpacity,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: SvgPicture.asset(
                            logo1,
                            width: 40,
                            height: 40,
                            color: textColor,
                            placeholderBuilder: (context) =>
                                CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(textColor),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Spacer(),
                // Animated login button
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _loginButtonSlide,
                      child: FadeTransition(
                        opacity: _loginButtonOpacity,
                        child: _buildButton(
                          context,
                          'Login',
                          Colors.white,
                          Colors.black,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          borderColor: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Animated signup button
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _signupButtonSlide,
                      child: FadeTransition(
                        opacity: _signupButtonOpacity,
                        child: _buildButton(
                          context,
                          'Create an account',
                          Colors.black,
                          Colors.white,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignUpScreen()),
                            );
                          },
                          borderColor: borderColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 118),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed, {
    Color? borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, size.height + 50, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
