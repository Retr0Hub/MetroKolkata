import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rive/rive.dart'; // Added for Rive animations
import 'phone_auth_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'enhanced_otp_verification_screen.dart';
import 'biometric_auth_screen.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isEmail = false;

  // --- Animation State and Controllers ---
  bool isShowLoading = false;
  bool isShowConfetti = false;
  bool isFormVisible = true; // Controls form opacity for fade-out
  late SMITrigger error;
  late SMITrigger success;
  late SMITrigger reset;
  late SMITrigger confetti;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_onIdentifierChanged);
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onIdentifierChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Rive Initialization Methods ---
  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');
    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    success = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  void _onIdentifierChanged() {
    if (isShowLoading) return; // Prevent changes during animation
    final text = _identifierController.text.trim();
    final bool isEmail = text.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(text);
    if (isEmail != _isEmail) {
      setState(() {
        _isEmail = isEmail;
      });
    }
  }

  // --- Updated Login Logic with New Animation Sequence ---
  Future<void> _loginWithEmail() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isShowLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithEmailPassword(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null) {
        success.fire(); // Start checkmark animation
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            isFormVisible = false; // Fade out form
            isShowConfetti = true; // Show confetti animation
          });
          confetti.fire(); // Trigger confetti burst
          // Navigate after fade-out and confetti has started
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            _navigatePostLogin(userCredential.user!);
          });
        });
      } else {
        _showErrorAndResetAnimation('Login failed. Please check your credentials.');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorAndResetAnimation(e.message ?? 'Login failed');
    }
  }
  
  void _showErrorAndResetAnimation(String message) {
    error.fire(); // Trigger error animation
    _showErrorSnackBar(message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isShowLoading = false;
          isFormVisible = true; // Ensure form is visible again
        });
        reset.fire();
      }
    });
  }

  Future<void> _navigatePostLogin(User user) async {
    final has2FA = await _authService.is2FAEnabledForUser(user.uid);
    final hasBiometric = await _authService.isBiometricEnabledForUser(user.uid);

    if (!mounted) return;

    if (has2FA) {
      // For 2FA, we navigate directly, bypassing the welcome animation for now
      final otpSent = await _authService.send2FAOTP(user.email!);
      if (otpSent) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ModernOtpScreen(
              email: user.email!,
              isSignup: false,
              onVerificationSuccess: () => _checkForBiometric(user.uid, user.email!),
              onResendOTP: () => _authService.send2FAOTP(user.email!),
            ),
          ),
          (route) => false,
        );
      } else {
        _showErrorSnackBar('Failed to send 2FA code. Please try again.');
      }
    } else if (hasBiometric) {
      _showBiometricAuthOption(user.uid, user.email!);
    } else {
      // Navigate to Home with the Welcome Text Animation
      _navigateToHomeWithAnimation();
    }
  }

  void _navigateToHomeWithAnimation() {
     Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return _PostAuthWrapper(
              child: const HomeScreen(),
              animation: animation,
            );
          },
          transitionDuration: const Duration(milliseconds: 300)),
      (route) => false,
    );
  }


  Future<void> _checkForBiometric(String userId, String email) async {
    final hasBiometric = await _authService.isBiometricEnabledForUser(userId);
    if (hasBiometric) {
      _showBiometricAuthOption(userId, email);
    } else {
      _navigateToHomeWithAnimation();
    }
  }

  void _showBiometricAuthOption(String userId, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Authentication'),
        content: const Text('Use biometric authentication for faster login?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHomeWithAnimation();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BiometricAuthScreen(
                    userId: userId,
                    email: email,
                  ),
                ),
              );
            },
            child: const Text('Use Biometric'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isShowLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => isShowLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null && userCredential.additionalUserInfo!.isNewUser) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'metroCardBalance': 0,
        });
      }

      if (mounted) {
        _navigateToHomeWithAnimation();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to sign in with Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isShowLoading = false);
    }
  }

  void _navigateToPhoneAuth() {
    if (!_formKey.currentState!.validate()) return;

    final phone = _identifierController.text.trim();
    if (RegExp(r'^\d{10}$').hasMatch(phone)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PhoneAuthScreen(initialPhoneNumber: phone),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid 10-digit phone number.')));
    }
  }

  void _navigateBackWithTransition() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final buttonBgColor = isDarkMode ? Colors.white : Colors.black;
    final buttonTextColor = isDarkMode ? Colors.black : Colors.white;
    final inputFillColor =
        isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final labelColor =
        isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final googleButtonBg =
        isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100;
    final googleButtonText = isDarkMode ? Colors.white : Colors.black;
    final linkColor = isDarkMode ? Colors.white : Colors.black;
    final forgotPasswordColor =
        isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                top: 100.0, left: 24.0, right: 24.0, bottom: 24.0),
            child: AnimatedOpacity(
              opacity: isFormVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Vertically center the form a bit more
                    const SizedBox(height: 150),
                    Text(
                      "What's your email or phone number?",
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _identifierController,
                      style: TextStyle(color: textColor, fontSize: 18),
                       readOnly: isShowLoading,
                      decoration: _uberInputDecoration(
                          'Email or Phone', inputFillColor, labelColor),
                      keyboardType: TextInputType.text,
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your email or phone number'
                          : null,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return SizeTransition(sizeFactor: animation, child: child);
                      },
                      child: _isEmail
                          ? Column(
                              key: const ValueKey('password_field'),
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: TextStyle(color: textColor, fontSize: 18),
                                  readOnly: isShowLoading,
                                  decoration: _uberInputDecoration(
                                      'Password', inputFillColor, labelColor),
                                  validator: (value) => _isEmail &&
                                          (value == null || value.isEmpty)
                                      ? 'Please enter a password'
                                      : null,
                                ),
                                TextButton(
                                  onPressed: isShowLoading ? null : () {
                                     Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(milliseconds: 300),
                                        reverseTransitionDuration: const Duration(milliseconds: 800),
                                        pageBuilder: (context, animation, secondaryAnimation) {
                                          return _NoReverseWrapper(
                                            child: const ForgotPasswordScreen(),
                                            animation: animation,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                      foregroundColor: forgotPasswordColor),
                                  child: const Text('Forgot Password?'),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey('empty_space')),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isShowLoading
                            ? null
                            : (_isEmail ? _loginWithEmail : _navigateToPhoneAuth),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBgColor,
                          foregroundColor: buttonTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isEmail ? 'Log In' : 'Continue',
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('or', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isShowLoading ? null : _signInWithGoogle,
                        icon: SvgPicture.asset('lib/assets/google_logo.svg',
                            height: 22),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: googleButtonBg,
                          foregroundColor: googleButtonText,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?",
                            style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: isShowLoading ? null : () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                                reverseTransitionDuration:
                                    const Duration(milliseconds: 800),
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                  return WelcomeTextWrapper(
                                    child: const SignUpScreen(),
                                    animation: animation,
                                    onBack: () {}, // Will handle with PopScope
                                  );
                                },
                              ),
                            );
                          },
                          style:
                              TextButton.styleFrom(foregroundColor: linkColor),
                          child: const Text('Sign up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- Rive Animation Overlays ---
          // This must be on top of the form but below the back button
           Positioned(
            top: 60,
            left: 12,
            child: isShowLoading ? const SizedBox() : IconButton(
              onPressed: () => _navigateBackWithTransition(),
              icon: Icon(Icons.arrow_back, color: textColor),
              padding: EdgeInsets.zero,
            ),
          ),
          if (isShowLoading)
            CustomPositioned(
              child: RiveAnimation.asset(
                'assets/RiveAssets/check.riv',
                onInit: _onCheckRiveInit,
                fit: BoxFit.cover,
              ),
            ),
          if (isShowConfetti)
            CustomPositioned(
              scale: 6,
              child: RiveAnimation.asset(
                "assets/RiveAssets/confetti.riv",
                onInit: _onConfettiRiveInit,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Helper widget to position Rive animations ---
class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: SizedBox(
          height: 100,
          width: 100,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        ),
      ),
    );
  }
}

