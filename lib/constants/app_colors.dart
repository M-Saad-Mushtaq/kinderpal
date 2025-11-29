import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Modernized
  static const Color primary = Color(0xFF7C3AED); // Vibrant Purple
  static const Color primaryLight = Color(0xFF9D6FF2);
  static const Color primaryDark = Color(0xFF5B21B6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9D6FF2)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0F4FF), Color(0xFFE8F0FF)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
  );

  // Background colors
  static const Color lightBlue = Color(0xFFE8F0FF); // Softer light blue
  static const Color veryLightBlue = Color(0xFFF0F7FF);
  static const Color beige = Color(0xFFFFFBF5); // Warmer beige

  // Accent colors - More vibrant
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color green = Color(0xFF10B981);
  static const Color pink = Color(0xFFEC4899);
  static const Color lightPurple = Color(0xFFA78BFA);
  static const Color peach = Color(0xFFFB923C);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color blue = Color(0xFF3B82F6);

  // Text colors
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Background
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  // Glass effect colors
  static const Color glassWhite = Color(0xFFFFFFFF);
  static const Color glassDark = Color(0xFF1E293B);
}
