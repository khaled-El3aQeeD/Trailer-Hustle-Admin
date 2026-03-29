import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/models/giveaway.dart';
import 'package:trailerhustle_admin/models/giveaway_participant.dart';
import 'package:trailerhustle_admin/services/file_export_service.dart';
import 'package:trailerhustle_admin/services/giveaway_service.dart';
import 'package:trailerhustle_admin/theme/theme_provider.dart';
import 'package:trailerhustle_admin/theme.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/giveaway_image_uploader.dart';
import 'package:trailerhustle_admin/widgets/sponsor_info_card.dart';
import 'package:trailerhustle_admin/widgets/sponsor_picker_dialog.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';
import 'package:trailerhustle_admin/services/sponsor_service.dart';
import 'package:trailerhustle_admin/models/sponsor_data.dart';
import 'dart:async';

class GiveawaysPage extends StatefulWidget {
  const GiveawaysPage({super.key});

  @override
  State<GiveawaysPage> createState() => _GiveawaysPageState();
}

class _GiveawaysPageState extends State<GiveawaysPage> with TickerProviderStateMixin {
  bool _isSidebarCollapsed = false;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    // Load from Supabase (schema is the source of truth).
    GiveawayService.refresh().then((_) {
      // After loading, archive any due giveaways server-side for consistency.
      GiveawayService.archiveDueGiveaways();
    });
    _sidebarAnimationController = AnimationController(
      duration: DashboardConstants.sidebarAnimationDuration,
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    );
    _sidebarAnimationController.forward();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final isMobile = context.theme.breakpoints.md > MediaQuery.of(context).size.width;

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
              builder: (context, child) {
                return ClipRect(
                  child: SizeTransition(
                    sizeFactor: _sidebarAnimation,
                    axis: Axis.horizontal,
                    axisAlignment: -1,
                    child: const Sidebar(),
                  ),
                );
              },
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.theme.colors.background,
                          borderRadius: BorderRadius.circular(DashboardConstants.containerBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: context.theme.colors.primary.withValues(alpha: 0.13),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            DashboardHeader(
                              pageTitle: 'Giveaways',
                              onSidebarToggle: isMobile ? null : _toggleSidebar,
                              sidebarAnimation: isMobile ? null : _sidebarAnimation,
                              onThemeToggle: () => context.read<ThemeProvider>().toggleThemeMode(),
                              themeMode: context.watch<ThemeProvider>().themeMode,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(DashboardConstants.contentPadding),
                              child: ValueListenableBuilder(
                                valueListenable: GiveawayService.giveaways,
                                builder: (context, giveaways, _) {
                                  final draft = GiveawayService.getDraftGiveaways();
                                  final active = GiveawayService.getActiveGiveaways();
                                  final archive = GiveawayService.getPastGiveaways();

                                  return ValueListenableBuilder(
                                    valueListenable: GiveawayService.isLoading,
                                    builder: (context, isLoading, __) {
                                      return ValueListenableBuilder(
                                        valueListenable: GiveawayService.lastError,
                                        builder: (context, lastError, ___) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (lastError != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 12),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: context.theme.colors.destructive.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: context.theme.colors.destructive.withValues(alpha: 0.35)),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Icon(Icons.error_outline, size: 18, color: context.theme.colors.destructive),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            'Failed to load giveaways from Supabase:\n$lastError',
                                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.foreground),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              _GiveawaysContent(
                                                draft: draft,
                                                active: active,
                                                past: archive,
                                                isLoading: isLoading,
                                                onRefresh: GiveawayService.refresh,
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
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

class _GiveawaysContent extends StatefulWidget {
  final List<Giveaway> draft;
  final List<Giveaway> active;
  final List<Giveaway> past;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _GiveawaysContent({required this.draft, required this.active, required this.past, required this.isLoading, required this.onRefresh});

  @override
  State<_GiveawaysContent> createState() => _GiveawaysContentState();
}

class _GiveawaysContentState extends State<_GiveawaysContent> {
  int _tabIndex = 0;

  void _setTab(int next) {
    if (_tabIndex == next) return;
    setState(() => _tabIndex = next);
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<Giveaway>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.theme.colors.background,
      // Wider surface for desktop/tablet while staying responsive.
      constraints: const BoxConstraints(maxWidth: 1100),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _CreateGiveawaySheet(),
          ),
        ),
      ),
    );

    if (created != null && mounted) {
      _setTab(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created draft: ${created.title}')),
      );
    }
  }

  Future<void> _openGiveawaySheet(Giveaway g) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.theme.colors.background,
      constraints: const BoxConstraints(maxWidth: 1100),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _GiveawayViewAndEditSheet(
              giveaway: g,
              onViewParticipants: () {
                Navigator.of(context).pop();
                _openParticipantsSheet(g);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openParticipantsSheet(Giveaway g) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.theme.colors.background,
      constraints: const BoxConstraints(maxWidth: 1100),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _GiveawayParticipantsSheet(giveaway: g),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = switch (_tabIndex) {
      0 => widget.draft,
      1 => widget.active,
      _ => widget.past,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage giveaways', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Participants are loaded from Supabase (giveawayparticipants).',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.isLoading ? null : widget.onRefresh,
              icon: Icon(Icons.refresh, color: context.foreground),
              label: Text('Refresh', style: TextStyle(color: context.foreground)),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _openCreateSheet,
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
              label: Text('Create new Giveaway', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.isLoading && list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _GiveawaysTable(
            list: list,
            tabIndex: _tabIndex,
            onTabChanged: _setTab,
             onViewGiveaway: _openGiveawaySheet,
             onViewParticipants: _openParticipantsSheet,
          ),
      ],
    );
  }
}

class _GiveawaysTable extends StatelessWidget {
  final List<Giveaway> list;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<Giveaway> onViewGiveaway;
  final ValueChanged<Giveaway> onViewParticipants;

  const _GiveawaysTable({
    required this.list,
    required this.tabIndex,
    required this.onTabChanged,
    required this.onViewGiveaway,
    required this.onViewParticipants,
  });

  String _formatDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.month)}/${two(dt.day)}/${dt.year}';
  }

  String _statusFor(Giveaway g) {
    if (g.isDraft) return 'Draft';
    if (g.isArchived) return 'Archived';
    final now = DateTime.now();
    return g.isDueForArchive(now) ? 'Archived' : 'Active';
  }

  DataRow _rowFor(BuildContext context, Giveaway g) {
    final status = _statusFor(g);
    final winnerLabel = () {
      final id = g.winnerUserId;
      if (id == null || id.trim().isEmpty) return '—';
      final match = g.participants.where((p) => p.userId == id).toList(growable: false);
      if (match.isNotEmpty) return match.first.companyName;
      return id;
    }();
    final isPast = status == 'Archived';

    TextStyle? cellStyle({bool muted = false}) => Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: muted ? context.theme.colors.mutedForeground : context.theme.colors.foreground);

    return DataRow(
      onSelectChanged: (_) => onViewGiveaway(g),
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
            child: Text(g.title, style: cellStyle(), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isPast ? context.theme.colors.muted : context.theme.colors.secondary).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: context.theme.colors.border.withValues(alpha: 0.7)),
            ),
            child: Text(status, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.theme.colors.foreground)),
          ),
        ),
        DataCell(Text('${g.participants.length}', style: cellStyle(muted: true))),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
            child: Text(winnerLabel, style: cellStyle(muted: true), overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(_formatDate(g.scheduledArchiveAt), style: cellStyle(muted: true))),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: Text(g.id, style: cellStyle(muted: true), overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 420),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onViewParticipants(g),
                  icon: Icon(Icons.group_outlined, size: 18, color: context.foreground),
                  label: Text('View participants', style: TextStyle(color: context.foreground)),
                ),
                FilledButton.icon(
                  onPressed: () => onViewGiveaway(g),
                  icon: Icon(Icons.card_giftcard, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                  label: Text('View giveaway', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FIcons.gift, size: 16, color: context.theme.colors.foreground),
                const SizedBox(width: 8),
                Expanded(child: Text('All giveaways', style: Theme.of(context).textTheme.titleMedium)),
                Text('${list.length}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.theme.colors.mutedForeground)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Draft')),
                    ButtonSegment(value: 1, label: Text('Active')),
                    ButtonSegment(value: 2, label: Text('Archive')),
                  ],
                  selected: {tabIndex},
                  onSelectionChanged: (s) => onTabChanged(s.first),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Nothing here yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.theme.colors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: context.theme.colors.border.withValues(alpha: 0.7),
                    dataTableTheme: DataTableThemeData(
                      headingRowColor: WidgetStatePropertyAll(context.theme.colors.muted.withValues(alpha: 0.55)),
                      headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.theme.colors.foreground),
                      dataTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.foreground),
                      horizontalMargin: 16,
                      columnSpacing: 18,
                      dividerThickness: 0.7,
                      dataRowMinHeight: 56,
                      // Keep max >= min. Flutter's default max is 48, which would assert.
                      dataRowMaxHeight: 72,
                      headingRowHeight: 46,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 1180),
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Status')),
                          DataColumn(numeric: true, label: Text('Entrants')),
                          DataColumn(label: Text('Winner')),
                          DataColumn(label: Text('Archive')),
                          DataColumn(label: Text('Giveaway ID')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: list.map((g) => _rowFor(context, g)).toList(growable: false),
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
}

