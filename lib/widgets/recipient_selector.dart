import 'package:flutter/material.dart';
import 'package:trailerhustle_admin/services/push_notification_service.dart';

/// Widget for selecting push notification recipients with filters, search, and select-all.
class RecipientSelector extends StatefulWidget {
  final List<PushRecipient> recipients;
  final Map<int, String> categories;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onSelectionChanged;

  const RecipientSelector({
    super.key,
    required this.recipients,
    required this.categories,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<RecipientSelector> createState() => _RecipientSelectorState();
}

class _RecipientSelectorState extends State<RecipientSelector> {
  final _searchController = TextEditingController();

  // Quick filters
  final Set<String> _selectedTiers = {};
  String _categoryFilter = 'All';

  int _page = 0;
  static const int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PushRecipient> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return widget.recipients.where((r) {
      // Tier filter (OR within group)
      if (_selectedTiers.isNotEmpty && !_selectedTiers.contains(r.subscriptionTier)) {
        return false;
      }
      // Category filter
      if (_categoryFilter != 'All') {
        final catName = widget.categories[r.categoryId] ?? '';
        if (catName != _categoryFilter) return false;
      }
      // Search
      if (q.isNotEmpty) {
        return r.name.toLowerCase().contains(q) ||
            r.email.toLowerCase().contains(q) ||
            r.id.toString().contains(q);
      }
      return true;
    }).toList();
  }

  int get _pageCount {
    final total = _filtered.length;
    if (total <= 0) return 1;
    return (total / _pageSize).ceil().clamp(1, 999999);
  }

  List<PushRecipient> get _pageSlice {
    final list = _filtered;
    final start = _page * _pageSize;
    if (start >= list.length) return [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  void _toggleSelectAll() {
    final filteredIds = _filtered.map((r) => r.id).toSet();
    final allSelected = filteredIds.every(widget.selectedIds.contains);
    final updated = Set<int>.from(widget.selectedIds);
    if (allSelected) {
      updated.removeAll(filteredIds);
    } else {
      updated.addAll(filteredIds);
    }
    widget.onSelectionChanged(updated);
  }

  void _toggleUser(int id) {
    final updated = Set<int>.from(widget.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    widget.onSelectionChanged(updated);
  }

  void _toggleTier(String tier) {
    setState(() {
      if (_selectedTiers.contains(tier)) {
        _selectedTiers.remove(tier);
      } else {
        _selectedTiers.add(tier);
      }
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filtered;
    final filteredIds = filtered.map((r) => r.id).toSet();
    final allFilteredSelected =
        filteredIds.isNotEmpty && filteredIds.every(widget.selectedIds.contains);

    // Ensure page is in range
    if (_page >= _pageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = (_pageCount - 1).clamp(0, 999999));
      });
    }

    // Get unique category names for dropdown
    final categoryNames = <String>{'All'};
    for (final r in widget.recipients) {
      final name = widget.categories[r.categoryId] ?? '';
      if (name.isNotEmpty) categoryNames.add(name);
    }

    // Get unique states from location
    final states = <String>{};
    for (final r in widget.recipients) {
      final loc = r.location.trim();
      if (loc.isNotEmpty) {
        // Extract state from "City, ST" format
        final parts = loc.split(',');
        if (parts.length >= 2) {
          final st = parts.last.trim();
          if (st.isNotEmpty) states.add(st);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: Select All + Search
        Row(
          children: [
            // Select All button
            FilledButton.icon(
              onPressed: _toggleSelectAll,
              icon: Icon(
                allFilteredSelected
                    ? Icons.deselect
                    : Icons.select_all,
                size: 18,
              ),
              label: Text(
                allFilteredSelected
                    ? 'Deselect All (${filtered.length})'
                    : 'Select All (${filtered.length})',
                style: const TextStyle(fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: allFilteredSelected
                    ? colors.errorContainer
                    : colors.primary,
                foregroundColor: allFilteredSelected
                    ? colors.onErrorContainer
                    : colors.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            // Selected count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.selectedIds.length} selected',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            // Search
            SizedBox(
              width: 260,
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() => _page = 0),
                decoration: InputDecoration(
                  hintText: 'Search name, email, ID...',
                  hintStyle: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: colors.onSurfaceVariant),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _page = 0);
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quick Filters row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('Tier:', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            _FilterChip(
              label: 'Pro',
              selected: _selectedTiers.contains('pro'),
              color: const Color(0xFF7C3AED),
              onTap: () => _toggleTier('pro'),
            ),
            _FilterChip(
              label: 'Lite',
              selected: _selectedTiers.contains('lite'),
              color: const Color(0xFF2563EB),
              onTap: () => _toggleTier('lite'),
            ),
            _FilterChip(
              label: 'Free',
              selected: _selectedTiers.contains('free'),
              color: const Color(0xFF6B7280),
              onTap: () => _toggleTier('free'),
            ),
            const SizedBox(width: 16),
            // Category dropdown
            SizedBox(
              width: 180,
              height: 34,
              child: DropdownButtonFormField<String>(
                value: _categoryFilter,
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: textTheme.labelSmall,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                style: textTheme.bodySmall,
                items: categoryNames.map((name) {
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() {
                  _categoryFilter = v ?? 'All';
                  _page = 0;
                }),
              ),
            ),
            // Clear filters
            if (_selectedTiers.isNotEmpty || _categoryFilter != 'All')
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedTiers.clear();
                  _categoryFilter = 'All';
                  _page = 0;
                }),
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Data Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  headingRowHeight: 42,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 42,
                  horizontalMargin: 12,
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(
                    colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  columns: [
                    DataColumn(
                      label: Checkbox(
                        value: allFilteredSelected && filteredIds.isNotEmpty,
                        onChanged: (_) => _toggleSelectAll(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    DataColumn(
                      label: Text('ID',
                          style: textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Business',
                          style: textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Email',
                          style: textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Tier',
                          style: textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Category',
                          style: textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Location',
                          style: textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: _pageSlice.map((r) {
                    final isSelected = widget.selectedIds.contains(r.id);
                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (_) => _toggleUser(r.id),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleUser(r.id),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        DataCell(Text(r.id.toString(),
                            style: textTheme.bodySmall)),
                        DataCell(
                          Text(
                            r.name.isEmpty ? '—' : r.name,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(Text(
                          r.email.isEmpty ? '—' : r.email,
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        )),
                        DataCell(_TierBadge(tier: r.subscriptionTier)),
                        DataCell(Text(
                          widget.categories[r.categoryId] ?? '—',
                          style: textTheme.bodySmall,
                        )),
                        DataCell(Text(
                          r.location.isEmpty ? '—' : r.location,
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        // Pagination
        if (filtered.length > _pageSize)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_page * _pageSize + 1}–${((_page + 1) * _pageSize).clamp(0, filtered.length)} of ${filtered.length}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _page > 0
                          ? () => setState(() => _page--)
                          : null,
                      icon: const Icon(Icons.chevron_left, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text('Page ${_page + 1} of $_pageCount',
                        style: textTheme.bodySmall),
                    IconButton(
                      onPressed: _page < _pageCount - 1
                          ? () => setState(() => _page++)
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tier) {
      'pro' => (const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
      'lite' => (const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
      _ => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tier[0].toUpperCase() + tier.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
