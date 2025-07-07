import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _onResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // --- TODO: Implement Backend Logic for Password Reset ---
    // This is a placeholder. A real implementation requires a backend.
    // 1. You would have generated a secure, one-time token on your backend
    //    when the user verified the OTP.
    // 2. You would pass that token to this screen.
    // 3. You would call a Cloud Function with the token and the new password.
    // 4. The Cloud Function would use the Firebase Admin SDK to update the user's password.
    //
    // For now, we'll simulate a delay and success.
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password has been reset successfully!')),
      );
      // Navigate back to the login screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter a new password for your account.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _onResetPassword,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.black))
                    : Text('Save New Password',
                        style: GoogleFonts.roboto(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}