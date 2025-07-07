import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _sendResetOtp() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    // --- TODO: Implement Backend Logic for Sending OTP ---
    // This would call your backend to generate and send an OTP to the email.
    debugPrint('Send OTP request for $email');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('(Demo) An OTP has been sent to the console.')),
    );

    // Simulate network call before navigating
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              verificationTarget: email,
              onVerify: (otp) async {
                // --- TODO: Implement Backend Logic for OTP Verification ---
                // This is a placeholder. A real implementation requires a backend.
                if (otp.length == 6) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const ResetPasswordScreen()));
                  return true;
                }
                return false;
              },
              onResend: () {
                // --- TODO: Implement Backend Logic for Resending OTP ---
                debugPrint('Resend OTP request for $email');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          '(Demo) A new OTP has been sent to the console.')),
                );
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your account\'s email',
                style: GoogleFonts.roboto(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ll send a verification code to your email to reset your password.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendResetOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.black))
                    : Text('Send Code',
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