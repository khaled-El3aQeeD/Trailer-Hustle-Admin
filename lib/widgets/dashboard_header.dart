import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Top navigation bar with sidebar and theme controls.

class DashboardHeader extends StatelessWidget {
  final String pageTitle;
  final VoidCallback? onSidebarToggle;
  final Animation<double>? sidebarAnimation;
  final VoidCallback? onThemeToggle;
  final ThemeMode themeMode;

  const DashboardHeader({
    super.key,
    required this.pageTitle,
    this.onSidebarToggle,
    this.sidebarAnimation,
    this.onThemeToggle,
    this.themeMode = ThemeMode.system,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Same height as sidebar header
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sidebar toggle button
          if (onSidebarToggle != null)
            Row(
              children: [
                IconButton(
                  onPressed: onSidebarToggle,
                  icon: const Icon(FIcons.panelLeft),
                  iconSize: 16,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(30, 30),
                    padding: EdgeInsets.zero,
                    foregroundColor: context.theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 16,
                  width: 1,
                  color: context.theme.colors.border,
                ),
                const SizedBox(width: 16),
              ],
            )
          else
            // Mobile hamburger menu button
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(FIcons.panelLeft),
                    iconSize: 16,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(30, 30),
                      padding: EdgeInsets.zero,
                      foregroundColor: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 16,
                  width: 1,
                  color: context.theme.colors.border,
                ),
                const SizedBox(width: 16),
              ],
            ),

          // Page title
          Text(
            pageTitle,
            style: context.theme.typography.sm.copyWith(
              fontWeight: FontWeight.w500,
              color: context.theme.colors.foreground,
            ),
          ),

          const Spacer(),

          // Theme toggle button
          if (onThemeToggle != null)
            IconButton(
              onPressed: onThemeToggle,
              icon: Icon(_getThemeIcon(themeMode)),
              iconSize: 16,
              style: IconButton.styleFrom(
                minimumSize: const Size(30, 30),
                padding: EdgeInsets.zero,
                foregroundColor: context.theme.colors.mutedForeground,
              ),
            ),

          // Optional: Add more header actions here
          // Example: User menu, notifications, etc.
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode currentMode) {
    switch (currentMode) {
      case ThemeMode.system:
        return FIcons.monitor;
      case ThemeMode.light:
        return FIcons.sun;
      case ThemeMode.dark:
        return FIcons.moon;
    }
  }
}
