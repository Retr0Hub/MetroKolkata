import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pin_setup_screen.dart';
import 'services/auth_service.dart';

class SignupFormScreen extends StatefulWidget {
  final String phoneNumber;
  
  const SignupFormScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continueToPinSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save user data to database
      final success = await _authService.createUserProfile(
        phoneNumber: widget.phoneNumber,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        gender: _selectedGender,
      );

      if (success) {
        // Store user session locally
        final prefs = await _authService.getSharedPreferences();
        await prefs.setString('user_phone_number', widget.phoneNumber);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PinSetupScreen(
              phoneNumber: widget.phoneNumber,
              isVerification: false,
            ),
          ),
        );
      } else {
        _showErrorSnackBar('Failed to create profile. Please try again.');
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
                    'Complete Your Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us a bit about yourself',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: GoogleFonts.poppins(color: labelColor),
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
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Gender Selection
                  Text(
                    'Gender',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderOption('Male', 'male', textColor, inputFillColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderOption('Female', 'female', textColor, inputFillColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderOption('Other', 'other', textColor, inputFillColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Email (Optional)
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: textColor, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Email (Optional)',
                      labelStyle: GoogleFonts.poppins(color: labelColor),
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
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && !value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continueToPinSetup,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, String value, Color textColor, Color fillColor) {
    final isSelected = _selectedGender == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C853) : fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}