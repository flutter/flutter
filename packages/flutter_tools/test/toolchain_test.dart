// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/build_configuration.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/toolchain.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('ToolConfiguration', () {
    Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flutter_temp');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    testUsingContext('using cache', () {
      ToolConfiguration toolConfig = new ToolConfiguration(
        overrideCache: new Cache(rootOverride: tempDir)
      );

      expect(
        toolConfig.getToolsDirectory(platform: HostPlatform.linux_x64).path,
        endsWith('cache/artifacts/engine/linux-x64')
      );
      expect(
        toolConfig.getEngineArtifactsDirectory(TargetPlatform.android_arm, BuildVariant.develop).path,
        endsWith('cache/artifacts/engine/android-arm')
      );
      expect(
        toolConfig.getEngineArtifactsDirectory(TargetPlatform.android_arm, BuildVariant.deploy).path,
        endsWith('cache/artifacts/engine/android-arm-deploy')
      );
    });

    testUsingContext('using enginePath', () {
      ToolConfiguration toolConfig = new ToolConfiguration();
      toolConfig.engineSrcPath = 'engine';
      toolConfig.engineRelease = true;

      expect(
        toolConfig.getToolsDirectory(platform: HostPlatform.linux_x64).path,
        'engine/out/Release'
      );
      expect(
        toolConfig.getEngineArtifactsDirectory(TargetPlatform.android_arm, BuildVariant.develop).path,
        'engine/out/android_Release'
      );

      toolConfig.engineRelease = false;
      expect(
        toolConfig.getToolsDirectory(platform: HostPlatform.linux_x64).path,
        'engine/out/Debug'
      );
    });
  });
}
