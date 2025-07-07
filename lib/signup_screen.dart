import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'phone_auth_screen.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Create user with email and password
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create a corresponding user document in Firestore
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'metroCardBalance': 0, // Initial balance
        });
      }
      // Pop back to the welcome screen. The AuthWrapper will detect the
      // unverified user and show the verification screen.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A verification link has been sent to your email.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid);
        final doc = await userDocRef.get();

        if (!doc.exists) {
          await userDocRef.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'fullName': userCredential.user!.displayName,
            'createdAt': FieldValue.serverTimestamp(),
            'metroCardBalance': 0,
          });
        }
      }
      // AuthWrapper will navigate to home
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
                'Create your account',
                style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: _uberInputDecoration(context, labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _uberInputDecoration(context, labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _uberInputDecoration(context, labelText: 'Password'),
                validator: (value) => value!.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                    : Text('Sign Up', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OR', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                icon: _isGoogleLoading
                    ? const SizedBox.shrink()
                    : SvgPicture.asset(
                        'lib/assets/google_logo.svg',
                        height: 24,
                      ),
                label: _isGoogleLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : Text(
                        'Continue with Google',
                        style: GoogleFonts.roboto(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PhoneAuthScreen()));
                },
                icon: const Icon(Icons.phone_outlined),
                label: Text(
                  'Continue with Phone',
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

InputDecoration _uberInputDecoration(BuildContext context, {required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: GoogleFonts.roboto(color: Theme.of(context).colorScheme.secondary),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).dividerColor),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).primaryColor),
    ),
    errorStyle: GoogleFonts.roboto(color: Theme.of(context).colorScheme.error),
  );
}