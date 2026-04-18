import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -0.85,
      );

  static TextStyle get h2 => GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -0.52,
      );

  static TextStyle get h3 => GoogleFonts.fraunces(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.19,
      );

  static TextStyle get subtitle => GoogleFonts.instrumentSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.instrumentSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        height: 1.4,
        letterSpacing: 0.88,
      );

  static TextStyle get overline => GoogleFonts.instrumentSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
        height: 1.4,
        letterSpacing: 1.4,
      );

  static TextStyle get button => GoogleFonts.instrumentSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.04,
      );

  static TextStyle get buttonSmall => GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.96,
      );

  static TextStyle get emphasis => GoogleFonts.instrumentSerif(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: AppColors.textPrimary,
        height: 1.5,
      );
}
