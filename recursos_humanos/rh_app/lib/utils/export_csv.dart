import 'export_csv_stub.dart'
    if (dart.library.html) 'export_csv_web.dart'
    if (dart.library.io) 'export_csv_io.dart' as impl;

import 'dart:typed_data';

Future<void> exportCsv({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) {
  return impl.exportCsv(
    filename: filename,
    bytes: bytes,
    mimeType: mimeType,
  );
}