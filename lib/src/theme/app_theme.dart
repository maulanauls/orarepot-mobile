import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ora_palette.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(OraPalette.dark, Brightness.dark);

  static ThemeData light() => _build(OraPalette.light, Brightness.light);

  static ThemeData _build(OraPalette ora, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseText = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.poppinsTextTheme(baseText).apply(
      bodyColor: ora.text,
      displayColor: ora.text,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: ora.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ora.lime,
        brightness: brightness,
        primary: ora.lime,
        onPrimary: ora.onLime,
        surface: ora.panel,
        onSurface: ora.text,
      ),
      textTheme: textTheme,
      extensions: [ora],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: ora.bg,
        foregroundColor: ora.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          color: ora.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: ora.text),
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.poppins(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: ora.text,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ora.text,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ora.text,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.45,
          color: ora.muted,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ora.muted2,
        ),
      ),
      dividerColor: ora.line,
      chipTheme: ChipThemeData(
        backgroundColor: ora.field,
        selectedColor: ora.panel,
        side: BorderSide(color: ora.line),
        labelStyle: GoogleFonts.poppins(color: ora.text, fontSize: 12, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.poppins(color: ora.lime, fontSize: 12, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ora.field,
        hintStyle: GoogleFonts.poppins(color: isDark ? const Color(0xFF475260) : const Color(0xFF9AABA2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ora.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ora.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ora.lime, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ora.panel2,
        selectedItemColor: ora.lime,
        unselectedItemColor: ora.muted2,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(backgroundColor: ora.panel),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ora.panel,
        modalBackgroundColor: ora.panel,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ora.panel,
        contentTextStyle: GoogleFonts.poppins(color: ora.text),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: ora.lime),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ora.lime,
          foregroundColor: ora.onLime,
          disabledBackgroundColor: ora.line,
          disabledForegroundColor: ora.muted2,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ora.lime;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(ora.onLime),
        side: BorderSide(color: ora.line),
      ),
    );
  }
}
