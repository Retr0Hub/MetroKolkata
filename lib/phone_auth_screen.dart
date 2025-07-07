import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'create_profile_screen.dart';

// For UI consistency, we can use the same input decoration style
// from your other authentication screens.
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

class PhoneAuthScreen extends StatefulWidget {
  final String? initialPhoneNumber;

  const PhoneAuthScreen({super.key, this.initialPhoneNumber});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = widget.initialPhoneNumber!;
      // Use a post-frame callback to ensure the widget is built before showing UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sendOtp();
      });
    }
  }
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text.trim()}',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signIn(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.message ?? 'Verification failed. Please check the number.')),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
          });
        }
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _otpController.text.trim(),
    );

    await _signIn(credential);
  }

  Future<void> _signIn(PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid);
        final doc = await userDocRef.get();

        if (!doc.exists) {
          if (mounted) {
            // New user, navigate to create profile screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
            );
          }
        } else {
          // Existing user, go to home screen
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Sign in failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _otpSent ? 'Enter the OTP' : 'Enter your phone number',
                style: GoogleFonts.roboto(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_otpSent)
                Text(
                  'A 6-digit code has been sent to +91 ${_phoneController.text}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              const SizedBox(height: 32),
              // This is the main content that switches between phone and OTP
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _otpSent ? _buildOtpForm() : _buildPhoneForm(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.black))
                    : Text(
                        _otpSent ? 'Verify & Continue' : 'Send OTP',
                        style: GoogleFonts.roboto(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              if (_otpSent)
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _otpSent = false;
                            _isLoading = false;
                            _otpController.clear();
                          }),
                  child: const Text('Change phone number'),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return TextFormField(
      key: const ValueKey('phone'),
      controller: _phoneController,
      decoration:
          _uberInputDecoration(context, labelText: '10-digit mobile number')
              .copyWith(prefixText: '+91 '),
      keyboardType: TextInputType.phone,
      validator: (value) => (value?.length ?? 0) != 10
          ? 'Please enter a valid 10-digit number'
          : null,
    );
  }

  Widget _buildOtpForm() {
    return TextFormField(
      key: const ValueKey('otp'),
      controller: _otpController,
      decoration: _uberInputDecoration(context, labelText: '6-digit OTP'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          (value?.length ?? 0) != 6 ? 'OTP must be 6 digits' : null,
    );
  }
}