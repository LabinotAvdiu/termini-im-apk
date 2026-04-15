import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary — violet/purple brand color
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);

  // Secondary — accent
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF9E9E);
  static const Color secondaryDark = Color(0xFFE54545);

  // Neutrals
  static const Color background = Color(0xFFF7F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textHint = Color(0xFF9E9EB0);
  static const Color divider = Color(0xFFE8E8F0);
  static const Color border = Color(0xFFD0D0DE);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Specific UI
  static const Color starRating = Color(0xFFFFC107);
  static const Color slotAvailable = Color(0xFFEDE7FF);
  static const Color slotSelected = Color(0xFF6C63FF);
  static const Color cardShadow = Color(0x1A000000);
}
