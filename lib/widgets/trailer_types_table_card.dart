import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/trailer_type_data.dart';
import 'package:trailerhustle_admin/services/trailer_service.dart';

class TrailerTypesTableCard extends StatefulWidget {
  const TrailerTypesTableCard({super.key});

  @override
  State<TrailerTypesTableCard> createState() => _TrailerTypesTableCardState();
}

class _TrailerTypesTableCardState extends State<TrailerTypesTableCard> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<TrailerTypeData> _all = const [];

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (!mounted) return;
      setState(() {});
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
      final rows = await TrailerService.fetchAllTrailerTypes();
      final types = rows.map(TrailerTypeData.fromJson).where((t) => t.id > 0).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _all = types;
      });
    } catch (e) {
      debugPrint('TrailerTypesTableCard refresh failed: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TrailerTypeData> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    bool match(TrailerTypeData t) {
      if (t.id.toString().contains(q)) return true;
      if (t.title.toLowerCase().contains(q)) return true;
      return false;
    }

    return _all.where(match).toList(growable: false);
  }

  Future<void> _openEditor({TrailerTypeData? existing}) async {
    final res = await showModalBottomSheet<_TypeEditResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FractionallySizedBox(
              heightFactor: 0.86,
              child: _DialogSurface(child: _TypeEditor(existing: existing)),
            ),
          ),
        );
      },
    );
    if (res == null) return;

    try {
      if (res.action == _TypeEditAction.create) {
        await TrailerService.createTrailerType(title: res.title, isPublished: res.isPublished);
      } else if (res.action == _TypeEditAction.update) {
        await TrailerService.updateTrailerType(
          typeId: existing!.id,
          data: {
            'title': res.title.trim(),
            'is_published': res.isPublished ? 1 : 0,
          },
        );
      }
      await _refresh();
    } catch (e) {
      debugPrint('TrailerTypesTableCard save failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save trailer type: $e')));
    }
  }

  Future<void> _confirmDelete(TrailerTypeData t) async {
    final theme = context.theme;
    final res = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _DialogSurface(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colors.destructive.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.colors.border),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.delete_outline, size: 20, color: theme.colors.destructive),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Delete type?', style: theme.typography.lg.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground))),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(FIcons.x),
                          iconSize: 16,
                          style: IconButton.styleFrom(minimumSize: const Size(38, 38), padding: EdgeInsets.zero, foregroundColor: theme.colors.mutedForeground),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This will soft-delete “${t.title}” by setting deletedAt. It can be recovered from the database if needed.',
                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.4, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FButton(
                            onPress: () => Navigator.of(context).pop(false),
                            style: FButtonStyle.secondary(),
                            child: Text('Cancel', style: TextStyle(color: theme.colors.foreground)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FButton(
                            onPress: () => Navigator.of(context).pop(true),
                            style: FButtonStyle.primary(),
                            child: Text('Delete', style: TextStyle(color: theme.colors.primaryForeground)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (res != true) return;
    try {
      await TrailerService.softDeleteTrailerType(typeId: t.id);
      await _refresh();
    } catch (e) {
      debugPrint('TrailerTypesTableCard delete failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete trailer type: $e')));
    }
  }

  String _dateText(BuildContext context, DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '—';
    final local = dt.toLocal();
    final ml = MaterialLocalizations.of(context);
    return '${ml.formatShortDate(local)} • ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final filtered = _filtered;
    final publishedCount = _all.where((t) => t.isPublished).length;
    final hiddenCount = _all.length - publishedCount;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: theme.colors.foreground),
                const SizedBox(width: 8),
                Expanded(child: Text('Default trailer types', style: Theme.of(context).textTheme.titleMedium)),
                Text('${filtered.length}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground)),
                const SizedBox(width: 10),
                IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh_outlined)),
                const SizedBox(width: 4),
                FButton(
                  onPress: _loading ? null : () => _openEditor(),
                  style: FButtonStyle.primary(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: theme.colors.primaryForeground),
                      const SizedBox(width: 8),
                      Text('Add type', style: TextStyle(color: theme.colors.primaryForeground)),
                    ],
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
                    decoration: const InputDecoration(labelText: 'Search', hintText: 'Title or ID…', prefixIcon: Icon(Icons.search_outlined)),
                  ),
                ),
                _StatPill(label: 'Published', value: '$publishedCount', icon: Icons.public),
                _StatPill(label: 'Hidden', value: '$hiddenCount', icon: Icons.visibility_off_outlined),
              ],
            ),
            const SizedBox(height: 10),
            if (_error != null) _ErrorCallout(message: _error!),
            if (_loading && _all.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (!_loading && filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No trailer types found.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground)),
              )
            else
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
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 72,
                      headingRowHeight: 46,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 900),
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Published')),
                          DataColumn(label: Text('Updated')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((t) => _rowFor(context, t)).toList(growable: false),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _rowFor(BuildContext context, TrailerTypeData t) {
    final theme = context.theme;
    final published = t.isPublished;
    return DataRow(
      onSelectChanged: (_) => _openEditor(existing: t),
      cells: [
        DataCell(Text('#${t.id}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.colors.mutedForeground))),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 520),
            child: Text(t.title.trim().isEmpty ? '—' : t.title.trim(), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(_PublishedPill(isPublished: published)),
        DataCell(Text(_dateText(context, t.updatedAt), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.colors.mutedForeground))),
        DataCell(
          Wrap(
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _openEditor(existing: t),
                icon: const Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(backgroundColor: theme.colors.muted.withValues(alpha: 0.25), foregroundColor: theme.colors.foreground, padding: const EdgeInsets.all(10)),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(t),
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(backgroundColor: theme.colors.destructive.withValues(alpha: 0.10), foregroundColor: theme.colors.destructive, padding: const EdgeInsets.all(10)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeEditor extends StatefulWidget {
  const _TypeEditor({required this.existing});
  final TrailerTypeData? existing;

  @override
  State<_TypeEditor> createState() => _TypeEditorState();
}

class _TypeEditorState extends State<_TypeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  bool _published = true;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _published = widget.existing?.isPublished ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final existing = widget.existing;
    final isEdit = existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colors.primary.withValues(alpha: 0.20), theme.colors.primary.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colors.border),
                ),
                alignment: Alignment.center,
                child: Icon(isEdit ? Icons.edit_outlined : Icons.add, size: 20, color: theme.colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? 'Edit trailer type' : 'Add trailer type', style: theme.typography.lg.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
                    const SizedBox(height: 4),
                    Text(
                      isEdit ? 'ID #${existing.id}' : 'Creates a new default option for the app.',
                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(FIcons.x),
                iconSize: 16,
                style: IconButton.styleFrom(minimumSize: const Size(38, 38), padding: EdgeInsets.zero, foregroundColor: theme.colors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Enclosed, Flatbed…', prefixIcon: Icon(Icons.title_outlined)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.muted.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public, size: 18, color: theme.colors.foreground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Published', style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
                            const SizedBox(height: 2),
                            Text(
                              'Published types are visible in the app dropdowns.',
                              style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, height: 1.35, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(value: _published, onChanged: (v) => setState(() => _published = v)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: () {
                    final ok = _formKey.currentState?.validate() ?? false;
                    if (!ok) return;
                    Navigator.of(context).pop(
                      _TypeEditResult(
                        action: isEdit ? _TypeEditAction.update : _TypeEditAction.create,
                        title: _title.text.trim(),
                        isPublished: _published,
                      ),
                    );
                  },
                  style: FButtonStyle.primary(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, size: 18, color: theme.colors.primaryForeground),
                      const SizedBox(width: 10),
                      Text(isEdit ? 'Save' : 'Create', style: TextStyle(color: theme.colors.primaryForeground)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TypeEditAction { create, update }

class _TypeEditResult {
  const _TypeEditResult({
    required this.action,
    required this.title,
    required this.isPublished,
  });
  final _TypeEditAction action;
  final String title;
  final bool isPublished;
}

class _PublishedPill extends StatelessWidget {
  const _PublishedPill({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bg = isPublished ? theme.colors.primary.withValues(alpha: 0.10) : theme.colors.muted.withValues(alpha: 0.18);
    final fg = isPublished ? theme.colors.primary : theme.colors.mutedForeground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: theme.colors.border.withValues(alpha: 0.9))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPublished ? Icons.check_circle_outline : Icons.remove_circle_outline, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(isPublished ? 'Yes' : 'No', style: theme.typography.sm.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w900)),
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
          Text('$label: ', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800)),
          Text(value, style: theme.typography.sm.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w900)),
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
          Expanded(child: SelectableText(message, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.35))),
        ],
      ),
    );
  }
}

class _DialogSurface extends StatelessWidget {
  const _DialogSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.border),
        boxShadow: [BoxShadow(color: theme.colors.foreground.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
