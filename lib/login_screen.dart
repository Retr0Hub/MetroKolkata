import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'phone_auth_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEmail = false;

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

  void _onIdentifierChanged() {
    final text = _identifierController.text.trim();
    // Check for a more complete email format (contains @ and a dot after @)
    final bool isEmail = text.contains('@') && text.contains('.') && text.indexOf('@') < text.lastIndexOf('.');
    if (isEmail != _isEmail) {
      setState(() {
        _isEmail = isEmail;
      });
    }
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _identifierController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // The AuthWrapper will handle navigation, so we just pop this screen.
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        if (mounted) setState(() => _isLoading = false);
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
        // Create a new document for the user in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'metroCardBalance': 0,
        });
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToPhoneAuth() {
    if (!_formKey.currentState!.validate()) return;

    final phone = _identifierController.text.trim();
    // Basic validation for a 10-digit number
    if (RegExp(r'^\d{10}$').hasMatch(phone)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PhoneAuthScreen(initialPhoneNumber: phone),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid phone number')));
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
    final inputFillColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final labelColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final googleButtonBg = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100;
    final googleButtonText = isDarkMode ? Colors.white : Colors.black;
    final linkColor = isDarkMode ? Colors.white : Colors.black;
    final forgotPasswordColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Fixed back button at top - aligned with content
          Positioned(
            top: 60,
            left: 12, // More left to align with text content
                                      child: IconButton(
              onPressed: () => _navigateBackWithTransition(),
              icon: Icon(Icons.arrow_back, color: textColor),
              padding: EdgeInsets.zero,
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 250.0, left: 24.0, right: 24.0, bottom: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                              Text(
                  "What's your email or phone number?",
                  style: GoogleFonts.inter(
                      fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                ),
              const SizedBox(height: 32),
                                              TextFormField(
                  controller: _identifierController,
                  style: TextStyle(color: textColor, fontSize: 18),
                  decoration: _uberInputDecoration('Email or Phone', inputFillColor, labelColor),
                keyboardType: TextInputType.text,
                                  validator: (value) =>
                      value!.isEmpty
                          ? 'Email or phone required'
                          : null,
              ),
              // Conditionally show the password field and forgot password button
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
                            decoration: _uberInputDecoration('Password', inputFillColor, labelColor),
                            validator: (value) => _isEmail && (value == null || value.isEmpty)
                                ? 'Password required'
                                : null,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()));
                            },
                            child: const Text('Forgot Password?'),
                            style: TextButton.styleFrom(foregroundColor: forgotPasswordColor),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_space')),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
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
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'lib/assets/loading.gif',
                            width: 24,
                            height: 24,
                          ))
                      : Text(
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
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: SvgPicture.asset('lib/assets/google_logo.svg', height: 22),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: googleButtonBg,
                    foregroundColor: googleButtonText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SignUpScreen()));
                    },
                    child: const Text('Sign up'),
                    style: TextButton.styleFrom(foregroundColor: linkColor),
                  )
                ],
              )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
