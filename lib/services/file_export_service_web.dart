// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FileExportServiceImpl {
  static Future<void> downloadCsv({required String filename, required String csv}) async {
    final bytes = csv;
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
