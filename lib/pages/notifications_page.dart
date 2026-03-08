import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  bool _isSidebarCollapsed = false;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(duration: DashboardConstants.sidebarAnimationDuration, vsync: this);
    _sidebarAnimation = CurvedAnimation(parent: _sidebarAnimationController, curve: Curves.easeInOut);
    _sidebarAnimationController.forward();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
    if (_isSidebarCollapsed) {
      _sidebarAnimationController.reverse();
    } else {
      _sidebarAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.theme.breakpoints.md > MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: context.theme.colors.primaryForeground,
      drawer: isMobile
          ? Container(color: context.theme.colors.background, child: const Sidebar())
          : null,
      body: Row(
        children: [
          if (!isMobile)
            AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) => ClipRect(
                child: SizeTransition(
                  sizeFactor: _sidebarAnimation,
                  axis: Axis.horizontal,
                  axisAlignment: -1,
                  child: const Sidebar(),
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.theme.colors.background,
                        borderRadius: BorderRadius.circular(DashboardConstants.containerBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: context.theme.colors.primary.withValues(alpha: 0.13),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          DashboardHeader(
                            pageTitle: 'Notifications',
                            onSidebarToggle: isMobile ? null : _toggleSidebar,
                            sidebarAnimation: isMobile ? null : _sidebarAnimation,
                            onThemeToggle: () => context.read<ThemeProvider>().toggleThemeMode(),
                            themeMode: context.watch<ThemeProvider>().themeMode,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(DashboardConstants.contentPadding),
                            child: const _ComingSoonPanel(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none_outlined, color: theme.colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
