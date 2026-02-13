import 'dart:html' as html;

Future<void> exportCsv(String filename, String csvContent) async {
  final blob = html.Blob([csvContent], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
