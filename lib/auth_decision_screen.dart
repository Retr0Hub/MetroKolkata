import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mobile_number_screen.dart';
import 'pin_setup_screen.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';

class AuthDecisionScreen extends StatefulWidget {
  const AuthDecisionScreen({super.key});

  @override
  State<AuthDecisionScreen> createState() => _AuthDecisionScreenState();
}

class _AuthDecisionScreenState extends State<AuthDecisionScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check if user is logged in and has a PIN set
      final prefs = await _authService.getSharedPreferences();
      final phoneNumber = prefs.getString('user_phone_number');
      final hasPin = prefs.getBool('has_pin') ?? false;
      
      if (phoneNumber != null && hasPin) {
        setState(() {
          _isLoggedIn = true;
          _userPhoneNumber = phoneNumber;
        });
      }
    } catch (e) {
      print('Error checking auth status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MobileNumberScreen(isFirstTimeUser: true),
      ),
    );
  }

  void _navigateToPinVerification() {
    if (_userPhoneNumber != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(
            phoneNumber: _userPhoneNumber!,
            isVerification: true,
          ),
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00C853)),
              ),
              const SizedBox(height: 24),
              Text(
                'Checking authentication...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      // User is logged in, show PIN verification or go directly to home
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
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.directions_subway,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Welcome text
                    Text(
                      'Welcome Back!',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your PIN to continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // PIN verification button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToPinVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Enter PIN',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Skip to home option (for development/testing)
                    TextButton(
                      onPressed: _navigateToHome,
                      child: Text(
                        'Skip to Home (Dev)',
                        style: GoogleFonts.poppins(
                          color: textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
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

    // User is not logged in, show welcome screen
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
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo/icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.directions_subway,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Welcome text
                  Text(
                    'Welcome to\nKolkata Metro',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your journey starts here',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Get started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get Started',
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
}