import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/user_data.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:trailerhustle_admin/widgets/profile/login_method_badge.dart';
import 'package:trailerhustle_admin/widgets/profile/section_wrapper.dart';

/// Section 1: User Details — Login method, IDs, dates, subscription, status.
///
/// This section is designed to make login troubleshooting extremely clear.
/// The login method badge is the FIRST visible element.
class UserDetailsSection extends StatefulWidget {
  const UserDetailsSection({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  final UserData user;
  final ValueChanged<UserData> onUserUpdated;

  @override
  State<UserDetailsSection> createState() => _UserDetailsSectionState();
}

class _UserDetailsSectionState extends State<UserDetailsSection> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _contactEmailCtrl;
  late TextEditingController _countryCodeCtrl;
  late bool _isActive;
  late bool _isVerify;
  late int _completeProfile;
  late String _tier;

  UserData get _user => widget.user;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant UserDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) _syncControllers();
  }

  void _syncControllers() {
    _emailCtrl = TextEditingController(text: _user.email);
    _phoneCtrl = TextEditingController(text: _user.phone);
    _contactEmailCtrl = TextEditingController(text: _user.contactEmail);
    _countryCodeCtrl = TextEditingController(text: _user.countryCode);
    _isActive = _user.isActive;
    _isVerify = _user.isVerify;
    _completeProfile = _user.completeProfile;
    _tier = _user.subscriptionTier;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    _countryCodeCtrl.dispose();
    super.dispose();
  }

  void _enterEdit() => setState(() => _isEditing = true);

  void _cancelEdit() {
    _syncControllers();
    setState(() => _isEditing = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = _user.copyWith(
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        contactEmail: _contactEmailCtrl.text.trim(),
        countryCode: _countryCodeCtrl.text.trim(),
        isActive: _isActive,
        isVerify: _isVerify,
        completeProfile: _completeProfile,
        subscriptionTier: _tier,
        isSubscribed: _tier != 'free',
        hasHustleProPlan: _tier == 'pro',
        updatedAt: DateTime.now().toUtc(),
      );
      await UserService.updateUser(updated);
      widget.onUserUpdated(updated);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User details updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  String _formatDate(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '—';
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  String _formatLoginTime() {
    final dt = _user.lastLoginDate;
    if (dt == null) return '—';
    return _formatDate(dt);
  }

  String _deviceLabel() {
    switch (_user.deviceType) {
      case 1:
        return 'iOS';
      case 2:
        return 'Android';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ProfileSection(
      title: 'User Details',
      icon: Icons.person_search_outlined,
      isEditing: _isEditing,
      onEdit: _enterEdit,
      onSave: _save,
      onCancel: _cancelEdit,
      isSaving: _isSaving,
      viewChild: _buildView(theme),
      editChild: _buildEdit(theme),
    );
  }

  Widget _buildView(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── LOGIN METHOD — most prominent element ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colors.muted.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGIN METHOD',
                style: theme.typography.xs.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colors.mutedForeground,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ..._user.loginMethods.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LoginMethodBadge(method: m),
                  )),
                  if (_user.isPrivateRelay)
                    StatusPill(text: 'Private Relay Email', color: Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              // Show credential rows for each detected method
              if (_user.loginMethods.contains('Email') || _user.loginMethods.contains('Apple') || _user.loginMethods.contains('Google'))
                _loginCredentialRow('Login Email', _user.email, Icons.email_outlined),
              if (_user.loginMethods.contains('Phone'))
                _loginCredentialRow(
                  'Login Phone',
                  _user.countryCode.isNotEmpty ? '+${_user.countryCode} ${_user.phone}' : _user.phone,
                  Icons.phone_outlined,
                ),
            ],
          ),
        ),

        // ── IDENTIFIERS ──
        _sectionLabel('Identifiers'),
        InfoRow(
          label: 'Unique User ID',
          value: _user.id,
          icon: Icons.fingerprint,
          copyable: true,
          monoValue: true,
          onCopy: () => _copyToClipboard(_user.id, 'User ID'),
        ),
        InfoRow(
          label: 'Business Number',
          value: _user.customerNumber,
          icon: Icons.confirmation_number_outlined,
          copyable: true,
          onCopy: () => _copyToClipboard(_user.customerNumber, 'Business Number'),
        ),
        InfoRow(
          label: 'Auth UID',
          value: _user.socialId,
          icon: Icons.vpn_key_outlined,
          copyable: true,
          monoValue: true,
          onCopy: () => _copyToClipboard(_user.socialId, 'Auth UID'),
        ),
        const Divider(height: 24),

        // ── CONTACT DETAILS ──
        _sectionLabel('Contact Information'),
        InfoRow(label: 'Email', value: _user.email, icon: Icons.email_outlined),
        InfoRow(label: 'Contact Email', value: _user.contactEmail, icon: Icons.alternate_email),
        InfoRow(
          label: 'Phone',
          value: _user.countryCode.isNotEmpty ? '+${_user.countryCode} ${_user.phone}' : _user.phone,
          icon: Icons.phone_outlined,
        ),
        const Divider(height: 24),

        // ── SUBSCRIPTION & STATUS ──
        _sectionLabel('Account Status'),
        InfoRow(
          label: 'Subscription Tier',
          value: '',
          icon: Icons.workspace_premium_outlined,
          valueWidget: _tierPill(_user.subscriptionTier),
        ),
        InfoRow(
          label: 'Account Status',
          value: '',
          icon: Icons.toggle_on_outlined,
          valueWidget: StatusPill(
            text: _user.isActive ? 'Active' : 'Inactive',
            color: _user.isActive ? Colors.green : Colors.red,
          ),
        ),
        InfoRow(
          label: 'Verified',
          value: '',
          icon: Icons.verified_outlined,
          valueWidget: StatusPill(
            text: _user.isVerify ? 'Verified' : 'Unverified',
            color: _user.isVerify ? Colors.green : Colors.orange,
          ),
        ),
        InfoRow(
          label: 'Profile Complete',
          value: _user.completeProfile == 1 ? 'Yes' : 'No',
          icon: Icons.check_circle_outline,
        ),
        const Divider(height: 24),

        // ── TIMESTAMPS ──
        _sectionLabel('Dates'),
        InfoRow(label: 'Created', value: _formatDate(_user.createdAt), icon: Icons.calendar_today_outlined),
        InfoRow(label: 'Last Updated', value: _formatDate(_user.updatedAt), icon: Icons.update_outlined),
        InfoRow(label: 'Last Login', value: _formatLoginTime(), icon: Icons.login_outlined),
        InfoRow(label: 'Device Type', value: _deviceLabel(), icon: Icons.devices_outlined),
      ],
    );
  }

  Widget _buildEdit(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Login method is NOT editable — display read-only
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colors.muted.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              ..._user.loginMethods.map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: LoginMethodBadge(method: m),
              )),
              const SizedBox(width: 4),
              Text('Login method cannot be changed', style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground)),
            ],
          ),
        ),

        EditableField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
        EditableField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
        EditableField(label: 'Country Code', controller: _countryCodeCtrl),
        EditableField(label: 'Contact Email (secondary)', controller: _contactEmailCtrl, keyboardType: TextInputType.emailAddress),

        const SizedBox(height: 8),

        // Subscription Tier
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colors.muted.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Subscription Tier'),
                trailing: DropdownButton<String>(
                  value: _tier,
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: 'free', child: Text('Free')),
                    DropdownMenuItem(value: 'lite', child: Text('Lite')),
                    DropdownMenuItem(value: 'pro', child: Text('Pro')),
                  ],
                  onChanged: _isSaving ? null : (v) {
                    if (v != null) setState(() => _tier = v);
                  },
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: _isSaving ? null : (v) => setState(() => _isActive = v),
                title: const Text('Account Active'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isVerify,
                onChanged: _isSaving ? null : (v) => setState(() => _isVerify = v),
                title: const Text('Verified'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _completeProfile == 1,
                onChanged: _isSaving ? null : (v) => setState(() => _completeProfile = v ? 1 : 0),
                title: const Text('Profile Complete'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loginCredentialRow(String label, String value, IconData icon) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colors.mutedForeground),
          const SizedBox(width: 8),
          Text(label, style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value.trim().isEmpty ? '—' : value,
              style: theme.typography.sm.copyWith(color: theme.colors.foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final theme = context.theme;
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

  Widget _tierPill(String tier) {
    Color color;
    switch (tier) {
      case 'pro':
        color = Colors.amber;
        break;
      case 'lite':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return StatusPill(
      text: tier[0].toUpperCase() + tier.substring(1),
      color: color,
    );
  }
}
