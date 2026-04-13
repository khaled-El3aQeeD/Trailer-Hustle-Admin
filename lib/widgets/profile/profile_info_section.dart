import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/user_data.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:trailerhustle_admin/widgets/profile/section_wrapper.dart';

/// Section 2: Full Profile Information — Name, description, categories,
/// location, social media, and contact details the customer entered.
class ProfileInfoSection extends StatefulWidget {
  const ProfileInfoSection({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  final UserData user;
  final ValueChanged<UserData> onUserUpdated;

  @override
  State<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _ProfileInfoSectionState extends State<ProfileInfoSection> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _facebookCtrl;
  late TextEditingController _youtubeCtrl;
  late TextEditingController _twitterCtrl;
  late TextEditingController _tiktokCtrl;
  late TextEditingController _businessPhoneCtrl;
  late TextEditingController _businessCountryCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _latitudeCtrl;
  late TextEditingController _longitudeCtrl;
  late TextEditingController _zipCodeCtrl;
  late TextEditingController _cityStateCtrl;
  late bool _isFeatured;

  // Categories
  List<Map<String, dynamic>> _allCategories = [];
  int? _selectedCategoryId;

  UserData get _user => widget.user;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant ProfileInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) _syncControllers();
  }

  void _syncControllers() {
    _nameCtrl = TextEditingController(text: _user.name);
    _descCtrl = TextEditingController(text: _user.description);
    _websiteCtrl = TextEditingController(text: _user.website);
    _locationCtrl = TextEditingController(text: _user.location.isNotEmpty ? _user.location : _user.regularCityState);
    _instagramCtrl = TextEditingController(text: _user.instagram);
    _facebookCtrl = TextEditingController(text: _user.facebook);
    _youtubeCtrl = TextEditingController(text: _user.youtube);
    _twitterCtrl = TextEditingController(text: _user.twitter);
    _tiktokCtrl = TextEditingController(text: _user.tiktok);
    _businessPhoneCtrl = TextEditingController(text: _user.businessContactNumber);
    _businessCountryCtrl = TextEditingController(text: _user.businessCountryCode);
    _colorCtrl = TextEditingController(text: _user.color);
    _latitudeCtrl = TextEditingController(text: _user.latitude != 0 ? _user.latitude.toString() : '');
    _longitudeCtrl = TextEditingController(text: _user.longitude != 0 ? _user.longitude.toString() : '');
    _zipCodeCtrl = TextEditingController(text: _user.zipCode);
    _cityStateCtrl = TextEditingController(text: _user.regularCityState);
    _isFeatured = _user.isFeatured;
    _selectedCategoryId = _user.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _youtubeCtrl.dispose();
    _twitterCtrl.dispose();
    _tiktokCtrl.dispose();
    _businessPhoneCtrl.dispose();
    _businessCountryCtrl.dispose();
    _colorCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _zipCodeCtrl.dispose();
    _cityStateCtrl.dispose();
    super.dispose();
  }

