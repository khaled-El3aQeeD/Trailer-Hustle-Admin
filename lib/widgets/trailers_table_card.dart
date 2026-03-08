import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/trailer_data.dart';
import 'package:trailerhustle_admin/models/trailer_rating_summary.dart';
import 'package:trailerhustle_admin/services/trailer_service.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:trailerhustle_admin/widgets/trailer_admin_dialog.dart';

/// Admin dashboard card that lists trailers with search, refresh and pagination.
///
/// Styled to match the main dashboard's modern, clean card system.
class TrailersTableCard extends StatefulWidget {
  const TrailersTableCard({super.key, this.mode = TrailersTableMode.all, this.showFilters = true});

  final TrailersTableMode mode;

  /// Whether to show the search/category/manufacturer filter row.
  ///
  /// Default is true. The dedicated review route hides this to keep the view focused.
  final bool showFilters;

  @override
  State<TrailersTableCard> createState() => _TrailersTableCardState();
}

class _TrailersTableCardState extends State<TrailersTableCard> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;

  final Set<int> _approvingTrailerIds = <int>{};

  List<TrailerData> _all = const [];
  Map<int, String> _businessNameById = const {};
  Map<int, String> _brandTitleById = const {};
  Map<int, String> _allBrandTitleById = const {};
  Map<int, String> _trailerTypeTitleById = const {};
  Map<int, TrailerRatingSummary> _ratingSummaryByTrailerId = const {};
  Map<int, bool> _brandPublishedById = const {};
  Map<int, String> _primaryImageByTrailerId = const {};

  int? _selectedTrailerTypeId;
  int? _selectedBrandId;

  int _page = 0;
  int _pageSize = 10;

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
      final trailers = await TrailerService.fetchAllTrailers();

      // We also treat trailers whose Brand is not published as needing admin
      // approval (submitted/pending).
      final allBrandIds = trailers.map((t) => t.brand).where((id) => id > 0).toSet().toList(growable: false);
      Map<int, bool> brandPublishedById;
      try {
        brandPublishedById = await TrailerService.fetchBrandPublishedByIds(brandIds: allBrandIds);
      } catch (e) {
        debugPrint('TrailersTableCard brand publish-status lookup failed: $e');
        brandPublishedById = const <int, bool>{};
      }

      bool needsApproval(TrailerData t) {
        final missingType = (t.trailerType ?? 0) == 0;
        final published = brandPublishedById[t.brand] ?? true;
        final brandUnpublished = !published;
        return missingType || brandUnpublished;
      }

      final filteredTrailers = switch (widget.mode) {
        TrailersTableMode.all => trailers,
        TrailersTableMode.submittedForApproval => trailers.where(needsApproval).toList(growable: false),
      };

      final businessIds = filteredTrailers.map((t) => t.businessId).where((id) => id > 0).toSet().toList(growable: false);
      final brandIds = filteredTrailers.map((t) => t.brand).where((id) => id > 0).toSet().toList(growable: false);
      final trailerIds = filteredTrailers.map((t) => t.id).where((id) => id > 0).toList(growable: false);
      Map<int, String> businessNameById;
      Map<int, String> brandTitleById;
      Map<int, String> allBrandTitleById;
      Map<int, String> trailerTypeTitleById;
      Map<int, TrailerRatingSummary> ratingSummaryByTrailerId;
      Map<int, String> primaryImageByTrailerId;
      try {
        businessNameById = await UserService.fetchBusinessNamesByIds(businessIds: businessIds);
      } catch (e) {
        debugPrint('TrailersTableCard business name lookup failed: $e');
        businessNameById = const <int, String>{};
      }

      try {
        brandTitleById = await TrailerService.fetchBrandTitlesByIds(brandIds: brandIds);
      } catch (e) {
        debugPrint('TrailersTableCard brand title lookup failed: $e');
        brandTitleById = const <int, String>{};
      }

      try {
        allBrandTitleById = await TrailerService.fetchAllBrandTitles();
      } catch (e) {
        debugPrint('TrailersTableCard all brands lookup failed: $e');
        allBrandTitleById = brandTitleById;
      }

      try {
        final rows = await TrailerService.fetchAllTrailerTypes();
        final out = <int, String>{};
        for (final r in rows) {
          final idRaw = r['id'];
          final id = idRaw is int ? idRaw : idRaw is num ? idRaw.toInt() : int.tryParse(idRaw?.toString() ?? '');
          if (id == null || id <= 0) continue;
          final title = (r['title'] ?? r['name'] ?? '').toString().trim();
          if (title.isEmpty) continue;
          out[id] = title;
        }
        trailerTypeTitleById = out;
      } catch (e) {
        debugPrint('TrailersTableCard trailer types lookup failed: $e');
        trailerTypeTitleById = const <int, String>{};
      }

      try {
        ratingSummaryByTrailerId = await TrailerService.fetchRatingSummariesForTrailers(trailerIds: trailerIds);
      } catch (e) {
        debugPrint('TrailersTableCard ratings summary lookup failed: $e');
        ratingSummaryByTrailerId = const <int, TrailerRatingSummary>{};
      }

      try {
        primaryImageByTrailerId = await TrailerService.fetchPrimaryTrailerImagesByTrailerIds(trailerIds: trailerIds);
      } catch (e) {
        debugPrint('TrailersTableCard trailer images lookup failed: $e');
        primaryImageByTrailerId = const <int, String>{};
      }

      if (!mounted) return;
      setState(() {
        _all = filteredTrailers;
        _businessNameById = businessNameById;
        _brandTitleById = brandTitleById;
        _allBrandTitleById = allBrandTitleById;
        _trailerTypeTitleById = trailerTypeTitleById;
        _ratingSummaryByTrailerId = ratingSummaryByTrailerId;
        _brandPublishedById = brandPublishedById;
        _primaryImageByTrailerId = primaryImageByTrailerId;
      });
    } catch (e) {
      debugPrint('TrailersTableCard refresh failed: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveTrailer(BuildContext context, TrailerData t) async {
    if (_approvingTrailerIds.contains(t.id)) return;

    final missingType = (t.trailerType ?? 0) == 0;
    final brandUnpublished = (_brandPublishedById[t.brand] ?? true) == false;
    if (!missingType && !brandUnpublished) return;

    final theme = context.theme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve trailer?'),
        content: Text(
          missingType && brandUnpublished
              ? 'This trailer is missing a category and its manufacturer is not published.\n\nApprove will open the edit dialog so you can set the category, then it will publish the manufacturer.'
              : missingType
                  ? 'This trailer is missing a category.\n\nApprove will open the edit dialog so you can set the category.'
                  : 'Approve will publish the manufacturer so this trailer can go live.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colors.primary, foregroundColor: theme.colors.primaryForeground),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _approvingTrailerIds.add(t.id));

    try {
      if (missingType) {
        final saved = await TrailerAdminDialog.show(context, trailer: t);
        if (!saved) return;
      }
      if (brandUnpublished && t.brand > 0) {
        await TrailerService.setBrandPublished(brandId: t.brand, published: true);
      }
      await _refresh();
    } catch (e) {
      debugPrint('Approve trailer failed (trailerId=${t.id}): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve trailer #${t.id}: $e')),
      );
    } finally {
      if (mounted) setState(() => _approvingTrailerIds.remove(t.id));
    }
  }

  String _businessNameFor(TrailerData t) {
    if (t.businessId <= 0) return '—';
    final name = _businessNameById[t.businessId];
    if ((name ?? '').trim().isNotEmpty) return name!.trim();
    return 'Business #${t.businessId}';
  }

  String _modelText(TrailerData t) {
    final model = (t.model ?? '').trim();
    if (model.isNotEmpty) return model;
    final dn = t.displayName.trim();
    if (dn.isNotEmpty) return dn;
    return 'Trailer #${t.id}';
  }

  String _imageFor(TrailerData t) {
    final direct = t.image.trim();
    if (direct.isNotEmpty) return direct;
    final fallback = _primaryImageByTrailerId[t.id];
    if ((fallback ?? '').trim().isNotEmpty) return fallback!.trim();
    return '';
  }

  String _makeText(TrailerData t) {
    if (t.brand <= 0) return '—';
    final title = _brandTitleById[t.brand];
    if ((title ?? '').trim().isNotEmpty) return title!.trim();
    return 'Make #${t.brand}';
  }

  String _categoryText(TrailerData t) {
    final typeId = t.trailerType ?? 0;
    if (typeId <= 0) return '—';
    final title = _trailerTypeTitleById[typeId];
    if ((title ?? '').trim().isNotEmpty) return title!.trim();
    return 'Category #$typeId';
  }

  String _submittedDateText(BuildContext context, TrailerData t) {
    final created = t.createdAt;
    if (created.millisecondsSinceEpoch <= 0) return '—';
    final local = created.toLocal();
    final date = MaterialLocalizations.of(context).formatShortDate(local);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: false);
    return '$date $time';
  }

  List<TrailerData> get _filtered {
    final q = _search.text.trim().toLowerCase();
    bool match(TrailerData t) {
      if ((_selectedBrandId ?? 0) > 0 && t.brand != _selectedBrandId) return false;
      if ((_selectedTrailerTypeId ?? 0) > 0 && (t.trailerType ?? 0) != _selectedTrailerTypeId) return false;
      if (q.isEmpty) return true;
      final model = _modelText(t).toLowerCase();
      final businessName = _businessNameFor(t).toLowerCase();
      final make = _makeText(t).toLowerCase();
      final category = _categoryText(t).toLowerCase();
      return t.id.toString().contains(q) || model.contains(q) || make.contains(q) || category.contains(q) || businessName.contains(q) || t.businessId.toString().contains(q);
    }

    return _all.where(match).toList(growable: false);
  }

  void _clearFilters() {
    if (!mounted) return;
    setState(() {
      _selectedBrandId = null;
      _selectedTrailerTypeId = null;
      _page = 0;
    });
  }

  int _pageCountFor(int total) {
    if (total <= 0) return 1;
    return (total / _pageSize).ceil().clamp(1, 999999);
  }

  void _ensurePageInRange({required int total}) {
    final maxPage = _pageCountFor(total) - 1;
    if (_page >= 0 && _page <= maxPage) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _page = _page.clamp(0, maxPage.clamp(0, 999999)));
    });
  }

  List<TrailerData> _pageSlice(List<TrailerData> list) {
    final safePage = _page < 0 ? 0 : _page;
    final start = safePage * _pageSize;
    if (start >= list.length) return const [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final headerTitle = switch (widget.mode) {
      TrailersTableMode.all => 'Trailers',
      TrailersTableMode.submittedForApproval => 'Submitted trailers for approval',
    };

    final filtered = _filtered;
    _ensurePageInRange(total: filtered.length);
    final pageCount = _pageCountFor(filtered.length);
    final pageItems = _pageSlice(filtered);

    final total = _all.length;
    final withImages = _all.where((t) => _imageFor(t).trim().isNotEmpty).length;
    final uniqueBusinesses = _all.map((t) => t.businessId).where((id) => id > 0).toSet().length;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 16, color: theme.colors.foreground),
                const SizedBox(width: 8),
                Expanded(child: Text(headerTitle, style: Theme.of(context).textTheme.titleMedium)),
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
            if (widget.showFilters)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(labelText: 'Search', hintText: 'Model, ID, business…', prefixIcon: Icon(Icons.search_outlined)),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
                    child: DropdownButtonFormField<int?>(
                      value: _selectedTrailerTypeId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                        ...(_trailerTypeTitleById.entries.toList(growable: false)
                          ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase())))
                            .map((e) => DropdownMenuItem<int?>(value: e.key, child: Text(e.value)))
                            .toList(growable: false),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) {
                              setState(() {
                                _selectedTrailerTypeId = (v ?? 0) <= 0 ? null : v;
                                _page = 0;
                              });
                            },
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                    child: DropdownButtonFormField<int?>(
                      value: _selectedBrandId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Manufacturer'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All manufacturers')),
                        ...(_allBrandTitleById.entries.toList(growable: false)
                          ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase())))
                            .map((e) => DropdownMenuItem<int?>(value: e.key, child: Text(e.value)))
                            .toList(growable: false),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) {
                              setState(() {
                                _selectedBrandId = (v ?? 0) <= 0 ? null : v;
                                _page = 0;
                              });
                            },
                    ),
                  ),
                  if ((_selectedBrandId ?? 0) > 0 || (_selectedTrailerTypeId ?? 0) > 0)
                    TextButton.icon(
                      onPressed: _loading ? null : _clearFilters,
                      icon: const Icon(Icons.clear_outlined, size: 18),
                      label: const Text('Clear'),
                    ),
                  _StatPill(label: 'Total', value: '$total', icon: Icons.inventory_2_outlined),
                  _StatPill(label: 'With images', value: '$withImages', icon: Icons.image_outlined),
                  _StatPill(label: 'Businesses', value: '$uniqueBusinesses', icon: Icons.store_outlined),
                ],
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatPill(label: 'Total', value: '$total', icon: Icons.inventory_2_outlined),
                  _StatPill(label: 'With images', value: '$withImages', icon: Icons.image_outlined),
                  _StatPill(label: 'Businesses', value: '$uniqueBusinesses', icon: Icons.store_outlined),
                ],
              ),
            const SizedBox(height: 10),
            if (_error != null) _TrailersErrorCallout(message: _error!),
            if (_loading && _all.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (!_loading && filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No trailers found.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground)),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
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
                          dataRowMinHeight: 62,
                          dataRowMaxHeight: 82,
                          headingRowHeight: 46,
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: widget.mode == TrailersTableMode.submittedForApproval ? 1380 : 1230),
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: [
                              const DataColumn(label: Text('ID')),
                              const DataColumn(label: Text('Trailer')),
                              const DataColumn(label: Text('Business')),
                              const DataColumn(label: Text('Make')),
                              if (widget.mode == TrailersTableMode.submittedForApproval) const DataColumn(label: Text('Date submitted')),
                              const DataColumn(label: Text('Category')),
                              const DataColumn(label: Text('Model')),
                              const DataColumn(label: Text('Ratings')),
                              const DataColumn(label: Text('Actions')),
                            ],
                            rows: pageItems.map((t) => _rowFor(context, t)).toList(growable: false),
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
                    onPrev: _page <= 0 ? null : () => setState(() => _page = (_page - 1).clamp(0, 999999)),
                    onNext: _page >= pageCount - 1 ? null : () => setState(() => _page += 1),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  DataRow _rowFor(BuildContext context, TrailerData t) {
    final theme = context.theme;
    TextStyle? cellStyle({bool muted = false}) => Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: muted ? theme.colors.mutedForeground : theme.colors.foreground);

    final missingType = (t.trailerType ?? 0) == 0;
    final brandUnpublished = (_brandPublishedById[t.brand] ?? true) == false;
    final needsApproval = widget.mode == TrailersTableMode.submittedForApproval && (missingType || brandUnpublished);
    final approving = _approvingTrailerIds.contains(t.id);

    return DataRow(
      onSelectChanged: (_) async {
        final saved = await TrailerAdminDialog.show(context, trailer: t);
        if (saved) _refresh();
      },
      cells: [
        DataCell(Text('#${t.id}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground))),
        DataCell(
          Row(
            children: [
              _TrailerImageThumb(url: TrailerService.resolveTrailerImageUrl(_imageFor(t))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.displayName.trim().isEmpty ? 'Trailer #${t.id}' : t.displayName.trim(), style: cellStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('VIN: ${t.winNumber.trim().isEmpty ? '—' : t.winNumber.trim()}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.colors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
            child: Text(_businessNameFor(t), style: cellStyle(muted: true), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(_makeText(t), style: cellStyle(muted: true))),
        if (widget.mode == TrailersTableMode.submittedForApproval)
          DataCell(
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
              child: Text(_submittedDateText(context, t), style: cellStyle(muted: true), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
            child: Text(_categoryText(t), style: cellStyle(muted: true), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
            child: Text(_modelText(t), style: cellStyle(muted: true), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(_TrailerRatingSummaryPill(summary: _ratingSummaryByTrailerId[t.id])),
        DataCell(
          Wrap(
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'View',
                onPressed: () async {
                  final saved = await TrailerAdminDialog.show(context, trailer: t);
                  if (saved) _refresh();
                },
                icon: const Icon(Icons.visibility_outlined),
                style: IconButton.styleFrom(backgroundColor: theme.colors.muted.withValues(alpha: 0.25), foregroundColor: theme.colors.foreground, padding: const EdgeInsets.all(10)),
              ),
              if (needsApproval)
                Tooltip(
                  message: approving
                      ? 'Approving…'
                      : missingType && brandUnpublished
                          ? 'Set category + publish manufacturer'
                          : missingType
                              ? 'Set category'
                              : 'Publish manufacturer',
                  child: FilledButton.icon(
                    onPressed: approving ? null : () => _approveTrailer(context, t),
                    icon: approving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colors.primaryForeground),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(backgroundColor: theme.colors.primary, foregroundColor: theme.colors.primaryForeground),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailerImageThumb extends StatelessWidget {
  const _TrailerImageThumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final u = url.trim();

    Widget child;
    if (u.isEmpty) {
      child = Icon(Icons.image_not_supported_outlined, size: 18, color: theme.colors.mutedForeground);
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          u,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            color: theme.colors.muted.withValues(alpha: 0.35),
            child: Icon(Icons.broken_image_outlined, size: 18, color: theme.colors.mutedForeground),
          ),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colors.muted.withValues(alpha: 0.14),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.22)),
      ),
      child: Center(child: child),
    );
  }
}

class _TrailerRatingSummaryPill extends StatelessWidget {
  const _TrailerRatingSummaryPill({required this.summary});
  final TrailerRatingSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final s = summary;
    final has = s != null && s.count > 0 && s.average > 0;
    final label = !has ? '—' : '${s!.average.toStringAsFixed(2)} (${s.count})';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: has ? theme.colors.primary.withValues(alpha: 0.10) : theme.colors.muted.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: has ? theme.colors.primary : theme.colors.mutedForeground),
          const SizedBox(width: 8),
          Text('Avg: ', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground)),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w800)),
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
        color: theme.colors.muted.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colors.mutedForeground),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground)),
          Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w800)),
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

class _TrailersErrorCallout extends StatelessWidget {
  const _TrailersErrorCallout({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
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
                Text('Couldn\'t load trailers', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                SelectableText(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.colors.mutedForeground, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum TrailersTableMode {
  all,
  submittedForApproval,
}
