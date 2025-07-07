import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'phone_auth_screen.dart';
import 'forgot_password_screen.dart';

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
    // A simple check to see if the input could be an email.
    final bool isEmail = text.contains('@');
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
          content: Text('Please enter a valid 10-digit phone number.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log in to your account',
                style: GoogleFonts.roboto(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _identifierController,
                decoration: _uberInputDecoration(context,
                    labelText: 'Email or Phone Number'),
                keyboardType: TextInputType.text,
                validator: (value) =>
                    value!.isEmpty
                        ? 'Please enter your email or phone number'
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
                            decoration: _uberInputDecoration(
                                context, labelText: 'Password'),
                            validator: (value) => _isEmail && (value == null || value.isEmpty)
                                ? 'Please enter a password'
                                : null,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()));
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_space')),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isEmail ? _loginWithEmail : _navigateToPhoneAuth),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.black))
                    : Text(
                        _isEmail ? 'Log In' : 'Continue',
                        style: GoogleFonts.roboto(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _uberInputDecoration(BuildContext context,
    {required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle:
        GoogleFonts.roboto(color: Theme.of(context).colorScheme.secondary),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).dividerColor),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).primaryColor),
    ),
    errorStyle: GoogleFonts.roboto(color: Theme.of(context).colorScheme.error),
  );
}
