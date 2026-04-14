import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';
import 'package:trailerhustle_admin/widgets/adaptive_sidebar.dart';
import 'package:trailerhustle_admin/services/sidebar_controller.dart';
import 'package:trailerhustle_admin/widgets/manufacturers_table_card.dart';
import 'package:trailerhustle_admin/widgets/trailers_table_card.dart';
import 'package:trailerhustle_admin/widgets/trailer_types_table_card.dart';

class TrailersPage extends StatefulWidget {
  const TrailersPage({super.key, this.initialTabIndex = 0, this.hideSubmittedApprovalFilters = false, this.showTopTabBar = true});

  /// Which tab should be selected when opening the page.
  ///
  /// 0 = Manage Default Trailer Types
  /// 1 = Edit Manufacturers
  /// 2 = Submitted Trailers for Approval
  /// 3 = View all Trailers
  final int initialTabIndex;

  /// When true, the "Submitted Trailers for Approval" tab hides the search/category/manufacturer
  /// filter row (useful for the dedicated review route).
  final bool hideSubmittedApprovalFilters;

  /// When false, hides the top tab bar and only shows the selected tab's content.
  ///
  /// This is useful for deep-linked routes like "Review submitted trailers" where the tab bar
  /// would be redundant.
  final bool showTopTabBar;

  @override
  State<TrailersPage> createState() => _TrailersPageState();
}

class _TrailersPageState extends State<TrailersPage> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.showTopTabBar) {
      _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 3));
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.theme.breakpoints.md > MediaQuery.of(context).size.width;
    final theme = context.theme;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarController = context.read<SidebarController>();
    sidebarController.autoCollapseIfNeeded(screenWidth);

    return Scaffold(
      backgroundColor: context.theme.colors.primaryForeground,
      drawer: isMobile
          ? Container(color: context.theme.colors.background, child: const Sidebar())
          : null,
      body: Row(
        children: [
          if (!isMobile) const AdaptiveSidebar(),
          Expanded(
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
                      pageTitle: 'Trailers',
                      onSidebarToggle: isMobile ? null : () => context.read<SidebarController>().toggle(),
                      onThemeToggle: () => context.read<ThemeProvider>().toggleThemeMode(),
                      themeMode: context.watch<ThemeProvider>().themeMode,
                    ),
                    if (widget.showTopTabBar)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DashboardConstants.contentPadding,
                          DashboardConstants.contentPadding,
                          DashboardConstants.contentPadding,
                          12,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colors.muted.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colors.border),
                          ),
                          child: TabBar(
                            controller: _tabController!,
                            dividerColor: Colors.transparent,
                            labelColor: theme.colors.foreground,
                            unselectedLabelColor: theme.colors.mutedForeground,
                            labelStyle: theme.typography.sm.copyWith(fontWeight: FontWeight.w800),
                            unselectedLabelStyle: theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: theme.colors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.colors.border),
                              boxShadow: [BoxShadow(color: theme.colors.foreground.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 10))],
                            ),
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: const [
                              Tab(text: 'Manage Default Trailer Types'),
                              Tab(text: 'Edit Manufacturers'),
                              Tab(text: 'Submitted Trailers for Approval'),
                              Tab(text: 'View all Trailers'),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DashboardConstants.contentPadding,
                          0,
                          DashboardConstants.contentPadding,
                          DashboardConstants.contentPadding,
                        ),
                        child: widget.showTopTabBar
                            ? TabBarView(
                                controller: _tabController!,
                                children: [
                                  const _TrailersTabScroll(child: TrailerTypesTableCard()),
                                  const _TrailersTabScroll(child: ManufacturersTableCard()),
                                  _TrailersTabScroll(
                                    child: TrailersTableCard(
                                      mode: TrailersTableMode.submittedForApproval,
                                      showFilters: !widget.hideSubmittedApprovalFilters,
                                    ),
                                  ),
                                  const _TrailersTabScroll(child: TrailersTableCard(mode: TrailersTableMode.all)),
                                ],
                              )
                            : _TrailersTabScroll(
                                child: TrailersTableCard(
                                  mode: TrailersTableMode.submittedForApproval,
                                  showFilters: !widget.hideSubmittedApprovalFilters,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailersTabScroll extends StatelessWidget {
  const _TrailersTabScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: child,
    );
  }
}
