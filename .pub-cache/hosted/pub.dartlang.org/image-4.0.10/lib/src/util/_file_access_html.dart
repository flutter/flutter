import 'dart:typed_data';

bool supportsFileAccess() => false;

Future<Uint8List?> readFile(String path) async => null;

Future<bool> writeFile(String path, Uint8List bytes) async => false;
