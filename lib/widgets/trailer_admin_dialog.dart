import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/trailer_data.dart';
import 'package:trailerhustle_admin/models/trailer_rating_data.dart';
import 'package:trailerhustle_admin/services/trailer_service.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:trailerhustle_admin/widgets/trailer_image_uploader.dart';

/// Admin dialog for viewing/editing a trailer and viewing its ratings.
///
/// Returns `true` from [show] when the trailer was successfully saved.
class TrailerAdminDialog extends StatefulWidget {
  const TrailerAdminDialog({super.key, required this.trailer});
  final TrailerData trailer;

  static Future<bool> show(BuildContext context, {required TrailerData trailer}) async {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final isCompact = width < 720;

    if (isCompact) {
      final res = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FractionallySizedBox(
                heightFactor: 0.94,
                child: _DialogSurface(child: TrailerAdminDialog(trailer: trailer)),
              ),
            ),
          );
        },
      );
      return res ?? false;
    }

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final maxWidth = (width * 0.72).clamp(820.0, 1080.0);
        final maxHeight = (height * 0.88).clamp(620.0, 900.0);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            child: _DialogSurface(child: TrailerAdminDialog(trailer: trailer)),
          ),
        );
      },
    );
    return res ?? false;
  }

  @override
  State<TrailerAdminDialog> createState() => _TrailerAdminDialogState();
}

