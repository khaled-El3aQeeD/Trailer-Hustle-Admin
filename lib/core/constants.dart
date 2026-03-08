/// Layout dimensions and timing constants.
///
/// Centralized configuration for dashboard layout dimensions, animations,
/// and responsive behavior. Ensures consistent spacing and timing across all components.
///
/// **Usage:**
/// ```dart
/// width: DashboardConstants.sidebarWidth,
/// duration: DashboardConstants.sidebarAnimationDuration,
/// padding: EdgeInsets.all(DashboardConstants.contentPadding),
/// ```
class DashboardConstants {
  /// Width of the sidebar when fully expanded
  static const double sidebarWidth = 260.0;

  /// Threshold for showing the sidebar toggle button
  /// When sidebar width is below this value, the toggle button appears
  static const double sidebarToggleThreshold = 130.0;

  /// Animation duration for sidebar transitions
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 200);

  /// Header height for dashboard content
  static const double headerHeight = 48.0;

  /// Content padding
  static const double contentPadding = 16.0;

  /// Container border radius
  static const double containerBorderRadius = 12.0;
}
