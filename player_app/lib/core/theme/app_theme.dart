import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AppTheme — Media Player
///
/// Two complete theme sets:
///   • AppTheme.midnightVioletDark  / AppTheme.midnightVioletLight
///   • AppTheme.deepEmberDark       / AppTheme.deepEmberLight
///
/// Shared design tokens live in AppColors, AppTextStyles, AppRadius,
/// and AppShadows so your widgets stay decoupled from ThemeData lookups.
/// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// 1.  COLOR PALETTES
// ─────────────────────────────────────────────────────────────────────────────

abstract final class MidnightViolet {
  // ── Backgrounds
  static const background     = Color(0xFF13111C);
  static const surface        = Color(0xFF1E1C2E);
  static const card           = Color(0xFF2A2740);
  static const cardSubtle     = Color(0xFF232135);
  static const overlay        = Color(0xCC13111C); // 80 % opaque bg

  // ── Brand
  static const primary        = Color(0xFF7C6FF7);
  static const primaryLight   = Color(0xFF9D97FF); // hover / icon tint
  static const primaryDark    = Color(0xFF5C55D8); // pressed state
  static const primaryMuted   = Color(0x337C6FF7); // 20 % fills / track bg

  // ── Accent  (liked / active / now-playing badge)
  static const highlight      = Color(0xFFF2517A);
  static const highlightMuted = Color(0x33F2517A);

  // ── Neutrals  (light → dark)
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFFB0ADCC);
  static const textTertiary   = Color(0xFF6E6A8A);
  static const divider        = Color(0xFF2E2B45);

  // ── Light-mode overrides
  static const lightBackground = Color(0xFFF4F3FF);
  static const lightSurface    = Color(0xFFFFFFFF);
  static const lightCard       = Color(0xFFECEAFF);
  static const lightPrimary    = Color(0xFF5C55D8);
  static const lightTextPrimary   = Color(0xFF13111C);
  static const lightTextSecondary = Color(0xFF4A4770);
  static const lightTextTertiary  = Color(0xFF9896B8);
  static const lightDivider       = Color(0xFFDAD8F5);
}

abstract final class DeepEmber {
  // ── Backgrounds
  static const background     = Color(0xFF110D0A);
  static const surface        = Color(0xFF1C1510);
  static const card           = Color(0xFF2B1E17);
  static const cardSubtle     = Color(0xFF221811);
  static const overlay        = Color(0xCC110D0A);

  // ── Brand
  static const primary        = Color(0xFFE8673A);
  static const primaryLight   = Color(0xFFF0936E);
  static const primaryDark    = Color(0xFFC94E24);
  static const primaryMuted   = Color(0x33E8673A);

  // ── Accent  (now-playing glow / favorite star)
  static const highlight      = Color(0xFFF7C948);
  static const highlightMuted = Color(0x33F7C948);

  // ── Neutrals
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFFCDB09A);
  static const textTertiary   = Color(0xFF7A5B49);
  static const divider        = Color(0xFF2F1F16);

  // ── Light-mode overrides
  static const lightBackground = Color(0xFFFFF7F4);
  static const lightSurface    = Color(0xFFFFFFFF);
  static const lightCard       = Color(0xFFFAEDE6);
  static const lightPrimary    = Color(0xFFC94E24);
  static const lightTextPrimary   = Color(0xFF110D0A);
  static const lightTextSecondary = Color(0xFF6B3822);
  static const lightTextTertiary  = Color(0xFFB88A76);
  static const lightDivider       = Color(0xFFF5C9B5);
}

// ─────────────────────────────────────────────────────────────────────────────
// 2.  SHARED DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppRadius {
  static double get xs  => 6.r;
  static double get sm  => 10.r;
  static double get md  => 14.r;
  static double get lg  => 20.r;
  static double get xl  => 28.r;
  static double get full => 999.r;
}

abstract final class AppShadows {
  /// Soft card elevation — works on both dark surfaces and light surfaces.
  static List<BoxShadow> card(Color primary) => [
    BoxShadow(
      color: primary.withOpacity(.18),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Floating player / bottom sheet glow.
  static List<BoxShadow> playerGlow(Color primary) => [
    BoxShadow(
      color: primary.withOpacity(.30),
      blurRadius: 48,
      offset: const Offset(0, -4),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// 3.  TEXT STYLES  (call after ScreenUtil.init)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  // Display — album title hero
  static TextStyle display(Color color) => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.8,
        height: 1.1,
      );

  // Section heading
  static TextStyle headingLarge(Color color) => TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.4,
        height: 1.2,
      );

  static TextStyle headingMedium(Color color) => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle headingSmall(Color color) => TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  // Body
  static TextStyle bodyLarge(Color color) => TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.55,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  // Labels / captions
  static TextStyle labelLarge(Color color) => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      );

  static TextStyle labelMedium(Color color) => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle labelSmall(Color color) => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.4,
      );

