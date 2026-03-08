import 'package:flutter/material.dart';

/// Application theme configuration compatible with the Theme Module.
///
/// This file defines colors, typography, and theme data using Material Design 3
/// naming conventions while maintaining compatibility with Forui components.
///
/// **Architecture:**
/// - Static color constants (parseable by the Theme Module)
/// - Standard Material ThemeData for Flutter widgets
/// - Optional FThemeData conversion for Forui components
/// - Extension methods for convenient access

/// Forui Theme Preset Options
///
/// Enum representing available Forui theme presets.
/// This will show as a dropdown in the Theme Module UI.
enum ForuiThemePreset {
  zinc,
  slate,
  red,
  rose,
  orange,
  green,
  blue,
  yellow,
  violet,
}

/// Forui Theme Configuration

///
/// Change this value to switch between Forui's built-in theme presets.
/// The Theme Module will display this as a dropdown selector.
class ForuiThemeConfig {
  /// The selected Forui theme preset
  static const ForuiThemePreset themePreset = ForuiThemePreset.zinc;
}

/// Light mode color palette
class LightModeColors {
  // Material Design 3 Colors
  static const lightPrimary = Color(0xFF71717A);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE4E4E7);
  static const lightOnPrimaryContainer = Color(0xFF18181B);
  static const lightSecondary = Color(0xFF6366F1);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFF10B981);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFEF4444);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFEE2E2);
  static const lightOnErrorContainer = Color(0xFF7F1D1D);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF18181B);
  static const lightSurfaceVariant = Color(0xFFF4F4F5);
  static const lightOnSurfaceVariant = Color(0xFF52525B);
  static const lightOutline = Color(0xFFE4E4E7);
  static const lightShadow = Color(0xFF000000);

  // Forui-style aliases for backward compatibility
  static const Color primary = lightPrimary;
  static const Color primaryForeground = lightOnPrimary;
  static const Color secondary = lightSecondary;
  static const Color secondaryForeground = lightOnSecondary;
  static const Color accent = lightTertiary;
  static const Color accentForeground = lightOnTertiary;
  static const Color destructive = lightError;
  static const Color destructiveForeground = lightOnError;
  static const Color background = lightSurface;
  static const Color foreground = lightOnSurface;
  static const Color muted = lightSurfaceVariant;
  static const Color mutedForeground = lightOnSurfaceVariant;
  static const Color border = lightOutline;
  static const Color ring = lightPrimary;
}

/// Dark mode color palette
class DarkModeColors {
  // Material Design 3 Colors
  static const darkPrimary = Color(0xFFA1A1AA);
  static const darkOnPrimary = Color(0xFF27272A);
  static const darkPrimaryContainer = Color(0xFF3F3F46);
  static const darkOnPrimaryContainer = Color(0xFFFAFAFA);
  static const darkSecondary = Color(0xFF818CF8);
  static const darkOnSecondary = Color(0xFF1E1B4B);
  static const darkTertiary = Color(0xFF34D399);
  static const darkOnTertiary = Color(0xFF064E3B);
  static const darkError = Color(0xFFF87171);
  static const darkOnError = Color(0xFF450A0A);
  static const darkErrorContainer = Color(0xFF7F1D1D);
  static const darkOnErrorContainer = Color(0xFFFEE2E2);
  static const darkSurface = Color(0xFF18181B);
  static const darkOnSurface = Color(0xFFFAFAFA);
  static const darkSurfaceVariant = Color(0xFF27272A);
  static const darkOnSurfaceVariant = Color(0xFFA1A1AA);
  static const darkOutline = Color(0xFF3F3F46);
  static const darkShadow = Color(0xFF000000);

  // Forui-style aliases
  static const Color primary = darkPrimary;
  static const Color primaryForeground = darkOnPrimary;
  static const Color secondary = darkSecondary;
  static const Color secondaryForeground = darkOnSecondary;
  static const Color accent = darkTertiary;
  static const Color accentForeground = darkOnTertiary;
  static const Color destructive = darkError;
  static const Color destructiveForeground = darkOnError;
  static const Color background = darkSurface;
  static const Color foreground = darkOnSurface;
  static const Color muted = darkSurfaceVariant;
  static const Color mutedForeground = darkOnSurfaceVariant;
  static const Color border = darkOutline;
  static const Color ring = darkPrimary;
}

/// Font sizes and typography definitions
class FontSizes {
  // Material Design scale
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;

