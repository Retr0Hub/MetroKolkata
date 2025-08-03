import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

// Assuming these files exist and define LoginScreen and SignUpScreen widgets
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
  late AnimationController _creditController;
  late AnimationController _exitController;

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
  late Animation<double> _creditOpacity;
  late Animation<Offset> _creditSlide;

  // Exit animations
  late Animation<Offset> _exitTextSlide;
  late Animation<double> _exitElementsOpacity;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Controller setup
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _creditController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation definitions
    _imageOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _imageController, curve: Curves.easeInOut));
    _imageSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _imageController, curve: Curves.easeOutCubic));

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _textController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _textController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _textController, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _textController, curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoRotation = Tween<double>(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic));

    _loginButtonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _buttonController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _loginButtonSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _buttonController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    _signupButtonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _buttonController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _signupButtonSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _buttonController, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));

    _creditOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _creditController, curve: Curves.easeIn));
    _creditSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _creditController, curve: Curves.easeOutCubic));

    _exitTextSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -205))
        .animate(CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic));
    _exitElementsOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitController, curve: Curves.easeOut));
  }

  void _startAnimations() async {
    _imageController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _buttonController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _creditController.forward();
  }

  void _navigateWithTransition(Widget destination) async {
    setState(() => _isExiting = true);
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) {
            return WelcomeTextWrapper(
              child: destination,
              animation: animation,
              onBack: _handleBackTransition,
            );
          },
        ),
      );
    }
  }

  void _handleBackTransition() {
    setState(() => _isExiting = false);
    _imageController.reset();
    _textController.reset();
    _logoController.reset();
    _buttonController.reset();
    _creditController.reset();
    _exitController.reset();
    _startAnimations();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
    _creditController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background for entry
          if (!_isExiting)
            AnimatedBuilder(
              animation: _imageController,
              builder: (context, child) {
                return SlideTransition(
                  position: _imageSlide,
                  child: FadeTransition(
                    opacity: _imageOpacity,
                    child: child,
                  ),
                );
              },
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

          // Fading background for exit
          if (_isExiting)
            AnimatedBuilder(
              animation: _exitController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _exitElementsOpacity,
                  child: child,
                );
              },
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

          // Sliding text for exit transition
          if (_isExiting)
            Positioned(
              top: 325,
              left: 24,
              right: 24,
              child: AnimatedBuilder(
                animation: _exitController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _exitTextSlide.value,
                    child: child,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome To',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 26,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Kolkata Metro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 46,
                        color: textColor,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Main content for entry animation
          if (!_isExiting)
            Padding(
              padding: const EdgeInsets.only(top: 225.0),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  // Animated welcome text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                    color: textColor,
                                    fontFamily: 'Arial',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
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
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      logo1,
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                      placeholderBuilder: (context) =>
                          CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Animated login button
                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _loginButtonSlide,
                        child: FadeTransition(
                          opacity: _loginButtonOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: _buildButton(
                      context,
                      'Login',
                      Colors.white,
                      Colors.black,
                      () => _navigateWithTransition(const LoginScreen()),
                      borderColor: Colors.black,
                    ),
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
                          child: child,
                        ),
                      );
                    },
                    child: _buildButton(
                      context,
                      'Create an account',
                      Colors.black,
                      Colors.white,
                      () => _navigateWithTransition(const SignUpScreen()),
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Animated credit text
                  AnimatedBuilder(
                    animation: _creditController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _creditSlide,
                        child: FadeTransition(
                          opacity: _creditOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                          children: const [
                            TextSpan(text: 'Made with '),
                            TextSpan(
                              text: '❤️',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                            TextSpan(text: ' by Ayush'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// Wrapper for the next screen to handle shared animations
class WelcomeTextWrapper extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;
  final VoidCallback? onBack;

  const WelcomeTextWrapper({
    super.key,
    required this.child,
    required this.animation,
    this.onBack,
  });

  @override
  State<WelcomeTextWrapper> createState() => _WelcomeTextWrapperState();
}

class _WelcomeTextWrapperState extends State<WelcomeTextWrapper>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _reverseController;
  late Animation<double> _headerOpacity;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  late Animation<Offset> _reverseTextSlide;
  late Animation<double> _reverseUIOpacity;
  late Animation<Offset> _reverseUISlide;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _reverseController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _headerController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _headerController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _headerController,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));

    _reverseTextSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 205))
        .animate(CurvedAnimation(parent: _reverseController, curve: Curves.easeInOutCubic));
    _reverseUIOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _reverseController, curve: Curves.easeOut));
    _reverseUISlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.5))
        .animate(CurvedAnimation(parent: _reverseController, curve: Curves.easeInOutCubic));

    widget.animation.addListener(_onPageAnimationChange);
  }

  void _onPageAnimationChange() {
    if (widget.animation.value > 0.3 &&
        !_headerController.isAnimating &&
        _headerController.value == 0) {
      _headerController.forward();
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onPageAnimationChange);
    _headerController.dispose();
    _reverseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final metroColor = isDarkMode ? Colors.white : Colors.black;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _reverseController.forward();
          await Future.delayed(const Duration(milliseconds: 800));
          widget.onBack?.call();
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Stack(
          children: [
            // Main form content
            AnimatedBuilder(
              animation: _reverseController,
              builder: (context, child) {
                return SlideTransition(
                  position: _reverseUISlide,
                  child: FadeTransition(
                    opacity: _reverseUIOpacity,
                    child: child,
                  ),
                );
              },
              child: FadeTransition(
                opacity: widget.animation,
                child: AnimatedBuilder(
                  animation: _headerController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _contentSlide,
                      child: FadeTransition(
                        opacity: _contentOpacity,
                        child: widget.child,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Welcome text overlay
            AnimatedBuilder(
              animation: _reverseController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _reverseTextSlide.value,
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 120, left: 24, right: 24, bottom: 20),
                child: AnimatedBuilder(
                  animation: _headerController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _headerOpacity,
                      child: child,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome To',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 26,
                          color: metroColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Kolkata Metro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 46,
                          color: metroColor,
                          fontFamily: 'Arial',
                        ),
                        maxLines: 1,
                      ),
                    ],
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

// Custom clipper for the curved background
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