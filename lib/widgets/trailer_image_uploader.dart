import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/services/trailer_service.dart';
import 'package:trailerhustle_admin/theme.dart';

/// Displays a trailer image preview (if available) and allows uploading a new image.
///
/// This uploads the selected image to the Supabase Storage bucket
/// [TrailerService.trailerImagesBucket] and returns a public URL via [onUrlChanged].
class TrailerImageUploader extends StatefulWidget {
  const TrailerImageUploader({
    super.key,
    required this.imageUrl,
    required this.onUrlChanged,
    this.aspectRatio = 16 / 9,
  });

  /// The current value stored for the trailer image.
  ///
  /// Can be a full URL or a Storage path; the widget will preview using
  /// [TrailerService.resolveTrailerImageUrl].
  final String imageUrl;
  final ValueChanged<String> onUrlChanged;
  final double aspectRatio;

  @override
  State<TrailerImageUploader> createState() => _TrailerImageUploaderState();
}

class _TrailerImageUploaderState extends State<TrailerImageUploader> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) throw StateError('Could not read selected image bytes.');

      final url = await TrailerService.uploadTrailerImage(bytes: bytes, filename: file.name);
      widget.onUrlChanged(url);
    } catch (e) {
      debugPrint('TrailerImageUploader: upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final raw = widget.imageUrl.trim();
    final previewUrl = TrailerService.resolveTrailerImageUrl(raw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colors.border),
            color: theme.colors.muted.withValues(alpha: 0.25),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: previewUrl.isEmpty
                ? Center(
                    child: Text(
                      _uploading ? 'Uploading…' : 'No image',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        previewUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(
                            'Could not load image',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.colors.mutedForeground),
                          ),
                        ),
                      ),
                      if (_uploading)
                        Container(
                          color: theme.colors.background.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colors.foreground),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: Icon(Icons.upload, color: theme.colors.background),
              label: Text(_uploading ? 'Uploading…' : 'Upload new image', style: TextStyle(color: theme.colors.background)),
            ),
            const SizedBox(width: 10),
            if (raw.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _uploading ? null : () => widget.onUrlChanged(''),
                icon: Icon(Icons.delete_outline, color: theme.colors.foreground),
                label: Text('Remove', style: TextStyle(color: theme.colors.foreground)),
              ),
          ],
        ),
      ],
    );
  }
}
