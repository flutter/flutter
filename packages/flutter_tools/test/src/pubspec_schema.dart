// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:yaml/yaml.dart';

import 'common.dart';
import 'context.dart' show FakeSignals;

/// Check if the pubspec.yaml file under the `projectDir` is valid for a plugin project.
void validatePubspecForPlugin({
  required String projectDir,
  String? pluginClass,
  bool ffiPlugin = false,
  required List<String> expectedPlatforms,
  List<String> unexpectedPlatforms = const <String>[],
  String? androidIdentifier,
  FileSystem? fileSystem,
  Logger? logger,
  String? webFileName,
}) {
  assert(pluginClass != null || ffiPlugin);
  final FlutterManifest manifest = FlutterManifest.createFromPath(
    '$projectDir/pubspec.yaml',
    fileSystem:
        fileSystem ??
        ErrorHandlingFileSystem(
          delegate: LocalFileSystem.test(signals: FakeSignals()),
          platform: const LocalPlatform(),
        ),
    logger: logger ?? BufferLogger.test(),
  )!;
  final platformMaps = YamlMap.wrap(manifest.supportedPlatforms!);
  for (final platform in expectedPlatforms) {
    expect(platformMaps[platform], isNotNull);
    final platformMap = platformMaps[platform]! as YamlMap;
    if (pluginClass != null) {
      expect(platformMap['pluginClass'], pluginClass);
    }
    if (platform == 'android') {
      expect(platformMap['package'], androidIdentifier);
    }
    if (platform == 'web') {
      expect(platformMap['fileName'], webFileName);
    }
  }
  for (final platform in unexpectedPlatforms) {
    expect(platformMaps[platform], isNull);
  }
}
