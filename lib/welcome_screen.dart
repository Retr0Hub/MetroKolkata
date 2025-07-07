import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final buttonTextStyle =
        GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Welcome to\nKolkata Metro',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: Theme.of(context).primaryColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: Text('Log In', style: buttonTextStyle),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()));
                },
                child: Text('Sign Up', style: buttonTextStyle),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}