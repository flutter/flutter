// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/ios/xcode_build_settings.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  late BufferLogger logger;
  setUp(() {
    logger = BufferLogger.test();
  });

  group('parsedBuildName', () {
    testUsingContext('validation enabled', () async {
      final FlutterManifest manifest = FlutterManifest.empty(logger: logger);

      String? buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: 'xyz'),
      );
      expect(buildName, null);

      buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: '0.0.1'),
      );
      expect(buildName, '0.0.1');

      buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: '1.0.0-beta'),
      );
      expect(buildName, '1.0.0');

      buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: '123.xyz'),
      );
      expect(buildName, '123.0.0');
    });

    testUsingContext('validation disabled', () async {
      final FlutterManifest manifest = FlutterManifest.empty(logger: logger);

      String? buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: 'xyz', validateBuildName: false),
      );
      expect(buildName, 'xyz');

      buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: '0.0.1', validateBuildName: false),
      );
      expect(buildName, '0.0.1');

      buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: '1.0.0-beta', validateBuildName: false),
      );
      expect(buildName, '1.0.0-beta');

      buildName = parsedBuildName(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: true, buildName: '123.xyz', validateBuildName: false),
      );
      expect(buildName, '123.xyz');
    });
  });
}
