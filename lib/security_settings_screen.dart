import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'enhanced_otp_verification_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final twoFAStatus = await _authService.is2FAEnabledForUser(user.uid);
        final biometricStatus = await _authService.isBiometricEnabledForUser(user.uid);
        final biometricAvailable = await _authService.isBiometricAvailable();

        setState(() {
          _twoFactorEnabled = twoFAStatus;
          _biometricEnabled = biometricStatus;
          _isBiometricAvailable = biometricAvailable;
          _isLoading = false;
        });
      } catch (e) {
        _showErrorSnackBar('Error loading security settings: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggle2FA(bool enabled) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (enabled) {
        // Send OTP for verification before enabling 2FA
        final otpSent = await _authService.send2FAOTP(user.email!);
        if (otpSent) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ModernOtpScreen(
                email: user.email!,
                isSignup: false,
                onVerificationSuccess: () async {
                  final success = await _authService.enable2FA(user.uid);
                  if (success) {
                    setState(() => _twoFactorEnabled = true);
                    _showSuccessSnackBar('Two-factor authentication enabled successfully!');
                  } else {
                    _showErrorSnackBar('Failed to enable two-factor authentication.');
                  }
                  Navigator.of(context).pop();
                },
                onResendOTP: () {
                  _authService.send2FAOTP(user.email!);
                },
              ),
            ),
          );
        } else {
          _showErrorSnackBar('Failed to send verification code.');
        }
      } else {
        final success = await _authService.disable2FA(user.uid);
        if (success) {
          setState(() => _twoFactorEnabled = false);
          _showSuccessSnackBar('Two-factor authentication disabled.');
        } else {
          _showErrorSnackBar('Failed to disable two-factor authentication.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      if (enabled) {
        success = await _authService.enableBiometricAuth(user.uid);
        if (success) {
          setState(() => _biometricEnabled = true);
          _showSuccessSnackBar('Biometric authentication enabled successfully!');
        } else {
          _showErrorSnackBar('Failed to enable biometric authentication.');
        }
      } else {
        success = await _authService.disableBiometricAuth(user.uid);
        if (success) {
          setState(() => _biometricEnabled = false);
          _showSuccessSnackBar('Biometric authentication disabled.');
        } else {
          _showErrorSnackBar('Failed to disable biometric authentication.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Security Settings',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Secure Your Account',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable additional security features to protect your Kolkata Metro account.',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Two-Factor Authentication
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.security,
                                color: Colors.blue.shade600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Two-Factor Authentication',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add an extra layer of security by requiring an OTP code sent to your email.',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _twoFactorEnabled,
                              onChanged: _isLoading ? null : _toggle2FA,
                              activeColor: Colors.blue.shade600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Biometric Authentication
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isBiometricAvailable 
                          ? Colors.green.shade50 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isBiometricAvailable 
                            ? Colors.green.shade100 
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isBiometricAvailable 
                                    ? Colors.green.shade100 
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fingerprint,
                                color: _isBiometricAvailable 
                                    ? Colors.green.shade600 
                                    : Colors.grey.shade500,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biometric Authentication',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _isBiometricAvailable 
                                          ? Colors.black87 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isBiometricAvailable
                                        ? 'Use your fingerprint or face to login quickly and securely.'
                                        : 'Biometric authentication is not available on this device.',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _biometricEnabled && _isBiometricAvailable,
                              onChanged: _isLoading || !_isBiometricAvailable 
                                  ? null 
                                  : _toggleBiometric,
                              activeColor: Colors.green.shade600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Security Tips
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates,
                              color: Colors.orange.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Security Tips',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTip('Use a strong, unique password for your account'),
                        _buildTip('Enable two-factor authentication for maximum security'),
                        _buildTip('Keep your email account secure'),
                        _buildTip('Don\'t share your OTP codes with anyone'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.orange.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}