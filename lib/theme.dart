import 'package:flutter/material.dart';

const _primaryBlue = Color(0xFF2196F3);

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryBlue,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white, // For title, icons
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryBlue,
      brightness: Brightness.light,
    ),
    // You can add more theme properties here
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryBlue,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white, // For title, icons
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryBlue,
      brightness: Brightness.dark,
      background: Colors.black,
    ),
    // You can add more theme properties here
  );
}