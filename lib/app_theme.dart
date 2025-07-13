import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Private constructor
  AppTheme._();

  // Define colors based on specs
  static const Color _primaryColor = Color(0xFF00C853);
  static const Color _secondaryColor = Color(0xFF121212);
  static const Color _secondaryTextColor = Color(0xFFB0BEC5);

  static ThemeData lightTheme() {
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
    );
  }

  static ThemeData darkTheme() {
    // Define a base text theme using the 'Poppins' font from Google Fonts.
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true, // Enable Material 3
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
        secondary: _secondaryColor,
      ),
      scaffoldBackgroundColor: _secondaryColor,
      textTheme: textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // For glass effect
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent, // Make drawer background transparent
      ),
      // Consistent styling for all cards.
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        // A slightly lighter shade of the background for cards.
        color: Colors.transparent, // Make cards transparent for glass effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      // Style for floating action buttons and other prominent buttons.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600, // Medium-Bold
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _secondaryColor.withOpacity(0.8), // Semi-transparent for glass effect
        selectedItemColor: _primaryColor,
        unselectedItemColor: _secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
    );
  }
}