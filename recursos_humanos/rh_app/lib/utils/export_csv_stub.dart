import 'dart:typed_data';

Future<void> exportCsv({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('Export no soportado en esta plataforma.');
}