class _GiveawayViewAndEditSheet extends StatefulWidget {
  final Giveaway giveaway;
  final VoidCallback onViewParticipants;

  const _GiveawayViewAndEditSheet({required this.giveaway, required this.onViewParticipants});

  @override
  State<_GiveawayViewAndEditSheet> createState() => _GiveawayViewAndEditSheetState();
}

class _GiveawayViewAndEditSheetState extends State<_GiveawayViewAndEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _image;
  late final TextEditingController _terms;
  late final TextEditingController _howTo;
  late final TextEditingController _sponsorId;
  String? _winnerUserId;
  bool _saving = false;

  Timer? _sponsorDebounce;
  Future<SponsorData?>? _sponsorFuture;
  int _lastSponsorId = -1;

  @override
  void initState() {
    super.initState();
    final g = widget.giveaway;
    _title = TextEditingController(text: g.title);
    _description = TextEditingController(text: g.description);
    _image = TextEditingController(text: g.image);
    _terms = TextEditingController(text: g.termsAndConditions);
    _howTo = TextEditingController(text: g.howToParticipate ?? '');
    _sponsorId = TextEditingController(text: g.sponsorId.toString());
    _winnerUserId = g.winnerUserId;

    _sponsorId.addListener(_onSponsorIdChanged);
    _refreshSponsorFuture();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _image.dispose();
    _terms.dispose();
    _howTo.dispose();
    _sponsorId.dispose();
    _sponsorDebounce?.cancel();
    super.dispose();
  }

  void _onSponsorIdChanged() {
    _sponsorDebounce?.cancel();
    _sponsorDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _refreshSponsorFuture();
    });
  }

  void _refreshSponsorFuture() {
    final sponsorId = int.tryParse(_sponsorId.text.trim()) ?? 0;
    if (sponsorId == _lastSponsorId) return;
    _lastSponsorId = sponsorId;
    setState(() {
      _sponsorFuture = sponsorId > 0 ? SponsorService.fetchSponsorById(sponsorId) : null;
    });
  }

  Future<void> _pickSchedule() async {
    final initial = widget.giveaway.scheduledArchiveAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final next = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await GiveawayService.updateSchedule(giveawayId: widget.giveaway.id, scheduledArchiveAt: next);
  }

  Future<void> _declareWinner() async {
    final winnerId = _winnerUserId;
    if (winnerId == null) return;
    setState(() => _saving = true);
    try {
      await GiveawayService.declareWinner(giveawayId: widget.giveaway.id, winnerUserId: winnerId);
    } catch (e) {
      debugPrint('Declare winner failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to declare winner: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishGiveaway() async {
    setState(() => _saving = true);
    try {
      await GiveawayService.publishGiveaway(giveawayId: widget.giveaway.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giveaway published')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Publish giveaway failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish giveaway: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEdits() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final sponsorId = int.tryParse(_sponsorId.text.trim()) ?? 0;
      // If the image hasn't been changed (no new upload / no removal), send the
      // original raw DB value so we don't overwrite a bare filename with the
      // resolved full URL — which would break the mobile app's image display.
      final currentImage = _image.text.trim();
      final imageChanged = currentImage != widget.giveaway.image;
      final imageToSave = imageChanged ? currentImage : widget.giveaway.rawImage;
      await GiveawayService.updateGiveawayDetails(
        giveawayId: widget.giveaway.id,
        title: _title.text,
        description: _description.text.trim(),
        image: imageToSave,
        termsAndConditions: _terms.text.trim(),
        sponsorId: sponsorId,
        howToParticipate: _howTo.text.trim().isEmpty ? null : _howTo.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giveaway updated')));
    } catch (e) {
      debugPrint('Update giveaway failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update giveaway: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete giveaway?'),
        content: Text('Are you sure you want to delete "${widget.giveaway.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await GiveawayService.deleteGiveaway(giveawayId: widget.giveaway.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giveaway deleted')));
      }
    } catch (e) {
      debugPrint('Delete giveaway failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete giveaway: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.giveaway;
    final isArchived = g.isDueForArchive(DateTime.now());
    final isDraft = g.isDraft;
    final hasWinner = g.winnerUserId != null && g.winnerUserId!.trim().isNotEmpty;
    final winnerOptions = g.participants
        .map((p) => DropdownMenuEntry<String>(value: p.userId, label: '${p.companyName} (${p.userId})'))
        .toList(growable: false);

    final imageUrl = _image.text.trim();

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('View giveaway', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        isDraft ? 'Draft giveaway' : (isArchived ? 'Archived giveaway' : 'Active giveaway'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onViewParticipants,
                  icon: Icon(Icons.group_outlined, color: context.foreground),
                  label: Text('Participants', style: TextStyle(color: context.foreground)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Delete giveaway',
                  onPressed: _saving ? null : _confirmDelete,
                  icon: Icon(Icons.delete_outline, color: context.theme.colors.destructive),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: context.foreground),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GiveawayImageUploader(
              imageUrl: imageUrl,
              onUrlChanged: (url) {
                _image.text = url;
                setState(() {});
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            // Image is managed via the uploader above.
            const SizedBox(height: 12),
            TextField(
              controller: _howTo,
              decoration: const InputDecoration(labelText: 'How to participate (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _terms,
              decoration: const InputDecoration(labelText: 'Terms & conditions'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sponsorId,
                    decoration: const InputDecoration(labelText: 'Sponsor ID'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await SponsorPickerDialog.show(context);
                      if (picked != null && mounted) {
                        _sponsorId.text = picked.id.toString();
                      }
                    },
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Browse'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _sponsorFuture == null
                  ? const SizedBox.shrink()
                  : FutureBuilder<SponsorData?>(
                      key: ValueKey(_lastSponsorId),
                      future: _sponsorFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.theme.colors.muted.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.theme.colors.border),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: context.theme.colors.primary),
                                ),
                                const SizedBox(width: 10),
                                Text('Loading sponsor…', style: TextStyle(color: context.theme.colors.mutedForeground)),
                              ],
                            ),
                          );
                        }

                        final sponsor = snapshot.data;
                        if (sponsor == null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.theme.colors.muted.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.theme.colors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: context.theme.colors.mutedForeground, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No sponsor found for ID ${_lastSponsorId}.',
                                    style: TextStyle(color: context.theme.colors.mutedForeground),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SponsorInfoCard(sponsor: sponsor);
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickSchedule,
                    icon: Icon(Icons.event, color: context.foreground),
                    label: Text('Edit archive date & time', style: TextStyle(color: context.foreground)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 340,
                  child: DropdownMenu<String>(
                    enabled: g.participants.isNotEmpty,
                    initialSelection: _winnerUserId,
                    expandedInsets: EdgeInsets.zero,
                    label: Text(hasWinner ? 'Change winner' : 'Declare winner'),
                    dropdownMenuEntries: winnerOptions,
                    onSelected: (v) => setState(() => _winnerUserId = v),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _winnerUserId == null || _saving || _winnerUserId == g.winnerUserId ? null : _declareWinner,
                  child: _saving
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                      : Text(hasWinner ? 'Update winner' : 'Declare', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDraft)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _publishGiveaway,
                    icon: Icon(Icons.public, color: Theme.of(context).colorScheme.onPrimary),
                    label: _saving
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                        : Text('Make Active (visible to users)', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: Text('Close', style: TextStyle(color: context.foreground)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _saveEdits,
                    child: _saving
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                        : Text('Save changes', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GiveawayParticipantsSheet extends StatelessWidget {
  final Giveaway giveaway;
  const _GiveawayParticipantsSheet({required this.giveaway});

  Future<void> _exportEntrants(BuildContext context) async {
    final csv = GiveawayService.buildEntrantsCsv(giveaway);
    final safeTitle = giveaway.title.replaceAll(RegExp(r'[^a-zA-Z0-9\-_ ]'), '').replaceAll(' ', '_');
    try {
      await FileExportService.downloadCsv(filename: 'giveaway_${giveaway.id}_$safeTitle.csv', csv: csv);
    } catch (e) {
      debugPrint('Export entrants failed: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export entrants: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Participants', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        giveaway.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: giveaway.participants.isEmpty ? null : () => _exportEntrants(context),
                  icon: Icon(Icons.download, color: Theme.of(context).colorScheme.onPrimary),
                  label: Text('Export users', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: context.foreground),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ParticipantsTable(participants: giveaway.participants),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsTable extends StatefulWidget {
  final List<GiveawayParticipant> participants;
  const _ParticipantsTable({required this.participants});

  @override
  State<_ParticipantsTable> createState() => _ParticipantsTableState();
}

class _ParticipantsTableState extends State<_ParticipantsTable> {
  int _pageIndex = 0;
  int _pageSize = 10;

  String _formatEnteredAt(DateTime? dt) {
    if (dt == null) return '—';
    final t = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  void didUpdateWidget(covariant _ParticipantsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participants.length != widget.participants.length) {
      _pageIndex = 0;
    }
  }

  void _setPageIndex(int next) {
    if (next == _pageIndex) return;
    setState(() => _pageIndex = next);
  }

  void _setPageSize(int next) {
    if (next == _pageSize) return;
    setState(() {
      _pageSize = next;
      _pageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge;
    final total = widget.participants.length;
    final pageCount = total == 0 ? 1 : ((total - 1) ~/ _pageSize) + 1;
    final safePageIndex = _pageIndex.clamp(0, pageCount - 1);
    if (safePageIndex != _pageIndex) {
      // keep state valid after page size changes
      _pageIndex = safePageIndex;
    }

    final start = total == 0 ? 0 : _pageIndex * _pageSize;
    final end = total == 0 ? 0 : (start + _pageSize).clamp(0, total);
    final pageItems = total == 0 ? const <GiveawayParticipant>[] : widget.participants.sublist(start, end);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.theme.colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.theme.colors.muted.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(child: Text('Company', style: label)),
                const SizedBox(width: 12),
                SizedBox(width: 230, child: Text('Email', style: label)),
                const SizedBox(width: 12),
                SizedBox(width: 160, child: Text('Phone', style: label)),
                const SizedBox(width: 12),
                SizedBox(width: 170, child: Text('CreatedAt', style: label)),
                const SizedBox(width: 12),
                SizedBox(width: 220, child: Text('Unique ID', style: label)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: Column(
              key: ValueKey('${_pageIndex}_${_pageSize}_${widget.participants.length}'),
              children: [
                if (pageItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No participants yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
                    ),
                  )
                else
                  ...pageItems.map((p) {
                    final company = p.companyName;
                    final email = (p.email ?? '').trim().isEmpty ? '—' : p.email!;
                    final phone = (p.phone ?? '').trim().isEmpty ? '—' : p.phone!;
                    final id = p.userId;
                    final avatarUrl = (p.avatarUrl ?? '').trim();
                    final enteredAt = _formatEnteredAt(p.enteredAt);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: context.theme.colors.border.withValues(alpha: 0.6))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (avatarUrl.isNotEmpty)
                                  FAvatar(image: NetworkImage(avatarUrl), size: 28)
                                else
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: context.theme.colors.muted.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: context.theme.colors.border.withValues(alpha: 0.6)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.person_outline, size: 16, color: context.theme.colors.mutedForeground),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    company,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 230,
                            child: Text(
                              email,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 160,
                            child: Text(
                              phone,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 170,
                            child: Text(
                              enteredAt,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: context.theme.colors.mutedForeground),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 220,
                            child: Text(
                              id,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: context.theme.colors.mutedForeground),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.theme.colors.border.withValues(alpha: 0.6))),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              color: context.theme.colors.background,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Text(
                  total == 0 ? '0 items' : 'Showing ${start + 1}–$end of $total',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.theme.colors.mutedForeground),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 155,
                  child: DropdownMenu<int>(
                    initialSelection: _pageSize,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Per page'),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 10, label: '10'),
                      DropdownMenuEntry(value: 25, label: '25'),
                      DropdownMenuEntry(value: 50, label: '50'),
                    ],
                    onSelected: (v) {
                      if (v == null) return;
                      _setPageSize(v);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: _pageIndex <= 0 ? null : () => _setPageIndex(_pageIndex - 1),
                  icon: Icon(Icons.chevron_left, color: context.foreground),
                ),
                Text(
                  '${_pageIndex + 1} / $pageCount',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: _pageIndex >= pageCount - 1 ? null : () => _setPageIndex(_pageIndex + 1),
                  icon: Icon(Icons.chevron_right, color: context.foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGiveawaySheet extends StatefulWidget {
  const _CreateGiveawaySheet();

  @override
  State<_CreateGiveawaySheet> createState() => _CreateGiveawaySheetState();
}

class _CreateGiveawaySheetState extends State<_CreateGiveawaySheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _termsController = TextEditingController();
  final _howToController = TextEditingController();
  final _sponsorIdController = TextEditingController(text: '0');

  Timer? _sponsorDebounce;
  Future<SponsorData?>? _sponsorFuture;
  int _lastSponsorId = -1;

  DateTime _scheduledArchiveAt = DateTime.now().add(const Duration(days: 30));
  bool _isDraft = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sponsorIdController.addListener(_onSponsorIdChanged);
    _refreshSponsorFuture();
    _loadDefaultTerms();
  }

  Future<void> _loadDefaultTerms() async {
    final terms = await GiveawayService.fetchDefaultTermsAndConditions();
    if (mounted && terms.isNotEmpty && _termsController.text.isEmpty) {
      _termsController.text = terms;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _termsController.dispose();
    _howToController.dispose();
    _sponsorIdController.dispose();
    _sponsorDebounce?.cancel();
    super.dispose();
  }

  void _onSponsorIdChanged() {
    _sponsorDebounce?.cancel();
    _sponsorDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _refreshSponsorFuture();
    });
  }

  void _refreshSponsorFuture() {
    final sponsorId = int.tryParse(_sponsorIdController.text.trim()) ?? 0;
    if (sponsorId == _lastSponsorId) return;
    _lastSponsorId = sponsorId;
    setState(() {
      _sponsorFuture = sponsorId > 0 ? SponsorService.fetchSponsorById(sponsorId) : null;
    });
  }

  Future<void> _pickSchedule() async {
    final initial = _scheduledArchiveAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    setState(() => _scheduledArchiveAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = two(dt.hour);
    final m = two(dt.minute);
    return '${two(dt.month)}/${two(dt.day)}/${dt.year} $h:$m';
  }

  Future<void> _create() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final sponsorId = int.tryParse(_sponsorIdController.text.trim()) ?? 0;
      final created = await GiveawayService.createGiveaway(
        title: _titleController.text,
        description: _descriptionController.text.trim(),
        image: _imageController.text.trim(),
        termsAndConditions: _termsController.text.trim(),
        sponsorId: sponsorId,
        howToParticipate: _howToController.text.trim().isEmpty ? null : _howToController.text.trim(),
        winnerAnnouncementDate: _scheduledArchiveAt,
        isDraft: _isDraft,
      );
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      debugPrint('Create giveaway failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create giveaway: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create new Giveaway', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        _isDraft ? 'Will be saved as Draft (not visible to users).' : 'Will be published immediately (visible to users).',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: context.foreground),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GiveawayImageUploader(
              imageUrl: _imageController.text.trim(),
              onUrlChanged: (url) {
                _imageController.text = url;
                setState(() {});
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Spring Promo Giveaway',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What is this giveaway about?',
              ),
              maxLines: 3,
            ),
            // Image is managed via the uploader above.
            const SizedBox(height: 12),
            TextField(
              controller: _howToController,
              decoration: const InputDecoration(
                labelText: 'How to participate (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _termsController,
              decoration: const InputDecoration(
                labelText: 'Terms & conditions',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sponsorIdController,
                    decoration: const InputDecoration(
                      labelText: 'Sponsor ID',
                      hintText: 'Numeric sponsor id (as stored in Supabase)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await SponsorPickerDialog.show(context);
                      if (picked != null && mounted) {
                        _sponsorIdController.text = picked.id.toString();
                      }
                    },
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Browse'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _sponsorFuture == null
                  ? const SizedBox.shrink()
                  : FutureBuilder<SponsorData?>(
                      key: ValueKey(_lastSponsorId),
                      future: _sponsorFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.theme.colors.muted.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.theme.colors.border),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: context.theme.colors.primary),
                                ),
                                const SizedBox(width: 10),
                                Text('Loading sponsor…', style: TextStyle(color: context.theme.colors.mutedForeground)),
                              ],
                            ),
                          );
                        }

                        final sponsor = snapshot.data;
                        if (sponsor == null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.theme.colors.muted.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.theme.colors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: context.theme.colors.mutedForeground, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No sponsor found for ID ${_lastSponsorId}.',
                                    style: TextStyle(color: context.theme.colors.mutedForeground),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SponsorInfoCard(sponsor: sponsor);
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickSchedule,
                    icon: Icon(Icons.event, color: context.foreground),
                    label: Text('Winner announcement date: ${_formatDateTime(_scheduledArchiveAt)}', style: TextStyle(color: context.foreground)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Status: ', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: true, label: Text('Draft'), icon: Icon(Icons.drafts_outlined, size: 16)),
                    ButtonSegment(value: false, label: Text('Active'), icon: Icon(Icons.public, size: 16)),
                  ],
                  selected: {_isDraft},
                  onSelectionChanged: (s) => setState(() => _isDraft = s.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: context.foreground)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _create,
                    child: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                          )
                        : Text(_isDraft ? 'Create as Draft' : 'Create & Publish', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


