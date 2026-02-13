import 'export_csv_stub.dart'
    if (dart.library.html) 'export_csv_web.dart' as impl;

Future<void> exportCsv(String filename, String csvContent) {
  return impl.exportCsv(filename, csvContent);
}
