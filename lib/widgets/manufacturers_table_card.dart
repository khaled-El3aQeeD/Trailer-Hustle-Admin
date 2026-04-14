import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/brand_data.dart';
import 'package:trailerhustle_admin/services/brand_service.dart';

class ManufacturersTableCard extends StatefulWidget {
  const ManufacturersTableCard({super.key});

  @override
  State<ManufacturersTableCard> createState() => _ManufacturersTableCardState();
}

class _ManufacturersTableCardState extends State<ManufacturersTableCard> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<BrandData> _all = const [];
  final Set<int> _updating = <int>{};

  _ManufacturerStatusFilter _statusFilter = _ManufacturerStatusFilter.all;
  int _page = 0;
  int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (!mounted) return;
      setState(() => _page = 0);
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
      final brands = await BrandService.fetchAllBrands();
      if (!mounted) return;
      setState(() => _all = brands);
    } catch (e) {
      debugPrint('ManufacturersTableCard refresh failed: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _togglePublished(BrandData brand, bool nextPublished) async {
    if (_updating.contains(brand.id)) return;

    final action = nextPublished ? 'Approve' : 'Unapprove';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = context.theme;
        return AlertDialog(
          backgroundColor: theme.colors.background,
          title: Text('$action manufacturer?', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w800)),
          content: Text(
            '${brand.title.trim().isEmpty ? 'This manufacturer' : brand.title.trim()} will be marked as ${nextPublished ? 'approved (published)' : 'unapproved (hidden)'}.' ,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground, height: 1.45),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(action)),
          ],
        );
      },
    );
    if (ok != true) return;

    setState(() => _updating.add(brand.id));
    try {
      await BrandService.setBrandPublished(brandId: brand.id, isPublished: nextPublished);
      if (!mounted) return;

      // Optimistic local update so it immediately moves sections.
      setState(() {
        _all = _all
            .map((b) => b.id == brand.id ? b.copyWith(isPublished: nextPublished, updatedAt: DateTime.now().toUtc()) : b)
            .toList(growable: false);
      });
      _showSnack('${nextPublished ? 'Approved' : 'Unapproved'} ${brand.title.trim().isEmpty ? 'manufacturer' : brand.title.trim()}');
    } catch (e) {
      debugPrint('ManufacturersTableCard toggle publish failed: $e');
      if (!mounted) return;
      _showSnack('Update failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _updating.remove(brand.id));
    }
  }

  List<BrandData> get _filtered {
    final q = _search.text.trim().toLowerCase();
    final base = _all.where((b) {
      switch (_statusFilter) {
        case _ManufacturerStatusFilter.all:
          return true;
        case _ManufacturerStatusFilter.approved:
          return b.isPublished;
        case _ManufacturerStatusFilter.unapproved:
          return !b.isPublished;
      }
    });

    if (q.isEmpty) return base.toList(growable: false);
    return base.where((b) {
      if (b.id.toString().contains(q)) return true;
      if (b.title.toLowerCase().contains(q)) return true;
      return false;
    }).toList(growable: false);
  }

  void _setStatusFilter(_ManufacturerStatusFilter v) {
    if (_statusFilter == v) return;
    setState(() {
      _statusFilter = v;
      _page = 0;
    });
  }

  void _setPageSize(int v) {
    if (_pageSize == v) return;
    setState(() {
      _pageSize = v;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final filtered = _filtered;

    final approvedTotal = _all.where((b) => b.isPublished).length;
    final unapprovedTotal = _all.where((b) => !b.isPublished).length;

    final pageCount = (filtered.isEmpty) ? 1 : ((filtered.length / _pageSize).ceil().clamp(1, 999999));
    final safePage = _page.clamp(0, pageCount - 1);
    if (safePage != _page) {
      // Keep state consistent if the filter shrinks the list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _page = safePage);
      });
    }

    final start = safePage * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(start, end);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Manufacturers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colors.foreground),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colors.muted.withValues(alpha: 0.25),
                    foregroundColor: theme.colors.foreground,
                    padding: const EdgeInsets.all(10),
                  ),
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
                    decoration: const InputDecoration(labelText: 'Search', hintText: 'Manufacturer name or ID…', prefixIcon: Icon(Icons.search_outlined)),
                  ),
                ),
                _StatusFilterPill(
                  value: _statusFilter,
                  onChanged: _loading ? null : _setStatusFilter,
                ),
                _StatPill(label: 'Approved', value: '$approvedTotal', icon: Icons.verified_outlined),
                _StatPill(label: 'Unapproved', value: '$unapprovedTotal', icon: Icons.visibility_off_outlined),
                _StatPill(label: 'Matching', value: '${filtered.length}', icon: Icons.factory_outlined),
              ],
            ),
            const SizedBox(height: 10),
            if (_error != null) _ErrorCallout(message: _error!),
            if (_loading && _all.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (!_loading && filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No manufacturers found.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground)),
              )
            else ...[
              _SectionHeader(title: _statusFilter.label, count: filtered.length),
              const SizedBox(height: 10),
              _BrandsTable(
                brands: pageItems,
                updatingIds: _updating,
                onTogglePublished: (b) => _togglePublished(b, !b.isPublished),
                actionLabelFor: (b) => b.isPublished ? 'Unapprove' : 'Approve',
              ),
              const SizedBox(height: 12),
              _PaginationFooter(
                total: filtered.length,
                page: safePage,
                pageCount: pageCount,
                pageSize: _pageSize,
                onPageSizeChanged: _setPageSize,
                onPrev: safePage > 0 ? () => setState(() => _page = safePage - 1) : null,
                onNext: safePage < pageCount - 1 ? () => setState(() => _page = safePage + 1) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ManufacturerStatusFilter { all, approved, unapproved }

extension on _ManufacturerStatusFilter {
  String get label {
    switch (this) {
      case _ManufacturerStatusFilter.all:
        return 'All Manufacturers';
      case _ManufacturerStatusFilter.approved:
        return 'Approved Manufacturers';
      case _ManufacturerStatusFilter.unapproved:
        return 'Unapproved Manufacturers';
    }
  }
}

class _StatusFilterPill extends StatelessWidget {
  const _StatusFilterPill({required this.value, required this.onChanged});

  final _ManufacturerStatusFilter value;
  final ValueChanged<_ManufacturerStatusFilter>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list, size: 16, color: theme.colors.mutedForeground),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<_ManufacturerStatusFilter>(
              value: value,
              borderRadius: BorderRadius.circular(12),
              iconEnabledColor: theme.colors.mutedForeground,
              dropdownColor: theme.colors.background,
              onChanged: onChanged == null ? null : (v) => v == null ? null : onChanged!(v),
              items: const [
                DropdownMenuItem(value: _ManufacturerStatusFilter.all, child: Text('All')),
                DropdownMenuItem(value: _ManufacturerStatusFilter.approved, child: Text('Approved')),
                DropdownMenuItem(value: _ManufacturerStatusFilter.unapproved, child: Text('Unapproved')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.total, required this.page, required this.pageCount, required this.pageSize, required this.onPageSizeChanged, required this.onPrev, required this.onNext});

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
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: theme.colors.border.withValues(alpha: 0.8))),
                child: Text('Page ${page + 1} of $pageCount', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.foreground)),
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(backgroundColor: theme.colors.muted.withValues(alpha: 0.25), foregroundColor: theme.colors.foreground),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(backgroundColor: theme.colors.muted.withValues(alpha: 0.25), foregroundColor: theme.colors.foreground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colors.foreground),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colors.mutedForeground),
        ),
      ],
    );
  }
}

