import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralised theme definitions for the Media Player app.
/// All sizes reference ScreenUtil extensions so they scale
/// correctly across phone / tablet / desktop.
abstract final class AppTheme {
  // ── Brand palette ──────────────────────────────────────
  static const _primary     = Color(0xFF6C63FF);
  static const _primaryDark = Color(0xFF9B94FF);
  static const _surface     = Color(0xFFF6F6F6);
  static const _surfaceDark = Color(0xFF1E1E2E);
  static const _cardDark    = Color(0xFF2A2A3C);
  // ignore: unused_field
  static const _error       = Color(0xFFE57373);

  // ── Light theme ────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          surface: _surface,
        ),
        scaffoldBackgroundColor: _surface,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        sliderTheme: SliderThemeData(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
          trackHeight: 3.h,
          activeTrackColor: _primary,
          inactiveTrackColor: _primary.withOpacity(.25),
          thumbColor: _primary,
          overlayColor: _primary.withOpacity(.12),
        ),
        iconTheme: const IconThemeData(color: Colors.black54),
        textTheme: _textTheme(Colors.black87),
      );

  // ── Dark theme ─────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryDark,
          brightness: Brightness.dark,
          surface: _surfaceDark,
        ),
        scaffoldBackgroundColor: _surfaceDark,
        appBarTheme: AppBarTheme(
          backgroundColor: _surfaceDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: _cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        sliderTheme: SliderThemeData(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
          trackHeight: 3.h,
          activeTrackColor: _primaryDark,
          inactiveTrackColor: _primaryDark.withOpacity(.25),
          thumbColor: _primaryDark,
          overlayColor: _primaryDark.withOpacity(.12),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        textTheme: _textTheme(Colors.white),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _cardDark,
        ),
      );

  static TextTheme _textTheme(Color base) => TextTheme(
        displayLarge:  TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold,  color: base),
        titleLarge:    TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600,  color: base),
        titleMedium:   TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600,  color: base),
        bodyLarge:     TextStyle(fontSize: 15.sp, fontWeight: FontWeight.normal, color: base),
        bodyMedium:    TextStyle(fontSize: 13.sp, fontWeight: FontWeight.normal, color: base.withOpacity(.7)),
        labelSmall:    TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500,  color: base.withOpacity(.5)),
      );
}
