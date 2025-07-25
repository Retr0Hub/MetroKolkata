import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'services/auth_service.dart';
import 'home_screen.dart';

class BiometricAuthScreen extends StatefulWidget {
  final String userId;
  final String email;

  const BiometricAuthScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkBiometricAvailability();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _authService.isBiometricAvailable();
      final availableBiometrics = await _authService.getAvailableBiometrics();
      
      setState(() {
        _isBiometricAvailable = isAvailable;
        _availableBiometrics = availableBiometrics;
      });
    } catch (e) {
      _showErrorSnackBar('Error checking biometric availability: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_isBiometricAvailable) {
      _showErrorSnackBar('Biometric authentication is not available on this device');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isAuthenticated = await _authService.authenticateWithBiometrics();
      
      if (isAuthenticated) {
        _showSuccessSnackBar('Authentication successful!');
        _navigateToHome();
      } else {
        _showErrorSnackBar('Authentication failed. Please try again.');
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Authentication failed';
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometric authentication is not available';
          break;
        case 'NotEnrolled':
          errorMessage = 'No biometrics enrolled on this device';
          break;
        case 'LockedOut':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometric authentication is permanently locked';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _usePasswordLogin() {
    Navigator.pop(context);
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

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.strong) || 
               _availableBiometrics.contains(BiometricType.weak)) {
      return Icons.security;
    }
    return Icons.lock;
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.strong) || 
               _availableBiometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }
    return 'Biometric';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Biometric Login',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isBiometricAvailable) ...[
              // Biometric not available
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Biometric Not Available',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Biometric authentication is not available on this device or no biometrics are enrolled.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              // Biometric available
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isLoading ? 1.0 : _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getBiometricIcon(),
                        size: 60,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Login with ${_getBiometricTypeText()}',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Use your ${_getBiometricTypeText().toLowerCase()} to securely access your account',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 48),
            
            if (_isBiometricAvailable) ...[
              // Authenticate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWithBiometrics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getBiometricIcon()),
                            const SizedBox(width: 12),
                            Text(
                              'Authenticate',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Use Password Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _usePasswordLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  side: BorderSide(color: Colors.blue.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Use Password Instead',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Available biometrics info
            if (_availableBiometrics.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Available Authentication Methods',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableBiometrics.map((biometric) {
                        IconData icon;
                        String label;
                        switch (biometric) {
                          case BiometricType.face:
                            icon = Icons.face;
                            label = 'Face ID';
                            break;
                          case BiometricType.fingerprint:
                            icon = Icons.fingerprint;
                            label = 'Fingerprint';
                            break;
                          case BiometricType.strong:
                            icon = Icons.security;
                            label = 'Strong Biometric';
                            break;
                          case BiometricType.weak:
                            icon = Icons.lock_outline;
                            label = 'Weak Biometric';
                            break;
                          default:
                            icon = Icons.security;
                            label = 'Biometric';
                        }
                        
                        return Chip(
                          avatar: Icon(icon, size: 16),
                          label: Text(
                            label,
                            style: GoogleFonts.roboto(fontSize: 12),
                          ),
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}