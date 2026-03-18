import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/sponsor_data.dart';
import 'package:trailerhustle_admin/services/sponsor_service.dart';

/// Full-screen dialog that lets the admin search and pick a sponsor (business).
///
/// Returns the selected [SponsorData] via `Navigator.pop`, or null if dismissed.
class SponsorPickerDialog extends StatefulWidget {
  const SponsorPickerDialog({super.key});

  /// Show the picker and return the selected sponsor, or null.
  static Future<SponsorData?> show(BuildContext context) {
    return showDialog<SponsorData>(
      context: context,
      builder: (_) => const SponsorPickerDialog(),
    );
  }

  @override
  State<SponsorPickerDialog> createState() => _SponsorPickerDialogState();
}

class _SponsorPickerDialogState extends State<SponsorPickerDialog> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<SponsorData> _results = const [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  Timer? _debounce;

  static const _pageSize = 40;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _fetch(reset: true);
    });
  }

  void _onScroll() {
    if (_loading || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetch();
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _offset = 0;
        _results = const [];
        _hasMore = true;
      }
    });

    try {
      final batch = await SponsorService.searchSponsors(
        query: _searchController.text,
        offset: _offset,
        limit: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _results = batch;
        } else {
          _results = [..._results, ...batch];
        }
        _offset = _results.length;
        _hasMore = batch.length >= _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colors.background,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.store_outlined, size: 22, color: theme.colors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Select Sponsor',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by business name…',
                  prefixIcon: Icon(Icons.search, color: theme.colors.mutedForeground),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: theme.colors.mutedForeground),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colors.muted.withValues(alpha: 0.14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),

            // Divider
            Divider(height: 1, color: theme.colors.border),

            // Results list
            Expanded(
              child: _buildBody(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FThemeData theme) {
    if (_error != null && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: theme.colors.mutedForeground),
              const SizedBox(height: 12),
              Text('Failed to load sponsors', style: TextStyle(color: theme.colors.mutedForeground)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _fetch(reset: true), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (!_loading && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 40, color: theme.colors.mutedForeground),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No businesses matching "${_searchController.text}"'
                    : 'No businesses found',
                style: TextStyle(color: theme.colors.mutedForeground),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => Divider(height: 1, indent: 20, endIndent: 20, color: theme.colors.border),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final sponsor = _results[index];
        final name = sponsor.name.trim().isEmpty ? '(no name)' : sponsor.name;
        final initial = name == '(no name)' ? '?' : name.characters.first.toUpperCase();

        return InkWell(
          onTap: () => Navigator.of(context).pop(sponsor),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        theme.colors.primary.withValues(alpha: 0.18),
                        theme.colors.primary.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: theme.colors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sponsor.email.isNotEmpty)
                        Text(
                          sponsor.email,
                          style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // ID badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colors.muted.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colors.border),
                  ),
                  child: Text(
                    'ID ${sponsor.id}',
                    style: theme.typography.xs.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
