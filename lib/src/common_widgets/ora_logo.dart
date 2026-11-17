import 'package:flutter/material.dart';

/// OraRepot brand mark from orappob `public/logo-orarepot*.png`.
class OraLogo extends StatelessWidget {
  const OraLogo({
    super.key,
    this.height = 36,
    this.iconOnly = false,
  });

  /// Wordmark height. Width follows the 938×240 source ratio (same as web BrandLogo).
  final double height;

  /// When true, uses the square icon mark instead of the full wordmark.
  final bool iconOnly;

  static const wordmarkAsset = 'assets/brand/logo-orarepot.png';
  static const iconAsset = 'assets/brand/logo-orarepot-icon.png';

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return Image.asset(
        iconAsset,
        width: height,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Ora Repot',
      );
    }

    final width = height * 938 / 240;
    return Image.asset(
      wordmarkAsset,
      height: height,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Ora Repot',
    );
  }
}
