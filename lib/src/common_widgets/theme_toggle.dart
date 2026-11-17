import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ora_palette.dart';
import '../theme/theme_controller.dart';

/// Matches orappob `.theme-toggle` (☼ LIGHT / ☾ DARK).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ora = context.ora;
        final isLight = controller.isLight;
        return Material(
          color: ora.field,
          borderRadius: BorderRadius.circular(3),
          child: InkWell(
            onTap: controller.toggle,
            borderRadius: BorderRadius.circular(3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: ora.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLight ? '☾' : '☼',
                    style: TextStyle(color: ora.muted, fontSize: 13, height: 1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLight ? 'DARK' : 'LIGHT',
                    style: GoogleFonts.poppins(
                      color: ora.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
