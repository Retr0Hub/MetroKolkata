import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationTarget; // e.g., email or phone number
  final Future<bool> Function(String otp) onVerify;
  final VoidCallback onResend;

  const OtpVerificationScreen({
    super.key,
    required this.verificationTarget,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Resend timer logic
  Timer? _resendTimer;
  int _resendCooldown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCooldown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        _resendTimer?.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _onVerifyPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await widget.onVerify(_otpController.text.trim());

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onResendPressed() {
    if (_canResend) {
      widget.onResend();
      _startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Verification Code',
                style: GoogleFonts.roboto(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'A 6-digit code has been sent to\n${widget.verificationTarget}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: '6-digit OTP'),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) =>
                    (value?.length ?? 0) != 6 ? 'OTP must be 6 digits' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _onVerifyPressed,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.black))
                    : Text('Verify',
                        style: GoogleFonts.roboto(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code? "),
                  TextButton(
                    onPressed: _onResendPressed,
                    child: Text(
                      _canResend
                          ? 'Resend OTP'
                          : 'Resend in $_resendCooldown s',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}