class _TrailerAdminDialogState extends State<TrailerAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _saveError;

  late final TextEditingController _businessId;
  late final TextEditingController _displayName;
  late final TextEditingController _email;
  late final TextEditingController _image;
  late final TextEditingController _makeId;
  late final TextEditingController _trailerName;
  late final TextEditingController _trailerType;
  late final TextEditingController _win;
  late final TextEditingController _length;
  late final TextEditingController _lengthUnit;
  late final TextEditingController _width;
  late final TextEditingController _widthUnit;
  late final TextEditingController _loadCapacity;

  int? _selectedBrandId;
  Future<Map<int, String>>? _brandsFuture;

  TrailerData get _t => widget.trailer;

  @override
  void initState() {
    super.initState();
    _businessId = TextEditingController(text: _t.businessId.toString());
    _displayName = TextEditingController(text: _t.displayName);
    _email = TextEditingController(text: _t.email ?? '');
    _image = TextEditingController(text: _t.image);
    _makeId = TextEditingController(text: _t.brand.toString());
    // Current backend schema: Trailers.model is stored in `trailerName`.
    // Keep the controller named `_trailerName` but treat it as the model field.
    _trailerName = TextEditingController(text: (_t.trailerName ?? _t.model ?? ''));
    _trailerType = TextEditingController(text: (_t.trailerType ?? 0).toString());
    _win = TextEditingController(text: _t.winNumber);
    _length = TextEditingController(text: _t.length.toString());
    _lengthUnit = TextEditingController(text: _t.lengthUnit);
    _width = TextEditingController(text: _t.width.toString());
    _widthUnit = TextEditingController(text: _t.widthUnit);
    _loadCapacity = TextEditingController(text: _t.loadCapacity.toString());
    _selectedBrandId = _t.brand > 0 ? _t.brand : null;
    _brandsFuture = TrailerService.fetchAllBrandTitles();
  }

  @override
  void dispose() {
    _businessId.dispose();
    _displayName.dispose();
    _email.dispose();
    _image.dispose();
    _makeId.dispose();
    _trailerName.dispose();
    _trailerType.dispose();
    _win.dispose();
    _length.dispose();
    _lengthUnit.dispose();
    _width.dispose();
    _widthUnit.dispose();
    _loadCapacity.dispose();
    super.dispose();
  }

  String _title() {
    final dn = _t.displayName.trim();
    if (dn.isNotEmpty) return dn;
    final tn = (_t.trailerName ?? '').trim();
    if (tn.isNotEmpty) return tn;
    return 'Trailer #${_t.id}';
  }

  int? _tryParseInt(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _save() async {
    setState(() {
      _saveError = null;
      _saving = true;
    });

    try {
      final formState = _formKey.currentState;
      final ok = formState?.validate() ?? true;
      if (!ok) return;

      final businessId = _tryParseInt(_businessId.text) ?? 0;
      final brandId = _selectedBrandId ?? _tryParseInt(_makeId.text) ?? 0;
      final trailerType = _tryParseInt(_trailerType.text);
      final length = _tryParseInt(_length.text) ?? 0;
      final width = _tryParseInt(_width.text) ?? 0;
      final loadCapacity = _tryParseInt(_loadCapacity.text) ?? 0;

      final payload = <String, dynamic>{
        'bussinessid': businessId,
        'displayName': _displayName.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'image': _image.text.trim(),
        'brand': brandId,
        // Current schema: model is stored under `trailerName`.
        'trailerName': _trailerName.text.trim().isEmpty ? null : _trailerName.text.trim(),
        'trailerType': trailerType == null || trailerType == 0 ? null : trailerType,
        'winNumber': _win.text.trim(),
        'length': length,
        'lengthUnit': _lengthUnit.text.trim(),
        'width': width,
        'widthUnit': _widthUnit.text.trim(),
        'loadCapacity': loadCapacity,
      };

      await TrailerService.updateTrailer(trailerId: _t.id, data: payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('TrailerAdminDialog save failed: $e');
      if (!mounted) return;
      setState(() => _saveError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t save trailer: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
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
                  child: Icon(Icons.local_shipping_outlined, size: 22, color: theme.colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(),
                        style: theme.typography.lg.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trailer #${_t.id} · Business ${_t.businessId}',
                        style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(false),
                  icon: const Icon(FIcons.x),
                  iconSize: 16,
                  style: IconButton.styleFrom(minimumSize: const Size(38, 38), padding: EdgeInsets.zero, foregroundColor: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colors.muted.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colors.border),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                labelColor: theme.colors.foreground,
                unselectedLabelColor: theme.colors.mutedForeground,
                labelStyle: theme.typography.sm.copyWith(fontWeight: FontWeight.w800),
                unselectedLabelStyle: theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colors.border),
                  boxShadow: [BoxShadow(color: theme.colors.foreground.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 10))],
                ),
                tabs: const [Tab(text: 'Edit'), Tab(text: 'Photos'), Tab(text: 'Comments'), Tab(text: 'Ratings')],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _TrailerEditTab(
                  formKey: _formKey,
                  saving: _saving,
                  saveError: _saveError,
                  brandsFuture: _brandsFuture,
                  selectedBrandId: _selectedBrandId,
                  onBrandChanged: (id) => setState(() {
                    _selectedBrandId = id;
                    if (id != null) _makeId.text = id.toString();
                  }),
                  businessId: _businessId,
                  displayName: _displayName,
                  email: _email,
                  makeId: _makeId,
                  trailerName: _trailerName,
                  trailerType: _trailerType,
                  win: _win,
                  length: _length,
                  lengthUnit: _lengthUnit,
                  width: _width,
                  widthUnit: _widthUnit,
                  loadCapacity: _loadCapacity,
                  onSave: _saving ? null : _save,
                ),
                _TrailerPhotosTab(image: _image, saving: _saving, onSave: _saving ? null : _save),
                _TrailerCommentsTab(trailerId: _t.id),
                _TrailerRatingsTab(trailerId: _t.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailerFeedbackRepository {
  static Future<_RatingsData> loadRatingsData({required int trailerId}) async {
    final ratings = await TrailerService.fetchRatingsForTrailer(trailerId: trailerId);
    final businessIds = ratings.map((r) => r.businessId).where((id) => id > 0).toSet().toList(growable: false);

    Map<int, String> businessNameById = const <int, String>{};
    if (businessIds.isNotEmpty) {
      try {
        businessNameById = await UserService.fetchBusinessNamesByIds(businessIds: businessIds);
      } catch (e) {
        debugPrint('Feedback tabs: failed to resolve business names: $e');
      }
    }

    return _RatingsData(ratings: ratings, businessNameById: businessNameById);
  }
}

class _TrailerEditTab extends StatelessWidget {
  const _TrailerEditTab({
    required this.formKey,
    required this.saving,
    required this.saveError,
    required this.brandsFuture,
    required this.selectedBrandId,
    required this.onBrandChanged,
    required this.businessId,
    required this.displayName,
    required this.email,
    required this.makeId,
    required this.trailerName,
    required this.trailerType,
    required this.win,
    required this.length,
    required this.lengthUnit,
    required this.width,
    required this.widthUnit,
    required this.loadCapacity,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final bool saving;
  final String? saveError;
  final Future<Map<int, String>>? brandsFuture;
  final int? selectedBrandId;
  final ValueChanged<int?> onBrandChanged;
  final TextEditingController businessId;
  final TextEditingController displayName;
  final TextEditingController email;
  final TextEditingController makeId;
  final TextEditingController trailerName;
  final TextEditingController trailerType;
  final TextEditingController win;
  final TextEditingController length;
  final TextEditingController lengthUnit;
  final TextEditingController width;
  final TextEditingController widthUnit;
  final TextEditingController loadCapacity;
  final VoidCallback? onSave;

  String? _requiredInt(String? v, {String? label}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return '${label ?? 'Field'} is required';
    if (int.tryParse(t) == null) return '${label ?? 'Field'} must be a number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          _AirbnbCard(
            title: 'Edit details',
            icon: Icons.edit_note_outlined,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _TwoCol(
                    left: TextFormField(
                      controller: businessId,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Business ID (bussinessid)', prefixIcon: Icon(Icons.confirmation_number_outlined)),
                      validator: (v) => _requiredInt(v, label: 'Business ID'),
                    ),
                    right: TextFormField(
                      controller: win,
                      decoration: const InputDecoration(labelText: 'WIN / VIN number', prefixIcon: Icon(Icons.numbers)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoCol(
                    left: TextFormField(
                      controller: displayName,
                      decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.badge_outlined)),
                    ),
                    right: TextFormField(
                      controller: trailerName,
                      decoration: const InputDecoration(labelText: 'Model (trailerName)', prefixIcon: Icon(Icons.drive_file_rename_outline)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoCol(
                    left: TextFormField(
                      controller: trailerType,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Trailer type (trailerType)', prefixIcon: Icon(Icons.category_outlined)),
                    ),
                    right: TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoCol(
                    left: FutureBuilder<Map<int, String>>(
                      future: brandsFuture,
                      builder: (context, snapshot) {
                        final options = snapshot.data ?? const <int, String>{};
                        final items = options.entries
                            .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                            .toList(growable: false);

                        final hasSelected = selectedBrandId != null && options.containsKey(selectedBrandId);
                        final effectiveValue = hasSelected ? selectedBrandId : null;

                        return DropdownButtonFormField<int>(
                          value: effectiveValue,
                          items: items,
                          onChanged: snapshot.connectionState == ConnectionState.waiting ? null : onBrandChanged,
                          decoration: InputDecoration(
                            labelText: 'Make (brand)',
                            prefixIcon: const Icon(Icons.factory_outlined),
                            helperText: snapshot.connectionState == ConnectionState.waiting
                                ? 'Loading makes…'
                                : (snapshot.hasError ? 'Couldn\'t load makes (you can type the ID below).' : null),
                          ),
                        );
                      },
                    ),
                    right: TextFormField(
                      controller: makeId,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Make ID (brand)', prefixIcon: Icon(Icons.tag)),
                      validator: (v) => _requiredInt(v, label: 'Make ID'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoCol(
                    left: TextFormField(
                      controller: loadCapacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Load capacity', prefixIcon: Icon(Icons.scale_outlined)),
                      validator: (v) => _requiredInt(v, label: 'Load capacity'),
                    ),
                    right: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  _TwoCol(
                    left: TextFormField(
                      controller: length,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Length', prefixIcon: Icon(Icons.straighten_outlined)),
                      validator: (v) => _requiredInt(v, label: 'Length'),
                    ),
                    right: TextFormField(
                      controller: lengthUnit,
                      decoration: const InputDecoration(labelText: 'Length unit', prefixIcon: Icon(Icons.square_foot_outlined)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoCol(
                    left: TextFormField(
                      controller: width,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Width', prefixIcon: Icon(Icons.straighten_outlined)),
                      validator: (v) => _requiredInt(v, label: 'Width'),
                    ),
                    right: TextFormField(
                      controller: widthUnit,
                      decoration: const InputDecoration(labelText: 'Width unit', prefixIcon: Icon(Icons.square_foot_outlined)),
                    ),
                  ),
                  if (saveError != null) ...[
                    const SizedBox(height: 12),
                    _ErrorCallout(message: saveError!),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          onPress: onSave,
                          style: FButtonStyle.primary(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (saving) ...[
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.colors.primaryForeground),
                                ),
                                const SizedBox(width: 10),
                              ] else ...[
                                Icon(Icons.save_outlined, size: 18, color: theme.colors.primaryForeground),
                                const SizedBox(width: 10),
                              ],
                              Text(saving ? 'Saving…' : 'Save changes', style: TextStyle(color: theme.colors.primaryForeground)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Edits update the Supabase "Trailers" row in-place.',
              style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailerPhotosTab extends StatefulWidget {
  const _TrailerPhotosTab({required this.image, required this.saving, required this.onSave});
  final TextEditingController image;
  final bool saving;
  final VoidCallback? onSave;

  @override
  State<_TrailerPhotosTab> createState() => _TrailerPhotosTabState();
}

class _TrailerPhotosTabState extends State<_TrailerPhotosTab> {
  @override
  void initState() {
    super.initState();
    widget.image.addListener(_onImageChanged);
  }

  @override
  void didUpdateWidget(covariant _TrailerPhotosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      oldWidget.image.removeListener(_onImageChanged);
      widget.image.addListener(_onImageChanged);
    }
  }

  @override
  void dispose() {
    widget.image.removeListener(_onImageChanged);
    super.dispose();
  }

  void _onImageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final rawImage = widget.image.text.trim();
    final previewUrl = TrailerService.resolveTrailerImageUrl(rawImage);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          _AirbnbCard(
            title: 'Photos',
            icon: Icons.image_outlined,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: previewUrl.isEmpty
                        ? Container(
                            color: theme.colors.muted.withValues(alpha: 0.35),
                            alignment: Alignment.center,
                            child: Text('No image', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800)),
                          )
                        : Image.network(
                            previewUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: theme.colors.muted.withValues(alpha: 0.35),
                              alignment: Alignment.center,
                              child: Text('Could not load image', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground)),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TrailerImageUploader(
                  imageUrl: rawImage,
                  onUrlChanged: (url) {
                    widget.image.text = url;
                    widget.image.selection = TextSelection.collapsed(offset: widget.image.text.length);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: widget.image,
                  decoration: const InputDecoration(
                    labelText: 'Image (URL or Storage path)',
                    hintText: 'https://… or trailers/my_image.jpg',
                    prefixIcon: Icon(Icons.link_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        onPress: widget.onSave,
                        style: FButtonStyle.primary(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.saving) ...[
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colors.primaryForeground)),
                              const SizedBox(width: 10),
                            ] else ...[
                              Icon(Icons.save_outlined, size: 18, color: theme.colors.primaryForeground),
                              const SizedBox(width: 10),
                            ],
                            Text(widget.saving ? 'Saving…' : 'Save changes', style: TextStyle(color: theme.colors.primaryForeground)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'The Image URL is saved on the trailer row (image column).',
              style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailerRatingsTab extends StatefulWidget {
  const _TrailerRatingsTab({required this.trailerId});
  final int trailerId;

  @override
  State<_TrailerRatingsTab> createState() => _TrailerRatingsTabState();
}

class _TrailerRatingsTabState extends State<_TrailerRatingsTab> {
  Future<_RatingsData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RatingsData> _load() async {
    return _TrailerFeedbackRepository.loadRatingsData(trailerId: widget.trailerId);
  }

  double _avgOf(List<double> values) => values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FutureBuilder<_RatingsData>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final err = snapshot.error;
        final data = snapshot.data;
        final ratings = data?.ratings ?? const <TrailerRatingData>[];
        final businessNameById = data?.businessNameById ?? const <int, String>{};

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (err != null) {
          debugPrint('Ratings tab load error: $err');
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: _AirbnbCard(
              title: 'Ratings',
              icon: Icons.star_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Could not load ratings from Supabase.', style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
                  const SizedBox(height: 8),
                  Text(
                    'Common causes: Row Level Security (RLS) is enabled without a SELECT policy, or column names don\'t match what the app expects (trailerId / createdAt).',
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Text(err.toString(), style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.4)),
                  const SizedBox(height: 12),
                  FButton(
                    onPress: () => setState(() => _future = _load()),
                    style: FButtonStyle.primary(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 18, color: theme.colors.primaryForeground),
                        const SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: theme.colors.primaryForeground)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (ratings.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: _AirbnbCard(
              title: 'Ratings',
              icon: Icons.star_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No ratings found for this trailer yet.',
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.45, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tip: confirm the row uses trailerId=${widget.trailerId} (exact value), and that your Supabase policies allow SELECT on the ratings table.',
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, height: 1.45, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        }

        final avgRatingAvg = _avgOf(ratings.map((r) => r.ratingAverage ?? 0).where((v) => v > 0).toList(growable: false));
        final avgOverall = _avgOf(ratings.map((r) => r.overallQuality.toDouble()).where((v) => v > 0).toList(growable: false));
        final effectiveAvg = avgRatingAvg > 0 ? avgRatingAvg : avgOverall;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            children: [
              _AirbnbCard(
                title: 'Ratings summary',
                icon: Icons.analytics_outlined,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SummaryPill(icon: Icons.reviews_outlined, label: 'Total ratings', value: ratings.length.toString()),
                    _SummaryPill(icon: Icons.star, label: 'Avg rating', value: effectiveAvg == 0 ? '—' : effectiveAvg.toStringAsFixed(2)),
                    _SummaryPill(icon: Icons.star_border, label: 'Avg overall', value: avgOverall == 0 ? '—' : avgOverall.toStringAsFixed(2)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _AirbnbCard(
                title: 'All ratings',
                icon: Icons.star_outline,
                child: Column(
                  children: [
                    for (final r in ratings) ...[
                      _RatingRow(rating: r, businessName: businessNameById[r.businessId]),
                      if (r != ratings.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Source: Supabase ratings / rating table (filtered by trailerId=${widget.trailerId})',
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrailerCommentsTab extends StatefulWidget {
  const _TrailerCommentsTab({required this.trailerId});
  final int trailerId;

  @override
  State<_TrailerCommentsTab> createState() => _TrailerCommentsTabState();
}

class _TrailerCommentsTabState extends State<_TrailerCommentsTab> {
  Future<_RatingsData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RatingsData> _load() async => _TrailerFeedbackRepository.loadRatingsData(trailerId: widget.trailerId);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FutureBuilder<_RatingsData>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final err = snapshot.error;
        final data = snapshot.data;
        final ratings = data?.ratings ?? const <TrailerRatingData>[];
        final businessNameById = data?.businessNameById ?? const <int, String>{};

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (err != null) {
          debugPrint('Comments tab load error: $err');
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: _AirbnbCard(
              title: 'Comments',
              icon: Icons.chat_bubble_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Could not load comments from Supabase.', style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.4)),
                  const SizedBox(height: 12),
                  FButton(
                    onPress: () => setState(() => _future = _load()),
                    style: FButtonStyle.primary(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 18, color: theme.colors.primaryForeground),
                        const SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: theme.colors.primaryForeground)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final commentRatings = ratings.where((r) => (r.comment ?? '').trim().isNotEmpty).toList(growable: false);
        if (commentRatings.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: _AirbnbCard(
              title: 'Comments',
              icon: Icons.chat_bubble_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No comments found for this trailer yet.',
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.45, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This tab shows only ratings that include a non-empty comment.',
                    style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, height: 1.45, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            children: [
              _AirbnbCard(
                title: 'All comments',
                icon: Icons.chat_bubble_outline,
                child: Column(
                  children: [
                    for (final r in commentRatings) ...[
                      _CommentRow(rating: r, businessName: businessNameById[r.businessId]),
                      if (r != commentRatings.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Source: Supabase ratings (filtered by trailerId=${widget.trailerId})',
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.rating, required this.businessName});
  final TrailerRatingData rating;
  final String? businessName;

  String _dateText(BuildContext context, DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '—';
    final local = dt.toLocal();
    final ml = MaterialLocalizations.of(context);
    return '${ml.formatShortDate(local)} • ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final avg = (rating.ratingAverage ?? 0) > 0 ? rating.ratingAverage! : rating.overallQuality.toDouble();
    final comment = (rating.comment ?? '').trim();
    final name = (businessName ?? '').trim();
    final label = name.isNotEmpty ? name : (rating.businessId > 0 ? 'Business ${rating.businessId}' : 'Business —');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: theme.colors.primary),
                    const SizedBox(width: 6),
                    Text(avg == 0 ? '—' : avg.toStringAsFixed(2), style: theme.typography.xs.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _dateText(context, rating.createdAt),
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Text(
                  label,
                  style: theme.typography.xs.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment, style: theme.typography.sm.copyWith(color: theme.colors.foreground, height: 1.35, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RatingsData {
  const _RatingsData({required this.ratings, required this.businessNameById});
  final List<TrailerRatingData> ratings;
  final Map<int, String> businessNameById;
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.businessName});
  final TrailerRatingData rating;
  final String? businessName;

  String _dateText(BuildContext context, DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '—';
    final local = dt.toLocal();
    final ml = MaterialLocalizations.of(context);
    return '${ml.formatShortDate(local)} • ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final avg = (rating.ratingAverage ?? 0) > 0 ? rating.ratingAverage! : rating.overallQuality.toDouble();
    final comment = (rating.comment ?? '').trim();
    final name = (businessName ?? '').trim();
    final label = name.isNotEmpty ? name : (rating.businessId > 0 ? 'Business ${rating.businessId}' : 'Business —');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: theme.colors.primary),
                    const SizedBox(width: 6),
                    Text(avg == 0 ? '—' : avg.toStringAsFixed(2), style: theme.typography.xs.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _dateText(context, rating.createdAt),
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Text(
                  label,
                  style: theme.typography.xs.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyMetric(label: 'Overall', value: rating.overallQuality),
              _TinyMetric(label: 'Durability', value: rating.durability),
              _TinyMetric(label: 'Ease', value: rating.easeOfUse),
              _TinyMetric(label: 'Features', value: rating.factoryFeature),
              _TinyMetric(label: 'Finish', value: rating.finishQuality),
              _TinyMetric(label: 'Maintenance', value: rating.maintenance),
              _TinyMetric(label: 'Safety', value: rating.safety),
              _TinyMetric(label: 'Towing', value: rating.towing),
              _TinyMetric(label: 'Value', value: rating.valueOfMoney),
              _TinyMetric(label: 'Additional', value: rating.additional),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: theme.typography.sm.copyWith(color: theme.colors.foreground, height: 1.35, fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  const _TinyMetric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final v = value <= 0 ? '—' : value.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.border),
      ),
      child: Text('$label: $v', style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w900)),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

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

class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 820;
        if (isNarrow) {
          return Column(
            children: [left, const SizedBox(height: 12), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: left), const SizedBox(width: 12), Expanded(child: right)],
        );
      },
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

class _AirbnbCard extends StatelessWidget {
  const _AirbnbCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.border),
        boxShadow: [BoxShadow(color: theme.colors.foreground.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colors.primary.withValues(alpha: 0.20), theme.colors.primary.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colors.border),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: theme.colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground))),
            ],
          ),
          const SizedBox(height: 12),
          child,
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