  Future<void> _enterEdit() async {
    // Load categories when entering edit mode
    if (_allCategories.isEmpty) {
      _allCategories = await UserService.fetchAllCategories();
    }
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    _syncControllers();
    setState(() => _isEditing = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = _user.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        instagram: _instagramCtrl.text.trim(),
        facebook: _facebookCtrl.text.trim(),
        youtube: _youtubeCtrl.text.trim(),
        twitter: _twitterCtrl.text.trim(),
        tiktok: _tiktokCtrl.text.trim(),
        businessContactNumber: _businessPhoneCtrl.text.trim(),
        businessCountryCode: _businessCountryCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        latitude: double.tryParse(_latitudeCtrl.text.trim()) ?? _user.latitude,
        longitude: double.tryParse(_longitudeCtrl.text.trim()) ?? _user.longitude,
        zipCode: _zipCodeCtrl.text.trim(),
        regularCityState: _cityStateCtrl.text.trim(),
        isFeatured: _isFeatured,
        categoryId: _selectedCategoryId,
        updatedAt: DateTime.now().toUtc(),
      );
      await UserService.updateUser(updated);
      widget.onUserUpdated(updated);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Full Profile Information',
      icon: Icons.account_box_outlined,
      isEditing: _isEditing,
      onEdit: _enterEdit,
      onSave: _save,
      onCancel: _cancelEdit,
      isSaving: _isSaving,
      viewChild: _buildView(context),
      editChild: _buildEdit(context),
    );
  }

  Widget _buildView(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Basic Info ──
        _sectionLabel(theme, 'Basic Information'),
        InfoRow(label: 'Display Name', value: _user.name, icon: Icons.badge_outlined),
        InfoRow(label: 'Category', value: _user.categoryType, icon: Icons.category_outlined),
        InfoRow(label: 'Featured', value: _user.isFeatured ? 'Yes' : 'No', icon: Icons.star_outline),
        if (_user.color.isNotEmpty)
          InfoRow(
            label: 'Accent Color',
            value: _user.color,
            icon: Icons.palette_outlined,
            valueWidget: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _parseColor(_user.color),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colors.border),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_user.color, style: theme.typography.sm.copyWith(color: theme.colors.foreground)),
              ],
            ),
          ),
        const Divider(height: 24),

        // ── About Us / Description ──
        _sectionLabel(theme, 'About Us'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colors.muted.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            _user.description.trim().isEmpty ? 'No description provided.' : _user.description,
            style: theme.typography.sm.copyWith(
              color: _user.description.trim().isEmpty ? theme.colors.mutedForeground : theme.colors.foreground,
              height: 1.5,
            ),
          ),
        ),
        const Divider(height: 24),

        // ── Location ──
        _sectionLabel(theme, 'Location'),
        InfoRow(label: 'Address', value: _user.location.isNotEmpty ? _user.location : _user.regularCityState, icon: Icons.location_on_outlined),
        InfoRow(label: 'City / State', value: _user.regularCityState, icon: Icons.location_city_outlined),
        if (_user.latitude != 0 || _user.longitude != 0)
          InfoRow(label: 'Coordinates', value: '${_user.latitude.toStringAsFixed(6)}, ${_user.longitude.toStringAsFixed(6)}', icon: Icons.my_location_outlined),
        if (_user.zipCode.isNotEmpty)
          InfoRow(label: 'Zip Code', value: _user.zipCode, icon: Icons.markunread_mailbox_outlined),
        const Divider(height: 24),

        // ── Contact Details ──
        _sectionLabel(theme, 'Business Contact'),
        InfoRow(label: 'Business Phone', value: _user.businessContactNumber, icon: Icons.phone_outlined),
        InfoRow(label: 'Website', value: _user.website, icon: Icons.language_outlined),
        const Divider(height: 24),

        // ── Social Media ──
        _sectionLabel(theme, 'Social Media'),
        _socialRow(Icons.camera_alt_outlined, 'Instagram', _user.instagram),
        _socialRow(Icons.facebook_outlined, 'Facebook', _user.facebook),
        _socialRow(Icons.play_circle_outline, 'YouTube', _user.youtube),
        _socialRow(Icons.alternate_email, 'Twitter / X', _user.twitter),
        _socialRow(Icons.music_note_outlined, 'TikTok', _user.tiktok),
      ],
    );
  }

  Widget _buildEdit(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(theme, 'Basic Information'),
        EditableField(label: 'Display Name', controller: _nameCtrl),
        // Category dropdown
        if (_allCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                ..._allCategories.map((c) {
                  final id = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '');
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(c['name']?.toString() ?? ''),
                  );
                }),
              ],
              onChanged: _isSaving ? null : (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _isFeatured,
          onChanged: _isSaving ? null : (v) => setState(() => _isFeatured = v),
          title: const Text('Featured Business'),
        ),
        EditableField(label: 'Accent Color (hex)', controller: _colorCtrl),
        const Divider(height: 24),

        _sectionLabel(theme, 'About Us'),
        EditableField(label: 'Description', controller: _descCtrl, maxLines: 5),
        const Divider(height: 24),

        _sectionLabel(theme, 'Location'),
        EditableField(label: 'Address / Location', controller: _locationCtrl),
        EditableField(label: 'City / State', controller: _cityStateCtrl),
        EditableField(label: 'Zip Code', controller: _zipCodeCtrl),
        Row(
          children: [
            Expanded(child: EditableField(label: 'Latitude', controller: _latitudeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: EditableField(label: 'Longitude', controller: _longitudeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          ],
        ),
        const Divider(height: 24),

        _sectionLabel(theme, 'Business Contact'),
        EditableField(label: 'Business Phone', controller: _businessPhoneCtrl, keyboardType: TextInputType.phone),
        EditableField(label: 'Business Country Code', controller: _businessCountryCtrl),
        EditableField(label: 'Website', controller: _websiteCtrl, keyboardType: TextInputType.url),
        const Divider(height: 24),

        _sectionLabel(theme, 'Social Media'),
        EditableField(label: 'Instagram', controller: _instagramCtrl),
        EditableField(label: 'Facebook', controller: _facebookCtrl),
        EditableField(label: 'YouTube', controller: _youtubeCtrl),
        EditableField(label: 'Twitter / X', controller: _twitterCtrl),
        EditableField(label: 'TikTok', controller: _tiktokCtrl),
      ],
    );
  }

  Widget _socialRow(IconData icon, String label, String value) {
    final theme = context.theme;
    final display = value.trim().isEmpty ? '—' : value.trim();
    final hasValue = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: hasValue ? theme.colors.primary : theme.colors.mutedForeground),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SelectableText(
              display,
              style: theme.typography.sm.copyWith(
                color: hasValue ? theme.colors.foreground : theme.colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(FThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: theme.typography.xs.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colors.mutedForeground,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
      if (cleaned.length == 8) return Color(int.parse(cleaned, radix: 16));
    } catch (_) {}
    return Colors.grey;
  }
}
