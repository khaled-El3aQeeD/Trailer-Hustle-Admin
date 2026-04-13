import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/user_data.dart';
import 'package:trailerhustle_admin/services/image_upload_service.dart';
import 'package:trailerhustle_admin/services/user_service.dart';
import 'package:trailerhustle_admin/widgets/profile/section_wrapper.dart';

/// Section 3: Photos — Profile photo management.
///
/// Admin can upload images from local device, paste URLs, replace, and remove
/// the profile photo.
class PhotosSection extends StatefulWidget {
  const PhotosSection({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  final UserData user;
  final ValueChanged<UserData> onUserUpdated;

  @override
  State<PhotosSection> createState() => _PhotosSectionState();
}

class _PhotosSectionState extends State<PhotosSection> {
  bool _isEditing = false;
  bool _isSaving = false;

  // Track whether an individual upload is in progress
  bool _uploadingProfile = false;

  late TextEditingController _profileImageCtrl;

  UserData get _user => widget.user;

  @override
  void initState() {
    super.initState();
    _profileImageCtrl = TextEditingController(text: _user.avatar);
  }

  @override
  void didUpdateWidget(covariant PhotosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _profileImageCtrl.text = widget.user.avatar;
    }
  }

  @override
  void dispose() {
    _profileImageCtrl.dispose();
    super.dispose();
  }

  void _enterEdit() => setState(() => _isEditing = true);

  void _cancelEdit() {
    _profileImageCtrl.text = _user.avatar;
    setState(() => _isEditing = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = _user.copyWith(
        avatar: _profileImageCtrl.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );
      await UserService.updateUser(updated);
      widget.onUserUpdated(updated);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Upload from device
  // ---------------------------------------------------------------------------

  Future<void> _uploadProfileImage() async {
    final file = await ImageUploadService.pickImage();
    if (file == null || file.bytes == null) return;
    setState(() => _uploadingProfile = true);
    try {
      final url = await ImageUploadService.uploadProfileImage(
        businessId: _user.id,
        bytes: file.bytes!,
        filename: file.name,
      );
      _profileImageCtrl.text = url;
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingProfile = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Photos',
      icon: Icons.photo_library_outlined,
      isEditing: _isEditing,
      onEdit: _enterEdit,
      onSave: _save,
      onCancel: _cancelEdit,
      isSaving: _isSaving,
      viewChild: _buildView(context),
      editChild: _buildEdit(context),
    );
  }

  // ---------------------------------------------------------------------------
  // View mode
  // ---------------------------------------------------------------------------

  Widget _buildView(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile photo
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Photo', style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: _networkImage(_user.avatar, 80, 80),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Edit mode
  // ---------------------------------------------------------------------------

  Widget _buildEdit(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Profile Photo ──
        Text('Profile Photo', style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            _imagePreviewWithUpload(
              currentUrl: _profileImageCtrl.text,
              size: 64,
              circular: true,
              uploading: _uploadingProfile,
              onUpload: _uploadProfileImage,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _profileImageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL (or upload)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            IconButton(
              onPressed: () {
                _profileImageCtrl.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Clear',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Click the image thumbnail to upload from your device, or paste a URL directly.',
          style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Image preview with a clickable upload overlay.
  Widget _imagePreviewWithUpload({
    required String currentUrl,
    required double size,
    required bool circular,
    required bool uploading,
    required VoidCallback onUpload,
  }) {
    final borderRadius = circular ? BorderRadius.circular(999) : BorderRadius.circular(8);
    return GestureDetector(
      onTap: uploading ? null : onUpload,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: _networkImage(currentUrl, size, size),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: uploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_outlined, size: 22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkImage(String url, double height, double fallbackSize, {double? width}) {
    if (url.trim().isEmpty) {
      return Container(
        width: width ?? fallbackSize,
        height: height,
        color: context.theme.colors.muted.withValues(alpha: 0.25),
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, size: 24, color: context.theme.colors.mutedForeground),
      );
    }
    return Image.network(
      url,
      width: width ?? fallbackSize,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width ?? fallbackSize,
        height: height,
        color: context.theme.colors.muted.withValues(alpha: 0.25),
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, size: 24, color: context.theme.colors.mutedForeground),
      ),
    );
  }
}
