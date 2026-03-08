import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart' hide FSidebar, FSidebarGroup, FSidebarItem;
import '../theme/sidebar_style.dart' as sidebar_style;
import 'package:trailerhustle_admin/services/navigation_service.dart';
import 'package:trailerhustle_admin/services/app_navigation_controller.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/auth/auth_controller.dart';
import 'patched_sidebar.dart';
import 'package:trailerhustle_admin/widgets/user_profile_dialog.dart';

/// Navigation sidebar with hierarchical menu structure.
/// Applies custom sidebar styling via `sidebar_style.dart` on top of Forui base.
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

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
      default:
        debugPrint('Navigation not implemented for: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
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
    };
    return PatchedFSidebar(
      style: sidebar_style.sidebarStyle(
        colors: context.theme.colors,
        typography: context.theme.typography,
        style: context.theme.style,
      )(context.theme),
      header: _buildHeader(context),
      footer: _buildFooter(context),
      children: [
        // Main Navigation
        PatchedFSidebarGroup(
          children:
              NavigationService.getMainNavigation(activeUrl: activeUrl).map((item) {
            final hasChildren = item.children != null;
            if (hasChildren) {
              return PatchedFSidebarItem(
                icon: Icon(item.icon),
                label: Text(item.title),
                selected: item.isActive,
                initiallyExpanded: item.isActive,
                children: item.children!
                    .map(
                      (child) => PatchedFSidebarItem(
                        label: Text(child.title),
                        onPress: () {
                          _handleNavigation(context, child.url);
                        },
                      ),
                    )
                    .toList(),
                onPress: () {
                  _handleNavigation(context, item.url);
                },
              );
            } else {
              return PatchedFSidebarItem(
                icon: Icon(item.icon),
                label: Text(item.title),
                selected: item.isActive,
                onPress: () {
                  _handleNavigation(context, item.url);
                },
              );
            }
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12, bottom: 12, top: 16),
      child: Row(
        spacing: 10,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: context.theme.colors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              FIcons.zap,
              color: context.theme.colors.background,
              size: 12,
            ),
          ),
          Text(
            'TrailerHustle',
            style: context.theme.typography.sm.copyWith(
              fontWeight: FontWeight.bold,
              color: context.theme.colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    // Rebuild the footer when auth state changes so email/phone/name update.
    context.watch<AuthController>();
    final user = UserService.getCurrentUser();
    return Column(
      children: [
        // Secondary Navigation (Settings, Help, etc.)
        PatchedFSidebarGroup(
          children: NavigationService.getSecondaryNavigation()
              .map(
                (item) => PatchedFSidebarItem(
                  icon: Icon(item.icon),
                  label: Text(item.title),
                  onPress: () {
                    // TODO: Navigate to ${item.url}
                  },
                ),
              )
              .toList(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _FooterUserCard(
            userName: user.name.trim().isEmpty ? '—' : user.name.trim(),
            userEmail: user.email.trim().isEmpty ? '—' : user.email.trim(),
            avatarUrl: user.avatar,
            onTap: () => UserProfileDialog.show(context, user: user),
          ),
        ),
      ],
    );
  }
}

class _FooterUserCard extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String avatarUrl;
  final VoidCallback onTap;

  const _FooterUserCard({
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  State<_FooterUserCard> createState() => _FooterUserCardState();
}

class _FooterUserCardState extends State<_FooterUserCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _hovered
                ? theme.colors.muted.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: FCard.raw(
            style: FCardStyle(
              decoration: const BoxDecoration(),
              contentStyle: FCardContentStyle(
                titleTextStyle: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colors.mutedForeground,
                ),
                subtitleTextStyle: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ).call,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Row(
                spacing: 10,
                children: [
                  FAvatar(image: NetworkImage(widget.avatarUrl), size: 36),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          widget.userName,
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colors.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.userEmail,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    FIcons.ellipsis,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
