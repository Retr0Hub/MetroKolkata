import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'verify_email_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          // Check if the user signed in with a provider that doesn't require email verification (like Google, Phone)
          final isPasswordProvider = user.providerData.any((info) => info.providerId == 'password');

          if (isPasswordProvider && !user.emailVerified) {
            // User signed up with email/password but hasn't verified yet
            return const VerifyEmailScreen();
          } else {
            // User is logged in and verified (or used a different provider)
            return const HomeScreen();
          }
        } else {
          // User is not logged in
          return const WelcomeScreen();
        }
      },
    );
  }
}