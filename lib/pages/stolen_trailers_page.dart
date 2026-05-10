import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/auth/auth_controller.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/models/stolen_report_data.dart';
import 'package:trailerhustle_admin/pages/stolen_zones_map_page.dart';
import 'package:trailerhustle_admin/services/sidebar_controller.dart';
import 'package:trailerhustle_admin/services/stolen_report_service.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/widgets/adaptive_sidebar.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';

class StolenTrailersPage extends StatefulWidget {
  const StolenTrailersPage({super.key});

  @override
  State<StolenTrailersPage> createState() => _StolenTrailersPageState();
}

class _StolenTrailersPageState extends State<StolenTrailersPage> {
  // Data
  List<StolenReportData> _reports = [];
  Map<String, int> _statusCounts = {};
  bool _loading = true;
  String? _error;

  // Filters
  StolenStatusFilter _statusFilter = StolenStatusFilter.pending;
  final TextEditingController _searchCtl = TextEditingController();

  // Pagination
  int _page = 0;
  final int _pageSize = 25;
  int _totalCount = 0;

  // Action progress
  final Set<int> _busyReportIds = {};

  // Cached resolved admin id (Users.id by email)
  int? _adminUserId;
  String? _adminLookupEmail;

  // Realtime
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = StolenReportService.subscribeToChanges(
      onChanged: () => _fetchData(),
    );
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    if (_channel != null) {
      SupabaseConfig.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<int?> _resolveAdminId() async {
    if (!mounted) return null;
    final auth = context.read<AuthController>();
    final email = auth.user?.email;
    if (email == null) return null;
    if (_adminUserId != null && _adminLookupEmail == email) return _adminUserId;
    try {
      final row = await SupabaseConfig.client
          .from('Users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      _adminLookupEmail = email;
      _adminUserId = row?['id'] as int?;
      return _adminUserId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _loading = _reports.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([
        StolenReportService.fetchPaginated(
          status: _statusFilter,
          page: _page,
          pageSize: _pageSize,
          search: _searchCtl.text.trim(),
        ),
        StolenReportService.fetchStatusCounts(),
      ]);
      final paginated = results[0]
          as ({List<StolenReportData> items, int total});
      final counts = results[1] as Map<String, int>;
      if (!mounted) return;
      setState(() {
        _reports = paginated.items;
        _totalCount = paginated.total;
        _statusCounts = counts;
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

  void _onFilterChanged(StolenStatusFilter f) {
    if (_statusFilter == f) return;
    setState(() {
      _statusFilter = f;
      _page = 0;
    });
    _fetchData();
  }

  Future<void> _approve(StolenReportData r) async {
    if (_busyReportIds.contains(r.id)) return;
    final adminNoteCtl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve stolen trailer report?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Approving will mark trailer #${r.trailerId} (${r.displayName}) as stolen. After approval, you\'ll draw alert zones on a map; the push goes out only after you confirm the zones.'),
            const SizedBox(height: 12),
            TextField(
              controller: adminNoteCtl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Admin note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final adminId = await _resolveAdminId();
    if (adminId == null) {
      _snack('Could not resolve admin user id');
      return;
    }
    if (!mounted) return;
    setState(() => _busyReportIds.add(r.id));
    try {
      final approved = await StolenReportService.approve(
        reportId: r.id,
        adminUserId: adminId,
        adminNote: adminNoteCtl.text,
      );
      if (approved == null) {
        _snack('Approve failed (report may have already been moderated)');
        return;
      }
      if (!mounted) return;
      final fired = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              StolenZonesMapPage(report: approved, justApproved: true),
          settings: const RouteSettings(name: 'stolen_zones_map'),
        ),
      );
      if (fired != true) {
        _snack(
            'Approved. Push not sent yet — use "Send geofence push" on the row to send it later.');
      }
      await _fetchData();
    } finally {
      if (mounted) setState(() => _busyReportIds.remove(r.id));
    }
  }

  Future<void> _reject(StolenReportData r) async {
    if (_busyReportIds.contains(r.id)) return;
    final adminNoteCtl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject stolen trailer report?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will mark report #${r.id} as rejected and notify the reporter.'),
            const SizedBox(height: 12),
            TextField(
              controller: adminNoteCtl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason (optional, sent to reporter)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final adminId = await _resolveAdminId();
    if (adminId == null) {
      _snack('Could not resolve admin user id');
      return;
    }
    if (!mounted) return;
    setState(() => _busyReportIds.add(r.id));
    try {
      final ok = await StolenReportService.reject(
        reportId: r.id,
        adminUserId: adminId,
        adminNote: adminNoteCtl.text,
      );
      _snack(ok ? 'Report rejected' : 'Reject failed');
      if (ok) await _fetchData();
    } finally {
      if (mounted) setState(() => _busyReportIds.remove(r.id));
    }
  }

  Future<void> _markRetrieved(StolenReportData r) async {
    if (_busyReportIds.contains(r.id)) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark trailer as retrieved?'),
        content: Text(
            'This clears the public stolen flag for ${r.displayName} and notifies the reporter.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark retrieved'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final adminId = await _resolveAdminId();
    if (adminId == null) {
      _snack('Could not resolve admin user id');
      return;
    }
    if (!mounted) return;
    setState(() => _busyReportIds.add(r.id));
    try {
      final ok = await StolenReportService.markRetrieved(
        reportId: r.id,
        adminUserId: adminId,
      );
      _snack(ok ? 'Marked as retrieved' : 'Could not mark as retrieved');
      if (ok) await _fetchData();
    } finally {
      if (mounted) setState(() => _busyReportIds.remove(r.id));
    }
  }

  Future<void> _resendNearbyPush(StolenReportData r) async {
    if (_busyReportIds.contains(r.id)) return;
    if (!mounted) return;
    setState(() => _busyReportIds.add(r.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              StolenZonesMapPage(report: r, justApproved: false),
          settings: const RouteSettings(name: 'stolen_zones_map_resend'),
        ),
      );
      await _fetchData();
    } finally {
      if (mounted) setState(() => _busyReportIds.remove(r.id));
    }
  }

  void _showDetails(StolenReportData r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report #${r.id} · ${r.displayName}'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Status', r.statusLabel),
                _kv('Trailer ID', '${r.trailerId}'),
                _kv('Reporter (Business id)', '${r.reporterId}'),
                _kv('VIN', r.vin ?? '—'),
                _kv('Type', r.trailerType ?? '—'),
                _kv('Manufacturer', r.manufacturer ?? '—'),
                _kv('Color', r.color ?? '—'),
                _kv('Plate', r.plate ?? '—'),
                _kv('Stolen at', r.stolenAt?.toLocal().toString() ?? '—'),
                _kv('Stolen location', r.stolenLocation ?? '—'),
                _kv(
                  'Coordinates',
                  (r.stolenLat != null && r.stolenLng != null)
                      ? '${r.stolenLat!.toStringAsFixed(5)}, ${r.stolenLng!.toStringAsFixed(5)}'
                      : '—',
                ),
                _kv(
                  'Reward',
                  (r.rewardAmount ?? 0) > 0
                      ? '${r.rewardCurrency ?? 'USD'} ${r.rewardAmount!.toStringAsFixed(0)}'
                      : '—',
                ),
                _kv('Contact', r.contactName ?? '—'),
                _kv('Email', r.contactEmail ?? '—'),
                _kv('Phone', r.contactPhone ?? '—'),
                _kv('Additional info', r.additionalInfo ?? '—'),
                _kv('Admin note', r.adminNote ?? '—'),
                _kv('Submitted', r.createdAt.toLocal().toString()),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(k,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _toggleSidebar() => context.read<SidebarController>().toggle();

  @override
  Widget build(BuildContext context) {
    final isMobile =
        context.theme.breakpoints.md > MediaQuery.of(context).size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    context.read<SidebarController>().autoCollapseIfNeeded(screenWidth);

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
          if (!isMobile) const AdaptiveSidebar(),
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
                            pageTitle: 'Stolen trailers',
                            onSidebarToggle:
                                isMobile ? null : _toggleSidebar,
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
                                _buildSummaryRow(context),
                                const SizedBox(height: 20),
                                _buildToolbar(context),
                                const SizedBox(height: 16),
                                _buildList(context),
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

  Widget _buildSummaryRow(BuildContext context) {
    final tiles = [
      _SummaryTile(
        icon: Icons.hourglass_top_outlined,
        iconColor: Colors.deepOrange,
        label: 'Pending',
        count: _statusCounts['pending'] ?? 0,
      ),
      _SummaryTile(
        icon: Icons.warning_amber_outlined,
        iconColor: Colors.red,
        label: 'Approved (active)',
        count: _statusCounts['approved'] ?? 0,
      ),
      _SummaryTile(
        icon: Icons.task_alt_outlined,
        iconColor: Colors.green,
        label: 'Retrieved',
        count: _statusCounts['retrieved'] ?? 0,
      ),
      _SummaryTile(
        icon: Icons.block_outlined,
        iconColor: Colors.grey,
        label: 'Rejected',
        count: _statusCounts['rejected'] ?? 0,
      ),
      _SummaryTile(
        icon: Icons.cancel_outlined,
        iconColor: Colors.blueGrey,
        label: 'Cancelled by user',
        count: _statusCounts['cancelled'] ?? 0,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        if (isMobile) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tiles
                .map((c) => SizedBox(
                    width: (constraints.maxWidth - 8) / 2, child: c))
                .toList(),
          );
        }
        return Row(
          children: tiles
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatusChip(
            label: 'Pending',
            selected: _statusFilter == StolenStatusFilter.pending,
            onTap: () => _onFilterChanged(StolenStatusFilter.pending),
            dotColor: Colors.deepOrange),
        _StatusChip(
            label: 'Approved',
            selected: _statusFilter == StolenStatusFilter.approved,
            onTap: () => _onFilterChanged(StolenStatusFilter.approved),
            dotColor: Colors.red),
        _StatusChip(
            label: 'Retrieved',
            selected: _statusFilter == StolenStatusFilter.retrieved,
            onTap: () => _onFilterChanged(StolenStatusFilter.retrieved),
            dotColor: Colors.green),
        _StatusChip(
            label: 'Rejected',
            selected: _statusFilter == StolenStatusFilter.rejected,
            onTap: () => _onFilterChanged(StolenStatusFilter.rejected),
            dotColor: Colors.grey),
        _StatusChip(
            label: 'Cancelled',
            selected: _statusFilter == StolenStatusFilter.cancelled,
            onTap: () => _onFilterChanged(StolenStatusFilter.cancelled),
            dotColor: Colors.blueGrey),
        _StatusChip(
            label: 'All',
            selected: _statusFilter == StolenStatusFilter.all,
            onTap: () => _onFilterChanged(StolenStatusFilter.all)),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
          child: TextField(
            controller: _searchCtl,
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Trailer name, VIN, plate, contact…',
              prefixIcon: Icon(Icons.search_outlined),
              isDense: true,
            ),
            onSubmitted: (_) {
              setState(() => _page = 0);
              _fetchData();
            },
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _fetchData,
          icon: const Icon(Icons.refresh_outlined),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load reports',
        subtitle: _error!,
      );
    }
    if (_reports.isEmpty) {
      return const _EmptyState(
        icon: Icons.warning_amber_outlined,
        title: 'No reports in this view',
        subtitle: 'When users submit stolen trailer reports, they appear here.',
      );
    }
    return Column(
      children: [
        ..._reports.map((r) => _ReportRow(
              report: r,
              busy: _busyReportIds.contains(r.id),
              onView: () => _showDetails(r),
              onApprove: r.isPending ? () => _approve(r) : null,
              onReject: r.isPending ? () => _reject(r) : null,
              onMarkRetrieved: r.isApproved ? () => _markRetrieved(r) : null,
              onResendPush:
                  r.isApproved ? () => _resendNearbyPush(r) : null,
            )),
        const SizedBox(height: 12),
        _Pagination(
          total: _totalCount,
          page: _page,
          pageSize: _pageSize,
          onPrev: _page > 0
              ? () {
                  setState(() => _page--);
                  _fetchData();
                }
              : null,
          onNext: (_page + 1) * _pageSize < _totalCount
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

// ─── Private widgets ─────────────────────────────────────────────────────

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
                Text('$count',
                    style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colors.foreground)),
                Text(label,
                    style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;
  const _StatusChip({
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
              color:
                  selected ? theme.colors.primary : theme.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: theme.typography.sm.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? theme.colors.primary
                        : theme.colors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final StolenReportData report;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onMarkRetrieved;
  final VoidCallback? onResendPush;

  const _ReportRow({
    required this.report,
    required this.busy,
    required this.onView,
    this.onApprove,
    this.onReject,
    this.onMarkRetrieved,
    this.onResendPush,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colors.border.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: report.status),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '#${report.id} · ${report.displayName}',
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatRelative(report.createdAt),
                  style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _kv(context, 'VIN', report.vin),
                _kv(context, 'Plate', report.plate),
                _kv(context, 'Color', report.color),
                _kv(context, 'Type', report.trailerType),
                _kv(context, 'Where',
                    report.stolenLocation ?? _coords(report)),
                _kv(
                  context,
                  'Reward',
                  (report.rewardAmount ?? 0) > 0
                      ? '${report.rewardCurrency ?? 'USD'} ${report.rewardAmount!.toStringAsFixed(0)}'
                      : null,
                ),
                _kv(context, 'Reporter', report.contactName),
              ],
            ),
            if ((report.additionalInfo ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(report.additionalInfo!,
                  style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                ),
                if (onApprove != null)
                  FilledButton.icon(
                    onPressed: busy ? null : onApprove,
                    icon: busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                  ),
                if (onReject != null)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onReject,
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.red)),
                  ),
                if (onMarkRetrieved != null)
                  FilledButton.icon(
                    onPressed: busy ? null : onMarkRetrieved,
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.task_alt, size: 16),
                    label: const Text('Mark retrieved'),
                  ),
                if (onResendPush != null)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onResendPush,
                    icon: const Icon(Icons.campaign_outlined, size: 16),
                    label: const Text('Resend nearby push'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _coords(StolenReportData r) {
    if (r.stolenLat == null || r.stolenLng == null) return null;
    return '${r.stolenLat!.toStringAsFixed(4)}, ${r.stolenLng!.toStringAsFixed(4)}';
  }

  String _formatRelative(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${(d.inDays / 30).floor()}mo ago';
  }

  Widget _kv(BuildContext context, String k, String? v) {
    if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
    final theme = context.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ',
            style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
                fontWeight: FontWeight.w500)),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(v,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.sm.copyWith(
                  color: theme.colors.foreground)),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('PENDING', Colors.deepOrange),
      'approved' => ('APPROVED', Colors.red),
      'retrieved' => ('RETRIEVED', Colors.green),
      'rejected' => ('REJECTED', Colors.grey),
      'cancelled' => ('CANCELLED', Colors.blueGrey),
      _ => (status.toUpperCase(), Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int total;
  final int page;
  final int pageSize;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pagination({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final from = total == 0 ? 0 : page * pageSize + 1;
    final to = ((page + 1) * pageSize).clamp(0, total);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$from–$to of $total',
            style: context.theme.typography.sm
                .copyWith(color: context.theme.colors.mutedForeground)),
        const SizedBox(width: 12),
        IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left)),
        IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: context.theme.colors.mutedForeground),
            const SizedBox(height: 12),
            Text(title,
                style: context.theme.typography.base
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
