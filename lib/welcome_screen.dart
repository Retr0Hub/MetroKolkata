import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  final String metroImage = 'lib/assets/welcomecircle.jpeg';
  final String logo1 = 'lib/assets/logo.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Image with circular curve bottom
          ClipPath(clipper: BottomCurveClipper(), child: Image.asset(metroImage, fit: BoxFit.cover, width: double.infinity, height: 450)),

          // Content overlay
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                RichText(
                  textAlign: TextAlign.left,
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(text: 'Welcome To\n'),
                      TextSpan(text: 'Kolkata Metro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 46)),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: SvgPicture.asset(logo1, width: 40, height: 40, placeholderBuilder: (context) => const CircularProgressIndicator()))),
                const SizedBox(height: 20),
                const Spacer(),
                _buildButton(context, 'Login', Colors.white, Colors.black, Colors.black, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }, borderColor: Colors.black),
                const SizedBox(height: 16),
                _buildButton(context, 'Create an account', Colors.black, Colors.white, Colors.white, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                }),
                const SizedBox(height: 118),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color bgColor, Color textColor, Color iconColor, VoidCallback onPressed, {Color? borderColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: bgColor, foregroundColor: textColor, side: borderColor != null ? BorderSide(color: borderColor) : null, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height + 50, size.width, size.height - 50);
    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
