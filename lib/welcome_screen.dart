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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode ? Colors.white : Colors.black;
    final metroColor = isDarkMode ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 255, 255, 255);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          ClipPath(
            clipper: BottomCurveClipper(),
            child: Image.asset(
              metroImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 450,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: Column(
              children: [
                const SizedBox(height: 120),
                RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 26,
                      color: metroColor,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: 'Welcome To\n'),
                      TextSpan(
                        text: 'Kolkata Metro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 46,
                          color: metroColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: SvgPicture.asset(
                      logo1,
                      width: 40,
                      height: 40,
                      color: textColor,
                      placeholderBuilder: (context) =>
                          CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Spacer(),
                _buildButton(
                  context,
                  'Login',
                  Colors.white,
                  Colors.black,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  borderColor: Colors.black,
                ),
                const SizedBox(height: 10),
                _buildButton(
                  context,
                  'Create an account',
                  Colors.black,
                  Colors.white,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  borderColor: borderColor,
                ),
                const SizedBox(height: 118),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed, {
    Color? borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, size.height + 50, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
