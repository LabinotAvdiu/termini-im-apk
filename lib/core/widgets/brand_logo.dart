import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum BrandLogoVariant { ivory, ink, burgundy }

class BrandLogo extends StatelessWidget {
  final BrandLogoVariant variant;
  final double size;

  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.ink,
    this.size = 48,
  });

  String get _asset {
    switch (variant) {
      case BrandLogoVariant.ivory:
        return 'assets/branding/logo-monogram-ivory.svg';
      case BrandLogoVariant.ink:
        return 'assets/branding/logo-monogram-ink.svg';
      case BrandLogoVariant.burgundy:
        return 'assets/branding/logo-monogram-burgundy.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      width: size,
      height: size,
    );
  }
}
