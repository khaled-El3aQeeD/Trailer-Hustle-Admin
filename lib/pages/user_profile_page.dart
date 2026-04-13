import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/models/user_data.dart';
import 'package:trailerhustle_admin/services/app_navigation_controller.dart';
import 'package:trailerhustle_admin/services/image_upload_service.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';
import 'package:trailerhustle_admin/widgets/adaptive_sidebar.dart';
import 'package:trailerhustle_admin/services/sidebar_controller.dart';
import 'package:trailerhustle_admin/widgets/user_profile_dialog.dart';
import 'package:trailerhustle_admin/widgets/profile/user_details_section.dart';
import 'package:trailerhustle_admin/widgets/profile/profile_info_section.dart';
import 'package:trailerhustle_admin/widgets/profile/photos_section.dart';
import 'package:trailerhustle_admin/widgets/profile/login_method_badge.dart';

/// Full-page customer profile view.
///
/// Replaces the old dialog-based profile. Opens inside the main admin layout
/// (sidebar + header) so the user has full-screen space.
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.user, this.initialTabIndex = 0});
  final UserData user;
  final int initialTabIndex;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late UserData _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void didUpdateWidget(covariant UserProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _user = widget.user;
    }
  }

  void _onUserUpdated(UserData updated) {
    if (!mounted) return;
    setState(() => _user = updated);
    context.read<AppNavigationController>().updateProfileUser(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isMobile = theme.breakpoints.md > MediaQuery.of(context).size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    context.read<SidebarController>().autoCollapseIfNeeded(screenWidth);

    return Scaffold(
      backgroundColor: theme.colors.primaryForeground,
      drawer: isMobile ? Container(color: theme.colors.background, child: const Sidebar()) : null,
      body: Row(
        children: [
          if (!isMobile) const AdaptiveSidebar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colors.background,
                          borderRadius: BorderRadius.circular(DashboardConstants.containerBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colors.primary.withValues(alpha: 0.13),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DashboardHeader(
                              pageTitle: 'TrailerHustle',
                              onSidebarToggle: isMobile ? null : () => context.read<SidebarController>().toggle(),
                              onThemeToggle: () => context.read<ThemeProvider>().toggleThemeMode(),
                              themeMode: context.watch<ThemeProvider>().themeMode,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(DashboardConstants.contentPadding),
                              child: _ProfileContent(
                                user: _user,
                                initialTabIndex: widget.initialTabIndex,
                                onUserUpdated: _onUserUpdated,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The profile content area — back button, header, stacked sections.
class _ProfileContent extends StatefulWidget {
  const _ProfileContent({required this.user, required this.initialTabIndex, required this.onUserUpdated});
  final UserData user;
  final int initialTabIndex;
  final ValueChanged<UserData> onUserUpdated;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  bool _uploadingAvatar = false;

  Future<void> _uploadAvatar() async {
    final file = await ImageUploadService.pickImage();
    if (file == null || file.bytes == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await ImageUploadService.uploadProfileImage(
        businessId: widget.user.id,
        bytes: file.bytes!,
        filename: file.name,
      );
      final updated = widget.user.copyWith(
        avatar: url,
        updatedAt: DateTime.now().toUtc(),
      );
      await UserService.updateUser(updated);
      widget.onUserUpdated(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final user = widget.user;
    final name = user.name.trim().isEmpty ? '—' : user.name.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Back button ──
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextButton.icon(
            onPressed: () => context.read<AppNavigationController>().goBack(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Businesses'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colors.mutedForeground,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),

        // ── Profile header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colors.border),
            boxShadow: [
              BoxShadow(
                color: theme.colors.foreground.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with upload overlay
              GestureDetector(
                onTap: _uploadingAvatar ? null : _uploadAvatar,
                child: Stack(
                  children: [
                    FAvatar(image: NetworkImage(widget.user.avatar), size: 56),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.30),
                        ),
                        alignment: Alignment.center,
                        child: _uploadingAvatar
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.typography.lg.copyWith(fontWeight: FontWeight.w800, color: theme.colors.foreground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...user.loginMethods.map((m) => LoginMethodBadge(method: m)),
                        StatusPill(
                          text: user.subscriptionTier.toUpperCase(),
                          color: user.subscriptionTier == 'pro'
                              ? const Color(0xFF7C3AED)
                              : user.subscriptionTier == 'lite'
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF6B7280),
                        ),
                        if (!user.isActive)
                          const StatusPill(text: 'INACTIVE', color: Color(0xFFDC2626)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: theme.colors.muted.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: theme.colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 14, color: theme.colors.mutedForeground),
                              const SizedBox(width: 6),
                              Text(
                                user.customerNumber.trim().isEmpty ? 'Business ID —' : 'Business ID ${user.customerNumber.trim()}',
                                style: theme.typography.xs.copyWith(fontWeight: FontWeight.w800, color: theme.colors.foreground),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Section 1: User Details (Login & Account) ──
        UserDetailsSection(user: user, onUserUpdated: widget.onUserUpdated),
        const SizedBox(height: 16),

        // ── Section 2: Profile Information ──
        ProfileInfoSection(user: user, onUserUpdated: widget.onUserUpdated),
        const SizedBox(height: 16),

        // ── Section 3: Photos ──
        PhotosSection(user: user, onUserUpdated: widget.onUserUpdated),
        const SizedBox(height: 16),

        // ── Section 4: Trailers ──
        _ReadOnlySection(
          title: 'Trailers',
          icon: Icons.local_shipping_outlined,
          childBuilder: (_) => UserProfileDialog.buildTrailersTab(user: user),
        ),
        const SizedBox(height: 16),

        // ── Section 5: Services & Products ──
        _ReadOnlySection(
          title: 'Services & Products',
          icon: Icons.build_outlined,
          childBuilder: (_) => UserProfileDialog.buildServicesTab(user: user),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// A simple read-only collapsible section wrapper for existing tab content.
///
/// Lazily builds [childBuilder] only when expanded so that the tab widgets
/// (which contain their own SingleChildScrollView) are not laid out inside
/// the outer scrollable Column with unbounded constraints.
class _ReadOnlySection extends StatefulWidget {
  const _ReadOnlySection({required this.title, required this.icon, required this.childBuilder});
  final String title;
  final IconData icon;
  final WidgetBuilder childBuilder;

  @override
  State<_ReadOnlySection> createState() => _ReadOnlySectionState();
}

class _ReadOnlySectionState extends State<_ReadOnlySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colors.muted.withValues(alpha: 0.15),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: theme.colors.primary),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    style: theme.typography.base.copyWith(fontWeight: FontWeight.w700, color: theme.colors.foreground),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: theme.colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 600),
                child: widget.childBuilder(context),
              ),
            ),
        ],
      ),
    );
  }
}
