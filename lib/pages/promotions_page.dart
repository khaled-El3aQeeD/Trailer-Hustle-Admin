import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/models/promotion.dart';
import 'package:trailerhustle_admin/models/sponsor_data.dart';
import 'package:trailerhustle_admin/services/promotion_service.dart';
import 'package:trailerhustle_admin/services/sidebar_controller.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/widgets/adaptive_sidebar.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';
import 'package:trailerhustle_admin/widgets/sponsor_picker_dialog.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    PromotionService.refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          if (!isMobile) const AdaptiveSidebar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
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
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            DashboardHeader(
                              pageTitle: 'Promotions',
                              onSidebarToggle: isMobile
                                  ? null
                                  : () => context
                                      .read<SidebarController>()
                                      .toggle(),
                              onThemeToggle: () => context
                                  .read<ThemeProvider>()
                                  .toggleThemeMode(),
                              themeMode:
                                  context.watch<ThemeProvider>().themeMode,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(
                                  DashboardConstants.contentPadding),
                              child: _PromotionsBody(
                                  tabController: _tabController),
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

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _PromotionsBody extends StatelessWidget {
  final TabController tabController;
  const _PromotionsBody({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Promotion>>(
      valueListenable: PromotionService.promotions,
      builder: (context, all, _) {
        final active = PromotionService.getActive();
        final scheduled = PromotionService.getScheduled();
        final archived = PromotionService.getArchived();

        return ValueListenableBuilder<bool>(
          valueListenable: PromotionService.isLoading,
          builder: (context, loading, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: PromotionService.lastError,
              builder: (context, err, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error banner
                    if (err != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.theme.colors.destructive
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: context.theme.colors.destructive
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Text(err,
                            style: TextStyle(
                                color: context.theme.colors.destructive)),
                      ),

                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sponsor Spotlights',
                          style: context.theme.typography.xl2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.theme.colors.foreground,
                          ),
                        ),
                        Row(
                          children: [
                            if (loading)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.theme.colors.primary,
                                  ),
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: () => PromotionService.refresh(),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Refresh'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () =>
                                  _showCreateDialog(context),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Create Promotion'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tabs
                    TabBar(
                      controller: tabController,
                      tabs: [
                        Tab(text: 'Active (${active.length})'),
                        Tab(text: 'Scheduled (${scheduled.length})'),
                        Tab(text: 'Archived (${archived.length})'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _PromotionList(items: active),
                          _PromotionList(items: scheduled),
                          _PromotionList(items: archived),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreatePromotionDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// Promotion list
// ---------------------------------------------------------------------------

class _PromotionList extends StatelessWidget {
  final List<Promotion> items;
  const _PromotionList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No promotions here.',
          style: TextStyle(color: context.theme.colors.mutedForeground),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _PromotionRow(promo: items[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Single row
// ---------------------------------------------------------------------------

class _PromotionRow extends StatefulWidget {
  final Promotion promo;
  const _PromotionRow({required this.promo});

  @override
  State<_PromotionRow> createState() => _PromotionRowState();
}

class _PromotionRowState extends State<_PromotionRow> {
  bool _showStats = false;
  PromotionStats? _stats;
  bool _loadingStats = false;

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final s = await PromotionService.getStats(widget.promo.id);
    if (mounted) setState(() { _stats = s; _loadingStats = false; });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promo;
    final dateRange =
        '${_fmt(p.startAt)} → ${_fmt(p.endAt)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 48,
                  child: p.displayImageUrl.isNotEmpty
                      ? Image.network(p.displayImageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 20)))
                      : Container(color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title,
                        style: context.theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.theme.colors.foreground)),
                    Text(
                      p.sponsorBusinessName ?? 'Business #${p.sponsorBusinessId}',
                      style: TextStyle(
                          color: context.theme.colors.mutedForeground,
                          fontSize: 12),
                    ),
                    Text(dateRange,
                        style: TextStyle(
                            color: context.theme.colors.mutedForeground,
                            fontSize: 11)),
                  ],
                ),
              ),

              // Status badge
              _StatusBadge(promo: p),
              const SizedBox(width: 8),

              // Action buttons
              TextButton(
                onPressed: () {
                  setState(() => _showStats = !_showStats);
                  if (!_showStats && _stats == null) _loadStats();
                  if (_showStats) _loadStats();
                },
                child: const Text('Stats'),
              ),
              TextButton(
                onPressed: () => _showEditDialog(context),
                child: const Text('Edit'),
              ),
              if (!p.isArchived)
                TextButton(
                  onPressed: () => _confirmArchive(context),
                  child: const Text('Archive',
                      style: TextStyle(color: Colors.orange)),
                ),
              TextButton(
                onPressed: () => _confirmDelete(context),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),

          // Stats panel
          if (_showStats) ...[
            const SizedBox(height: 8),
            _StatsPanel(stats: _stats, loading: _loadingStats),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }

  void _confirmArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive promotion?'),
        content: Text(
            'This will deactivate "${widget.promo.title}". It can be re-enabled by editing.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await PromotionService.archivePromotion(widget.promo.id);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete promotion?'),
        content: Text(
            'This permanently deletes "${widget.promo.title}" and all its event data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await PromotionService.deletePromotion(widget.promo.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditPromotionDialog(promo: widget.promo),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Promotion promo;
  const _StatusBadge({required this.promo});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (promo.isLive) {
      color = Colors.green;
      label = 'Live';
    } else if (promo.isScheduled) {
      color = Colors.blue;
      label = 'Scheduled';
    } else {
      color = Colors.grey;
      label = 'Archived';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final PromotionStats? stats;
  final bool loading;
  const _StatsPanel({this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final s = stats ?? PromotionStats.empty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.colors.muted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          _StatChip('Impressions', '${s.impressions}'),
          _StatChip('Skips', '${s.skips}'),
          _StatChip('Closes', '${s.closes}'),
          _StatChip('Image clicks', '${s.imageClicks}'),
          _StatChip('Profile clicks', '${s.profileClicks}'),
          _StatChip('CTR', '${(s.ctr * 100).toStringAsFixed(1)}%'),
          _StatChip('Skip rate', '${(s.skipRate * 100).toStringAsFixed(1)}%'),
          _StatChip('Avg dwell', '${s.avgDwellSeconds.toStringAsFixed(1)}s'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: context.theme.colors.mutedForeground)),
        Text(value,
            style: context.theme.typography.base
                .copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Create dialog
// ---------------------------------------------------------------------------

class _CreatePromotionDialog extends StatefulWidget {
  const _CreatePromotionDialog();

  @override
  State<_CreatePromotionDialog> createState() => _CreatePromotionDialogState();
}

class _CreatePromotionDialogState extends State<_CreatePromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(text: '1');

  SponsorData? _sponsor;
  Uint8List? _imageBytes;
  String _imageFilename = '';

  // Duration
  String _durationPreset = '1w';
  DateTime? _customEndDate;

  bool _isActive = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  DateTime get _endAt {
    final now = DateTime.now().toUtc();
    switch (_durationPreset) {
      case '2w':
        return now.add(const Duration(days: 14));
      case '1m':
        return DateTime(now.year, now.month + 1, now.day,
            now.hour, now.minute, now.second);
      case '3m':
        return DateTime(now.year, now.month + 3, now.day,
            now.hour, now.minute, now.second);
      case 'custom':
        return _customEndDate?.toUtc() ?? now.add(const Duration(days: 7));
      default: // 1w
        return now.add(const Duration(days: 7));
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.bytes == null) return;
    setState(() {
      _imageBytes = f.bytes;
      _imageFilename = f.name;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sponsor == null) {
      setState(() => _error = 'Please select a sponsor business.');
      return;
    }
    if (_imageBytes == null) {
      setState(() => _error = 'Please upload a cover image.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await PromotionService.createPromotion(
        title: _titleCtrl.text.trim(),
        sponsorBusinessId: _sponsor!.id,
        imageBytes: _imageBytes!,
        imageFilename: _imageFilename,
        externalUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        startAt: DateTime.now().toUtc(),
        endAt: _endAt,
        weight: int.tryParse(_weightCtrl.text.trim()) ?? 1,
        isActive: _isActive,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Promotion'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  _ErrorBanner(message: _error!),

                // Title
                _Label('Title *'),
                TextFormField(
                  controller: _titleCtrl,
                  maxLength: 80,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Summer Trailer Sale',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Sponsor
                _Label('Sponsor Business *'),
                OutlinedButton.icon(
                  onPressed: () async {
                    final s = await SponsorPickerDialog.show(context);
                    if (s != null) setState(() => _sponsor = s);
                  },
                  icon: const Icon(Icons.search, size: 16),
                  label: Text(_sponsor?.name ?? 'Pick business…'),
                ),
                const SizedBox(height: 12),

                // Cover image
                _Label('Cover Image *'),
                if (_imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_imageBytes!,
                        height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                ],
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload, size: 16),
                  label: Text(_imageBytes == null
                      ? 'Upload image'
                      : 'Change image'),
                ),
                const SizedBox(height: 12),

                // External URL
                _Label('External URL (optional)'),
                TextFormField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                      hintText: 'https://…',
                      border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final uri = Uri.tryParse(v.trim());
                    if (uri == null || !uri.hasScheme) {
                      return 'Enter a valid URL (include https://)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Duration
                _Label('Duration *'),
                Wrap(
                  spacing: 8,
                  children: [
                    _DurationChip('1 week', '1w', _durationPreset,
                        (v) => setState(() => _durationPreset = v)),
                    _DurationChip('2 weeks', '2w', _durationPreset,
                        (v) => setState(() => _durationPreset = v)),
                    _DurationChip('1 month', '1m', _durationPreset,
                        (v) => setState(() => _durationPreset = v)),
                    _DurationChip('3 months', '3m', _durationPreset,
                        (v) => setState(() => _durationPreset = v)),
                    _DurationChip('Custom', 'custom', _durationPreset,
                        (v) => setState(() => _durationPreset = v)),
                  ],
                ),
                if (_durationPreset == 'custom') ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _customEndDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_customEndDate == null
                        ? 'Pick end date'
                        : 'End: ${_customEndDate!.year}-${_customEndDate!.month.toString().padLeft(2,'0')}-${_customEndDate!.day.toString().padLeft(2,'0')}'),
                  ),
                ],
                const SizedBox(height: 12),

                // Weight
                _Label('Weight (higher = shown more often)'),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(height: 12),

                // Active toggle
                Row(
                  children: [
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Active immediately'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit dialog
// ---------------------------------------------------------------------------

class _EditPromotionDialog extends StatefulWidget {
  final Promotion promo;
  const _EditPromotionDialog({required this.promo});

  @override
  State<_EditPromotionDialog> createState() => _EditPromotionDialogState();
}

class _EditPromotionDialogState extends State<_EditPromotionDialog> {
  late final _titleCtrl = TextEditingController(text: widget.promo.title);
  late final _urlCtrl = TextEditingController(text: widget.promo.externalUrl ?? '');
  late final _weightCtrl =
      TextEditingController(text: '${widget.promo.weight}');
  late bool _isActive = widget.promo.isActive;

  Uint8List? _newImageBytes;
  String _newImageFilename = '';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.bytes == null) return;
    setState(() {
      _newImageBytes = f.bytes;
      _newImageFilename = f.name;
    });
  }

  Future<void> _submit() async {
    setState(() { _saving = true; _error = null; });
    try {
      await PromotionService.updatePromotion(
        widget.promo.id,
        title: _titleCtrl.text.trim(),
        externalUrl: _urlCtrl.text.trim(),
        isActive: _isActive,
        weight: int.tryParse(_weightCtrl.text.trim()),
        imageBytes: _newImageBytes,
        imageFilename: _newImageBytes != null ? _newImageFilename : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit: ${widget.promo.title}'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) _ErrorBanner(message: _error!),
              _Label('Title'),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 80,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              _Label('External URL'),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                    hintText: 'https://…', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              _Label('Cover image (leave empty to keep current)'),
              if (_newImageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_newImageBytes!,
                      height: 100, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 6),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Change image'),
              ),
              const SizedBox(height: 12),
              _Label('Weight'),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(width: 8),
                  const Text('Active'),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: context.theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: context.theme.colors.foreground)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.theme.colors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: context.theme.colors.destructive.withValues(alpha: 0.4)),
      ),
      child: Text(message,
          style: TextStyle(color: context.theme.colors.destructive, fontSize: 13)),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _DurationChip(this.label, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(value),
    );
  }
}
