import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('Password reset link sent! Check your email.')),
      );
      navigator.pop();
    } on FirebaseAuthException catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'An error occurred.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email to reset your password',
                style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: textColor, fontSize: 18),
                decoration: _uberInputDecoration('Email', inputFillColor, labelColor),
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
                onPressed: _isLoading ? null : _sendPasswordResetEmail,
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
                    : Text('Send Reset Link',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        ),
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