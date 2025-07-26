import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'signup_form_screen.dart';
import 'pin_setup_screen.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationTarget; // e.g., email or phone number
  final Future<bool> Function(String otp) onVerify;
  final VoidCallback onResend;
  final bool isFirstTimeUser;

  const OtpVerificationScreen({
    super.key,
    required this.verificationTarget,
    required this.onVerify,
    required this.onResend,
    this.isFirstTimeUser = true,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  // Resend timer logic
  Timer? _resendTimer;
  int _resendCooldown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCooldown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        _resendTimer?.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _onVerifyPressed() async {
    if (_otpController.text.length != 6) {
      _showErrorSnackBar('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await widget.onVerify(_otpController.text.trim());

      if (success) {
        _showSuccessSnackBar('OTP verified successfully!');
        
        // Navigate based on user type
        if (widget.isFirstTimeUser) {
          // Check if user exists in database
          final userExists = await _authService.checkUserExists(widget.verificationTarget);
          
          if (userExists) {
            // User exists, go to PIN setup or home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            // New user, go to signup form
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SignupFormScreen(
                  phoneNumber: widget.verificationTarget,
                ),
              ),
            );
          }
        } else {
          // Returning user or PIN reset, go to PIN setup
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PinSetupScreen(
                phoneNumber: widget.verificationTarget,
                isVerification: false, // Set new PIN
              ),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Invalid OTP. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _onResendPressed() {
    if (_canResend) {
      widget.onResend();
      _startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final inputFillColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final labelColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF121212),
                        const Color(0xFF0A0A0A),
                      ]
                    : [
                        Colors.white,
                        Colors.grey.shade50,
                        Colors.grey.shade100,
                      ],
              ),
            ),
          ),
          // Fixed back button at top
          Positioned(
            top: 60,
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: textColor),
              padding: EdgeInsets.zero,
            ),
          ),
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 120.0, left: 24.0, right: 24.0, bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Verify OTP',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to\n+91 ${widget.verificationTarget}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),
                
                // OTP Input
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  onChanged: (value) {},
                  onCompleted: (value) {
                    _onVerifyPressed();
                  },
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 60,
                    fieldWidth: 50,
                    activeFillColor: inputFillColor,
                    inactiveFillColor: inputFillColor,
                    selectedFillColor: inputFillColor,
                    activeColor: const Color(0xFF00C853),
                    inactiveColor: Colors.grey.shade400,
                    selectedColor: const Color(0xFF00C853),
                  ),
                  keyboardType: TextInputType.number,
                  enableActiveFill: true,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onVerifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Verify OTP',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Resend section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: _canResend ? _onResendPressed : null,
                      child: Text(
                        _canResend
                            ? 'Resend OTP'
                            : 'Resend in $_resendCooldown s',
                        style: GoogleFonts.poppins(
                          color: _canResend ? const Color(0xFF00C853) : textColor.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}