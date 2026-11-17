import 'package:flutter/material.dart';

/// Brand palette as ThemeExtension — dark + light match orappob `globals.css`.
@immutable
class OraPalette extends ThemeExtension<OraPalette> {
  const OraPalette({
    required this.lime,
    required this.limeBright,
    required this.onLime,
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.field,
    required this.line,
    required this.text,
    required this.muted,
    required this.muted2,
    required this.success,
    required this.warning,
    required this.danger,
    required this.pointsGold,
    required this.balanceGradient,
  });

  final Color lime;
  final Color limeBright;
  final Color onLime;
  final Color bg;
  final Color panel;
  final Color panel2;
  final Color field;
  final Color line;
  final Color text;
  final Color muted;
  final Color muted2;
  final Color success;
  final Color warning;
  final Color danger;
  final Color pointsGold;
  final LinearGradient balanceGradient;

  static OraPalette of(BuildContext context) {
    return Theme.of(context).extension<OraPalette>()!;
  }

  /// orappob `:root` dark tokens.
  static const dark = OraPalette(
    lime: Color(0xFFC6E800),
    limeBright: Color(0xFFD4F033),
    onLime: Color(0xFF0C1413),
    bg: Color(0xFF0C1413),
    panel: Color(0xFF121A19),
    panel2: Color(0xFF101817),
    field: Color(0xFF0B1211),
    line: Color(0xFF2A3830),
    text: Color(0xFFF4F8F2),
    muted: Color(0xFF9AAB9E),
    muted2: Color(0xFF75857A),
    success: Color(0xFF16A34A),
    warning: Color(0xFFEAB308),
    danger: Color(0xFFFF9C9C),
    pointsGold: Color(0xFFD4A017),
    balanceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A2E24),
        Color(0xFF15241E),
        Color(0xFF1C3218),
        Color(0xFF24310E),
      ],
    ),
  );

  /// orappob `.light-mode` tokens.
  static const light = OraPalette(
    lime: Color(0xFF0F6B66),
    limeBright: Color(0xFF0A4F4B),
    onLime: Color(0xFFFFFFFF),
    bg: Color(0xFFF7FBF8),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFF3F8F6),
    field: Color(0xFFF3F8F6),
    line: Color(0xFFD5E4E0),
    text: Color(0xFF0C1413),
    muted: Color(0xFF4E6460),
    muted2: Color(0xFF718178),
    success: Color(0xFF16A34A),
    warning: Color(0xFFEAB308),
    danger: Color(0xFFDC2626),
    pointsGold: Color(0xFFD4A017),
    balanceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE7F4F1),
        Color(0xFFF3F8F6),
        Color(0xFFE6F0EA),
        Color(0xFFD8EFE8),
      ],
    ),
  );

  @override
  OraPalette copyWith({
    Color? lime,
    Color? limeBright,
    Color? onLime,
    Color? bg,
    Color? panel,
    Color? panel2,
    Color? field,
    Color? line,
    Color? text,
    Color? muted,
    Color? muted2,
    Color? success,
    Color? warning,
    Color? danger,
    Color? pointsGold,
    LinearGradient? balanceGradient,
  }) {
    return OraPalette(
      lime: lime ?? this.lime,
      limeBright: limeBright ?? this.limeBright,
      onLime: onLime ?? this.onLime,
      bg: bg ?? this.bg,
      panel: panel ?? this.panel,
      panel2: panel2 ?? this.panel2,
      field: field ?? this.field,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      muted2: muted2 ?? this.muted2,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      pointsGold: pointsGold ?? this.pointsGold,
      balanceGradient: balanceGradient ?? this.balanceGradient,
    );
  }

  @override
  OraPalette lerp(ThemeExtension<OraPalette>? other, double t) {
    if (other is! OraPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return OraPalette(
      lime: mix(lime, other.lime),
      limeBright: mix(limeBright, other.limeBright),
      onLime: mix(onLime, other.onLime),
      bg: mix(bg, other.bg),
      panel: mix(panel, other.panel),
      panel2: mix(panel2, other.panel2),
      field: mix(field, other.field),
      line: mix(line, other.line),
      text: mix(text, other.text),
      muted: mix(muted, other.muted),
      muted2: mix(muted2, other.muted2),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      pointsGold: mix(pointsGold, other.pointsGold),
      balanceGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          for (var i = 0; i < balanceGradient.colors.length; i++)
            mix(
              balanceGradient.colors[i],
              other.balanceGradient.colors[i.clamp(0, other.balanceGradient.colors.length - 1)],
            ),
        ],
      ),
    );
  }
}

extension OraPaletteX on BuildContext {
  OraPalette get ora => OraPalette.of(this);
  bool get isOraDark => Theme.of(this).brightness == Brightness.dark;
}
