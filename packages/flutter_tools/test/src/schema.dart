import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';

/// Writes a schemaData, required for pubspec.yaml to be loaded.
void writeSchemaFile(FileSystem filesystem, String schemaData) {
  final String schemaPath = buildSchemaPath(filesystem);
  final File schemaFile = filesystem.file(schemaPath);

  final String schemaDir = buildSchemaDir(filesystem);

  filesystem.directory(schemaDir).createSync(recursive: true);
  filesystem.file(schemaFile).writeAsStringSync(schemaData);
}

/// Writes an empty schemaData. A schema file is required for pubspec.yaml to be loaded.
void writeEmptySchemaFile(FileSystem filesystem) {
  writeSchemaFile(filesystem, '{}');
}
