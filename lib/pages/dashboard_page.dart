import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/services/sidebar_controller.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/widgets/customers_table_card.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/adaptive_sidebar.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';
import 'package:trailerhustle_admin/widgets/trailers_table_card.dart';

/// Main dashboard layout with responsive grid system.
///
/// Coordinates the overall dashboard layout with sidebar navigation,
/// header controls, and adaptive content grid for different screen sizes.
///
/// **Layout Structure:**
/// ```
/// [Sidebar] | [Header            ]
///          | [Metrics Grid      ]
///          | [Chart Card        ]
///          | [Progress Cards    ]
///          | [Lists & Activity  ]
/// ```
///
/// **Responsive Breakpoints:**
/// - **Mobile** (< md): Drawer sidebar, 1-column metrics
/// - **Tablet** (md-lg): Collapsible sidebar, 2-column metrics
/// - **Desktop** (lg+): Fixed sidebar, 4-column metrics
///
/// **Data Sources:**
/// - All displayed data is currently mock/hardcoded sample data
/// - Chart data generated via `_generateChartDatasets()` with 3 months of sample points
/// - Metric cards use static demo values
/// - Replace these with real API calls for production use
///
/// **State Management:**
/// - Uses `ThemeProvider` for theme switching
/// - Local state for sidebar collapse animation
/// - No external data state - currently demonstration only
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  @override
  Widget build(BuildContext context) {
    final isMobile =
        context.theme.breakpoints.md > MediaQuery.of(context).size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarController = context.read<SidebarController>();
    sidebarController.autoCollapseIfNeeded(screenWidth);

    return Scaffold(
      backgroundColor: context.theme.colors.primaryForeground,
      drawer: isMobile
          ? Container(
              color: context.theme.colors.background,
              child: const Sidebar(),
            )
          : null,
      body: Row(
        children: [
          // Desktop sidebar (hidden on mobile)
          if (!isMobile) const AdaptiveSidebar(),

          // Main content area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.theme.colors.background,
                          borderRadius: BorderRadius.circular(
                            DashboardConstants.containerBorderRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.theme.colors.primary.withValues(
                                alpha: 0.13,
                              ),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header inside the container
                            DashboardHeader(
                              pageTitle: 'TrailerHustle',
                              onSidebarToggle: isMobile ? null : () => context.read<SidebarController>().toggle(),
                              onThemeToggle: () => context
                                  .read<ThemeProvider>()
                                  .toggleThemeMode(),
                              themeMode: context
                                  .watch<ThemeProvider>()
                                  .themeMode,
                            ),

                            Padding(
                              padding: const EdgeInsets.all(DashboardConstants.contentPadding),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomersTableCard(),
                                  SizedBox(height: 12),
                                  TrailersTableCard(),
                                ],
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
