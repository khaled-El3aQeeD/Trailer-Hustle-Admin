import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'theme.dart';
import 'pages/dashboard_page.dart';
import 'package:trailerhustle_admin/pages/giveaways_page.dart';
import 'package:trailerhustle_admin/pages/trailers_page.dart';
import 'package:trailerhustle_admin/pages/notifications_page.dart';
import 'package:trailerhustle_admin/services/app_navigation_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/auth/auth_controller.dart';
import 'package:trailerhustle_admin/pages/auth_page.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

/// Dashboard Template Application Entry Point.
///
/// Sets up the Flutter app with both Material and Forui theme systems.
/// Uses a custom theme configuration that is compatible with the Theme Module.
///
/// **Setup:**
/// - `ThemeProvider`: Manages system/light/dark theme switching
/// - `theme.dart`: Custom Material Design 3 theme (parseable by Theme Module)
/// - Forui theme derived from Material theme for component compatibility
/// - `DashboardPage`: Main dashboard layout with responsive grid
///
/// **Architecture:**
/// 1. Material ThemeData defined in theme.dart (primary source of truth)
/// 2. Forui FThemeData derived from Material theme via extension
/// 3. Both theme systems use the same underlying color/typography constants
///
/// **Theme Module Compatibility:**
/// The Theme Module can parse and edit colors/typography in theme.dart
/// because it uses standard Material Design 3 ThemeData structure.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialize failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppNavigationController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: const Application(),
    ),
  );
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Use our custom Material themes from theme.dart
    // These can be parsed and edited by Theme Module
    final materialLightTheme = lightTheme;
    final materialDarkTheme = darkTheme;

    // Dynamically select Forui theme based on theme.dart configuration
    // The selectedForuiTheme constant can be changed in the Theme Module
    final (foruiLightTheme, foruiDarkTheme) = _getForuiTheme(
      selectedForuiTheme,
    );

    // Determine current Forui theme based on themeMode and system brightness
    final FThemeData currentForuiTheme;
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        currentForuiTheme = foruiLightTheme;
        break;
      case ThemeMode.dark:
        currentForuiTheme = foruiDarkTheme;
        break;
      case ThemeMode.system:
        final systemBrightness = MediaQuery.platformBrightnessOf(context);
        currentForuiTheme = systemBrightness == Brightness.light
            ? foruiLightTheme
            : foruiDarkTheme;
        break;
    }

    return MaterialApp(
      title: 'Dashboard Template',
      debugShowCheckedModeBanner: false,
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...FLocalizations.localizationsDelegates,
      ],
      // Wrap with FTheme for Forui components
      builder: (_, child) => FTheme(data: currentForuiTheme, child: child!),
      // Use our custom Material themes (Theme Module can parse these)
      theme: materialLightTheme,
      darkTheme: materialDarkTheme,
      themeMode: themeProvider.themeMode,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: auth.isSignedIn
          ? const _AdminRoot(key: ValueKey('admin_root'))
          : const AuthPage(key: ValueKey('auth_page')),
    );
  }
}

class _AdminRoot extends StatelessWidget {
  const _AdminRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final route = context.watch<AppNavigationController>().route;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (route) {
        AppRoute.dashboard => const DashboardPage(key: ValueKey('dashboard')),
        AppRoute.giveaways => const GiveawaysPage(key: ValueKey('giveaways')),
        AppRoute.trailers => const TrailersPage(key: ValueKey('trailers'), initialTabIndex: 0),
        AppRoute.trailersReview => const TrailersPage(
          key: ValueKey('trailers_review'),
          initialTabIndex: 2,
          hideSubmittedApprovalFilters: true,
          showTopTabBar: false,
        ),
        AppRoute.trailersAll => const TrailersPage(key: ValueKey('trailers_all'), initialTabIndex: 3),
        AppRoute.trailerTypesEdit => const TrailersPage(key: ValueKey('trailer_types_edit'), initialTabIndex: 0),
        AppRoute.manufacturersEdit => const TrailersPage(key: ValueKey('manufacturers_edit'), initialTabIndex: 1),
        AppRoute.notifications => const NotificationsPage(key: ValueKey('notifications')),
      },
    );
  }
}

/// Helper function to dynamically select Forui theme based on configuration
///
/// Returns a tuple of (light, dark) FThemeData for the specified theme preset.
/// The theme preset comes from ForuiThemeConfig.themePreset (exposed as selectedForuiTheme) in theme.dart,
/// which can be edited through the Theme Module.
(FThemeData, FThemeData) _getForuiTheme(String themeName) {
  switch (themeName.toLowerCase()) {
    case 'slate':
      return (FThemes.slate.light, FThemes.slate.dark);
    case 'red':
      return (FThemes.red.light, FThemes.red.dark);
    case 'rose':
      return (FThemes.rose.light, FThemes.rose.dark);
    case 'orange':
      return (FThemes.orange.light, FThemes.orange.dark);
    case 'green':
      return (FThemes.green.light, FThemes.green.dark);
    case 'blue':
      return (FThemes.blue.light, FThemes.blue.dark);
    case 'yellow':
      return (FThemes.yellow.light, FThemes.yellow.dark);
    case 'violet':
      return (FThemes.violet.light, FThemes.violet.dark);
    case 'zinc':
    default:
      return (FThemes.zinc.light, FThemes.zinc.dark);
  }
}