// All other helper widgets (_NoReverseWrapper, _PostAuthWrapper, etc.) remain unchanged.
// ... (Paste the rest of the original code from LoginScreen here)

InputDecoration _uberInputDecoration(String labelText, Color fillColor, Color labelColor) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: GoogleFonts.inter(color: labelColor),
    filled: true,
    fillColor: fillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
  );
}

class WelcomeTextWrapper extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;
  final VoidCallback onBack;

  const WelcomeTextWrapper({
    super.key,
    required this.child,
    required this.animation,
    required this.onBack,
  });

  @override
  State<WelcomeTextWrapper> createState() => _WelcomeTextWrapperState();
}

class _WelcomeTextWrapperState extends State<WelcomeTextWrapper> with TickerProviderStateMixin {
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
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final metroColor = isDarkMode ? Colors.white : Colors.black;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _headerController.reverse();
        widget.onBack();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Main content
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
            // Welcome text overlay
            FadeTransition(
              opacity: widget.animation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 120,
                  left: 24,
                  right: 24,
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
                          Text(
                            'Kolkata Metro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 46,
                              color: metroColor,
                              fontFamily: 'Arial',
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NoReverseWrapper extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;

  const _NoReverseWrapper({
    required this.child,
    required this.animation,
  });

  @override
  State<_NoReverseWrapper> createState() => _NoReverseWrapperState();
}

class _NoReverseWrapperState extends State<_NoReverseWrapper>
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

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Main content (no reverse animation)
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
          // Welcome text overlay (no reverse animation)
          FadeTransition(
            opacity: widget.animation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 120,
                left: 24,
                right: 24,
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
                        Text(
                          'Kolkata Metro',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 46,
                            color: metroColor,
                            fontFamily: 'Arial',
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _PostAuthWrapper extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;

  const _PostAuthWrapper({
    required this.child,
    required this.animation,
  });

  @override
  State<_PostAuthWrapper> createState() => _PostAuthWrapperState();
}

class _PostAuthWrapperState extends State<_PostAuthWrapper>
    with TickerProviderStateMixin {
  late AnimationController _textMoveController;
  late AnimationController _delayController;
  late Animation<Offset> _textCenterSlide;
  late Animation<double> _textOpacity;
  
  @override
  void initState() {
    super.initState();
    
    _textMoveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _delayController = AnimationController(
      duration: const Duration(milliseconds: 2000), // 2 second delay
      vsync: this,
    );
    
    _textCenterSlide = Tween<Offset>(
      begin: Offset.zero, // Start at current position (120px from top)
      end: const Offset(0, 200), // Move to vertical center of screen
    ).animate(CurvedAnimation(
      parent: _textMoveController,
      curve: Curves.easeInOutCubic,
    ));
    
    _textOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _delayController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
    ));
    
    // Start the sequence
    _startPostAuthSequence();
  }
  
  void _startPostAuthSequence() async {
    // First, move text to center
    _textMoveController.forward();
    
    // Wait for move animation to complete
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Start 2 second delay timer and fade at the end
    _delayController.forward();
    
    // Wait for delay to complete
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Navigate to home screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.child),
      );
    }
  }
  
  @override
  void dispose() {
    _textMoveController.dispose();
    _delayController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final metroColor = isDarkMode ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Welcome text that moves to center and stays
          AnimatedBuilder(
            animation: _textMoveController,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _delayController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _textCenterSlide.value.dy),
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          top: 120, // Start from login screen position
                          left: 24,
                          right: 24,
                          bottom: 20,
                        ),
                                                child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Keep text left-aligned
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
                            Text(
                              'Kolkata Metro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 46,
                                color: metroColor,
                                fontFamily: 'Arial',
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}