  // Forui/Tailwind-style aliases
  static const double xs = labelSmall; // 11
  static const double sm = labelMedium; // 12
  static const double base = bodyMedium; // 14
  static const double lg = bodyLarge; // 16
  static const double xl = titleLarge; // 22
  static const double xl2 = headlineSmall; // 24
  static const double xl3 = headlineMedium; // 28
  static const double xl4 = headlineLarge; // 32
  static const double xl5 = displaySmall; // 36
  static const double xl6 = displayMedium; // 45
  static const double xl7 = displayLarge; // 57
}

/// Breakpoints for responsive design
class Breakpoints {
  static const double sm = 640.0;
  static const double md = 768.0;
  static const double lg = 1024.0;
  static const double xl = 1280.0;
  static const double xl2 = 1536.0;
}

/// Extension methods to check screen size
extension BreakpointExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  bool get isSm => screenWidth >= Breakpoints.sm;
  bool get isMd => screenWidth >= Breakpoints.md;
  bool get isLg => screenWidth >= Breakpoints.lg;
  bool get isXl => screenWidth >= Breakpoints.xl;
  bool get is2Xl => screenWidth >= Breakpoints.xl2;
}

/// Extension methods to easily access theme colors
extension ThemeColors on BuildContext {
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get primaryForeground => Theme.of(this).colorScheme.onPrimary;
  Color get secondary => Theme.of(this).colorScheme.secondary;
  Color get secondaryForeground => Theme.of(this).colorScheme.onSecondary;
  Color get background => Theme.of(this).colorScheme.surface;
  Color get foreground => Theme.of(this).colorScheme.onSurface;
  Color get error => Theme.of(this).colorScheme.error;
  Color get errorForeground => Theme.of(this).colorScheme.onError;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get surfaceVariant =>
      Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get outline => Theme.of(this).colorScheme.outline;
}

/// Light theme data (Material Design 3)
///
/// This is the primary theme that the Theme Module can parse and edit.
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
    onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
    outline: LightModeColors.lightOutline,
    shadow: LightModeColors.lightShadow,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: LightModeColors.lightSurface,
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
      color: LightModeColors.lightOnSurface,
    ),
    displayMedium: TextStyle(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
      color: LightModeColors.lightOnSurface,
    ),
    displaySmall: TextStyle(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
      color: LightModeColors.lightOnSurface,
    ),
    headlineLarge: TextStyle(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
    titleLarge: TextStyle(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    titleMedium: TextStyle(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    titleSmall: TextStyle(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    labelLarge: TextStyle(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    labelMedium: TextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    labelSmall: TextStyle(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      color: LightModeColors.lightOnSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      color: LightModeColors.lightOnSurface,
    ),
    bodySmall: TextStyle(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      color: LightModeColors.lightOnSurface,
    ),
  ),
);

/// Dark theme data (Material Design 3)
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
    surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
    onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
    outline: DarkModeColors.darkOutline,
    shadow: DarkModeColors.darkShadow,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: DarkModeColors.darkSurface,
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
      color: DarkModeColors.darkOnSurface,
    ),
    displayMedium: TextStyle(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
      color: DarkModeColors.darkOnSurface,
    ),
    displaySmall: TextStyle(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
      color: DarkModeColors.darkOnSurface,
    ),
    headlineLarge: TextStyle(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w600,
      color: DarkModeColors.darkOnSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
      color: DarkModeColors.darkOnSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
      color: DarkModeColors.darkOnSurface,
    ),
    titleLarge: TextStyle(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
      color: DarkModeColors.darkOnSurface,
    ),
    titleMedium: TextStyle(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: DarkModeColors.darkOnSurface,
    ),
    titleSmall: TextStyle(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: DarkModeColors.darkOnSurface,
    ),
    labelLarge: TextStyle(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: DarkModeColors.darkOnSurface,
    ),
    labelMedium: TextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: DarkModeColors.darkOnSurface,
    ),
    labelSmall: TextStyle(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: DarkModeColors.darkOnSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      color: DarkModeColors.darkOnSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      color: DarkModeColors.darkOnSurface,
    ),
    bodySmall: TextStyle(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      color: DarkModeColors.darkOnSurface,
    ),
  ),
);

/// Helper to get the selected Forui theme name as a string
///
/// Converts the enum value to a string that can be used to
/// dynamically select the Forui theme in main.dart.
String get selectedForuiTheme => ForuiThemeConfig.themePreset.name;
