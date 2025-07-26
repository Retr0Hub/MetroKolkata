import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'home_screen.dart';
import 'forgot_pin_screen.dart';
import 'services/auth_service.dart';

class PinSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isVerification; // true for PIN verification, false for PIN setup
  
  const PinSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.isVerification,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isConfirmingPin = false;
  bool _showBiometricOption = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVerification) {
      _checkBiometricAvailability();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _authService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _showBiometricOption = isAvailable;
      });
    }
  }

  Future<void> _onPinCompleted(String pin) async {
    if (widget.isVerification) {
      await _verifyPin(pin);
    } else {
      if (!_isConfirmingPin) {
        setState(() {
          _isConfirmingPin = true;
        });
        _showConfirmPinDialog();
      } else {
        await _confirmPin(pin);
      }
    }
  }

  Future<void> _verifyPin(String pin) async {
    setState(() => _isLoading = true);

    try {
      final isValid = await _authService.verifyPin(widget.phoneNumber, pin);
      
      if (isValid) {
        // Store user session locally
        final prefs = await _authService.getSharedPreferences();
        await prefs.setString('user_phone_number', widget.phoneNumber);
        await prefs.setBool('has_pin', true);
        
        _showSuccessSnackBar('PIN verified successfully!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showErrorSnackBar('Invalid PIN. Please try again.');
        _pinController.clear();
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmPin(String confirmPin) async {
    final originalPin = _pinController.text;
    
    if (originalPin != confirmPin) {
      _showErrorSnackBar('PINs do not match. Please try again.');
      _confirmPinController.clear();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.setPin(widget.phoneNumber, originalPin);
      
      if (success) {
        // Store user session locally
        final prefs = await _authService.getSharedPreferences();
        await prefs.setString('user_phone_number', widget.phoneNumber);
        await prefs.setBool('has_pin', true);
        
        _showSuccessSnackBar('PIN set successfully!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showErrorSnackBar('Failed to set PIN. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConfirmPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm PIN',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your PIN again to confirm',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 20),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _confirmPinController,
              onChanged: (value) {},
              onCompleted: (value) {
                Navigator.of(context).pop();
                _confirmPin(value);
              },
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.grey.shade100,
                inactiveFillColor: Colors.grey.shade100,
                selectedFillColor: Colors.grey.shade100,
                activeColor: const Color(0xFF00C853),
                inactiveColor: Colors.grey.shade400,
                selectedColor: const Color(0xFF00C853),
              ),
              keyboardType: TextInputType.number,
              enableActiveFill: true,
              textStyle: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isConfirmingPin = false;
                _pinController.clear();
              });
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final success = await _authService.authenticateWithBiometric();
      
      if (success) {
        // Store user session locally
        final prefs = await _authService.getSharedPreferences();
        await prefs.setString('user_phone_number', widget.phoneNumber);
        await prefs.setBool('has_pin', true);
        
        _showSuccessSnackBar('Biometric authentication successful!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showErrorSnackBar('Biometric authentication failed. Please use PIN.');
      }
    } catch (e) {
      _showErrorSnackBar('Biometric authentication not available.');
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
                  widget.isVerification ? 'Enter Your PIN' : 'Set Your PIN',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isVerification 
                      ? 'Enter your 6-digit PIN to continue'
                      : 'Create a 6-digit PIN for secure access',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),
                
                // PIN Input
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _pinController,
                  onChanged: (value) {},
                  onCompleted: _onPinCompleted,
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
                
                // Biometric option (only for verification)
                if (widget.isVerification && _showBiometricOption) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: textColor.withOpacity(0.3)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: textColor.withOpacity(0.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _authenticateWithBiometric,
                      icon: Icon(Icons.fingerprint, color: const Color(0xFF00C853)),
                      label: Text(
                        'Use Biometric',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF00C853)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Forgot PIN option (only for verification)
                if (widget.isVerification) ...[
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ForgotPinScreen(
                              phoneNumber: widget.phoneNumber,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot PIN?',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00C853),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}