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

    // Credit animation controller (600ms, starts after 1600ms)
    _creditController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Exit animation controller (800ms)
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    // Credit animations
    _creditOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _creditController,
      curve: Curves.easeIn,
    ));

    _creditSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _creditController,
      curve: Curves.easeOutCubic,
    ));

    // Exit animations - Fixed positioning to prevent jumping
    _exitTextSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.3), // Reduced offset to prevent jumping
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInOutCubic,
    ));

    _exitElementsOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOut,
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
    
    // Start credit animation after 1600ms total
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _creditController.forward();
  }

  void _navigateWithTransition(Widget destination) async {
    setState(() {
      _isExiting = true;
    });

    // Start exit animation
    _exitController.forward();

    // Wait for animation to complete, then navigate
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) {
            return _WelcomeTextWrapper(
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
    // Reset exit state and restart welcome animations
    setState(() {
      _isExiting = false;
    });
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
    final metroColor = isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background image
          if (!_isExiting)
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
          
          // Exit animation overlay for background
          if (_isExiting)
            AnimatedBuilder(
              animation: _exitController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _exitElementsOpacity,
                  child: ClipPath(
                    clipper: BottomCurveClipper(),
                    child: Image.asset(
                      metroImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 450,
                    ),
                  ),
                );
              },
            ),

          // Exit animation layout with fixed positioning to prevent jumping
          if (_isExiting) ...[
            // Fixed position text at 160px - no movement, just stays there
            Positioned(
              top: 160, // Fixed at 160px from top
              left: 48,
              right: 48,
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
                    textAlign: TextAlign.left,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kolkata Metro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 46,
                        color: metroColor,
                        fontFamily: 'Arial',
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Fixed position other elements that fade out
            Positioned(
              top: 447, // Position for logo
              left: 48,
              right: 48,
              child: AnimatedBuilder(
                animation: _exitController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _exitElementsOpacity,
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          logo1,
                          width: 40,
                          height: 40,
                          color: textColor,
                        ),
                        const SizedBox(height: 180), // Space for buttons
                        // Exit state buttons
                        _buildButton(
                          context,
                          'Login',
                          Colors.white,
                          Colors.black,
                          () {},
                          borderColor: Colors.black,
                        ),
                        const SizedBox(height: 10),
                        _buildButton(
                          context,
                          'Create an account',
                          Colors.black,
                          Colors.white,
                          () {},
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 20),
                        // Credit text
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              const TextSpan(text: 'Made with '),
                              TextSpan(
                                text: '❤️',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const TextSpan(text: ' by Ayush'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else
            // Normal layout for initial animation
            Padding(
              padding: const EdgeInsets.only(top: 225.0),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  // Animated welcome text (normal state only)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
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
                                    color: metroColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                            SlideTransition(
                              position: _subtitleSlide,
                              child: FadeTransition(
                                opacity: _subtitleOpacity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Kolkata Metro',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 46,
                                      color: metroColor,
                                      fontFamily: 'Arial',
                                    ),
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
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
                  // Animated logo (normal state only)
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
                
                  const SizedBox(height: 15),
                  const Spacer(),
                  
                  // Animated login button (normal state only)
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
                            () => _navigateWithTransition(const LoginScreen()),
                            borderColor: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Animated signup button (normal state only)
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
                            () => _navigateWithTransition(const SignUpScreen()),
                            borderColor: borderColor,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Credit text with animation (normal state only)
                  AnimatedBuilder(
                    animation: _creditController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _creditSlide,
                        child: FadeTransition(
                          opacity: _creditOpacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Arial',
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  const TextSpan(text: 'Made with '),
                                  TextSpan(
                                    text: '❤️',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const TextSpan(text: ' by Ayush'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

class _WelcomeTextWrapper extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;
  final VoidCallback? onBack;

  const _WelcomeTextWrapper({
    required this.child,
    required this.animation,
    this.onBack,
  });

  @override
  State<_WelcomeTextWrapper> createState() => _WelcomeTextWrapperState();
}

class _WelcomeTextWrapperState extends State<_WelcomeTextWrapper>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerOpacity;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _contentOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // Start the header animation after the page transition begins
    widget.animation.addListener(_onPageAnimationChange);
  }

  void _onPageAnimationChange() {
    if (widget.animation.value > 0.3 && !_headerController.isAnimating && _headerController.value == 0) {
      _headerController.forward();
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onPageAnimationChange);
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final metroColor = isDarkMode ? Colors.white : Colors.black;

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          widget.onBack?.call();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Stack(
          children: [
            // Main content with login/signup form
            FadeTransition(
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
            // Welcome text overlay - positioned below back button
            FadeTransition(
              opacity: widget.animation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 80, // Below back button area
                  left: 48,
                  right: 48,
                  bottom: 20,
                ),
               child: AnimatedBuilder(
                 animation: _headerController,
                 builder: (context, child) {
                   return FadeTransition(
                     opacity: _headerOpacity,
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
                           textAlign: TextAlign.left,
                         ),
                         FittedBox(
                           fit: BoxFit.scaleDown,
                           alignment: Alignment.centerLeft,
                           child: Text(
                             'Kolkata Metro',
                             style: TextStyle(
                               fontWeight: FontWeight.bold,
                               fontSize: 46,
                               color: metroColor,
                               fontFamily: 'Arial',
                             ),
                             textAlign: TextAlign.left,
                             maxLines: 1,
                           ),
                         ),
                       ],
                     ),
                   );
                 },
               ),
             ),
           ],
         ),
      ),
    )
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
