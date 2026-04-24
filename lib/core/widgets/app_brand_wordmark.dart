import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Wordmark textuel "Termini im" conforme à la charte Termini Im.
///
/// - "Termini" : Fraunces, encre [AppColors.textPrimary] (ou [textColor])
/// - "im"      : Instrument Serif italic, bourgogne [AppColors.primary]
///               (ou [accentColor])
///
/// Taille par défaut : 15 dp. Configurable via [fontSize].
///
/// Ce widget remplace toute occurrence de "TERMINI IM" all-caps avec
/// letter-spacing élargi — violant la règle §6 de la charte de marque.
class AppBrandWordmark extends StatelessWidget {
  final double fontSize;
  final Color? textColor;
  final Color? accentColor;
  final TextAlign textAlign;

  const AppBrandWordmark({
    super.key,
    this.fontSize = 15,
    this.textColor,
    this.accentColor,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedText = textColor ?? AppColors.textPrimary;
    final resolvedAccent = accentColor ?? AppColors.primary;

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Termini',
            style: GoogleFonts.fraunces(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: resolvedText,
              letterSpacing: 0.2,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: 'im',
            style: GoogleFonts.instrumentSerif(
              fontSize: fontSize,
              fontStyle: FontStyle.italic,
              color: resolvedAccent,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
