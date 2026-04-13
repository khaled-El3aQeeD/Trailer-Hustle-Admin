import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

/// Centralized image upload service for the admin dashboard.
///
/// Uploads files to the Supabase Storage `images` bucket and returns
/// the public URL. Provides helper methods for profile, cover, and
/// gallery image uploads.
class ImageUploadService {
  static const String _bucket = 'images';

  // ---------------------------------------------------------------------------
  // File picker helpers
  // ---------------------------------------------------------------------------

  /// Open the native file picker for a single image.
  ///
  /// Returns `null` if the user cancels.
  static Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single;
  }

  /// Open the native file picker for multiple images.
  static Future<List<PlatformFile>> pickMultipleImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );
    return result?.files ?? const [];
  }

  // ---------------------------------------------------------------------------
  // Upload methods
  // ---------------------------------------------------------------------------

  /// Upload raw bytes to Supabase Storage and return the public URL.
  static Future<String> _upload({
    required String storagePath,
    required Uint8List bytes,
    required String filename,
  }) async {
    final storage = SupabaseConfig.client.storage.from(_bucket);
    await storage.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(
        contentType: _contentType(filename),
        upsert: true,
      ),
    );
    return storage.getPublicUrl(storagePath);
  }

  /// Upload a profile photo for a business.
  ///
  /// Stores at `profiles/{businessId}/profile_{timestamp}.{ext}`.
  static Future<String> uploadProfileImage({
    required String businessId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final ext = _extension(filename);
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = 'profiles/$businessId/profile_$ts.$ext';
    return _upload(storagePath: path, bytes: bytes, filename: filename);
  }

  /// Upload a cover image for a business.
  ///
  /// Stores at `profiles/{businessId}/cover_{timestamp}.{ext}`.
  static Future<String> uploadCoverImage({
    required String businessId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final ext = _extension(filename);
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = 'profiles/$businessId/cover_$ts.$ext';
    return _upload(storagePath: path, bytes: bytes, filename: filename);
  }

  /// Upload a gallery image for a business.
  ///
  /// Stores at `businesses/{businessId}/gallery_{timestamp}.{ext}`.
  static Future<String> uploadGalleryImage({
    required String businessId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final ext = _extension(filename);
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = 'businesses/$businessId/gallery_$ts.$ext';
    return _upload(storagePath: path, bytes: bytes, filename: filename);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return 'jpg';
    return filename.substring(dot + 1).toLowerCase();
  }

  static String _contentType(String filename) {
    final ext = _extension(filename);
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
