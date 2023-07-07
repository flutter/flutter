import 'dart:typed_data';

bool supportsFileAccess() => false;

Future<Uint8List?> readFile(String path) async =>
    throw UnsupportedError('File access is only supported by dart:io');

Future<bool> writeFile(String path, Uint8List bytes) async =>
    throw UnsupportedError('File access is only supported by dart:io');
