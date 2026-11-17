import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ora_palette.dart';

/// Centered empty / no-data placeholder with brand illustration.
class NoDataState extends StatelessWidget {
  const NoDataState({
    super.key,
    this.title = 'Data Kosong',
    this.message = 'Belum ada data yang tersedia saat ini.',
    this.illustrationHeight = 160,
  });

  final String title;
  final String message;
  final double illustrationHeight;

  static const darkAsset = 'assets/illustrations/no-data-state-dark.png';
  static const lightAsset = 'assets/illustrations/no-data-state-light.png';

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark ? darkAsset : lightAsset;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              height: illustrationHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: title,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: ora.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: ora.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
