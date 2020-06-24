// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:meta/meta.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:yaml/yaml.dart';
import 'common.dart';

/// Writes a schemaData used for validating pubspec.yaml files when parsing
/// asset information.
void writeSchemaFile(FileSystem filesystem, String schemaData) {
  final String schemaPath = buildSchemaPath(filesystem);
  final File schemaFile = filesystem.file(schemaPath);

  final String schemaDir = buildSchemaDir(filesystem);

  filesystem.directory(schemaDir).createSync(recursive: true);
  schemaFile.writeAsStringSync(schemaData);
}

/// Writes an empty schemaData that will validate any pubspec.yaml file.
void writeEmptySchemaFile(FileSystem filesystem) {
  writeSchemaFile(filesystem, '{}');
}

/// Check if the pubspec.yaml file under the `projectDir` is valid for a plugin project.
void validatePubspecForPlugin({@required String projectDir, @required String pluginClass, @required List<String> expectedPlatforms, List<String> unexpectedPlatforms = const <String>[], String androidIdentifier, String webFileName}) {
    final FlutterManifest manifest = FlutterManifest.createFromPath(projectDir+'/pubspec.yaml', fileSystem: globals.fs, logger: globals.logger);
    final YamlMap platformsMap = YamlMap.wrap(manifest.supportedPlatforms);
    for (final String platform in expectedPlatforms) {
      expect(platformsMap[platform], isNotNull);
      expect(platformsMap[platform]['pluginClass'], pluginClass);
      if (platform == 'android') {
        expect(platformsMap[platform]['package'], androidIdentifier);
      }
      if (platform == 'web') {
        expect(platformsMap[platform]['fileName'], webFileName);
      }
    }
    for (final String platform in unexpectedPlatforms) {
      expect(platformsMap[platform], isNull);
    }
}
