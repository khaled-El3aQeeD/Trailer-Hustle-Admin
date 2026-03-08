import 'package:trailerhustle_admin/services/file_export_service_impl.dart'
    if (dart.library.html) 'package:trailerhustle_admin/services/file_export_service_web.dart';

class FileExportService {
  static Future<void> downloadCsv({required String filename, required String csv}) =>
      FileExportServiceImpl.downloadCsv(filename: filename, csv: csv);
}
