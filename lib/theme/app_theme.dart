import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - Updated to match design specs
  static const Color primaryBackground = Color(0xFFFFFDE7); // Light Yellow
  static const Color bottomPanel = Color(0xFF4A3F55); // Dark Purple
  static const Color notificationPanel = Color(0xFFD9D5D8); // Light Gray/Purple
  static const Color buttonAndAbout = Color(0xFFF5ECEB); // Light Pink/Beige
  static const Color indicatorAndIcon = Color(0xFFD4AF37); // Golden Yellow
  
  // Additional colors from design specs
  static const Color darkText = Color(0xFF4B3C52);
  
  // Text Colors
  static const Color primaryText = Color(0xFF2C2C2C); // Dark text
  static const Color secondaryText = Color(0xFF666666); // Medium gray text
  static const Color whiteText = Color(0xFFFFFFFF);
  
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: indicatorAndIcon,
        primary: indicatorAndIcon,
        surface: primaryBackground,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: primaryText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: secondaryText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: secondaryText,
        ),
      ),
    );
  }
}
