import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/services/app_navigation_controller.dart';
import 'package:trailerhustle_admin/services/navigation_service.dart';
import 'package:trailerhustle_admin/services/sidebar_controller.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';

/// Adaptive sidebar that switches between full and collapsed (icon-only) mode.
///
/// Listens to [SidebarController] for collapse state and auto-collapses
/// when screen width drops below 1280px.
class AdaptiveSidebar extends StatelessWidget {
  const AdaptiveSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SidebarController>();

    if (controller.collapsed) {
      return const _CollapsedSidebar();
    }
    return const Sidebar();
  }
}

class _CollapsedSidebar extends StatelessWidget {
  const _CollapsedSidebar();

  void _handleNavigation(BuildContext context, String url) {
    final nav = context.read<AppNavigationController>();
    switch (url) {
      case '/dashboard':
        nav.go(AppRoute.dashboard);
        break;
      case '/giveaways':
        nav.go(AppRoute.giveaways);
        break;
      case '/trailers':
        nav.go(AppRoute.trailers);
        break;
      case '/trailers/review':
        nav.go(AppRoute.trailersReview);
        break;
      case '/trailers/types':
        nav.go(AppRoute.trailerTypesEdit);
        break;
      case '/trailers/manufacturers':
        nav.go(AppRoute.manufacturersEdit);
        break;
      case '/trailers/all':
        nav.go(AppRoute.trailersAll);
        break;
      case '/notifications':
        nav.go(AppRoute.notifications);
        break;
      case '/send-push':
        nav.go(AppRoute.sendPush);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final route = context.watch<AppNavigationController>().route;
    final activeUrl = switch (route) {
      AppRoute.dashboard => '/dashboard',
      AppRoute.giveaways => '/giveaways',
      AppRoute.trailers => '/trailers',
      AppRoute.trailersReview => '/trailers/review',
      AppRoute.trailersAll => '/trailers/all',
      AppRoute.trailerTypesEdit => '/trailers/types',
      AppRoute.manufacturersEdit => '/trailers/manufacturers',
      AppRoute.notifications => '/notifications',
      AppRoute.sendPush => '/send-push',
      AppRoute.customerProfile => '/dashboard',
    };

    final items = NavigationService.getMainNavigation(activeUrl: activeUrl);

    return Container(
      width: DashboardConstants.sidebarCollapsedWidth,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header logo
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(FIcons.zap, color: theme.colors.background, size: 14),
            ),
          ),
          const Divider(height: 1),
          // Navigation icons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: items.map((item) {
                  final isActive = item.isActive;
                  return Tooltip(
                    message: item.title,
                    preferBelow: false,
                    waitDuration: const Duration(milliseconds: 400),
                    child: InkWell(
                      onTap: () => _handleNavigation(context, item.url),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: isActive
                              ? theme.colors.foreground
                              : theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Settings icon at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Tooltip(
              message: 'Settings',
              child: Icon(FIcons.settings, size: 18, color: theme.colors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}