class _BrandsTable extends StatelessWidget {
  const _BrandsTable({required this.brands, required this.onTogglePublished, required this.actionLabelFor, required this.updatingIds});

  final List<BrandData> brands;
  final void Function(BrandData brand) onTogglePublished;
  final String Function(BrandData brand) actionLabelFor;
  final Set<int> updatingIds;

  String _dateText(DateTime d) {
    if (d.millisecondsSinceEpoch == 0) return '—';
    final local = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (brands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('—', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground)),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: theme.colors.border), borderRadius: BorderRadius.circular(12)),
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
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            headingRowHeight: 46,
          ),
        ),
        child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Manufacturer')),
              DataColumn(label: Text('Published')),
              DataColumn(label: Text('Updated')),
              DataColumn(label: Text('')),
            ],
                rows: brands.map((b) {
                  final busy = updatingIds.contains(b.id);
                  final actionLabel = actionLabelFor(b);
                  return DataRow(
                    cells: [
                      DataCell(Text('#${b.id}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground))),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Text(b.title.trim().isEmpty ? '—' : b.title.trim(), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(_PublishedPill(isPublished: b.isPublished)),
                      DataCell(Text(_dateText(b.updatedAt), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.colors.mutedForeground))),
                      DataCell(
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: busy ? null : () => onTogglePublished(b),
                            icon: busy
                                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colors.mutedForeground))
                                : Icon(b.isPublished ? Icons.visibility_off_outlined : Icons.verified_outlined, size: 18, color: theme.colors.foreground),
                            label: Text(actionLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
        ),
      ),
    );
  }
}

class _PublishedPill extends StatelessWidget {
  const _PublishedPill({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bg = isPublished ? theme.colors.primary.withValues(alpha: 0.12) : theme.colors.muted.withValues(alpha: 0.25);
    final fg = isPublished ? theme.colors.primary : theme.colors.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: fg.withValues(alpha: 0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPublished ? Icons.public : Icons.lock_outline, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(isPublished ? 'Published' : 'Hidden', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colors.mutedForeground),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ErrorCallout extends StatelessWidget {
  const _ErrorCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colors.destructive.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.destructive.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colors.destructive),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.destructive, height: 1.4))),
        ],
      ),
    );
  }
}
