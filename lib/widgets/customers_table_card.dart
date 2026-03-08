import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:trailerhustle_admin/models/user_data.dart';
import 'package:trailerhustle_admin/services/file_export_service.dart';
import 'package:trailerhustle_admin/services/trailer_service.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:trailerhustle_admin/widgets/user_profile_dialog.dart';

/// Admin dashboard card that lists businesses with search, filters, actions and export.
class CustomersTableCard extends StatefulWidget {
  const CustomersTableCard({super.key});

  @override
  State<CustomersTableCard> createState() => _CustomersTableCardState();
}

class _CustomersTableCardState extends State<CustomersTableCard> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<UserData> _all = const [];
  Map<int, int> _trailerCounts = const {};

  int _subscriptionFilter = 0; // 0 all, 1 subscribed, 2 not
  int _activeFilter = 0; // 0 all, 1 active, 2 inactive
  int _hustleProFilter = 0; // 0 all, 1 featured, 2 not
  int _sortMode = 0; // 0 default, 1 trailers desc

  String _categoryFilter = 'All';

  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (!mounted) return;
      setState(() {
        _page = 0;
      });
    });
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await UserService.fetchCustomers();
      // Try to batch-load trailer counts for the businesses in the list.
      // This is best-effort; the table still renders even if this fails.
      Map<int, int> trailerCounts = const {};
      try {
        final businessIds = list.map((u) => int.tryParse(u.id)).whereType<int>().toList(growable: false);
        trailerCounts = await TrailerService.fetchTrailerCountsForBusinesses(businessIds: businessIds);
      } catch (e) {
        debugPrint('CustomersTableCard trailer count refresh failed: $e');
      }
      if (!mounted) return;
      setState(() {
        _all = list;
        _trailerCounts = trailerCounts;

        // Keep the selected category stable, but if it no longer exists, reset.
        final options = _categoryOptionsFrom(list);
        if (_categoryFilter != 'All' && !options.contains(_categoryFilter)) {
          _categoryFilter = 'All';
          _page = 0;
        }
      });
    } catch (e) {
      debugPrint('CustomersTableCard refresh failed: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _categoryOptionsFrom(List<UserData> list) {
    final set = <String>{};
    for (final u in list) {
      final v = u.categoryType.trim();
      if (v.isNotEmpty) set.add(v);
    }
    final options = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return options;
  }

  List<String> get _categoryOptions => _categoryOptionsFrom(_all);

  List<UserData> get _filtered {
    final q = _search.text.trim().toLowerCase();
    bool match(UserData u) {
      if (_subscriptionFilter == 1 && !u.isSubscribed) return false;
      if (_subscriptionFilter == 2 && u.isSubscribed) return false;
      if (_activeFilter == 1 && !u.isActive) return false;
      if (_activeFilter == 2 && u.isActive) return false;
      if (_hustleProFilter == 1 && !u.hasHustleProPlan) return false;
      if (_hustleProFilter == 2 && u.hasHustleProPlan) return false;
      if (_categoryFilter != 'All') {
        if (u.categoryType.trim().toLowerCase() != _categoryFilter.toLowerCase()) return false;
      }
      if (q.isEmpty) return true;
      return u.id.toLowerCase().contains(q) ||
          u.customerNumber.toLowerCase().contains(q) ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q);
    }

    return _all.where(match).toList(growable: false);
  }

  int _trailerCountForUser(UserData u) {
    final businessId = int.tryParse(u.id);
    if (businessId == null) return 0;
    return _trailerCounts[businessId] ?? 0;
  }

  List<UserData> _applySort(List<UserData> list) {
    if (_sortMode == 0) return list;
    final sorted = List<UserData>.of(list);
    sorted.sort((a, b) {
      final byTrailers = _trailerCountForUser(b).compareTo(_trailerCountForUser(a));
      if (byTrailers != 0) return byTrailers;
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  int _pageCountFor(int total) {
    if (total <= 0) return 1;
    return (total / _pageSize).ceil().clamp(1, 999999);
  }

  List<UserData> _pageSlice(List<UserData> list) {
    // Be defensive: page can briefly go negative when state changes quickly.
    // Never allow a negative index into sublist.
    final safePage = _page < 0 ? 0 : _page;
    final start = safePage * _pageSize;
    if (start >= list.length) return const [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  void _ensurePageInRange({required int total}) {
    final maxPage = _pageCountFor(total) - 1;
    if (_page >= 0 && _page <= maxPage) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final clamped = _page.clamp(0, maxPage.clamp(0, 999999));
      setState(() => _page = clamped);
    });
  }

  String _toCsv(List<List<String>> rows) {
    String esc(String v) {
      final s = v.replaceAll('"', '""');
      return s.contains(',') || s.contains('\n') || s.contains('\r') || s.contains('"') ? '"$s"' : s;
    }

    return rows.map((r) => r.map(esc).join(',')).join('\n');
  }

  String _formatCreatedOn(DateTime dt) {
    // `UserData` defaults to epoch when the backend value is missing.
    if (dt.millisecondsSinceEpoch == 0) return '—';
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _exportExcelCsv() async {
    final list = _applySort(_filtered);
    final rows = <List<String>>[
      ['ID', 'Business ID', 'Name', 'Category Type', 'Email', 'Phone', 'Created on Date', 'Trailers', 'Subscribed', 'Active', 'Is Featured'],
      ...list.map(
        (u) => [
          u.id,
          u.customerNumber,
          u.name,
          u.categoryType.trim().isEmpty ? '—' : u.categoryType.trim(),
          u.email,
          u.phone,
          _formatCreatedOn(u.createdAt),
          '${_trailerCountForUser(u)}',
          u.isSubscribed ? 'Yes' : 'No',
          u.isActive ? 'Active' : 'Inactive',
          u.hasHustleProPlan ? 'Yes' : 'No',
        ],
      ),
    ];

    final csv = _toCsv(rows);
    await FileExportService.downloadCsv(filename: 'businesses_${DateTime.now().toUtc().toIso8601String()}.csv', csv: csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported businesses to CSV.')));
  }

  Future<void> _exportPdf() async {
    final list = _applySort(_filtered);
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text('Businesses', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const ['ID', 'Business ID', 'Name', 'Category', 'Email', 'Created on', 'Trailers', 'Subscribed', 'Status', 'Is Featured'],
              data: list
                  .map(
                    (u) => [
                      u.id,
                      u.customerNumber,
                      u.name,
                      u.categoryType.trim().isEmpty ? '—' : u.categoryType.trim(),
                      u.email,
                      _formatCreatedOn(u.createdAt),
                      '${_trailerCountForUser(u)}',
                      u.isSubscribed ? 'Subscribed' : 'Not subscribed',
                      u.isActive ? 'Active' : 'Inactive',
                      u.hasHustleProPlan ? 'Yes' : 'No',
                    ],
                  )
                  .toList(growable: false),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 18,
              columnWidths: const {
                0: pw.FlexColumnWidth(1.0),
                1: pw.FlexColumnWidth(1.1),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.1),
                4: pw.FlexColumnWidth(1.8),
                5: pw.FlexColumnWidth(1.0),
                6: pw.FlexColumnWidth(0.7),
                7: pw.FlexColumnWidth(1.0),
                8: pw.FlexColumnWidth(1.0),
                9: pw.FlexColumnWidth(0.9),
              },
            ),
          ];
        },
      ),
    );

    // On web this opens the print dialog, allowing “Save as PDF”.
    // On mobile/desktop this also supports saving/sharing depending on platform.
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Color _chipBg(BuildContext context, Color base) =>
      base.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.14);

  Widget _pill({required BuildContext context, required String text, required Color color}) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBg(context, color),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.7)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.foreground),
      ),
    );
  }

  Future<void> _openEdit(UserData user) async {
    final name = TextEditingController(text: user.name);
    final email = TextEditingController(text: user.email);
    final phone = TextEditingController(text: user.phone);
    var isActive = user.isActive;
    var isSubscribed = user.isSubscribed;
    var hustlePro = user.hasHustleProPlan;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = context.theme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 12,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  Future<void> save() async {
                    if (saving) return;
                    setSheetState(() => saving = true);
                    try {
                      final updated = user.copyWith(
                        name: name.text.trim(),
                        email: email.text.trim(),
                        phone: phone.text.trim(),
                        isActive: isActive,
                        isSubscribed: isSubscribed,
                        hasHustleProPlan: hustlePro,
                        updatedAt: DateTime.now().toUtc(),
                      );
                      await UserService.updateUser(updated);
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      await _refresh();
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Business updated.')));
                    } catch (e) {
                      debugPrint('Failed to update business: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                    } finally {
                      if (mounted) setSheetState(() => saving = false);
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Edit business',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(FIcons.x),
                            iconSize: 16,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(38, 38),
                              padding: EdgeInsets.zero,
                              foregroundColor: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user.id}  •  Business ID: ${user.customerNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.colors.mutedForeground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                      const SizedBox(height: 10),
                      TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 10),
                      TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colors.muted.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colors.border),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              value: isActive,
                              onChanged: saving ? null : (v) => setSheetState(() => isActive = v),
                              title: const Text('Account active'),
                               subtitle: const Text('If off, the business is deactivated.'),
                            ),
                            SwitchListTile.adaptive(
                              value: isSubscribed,
                              onChanged: saving ? null : (v) => setSheetState(() => isSubscribed = v),
                              title: const Text('Subscribed'),
                               subtitle: const Text('Mark whether the business has an active subscription.'),
                            ),
                            SwitchListTile.adaptive(
                              value: hustlePro,
                              onChanged: saving ? null : (v) => setSheetState(() => hustlePro = v),
                              title: const Text('Hustle Pro plan enabled'),
                              subtitle: const Text('Feature access flag (Hustle Pro Plan).'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: saving ? null : save,
                          icon: Icon(Icons.save_outlined, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                          label: Text(saving ? 'Saving…' : 'Save changes', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    name.dispose();
    email.dispose();
    phone.dispose();
  }

  DataRow _rowFor(BuildContext context, UserData u) {
    final theme = context.theme;
    TextStyle? cellStyle({bool muted = false}) => Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: muted ? theme.colors.mutedForeground : theme.colors.foreground);

    final businessId = int.tryParse(u.id);
    final trailerCount = businessId == null ? null : _trailerCounts[businessId];

    return DataRow(
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: u.id,
                    child: Text(
                      u.id.isEmpty ? '—' : u.id,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy ID',
                  onPressed: u.id.trim().isEmpty
                      ? null
                      : () async {
                          try {
                            await Clipboard.setData(ClipboardData(text: u.id));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied ID.')));
                          } catch (e) {
                            debugPrint('Failed to copy business id: $e');
                          }
                        },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                    foregroundColor: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  u.avatar,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    color: theme.colors.muted.withValues(alpha: 0.35),
                    child: Icon(Icons.person_outline, size: 18, color: theme.colors.mutedForeground),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name.isEmpty ? '—' : u.name, style: cellStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(u.customerNumber, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.colors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
            child: Text(u.email.isEmpty ? '—' : u.email, style: cellStyle(muted: true), overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 170, maxWidth: 220),
            child: Text(
              u.categoryType.trim().isEmpty ? '—' : u.categoryType.trim(),
              style: cellStyle(muted: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(_formatCreatedOn(u.createdAt), style: cellStyle(muted: true))),
        DataCell(
          Text(
            trailerCount?.toString() ?? '—',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: trailerCount == null ? theme.colors.mutedForeground : theme.colors.primary,
              fontWeight: FontWeight.w800,
              decoration: trailerCount == null ? null : TextDecoration.underline,
              decorationColor: theme.colors.primary.withValues(alpha: 0.55),
            ),
          ),
          onTap: trailerCount == null ? null : () => UserProfileDialog.show(context, user: u, initialTabIndex: 1),
        ),
        DataCell(
          _pill(
            context: context,
            text: u.isSubscribed ? 'Subscribed' : 'Not subscribed',
            color: u.isSubscribed ? theme.colors.primary : theme.colors.mutedForeground,
          ),
        ),
        DataCell(
          _pill(
            context: context,
            text: u.isActive ? 'Active' : 'Inactive',
            color: u.isActive ? theme.colors.secondary : theme.colors.destructive,
          ),
        ),
        DataCell(
          _pill(
            context: context,
            text: u.hasHustleProPlan ? 'Yes' : 'No',
            color: u.hasHustleProPlan ? Colors.green : Colors.red,
          ),
        ),
        DataCell(
          Wrap(
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'View',
                onPressed: () => UserProfileDialog.show(context, user: u),
                icon: const Icon(Icons.visibility_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colors.muted.withValues(alpha: 0.25),
                  foregroundColor: theme.colors.foreground,
                  padding: const EdgeInsets.all(10),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _openEdit(u),
                icon: const Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colors.primary.withValues(alpha: 0.14),
                  foregroundColor: theme.colors.primary,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final filtered = _applySort(_filtered);
    _ensurePageInRange(total: filtered.length);
    final pageCount = _pageCountFor(filtered.length);
    final pageItems = _pageSlice(filtered);

    final categories = _categoryOptions;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FIcons.users, size: 16, color: theme.colors.foreground),
                const SizedBox(width: 8),
                Expanded(child: Text('Businesses', style: Theme.of(context).textTheme.titleMedium)),
                Text('${filtered.length}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground)),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      hintText: 'Name, email, phone, business ID, record ID…',
                      prefixIcon: Icon(Icons.search_outlined),
                    ),
                  ),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All subs')),
                    ButtonSegment(value: 1, label: Text('Subscribed')),
                    ButtonSegment(value: 2, label: Text('Not')),
                  ],
                  selected: {_subscriptionFilter},
                  onSelectionChanged: _loading
                      ? null
                      : (s) => setState(() {
                          _subscriptionFilter = s.first;
                          _page = 0;
                        }),
                ),
                if (categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.colors.border.withValues(alpha: 0.8)),
                      color: theme.colors.muted.withValues(alpha: 0.10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoryFilter,
                        borderRadius: BorderRadius.circular(14),
                        icon: Icon(Icons.expand_more, color: theme.colors.mutedForeground),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.foreground),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All categories')),
                          ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: _loading
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() {
                                  _categoryFilter = v;
                                  _page = 0;
                                });
                              },
                      ),
                    ),
                  ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All status')),
                    ButtonSegment(value: 1, label: Text('Active')),
                    ButtonSegment(value: 2, label: Text('Inactive')),
                  ],
                  selected: {_activeFilter},
                  onSelectionChanged: _loading
                      ? null
                      : (s) => setState(() {
                          _activeFilter = s.first;
                          _page = 0;
                        }),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All featured')),
                    ButtonSegment(value: 1, label: Text('Yes')),
                    ButtonSegment(value: 2, label: Text('No')),
                  ],
                  selected: {_hustleProFilter},
                  onSelectionChanged: _loading
                      ? null
                      : (s) => setState(() {
                          _hustleProFilter = s.first;
                          _page = 0;
                        }),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Default order')),
                    ButtonSegment(value: 1, label: Text('Most trailers')),
                  ],
                  selected: {_sortMode},
                  onSelectionChanged: _loading
                      ? null
                      : (s) => setState(() {
                          _sortMode = s.first;
                          _page = 0;
                        }),
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: filtered.isEmpty || _loading ? null : _exportExcelCsv,
                  icon: Icon(Icons.table_view_outlined, size: 18, color: theme.colors.foreground),
                  label: Text('Export to Excel', style: TextStyle(color: theme.colors.foreground)),
                ),
                FilledButton.icon(
                  onPressed: filtered.isEmpty || _loading ? null : _exportPdf,
                  icon: Icon(Icons.picture_as_pdf_outlined, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                  label: Text('Export PDF', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_error != null) _DashboardErrorCallout(message: _error!),
            if (_loading && _all.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No businesses found.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground)),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: theme.colors.border.withValues(alpha: 0.7),
                        dataTableTheme: DataTableThemeData(
                          headingRowColor: WidgetStatePropertyAll(theme.colors.muted.withValues(alpha: 0.55)),
                          headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: theme.colors.foreground),
                          dataTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.foreground),
                          horizontalMargin: 16,
                          columnSpacing: 18,
                          dividerThickness: 0.7,
                          dataRowMinHeight: 62,
                          dataRowMaxHeight: 82,
                          headingRowHeight: 46,
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1700),
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Business')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Category Type')),
                              DataColumn(label: Text('Created on Date')),
                              DataColumn(label: Text('Trailers')),
                              DataColumn(label: Text('Subscription')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Is Featured?')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: pageItems.map((u) => _rowFor(context, u)).toList(growable: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PaginationFooter(
                    total: filtered.length,
                    page: _page,
                    pageCount: pageCount,
                    pageSize: _pageSize,
                    onPageSizeChanged: (v) => setState(() {
                      _pageSize = v;
                      _page = 0;
                    }),
                    onPrev: _page <= 0
                        ? null
                        : () => setState(() {
                            _page = (_page - 1).clamp(0, 999999);
                          }),
                    onNext: _page >= pageCount - 1
                        ? null
                        : () => setState(() {
                            _page += 1;
                          }),
                  ),
                ],
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
    final end = total == 0 ? 0 : ((page * pageSize + pageSize).clamp(0, total));
    final label = 'Showing $start–$end of $total';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.9)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border.withValues(alpha: 0.8)),
                ),
                child: Text('Page ${page + 1} of $pageCount', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.foreground)),
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colors.muted.withValues(alpha: 0.25),
                  foregroundColor: theme.colors.foreground,
                ),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colors.muted.withValues(alpha: 0.25),
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

class _DashboardErrorCallout extends StatelessWidget {
  const _DashboardErrorCallout({required this.message});

  final String message;

  bool get _looksLikeMissingBusinessesTable {
    final s = message.toLowerCase();
    return (s.contains('businesses') || s.contains('public.businesses')) &&
        (s.contains('could not find the table') || s.contains('schema cache') || s.contains('does not exist'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final title = _looksLikeMissingBusinessesTable ? 'Database access required' : 'Couldn\'t load businesses';
    final detail = _looksLikeMissingBusinessesTable
        ? "Your Supabase project doesn't expose the `Businesses` table to this app (or RLS is blocking it).\n\nFix: verify the exact table name in Supabase is `Businesses`, then ensure your logged-in admin user has SELECT permissions via RLS policies.\n\nAfter fixing, press Refresh."
        : message;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.destructive.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colors.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                SelectableText(detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.colors.mutedForeground, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
