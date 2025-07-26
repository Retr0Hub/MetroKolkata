import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'otp_verification_screen.dart';
import 'services/auth_service.dart';

class MobileNumberScreen extends StatefulWidget {
  final bool isFirstTimeUser;
  
  const MobileNumberScreen({
    super.key,
    this.isFirstTimeUser = true,
  });

  @override
  State<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends State<MobileNumberScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _authService.sendPhoneOTP(_phoneController.text.trim());
      
      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              verificationTarget: _phoneController.text.trim(),
              isFirstTimeUser: widget.isFirstTimeUser,
              onVerify: (otp) => _authService.verifyPhoneOTP(_phoneController.text.trim(), otp),
              onResend: () => _authService.sendPhoneOTP(_phoneController.text.trim()),
            ),
          ),
        );
      } else {
        _showErrorSnackBar('Failed to send OTP. Please try again.');
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    widget.isFirstTimeUser ? "Welcome!" : "Welcome Back!",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isFirstTimeUser 
                        ? "Enter your mobile number to get started"
                        : "Enter your mobile number to continue",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Mobile number input
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: textColor, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      labelStyle: GoogleFonts.poppins(color: labelColor),
                      prefixText: '+91 ',
                      prefixStyle: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFF00C853), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.length != 10) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                        return 'Please enter a valid Indian mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
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
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Terms and conditions
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}