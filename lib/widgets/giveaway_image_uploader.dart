import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/services/giveaway_service.dart';
import 'package:trailerhustle_admin/theme.dart';

/// Displays an image preview (if available) and allows uploading a new image.
///
/// This widget uploads the selected image to Supabase Storage and returns the
/// resulting public URL via [onUrlChanged].
class GiveawayImageUploader extends StatefulWidget {
  const GiveawayImageUploader({
    super.key,
    required this.imageUrl,
    required this.onUrlChanged,
    this.aspectRatio = 16 / 6,
  });

  final String imageUrl;
  final ValueChanged<String> onUrlChanged;
  final double aspectRatio;

  @override
  State<GiveawayImageUploader> createState() => _GiveawayImageUploaderState();
}

class _GiveawayImageUploaderState extends State<GiveawayImageUploader> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Could not read selected image bytes.');
      }

      final url = await GiveawayService.uploadGiveawayImage(bytes: bytes, filename: file.name);
      widget.onUrlChanged(url);
    } catch (e) {
      debugPrint('GiveawayImageUploader: upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.imageUrl.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.theme.colors.border),
            color: context.theme.colors.muted.withValues(alpha: 0.25),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: imageUrl.isEmpty
                ? Center(
                    child: Text(
                      _uploading ? 'Uploading…' : 'No image',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(
                            'Could not load image',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
                          ),
                        ),
                      ),
                      if (_uploading)
                        Container(
                          color: context.theme.colors.background.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: context.theme.colors.foreground),
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
              icon: Icon(Icons.upload, color: context.theme.colors.background),
              label: Text(_uploading ? 'Uploading…' : 'Upload new image', style: TextStyle(color: context.theme.colors.background)),
            ),
            const SizedBox(width: 10),
            if (imageUrl.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _uploading ? null : () => widget.onUrlChanged(''),
                icon: Icon(Icons.delete_outline, color: context.foreground),
                label: Text('Remove', style: TextStyle(color: context.foreground)),
              ),
          ],
        ),
      ],
    );
  }
}
