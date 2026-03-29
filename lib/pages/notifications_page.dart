import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/models/admin_notification_data.dart';
import 'package:trailerhustle_admin/services/admin_notification_service.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  bool _isSidebarCollapsed = false;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  // Data state
  List<AdminNotificationData> _notifications = [];
  bool _loading = true;
  String? _error;
  int _selectedTypeFilter = 0; // 0 = All

  // Pagination
  int _page = 0;
  int _pageSize = 25;
  int _totalCount = 0;

  // Summary counts (across all pages)
  int _summaryUnread = 0;
  Map<int, int> _summaryTypeCounts = {};

  // Real-time
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      duration: DashboardConstants.sidebarAnimationDuration,
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    );
    _sidebarAnimationController.forward();

    _realtimeChannel = AdminNotificationService.subscribeToChanges(
      onChanged: () => _fetchData(),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _loading = _notifications.isEmpty;
      _error = null;
    });

    try {
      final typeArg = _selectedTypeFilter == 0 ? null : _selectedTypeFilter;
      final results = await Future.wait([
        AdminNotificationService.fetchPaginated(
          typeFilter: typeArg,
          page: _page,
          pageSize: _pageSize,
        ),
        AdminNotificationService.fetchSummaryCounts(),
      ]);

      final paginated = results[0]
          as ({List<AdminNotificationData> items, int total});
      final summary = results[1]
          as ({int unread, Map<int, int> typeCounts});

      if (!mounted) return;
      setState(() {
        _notifications = paginated.items;
        _totalCount = paginated.total;
        _summaryUnread = summary.unread;
        _summaryTypeCounts = summary.typeCounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      SupabaseConfig.client.removeChannel(_realtimeChannel!);
    }
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

  void _onFilterChanged(int type) {
    if (_selectedTypeFilter == type) return;
    setState(() {
      _selectedTypeFilter = type;
      _page = 0;
    });
    _fetchData();
  }

  Future<void> _markAllRead() async {
    await AdminNotificationService.markAllAsRead();
    if (!mounted) return;
    // Optimistic local update + refresh summary
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        if (_notifications[i].isUnread) {
          _notifications[i] = _notifications[i].copyWithRead();
        }
      }
      _summaryUnread = 0;
    });
  }

  Future<void> _markOneRead(AdminNotificationData n) async {
    if (n.isUnread) {
      await AdminNotificationService.markAsRead(n.id);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) {
          _notifications[idx] = _notifications[idx].copyWithRead();
        }
        _summaryUnread = (_summaryUnread - 1).clamp(0, _summaryUnread);
      });
    }
  }

  Future<void> _deleteOne(AdminNotificationData n) async {
    await AdminNotificationService.softDelete(n.id);
    if (!mounted) return;
    setState(() {
      _notifications.removeWhere((x) => x.id == n.id);
      _totalCount = (_totalCount - 1).clamp(0, _totalCount);
      final t = n.type;
      _summaryTypeCounts[t] = ((_summaryTypeCounts[t] ?? 1) - 1).clamp(0, 999999);
      if (n.isUnread) _summaryUnread = (_summaryUnread - 1).clamp(0, _summaryUnread);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        context.theme.breakpoints.md > MediaQuery.of(context).size.width;

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
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.theme.colors.background,
                        borderRadius: BorderRadius.circular(
                            DashboardConstants.containerBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: context.theme.colors.primary
                                .withValues(alpha: 0.13),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DashboardHeader(
                            pageTitle: 'Notifications',
                            onSidebarToggle:
                                isMobile ? null : _toggleSidebar,
                            sidebarAnimation:
                                isMobile ? null : _sidebarAnimation,
                            onThemeToggle: () => context
                                .read<ThemeProvider>()
                                .toggleThemeMode(),
                            themeMode:
                                context.watch<ThemeProvider>().themeMode,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(
                                DashboardConstants.contentPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSummaryCards(context),
                                const SizedBox(height: 20),
                                _buildFilterBar(context),
                                const SizedBox(height: 16),
                                _buildNotificationList(context),
                              ],
                            ),
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

  // ─── Summary cards ──────────────────────────────────────────────

  Widget _buildSummaryCards(BuildContext context) {
    final cards = [
      _SummaryTile(
        icon: Icons.notifications_active,
        iconColor: Colors.orange,
        label: 'Unread',
        count: _summaryUnread,
      ),
      _SummaryTile(
        icon: Icons.precision_manufacturing_outlined,
        iconColor: Colors.blue,
        label: 'Trailer Makes',
        count: _summaryTypeCounts[10] ?? 0,
      ),
      _SummaryTile(
        icon: Icons.mail_outline,
        iconColor: Colors.green,
        label: 'Contact Us',
        count: _summaryTypeCounts[11] ?? 0,
      ),
      _SummaryTile(
        icon: Icons.handshake_outlined,
        iconColor: Colors.purple,
        label: 'Brand Partners',
        count: _summaryTypeCounts[8] ?? 0,
      ),
      _SummaryTile(
        icon: Icons.report_outlined,
        iconColor: Colors.red,
        label: 'Reported Chats',
        count: _summaryTypeCounts[13] ?? 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cards
                .map((c) => SizedBox(
                    width: (constraints.maxWidth - 8) / 2, child: c))
                .toList(),
          );
        }
        return Row(
          children: cards
              .map((c) => Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  )))
              .toList(),
        );
      },
    );
  }

  // ─── Filter chips ───────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: _selectedTypeFilter == 0,
                onTap: () => _onFilterChanged(0),
              ),
              _FilterChip(
                label: 'Trailer Makes',
                selected: _selectedTypeFilter == 10,
                onTap: () => _onFilterChanged(10),
                dotColor: Colors.blue,
              ),
              _FilterChip(
                label: 'Contact Us',
                selected: _selectedTypeFilter == 11,
                onTap: () => _onFilterChanged(11),
                dotColor: Colors.green,
              ),
              _FilterChip(
                label: 'Brand Partners',
                selected: _selectedTypeFilter == 8,
                onTap: () => _onFilterChanged(8),
                dotColor: Colors.purple,
              ),
              _FilterChip(
                label: 'Reported Chats',
                selected: _selectedTypeFilter == 13,
                onTap: () => _onFilterChanged(13),
                dotColor: Colors.red,
              ),
            ],
          ),
        ),
        if (_summaryUnread > 0)
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, size: 16),
            label: Text(
              'Mark all read',
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Notification list ──────────────────────────────────────────

  Widget _buildNotificationList(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load notifications',
        subtitle: _error!,
      );
    }

    if (_notifications.isEmpty) {
      return const _EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'No notifications yet',
        subtitle:
            'You\'ll see notifications here when users submit trailer makes, contact forms, brand partner requests, or chat reports.',
      );
    }

    return Column(
      children: [
        ..._notifications
            .map((n) => _NotificationTile(
                  notification: n,
                  onMarkRead: () => _markOneRead(n),
                  onDelete: () => _deleteOne(n),
                ))
            .toList(),
        const SizedBox(height: 16),
        _PaginationFooter(
          total: _totalCount,
          page: _page,
          pageCount: (_totalCount / _pageSize).ceil().clamp(1, 999999),
          pageSize: _pageSize,
          onPageSizeChanged: (size) {
            setState(() {
              _pageSize = size;
              _page = 0;
            });
            _fetchData();
          },
          onPrev: _page > 0
              ? () {
                  setState(() => _page--);
                  _fetchData();
                }
              : null,
          onNext:
              (_page + 1) * _pageSize < _totalCount
                  ? () {
                      setState(() => _page++);
                      _fetchData();
                    }
                  : null,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═════════════════════════════════════════════════════════════════════

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  const _SummaryTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colors.foreground,
                  ),
                ),
                Text(
                  label,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? theme.colors.primary.withValues(alpha: 0.1)
              : theme.colors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.colors.primary : theme.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.typography.sm.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? theme.colors.primary
                    : theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AdminNotificationData notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  Color _typeColor() => switch (notification.type) {
        10 => Colors.blue,
        11 => Colors.green,
        8 => Colors.purple,
        13 => Colors.red,
        _ => Colors.grey,
      };

  IconData _typeIcon() => switch (notification.type) {
        10 => Icons.precision_manufacturing_outlined,
        11 => Icons.mail_outline,
        8 => Icons.handshake_outlined,
        13 => Icons.report_outlined,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = _typeColor();
    final isUnread = notification.isUnread;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isUnread
            ? color.withValues(alpha: 0.04)
            : theme.colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnread
              ? color.withValues(alpha: 0.25)
              : theme.colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onMarkRead,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Unread dot ──
                if (isUnread)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 16),

                // ── Avatar / icon ──
                _buildAvatar(context, color),
                const SizedBox(width: 12),

                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row: category badge + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.categoryLabel,
                              style: theme.typography.xs.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(notification.createdAt),
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Submitter identity — the key info
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14,
                              color: theme.colors.mutedForeground),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              notification.submitterDisplay,
                              style: theme.typography.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colors.foreground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (notification.email.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.email_outlined,
                                size: 13,
                                color: theme.colors.mutedForeground),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                notification.email,
                                style: theme.typography.xs.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        notification.description,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ── Actions ──
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert,
                      size: 18, color: theme.colors.mutedForeground),
                  onSelected: (value) {
                    if (value == 'read') onMarkRead();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (isUnread)
                      const PopupMenuItem(
                          value: 'read', child: Text('Mark as read')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Color color) {
    final hasImage = notification.submitterImage != null &&
        notification.submitterImage!.isNotEmpty;

    if (hasImage) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(notification.submitterImage!),
        onBackgroundImageError: (_, __) {},
        backgroundColor: color.withValues(alpha: 0.12),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(_typeIcon(), size: 18, color: color),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$m/$d/${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colors.mutedForeground),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 360,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.total,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.onPageSizeChanged,
    required this.onPrev,
    required this.onNext,
  });

  final int total;
  final int page;
  final int pageCount;
  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final start = total == 0 ? 0 : (page * pageSize + 1);
    final end =
        total == 0 ? 0 : ((page * pageSize + pageSize).clamp(0, total));
    final label = 'Showing $start\u2013$end of $total';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colors.border.withValues(alpha: 0.9)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: theme.colors.mutedForeground)),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSize,
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 / page')),
                    DropdownMenuItem(value: 25, child: Text('25 / page')),
                    DropdownMenuItem(value: 50, child: Text('50 / page')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    onPageSizeChanged(v);
                  },
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: theme.colors.border.withValues(alpha: 0.8)),
                ),
                child: Text(
                  'Page ${page + 1} of $pageCount',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: theme.colors.foreground),
                ),
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor:
                      theme.colors.muted.withValues(alpha: 0.25),
                  foregroundColor: theme.colors.foreground,
                ),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor:
                      theme.colors.muted.withValues(alpha: 0.25),
                  foregroundColor: theme.colors.foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
