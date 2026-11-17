import 'package:flutter/material.dart';

/// Static dark tokens kept for widgets without a BuildContext.
/// Prefer `context.ora` so light/dark switching applies.
abstract final class OraColors {
  static const lime = Color(0xFFC6E800);
  static const limeBright = Color(0xFFD4F033);
  static const onLime = Color(0xFF0C1413);
  static const ink = Color(0xFF0C1413);
  static const bg = Color(0xFF0C1413);
  static const panel = Color(0xFF121A19);
  static const panel2 = Color(0xFF101817);
  static const field = Color(0xFF0B1211);
  static const line = Color(0xFF2A3830);
  static const text = Color(0xFFF4F8F2);
  static const muted = Color(0xFF9AAB9E);
  static const muted2 = Color(0xFF75857A);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFEAB308);
  static const danger = Color(0xFFFF9C9C);
  static const pointsGold = Color(0xFFD4A017);

  static const balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2E24),
      Color(0xFF15241E),
      Color(0xFF1C3218),
      Color(0xFF24310E),
    ],
  );
}
