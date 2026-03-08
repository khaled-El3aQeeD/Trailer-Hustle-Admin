import 'package:flutter/foundation.dart';

class FileExportServiceImpl {
  static Future<void> downloadCsv({required String filename, required String csv}) async {
    debugPrint(
      'CSV export is only implemented for web in this project template. Requested: $filename',
    );
  }
}
