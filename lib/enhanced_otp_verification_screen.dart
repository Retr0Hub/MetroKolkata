import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'services/auth_service.dart'; // Assuming this path is correct

class ModernOtpScreen extends StatefulWidget {
  final String email;
  final String? userName;
  final VoidCallback onVerificationSuccess;
  final VoidCallback? onResendOTP;
  final bool isSignup;

  const ModernOtpScreen({
    super.key,
    required this.email,
    this.userName,
    required this.onVerificationSuccess,
    this.onResendOTP,
    this.isSignup = false,
  });

  @override
  State<ModernOtpScreen> createState() => _ModernOtpScreenState();
}

class _ModernOtpScreenState extends State<ModernOtpScreen> with TickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  // Stream controller for the shake animation on error
  final StreamController<ErrorAnimationType> _errorController = StreamController<ErrorAnimationType>();
  
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCooldown = 60;
  Timer? _resendTimer;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _animationController.dispose();
    _otpController.dispose();
    _errorController.close(); // Close the stream controller
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCooldown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        _resendTimer?.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // Hide keyboard

    try {
      final isValid = await _authService.verifyOTP(widget.email, _otpController.text);
      
      if (isValid) {
        _showSuccessSnackBar('Verification successful!');
        // A small delay to let the user see the success message before navigating
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onVerificationSuccess();
      } else {
        _errorController.add(ErrorAnimationType.shake); // Trigger shake animation
        _showErrorSnackBar('Invalid or expired OTP. Please try again.');
        _otpController.clear();
      }
    } catch (e) {
      _errorController.add(ErrorAnimationType.shake);
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      if (widget.isSignup) {
        success = await _authService.sendSignupOTP(widget.email, widget.userName ?? '');
      } else {
        success = await _authService.send2FAOTP(widget.email);
      }

      if (success) {
        _showSuccessSnackBar('A new OTP has been sent to your email');
        _startResendTimer();
        _otpController.clear();
        widget.onResendOTP?.call();
      } else {
        _showErrorSnackBar('Failed to resend OTP. Please try again later.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while resending OTP.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Colors.deepPurple; // A modern, friendly color

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Engaging Header Graphic
                  SvgPicture.asset(
                    'assets/icons/shield_check.svg', // Use a relevant and clean SVG icon
                    height: 100,
                    colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Enter Verification Code',
                    style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600], height: 1.5),
                        children: [
                          const TextSpan(text: "We've sent a 6-digit code to "),
                          TextSpan(
                            text: widget.email,
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // OTP Input Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpController,
                      readOnly: _isLoading,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.fade,
                      errorAnimationController: _errorController,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 55,
                        fieldWidth: 45,
                        borderWidth: 1.5,
                        activeFillColor: primaryColor.withOpacity(0.05),
                        inactiveFillColor: Colors.grey.shade100,
                        selectedFillColor: primaryColor.withOpacity(0.1),
                        activeColor: primaryColor,
                        inactiveColor: Colors.grey.shade300,
                        selectedColor: primaryColor,
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      enableActiveFill: true,
                      onCompleted: (value) => _verifyOTP(),
                      onChanged: (value) {},
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                  const SizedBox(height: 32),
                  
                  // Resend OTP Text
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: "Didn't receive the code? "),
                        _canResend
                            ? TextSpan(
                                text: 'Resend',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                // Implement recognizer for tap events
                              )
                            : TextSpan(
                                text: 'Resend in ${_resendCooldown}s',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}