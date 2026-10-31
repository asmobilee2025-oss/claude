import 'package:flutter/material.dart';

class AppTheme {
  static const brand = Color(0xFF0B6E4F); // deep emerald
  static const accent = Color(0xFFF4A524); // warm amber for prices / featured

  static ThemeData light(Locale locale) => _build(Brightness.light, locale);
  static ThemeData dark(Locale locale) => _build(Brightness.dark, locale);

  static ThemeData _build(Brightness b, Locale locale) {
    final arabic = locale.languageCode == 'ar';
    final scheme = ColorScheme.fromSeed(seedColor: brand, brightness: b).copyWith(
      primary: b == Brightness.light ? brand : const Color(0xFF5FD3A8),
      tertiary: accent,
    );
    final radius = BorderRadius.circular(14);
    return ThemeData(
      useMaterial3: true,
      // Bundled fonts: consistent premium typography on every device, no CDN needed.
      fontFamily: arabic ? 'IBMPlexSansArabic' : 'Inter',
      fontFamilyFallback: arabic ? const ['Inter'] : const ['IBMPlexSansArabic'],
      colorScheme: scheme,
      brightness: b,
      scaffoldBackgroundColor: b == Brightness.light ? const Color(0xFFF6F7F9) : const Color(0xFF0F1214),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(fontFamily: arabic ? 'IBMPlexSansArabic' : 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
    );
  }
}
