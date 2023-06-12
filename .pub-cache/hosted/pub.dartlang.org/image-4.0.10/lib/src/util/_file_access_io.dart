import 'dart:io';
import 'dart:typed_data';

bool supportsFileAccess() => true;

Future<Uint8List?> readFile(String path) => File(path).readAsBytes();

Future<bool> writeFile(String path, Uint8List bytes) async {
  final fp = File(path);
  await fp.create(recursive: true);
  await fp.writeAsBytes(bytes);
  return fp.exists();
}