  // Time / mono readouts (seek bar timestamps)
  static TextStyle mono(Color color) => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
        letterSpacing: 0.5,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 4.  THEME BUILDER  (private helper)
// ─────────────────────────────────────────────────────────────────────────────

ThemeData _buildTheme({
  required Brightness brightness,
  required Color seedColor,
  required Color scaffoldBg,
  required Color appBarBg,
  required Color cardColor,
  required Color navBarBg,
  required Color primary,
  required Color primaryContainer,
  required Color onPrimary,
  required Color textPrimary,
  required Color textSecondary,
  required Color divider,
  required Color sliderActive,
  required Color sliderInactive,
  required Color iconColor,
  required Color statusBarIconColor,
}) {
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,

    // ── Color scheme ────────────────────────────────────────────────────────
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      surface: scaffoldBg,
    ),

    // ── Scaffold ─────────────────────────────────────────────────────────────
    scaffoldBackgroundColor: scaffoldBg,

    // ── AppBar ───────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
      titleTextStyle: AppTextStyles.headingMedium(textPrimary),
      iconTheme: IconThemeData(color: iconColor, size: 24.sp),
      actionsIconTheme: IconThemeData(color: iconColor, size: 24.sp),
    ),

    // ── Cards ────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    // ── Slider (seek bar + volume) ───────────────────────────────────────────
    sliderTheme: SliderThemeData(
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
      trackHeight: 3.h,
      activeTrackColor: sliderActive,
      inactiveTrackColor: sliderInactive,
      thumbColor: sliderActive,
      overlayColor: sliderActive.withOpacity(.16),
      valueIndicatorColor: sliderActive,
      valueIndicatorTextStyle: AppTextStyles.labelSmall(onPrimary),
    ),

    // ── Elevated button ──────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        textStyle: AppTextStyles.labelLarge(onPrimary),
      ),
    ),

    // ── Text button ──────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTextStyles.labelLarge(primary),
      ),
    ),

    // ── Icon button ──────────────────────────────────────────────────────────
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: iconColor,
        highlightColor: primary.withOpacity(.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),

    // ── Bottom navigation bar ─────────────────────────────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: navBarBg,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: AppTextStyles.labelSmall(primary),
      unselectedLabelStyle: AppTextStyles.labelSmall(textSecondary),
    ),

    // ── Navigation bar (Material 3) ───────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navBarBg,
      indicatorColor: primary.withOpacity(.18),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? primary : textSecondary,
          size: 24.sp,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppTextStyles.labelSmall(primary)
            : AppTextStyles.labelSmall(textSecondary),
      ),
    ),

    // ── Bottom sheet ─────────────────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: navBarBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
    ),

    // ── Chip ─────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: primaryContainer,
      selectedColor: primary,
      labelStyle: AppTextStyles.labelMedium(textPrimary),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    ),

    // ── Dialog ───────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: AppTextStyles.headingMedium(textPrimary),
      contentTextStyle: AppTextStyles.bodyMedium(textSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),

    // ── Snack bar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardColor,
      contentTextStyle: AppTextStyles.bodyMedium(textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── List tile ────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: iconColor,
      titleTextStyle: AppTextStyles.bodyLarge(textPrimary),
      subtitleTextStyle: AppTextStyles.bodyMedium(textSecondary),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    ),

    // ── Switch ───────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? onPrimary
            : textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primary
            : divider,
      ),
    ),

    // ── Progress indicator ───────────────────────────────────────────────────
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: sliderInactive,
      circularTrackColor: sliderInactive,
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: divider,
      thickness: 0.5,
      space: 0,
    ),

    // ── Icon ─────────────────────────────────────────────────────────────────
    iconTheme: IconThemeData(color: iconColor, size: 24.sp),

    // ── Text ─────────────────────────────────────────────────────────────────
    textTheme: TextTheme(
      displayLarge:  AppTextStyles.display(textPrimary),
      displayMedium: AppTextStyles.headingLarge(textPrimary),
      displaySmall:  AppTextStyles.headingMedium(textPrimary),
      headlineMedium: AppTextStyles.headingMedium(textPrimary),
      headlineSmall:  AppTextStyles.headingSmall(textPrimary),
      titleLarge:    AppTextStyles.headingSmall(textPrimary),
      titleMedium:   AppTextStyles.labelLarge(textPrimary),
      titleSmall:    AppTextStyles.labelMedium(textPrimary),
      bodyLarge:     AppTextStyles.bodyLarge(textPrimary),
      bodyMedium:    AppTextStyles.bodyMedium(textPrimary),
      bodySmall:     AppTextStyles.bodyMedium(textSecondary),
      labelLarge:    AppTextStyles.labelLarge(textPrimary),
      labelMedium:   AppTextStyles.labelMedium(textSecondary),
      labelSmall:    AppTextStyles.labelSmall(textSecondary),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 5.  PUBLIC APPTHEME ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  // ╔══════════════════════════════════╗
  // ║   MIDNIGHT VIOLET               ║
  // ╚══════════════════════════════════╝

  static ThemeData get midnightVioletDark => _buildTheme(
        brightness: Brightness.dark,
        seedColor: MidnightViolet.primary,
        scaffoldBg: MidnightViolet.background,
        appBarBg: MidnightViolet.background,
        cardColor: MidnightViolet.card,
        navBarBg: MidnightViolet.surface,
        primary: MidnightViolet.primary,
        primaryContainer: MidnightViolet.primaryMuted,
        onPrimary: Colors.white,
        textPrimary: MidnightViolet.textPrimary,
        textSecondary: MidnightViolet.textSecondary,
        divider: MidnightViolet.divider,
        sliderActive: MidnightViolet.highlight,
        sliderInactive: MidnightViolet.primaryMuted,
        iconColor: MidnightViolet.textSecondary,
        statusBarIconColor: Colors.white,
      );

  static ThemeData get midnightVioletLight => _buildTheme(
        brightness: Brightness.light,
        seedColor: MidnightViolet.lightPrimary,
        scaffoldBg: MidnightViolet.lightBackground,
        appBarBg: MidnightViolet.lightSurface,
        cardColor: MidnightViolet.lightCard,
        navBarBg: MidnightViolet.lightSurface,
        primary: MidnightViolet.lightPrimary,
        primaryContainer: MidnightViolet.lightCard,
        onPrimary: Colors.white,
        textPrimary: MidnightViolet.lightTextPrimary,
        textSecondary: MidnightViolet.lightTextSecondary,
        divider: MidnightViolet.lightDivider,
        sliderActive: MidnightViolet.highlight,
        sliderInactive: MidnightViolet.lightDivider,
        iconColor: MidnightViolet.lightTextSecondary,
        statusBarIconColor: Colors.black,
      );

  // ╔══════════════════════════════════╗
  // ║   DEEP EMBER                    ║
  // ╚══════════════════════════════════╝

  static ThemeData get deepEmberDark => _buildTheme(
        brightness: Brightness.dark,
        seedColor: DeepEmber.primary,
        scaffoldBg: DeepEmber.background,
        appBarBg: DeepEmber.background,
        cardColor: DeepEmber.card,
        navBarBg: DeepEmber.surface,
        primary: DeepEmber.primary,
        primaryContainer: DeepEmber.primaryMuted,
        onPrimary: Colors.white,
        textPrimary: DeepEmber.textPrimary,
        textSecondary: DeepEmber.textSecondary,
        divider: DeepEmber.divider,
        sliderActive: DeepEmber.highlight,
        sliderInactive: DeepEmber.primaryMuted,
        iconColor: DeepEmber.textSecondary,
        statusBarIconColor: Colors.white,
      );

  static ThemeData get deepEmberLight => _buildTheme(
        brightness: Brightness.light,
        seedColor: DeepEmber.lightPrimary,
        scaffoldBg: DeepEmber.lightBackground,
        appBarBg: DeepEmber.lightSurface,
        cardColor: DeepEmber.lightCard,
        navBarBg: DeepEmber.lightSurface,
        primary: DeepEmber.lightPrimary,
        primaryContainer: DeepEmber.lightCard,
        onPrimary: Colors.white,
        textPrimary: DeepEmber.lightTextPrimary,
        textSecondary: DeepEmber.lightTextSecondary,
        divider: DeepEmber.lightDivider,
        sliderActive: DeepEmber.lightPrimary,
        sliderInactive: DeepEmber.lightDivider,
        iconColor: DeepEmber.lightTextSecondary,
        statusBarIconColor: Colors.black,
      );

  // ── Convenience: system-default pickers ─────────────────────────────────
  /// Returns the active dark theme (defaults to Midnight Violet).
  static ThemeData darkTheme([String name = 'midnight']) =>
      name == 'ember' ? deepEmberDark : midnightVioletDark;

  /// Returns the active light theme (defaults to Midnight Violet).
  static ThemeData lightTheme([String name = 'midnight']) =>
      name == 'ember' ? deepEmberLight : midnightVioletLight;
}

// ─────────────────────────────────────────────────────────────────────────────
// 6.  EXTENSION HELPERS  (optional but convenient in widgets)
// ─────────────────────────────────────────────────────────────────────────────

extension AppThemeContext on BuildContext {
  /// Primary brand color of the current theme.
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// Quick shorthand for the color scheme.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Quick shorthand for the text theme.
  TextTheme get textStyles => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// 7.  USAGE EXAMPLE (main.dart)
// ─────────────────────────────────────────────────────────────────────────────
//
// MaterialApp(
//   theme:      AppTheme.midnightVioletLight,  // or deepEmberLight
//   darkTheme:  AppTheme.midnightVioletDark,   // or deepEmberDark
//   themeMode:  ThemeMode.system,
//   ...
// );
//
// To let the user switch at runtime, keep a ValueNotifier<String> ('midnight'
// or 'ember') and rebuild MaterialApp when it changes:
//
//   theme:     AppTheme.lightTheme(themeName),
//   darkTheme: AppTheme.darkTheme(themeName),

