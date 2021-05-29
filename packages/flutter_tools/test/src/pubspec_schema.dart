// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:meta/meta.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:yaml/yaml.dart';
import 'common.dart';

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
