// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/toolchain.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('ToolConfiguration', () {
    Directory tempDir;
    tempDir = fs.systemTempDirectory.createTempSync('flutter_temp');

    testUsingContext('using cache', () {
      ToolConfiguration toolConfig = new ToolConfiguration();

      expect(
        toolConfig.getEngineArtifactsDirectory(TargetPlatform.android_arm, BuildMode.debug).path,
        endsWith(path.join('cache', 'artifacts', 'engine', 'android-arm'))
      );
      expect(
        toolConfig.getEngineArtifactsDirectory(TargetPlatform.android_arm, BuildMode.release).path,
        endsWith(path.join('cache', 'artifacts', 'engine', 'android-arm-release'))
      );
      expect(tempDir, isNotNull);
      tempDir.deleteSync(recursive: true);
    }, overrides: <Type, Generator> {
      Cache: () => new Cache(rootOverride: tempDir),
    });

    testUsingContext('using enginePath', () {
      ToolConfiguration toolConfig = new ToolConfiguration();
      toolConfig.engineSrcPath = 'engine';
      toolConfig.engineBuildPath = 'engine/out/android_debug';

      expect(
        toolConfig.getEngineArtifactsDirectory(TargetPlatform.android_arm, BuildMode.debug).path,
        'engine/out/android_debug'
      );
    });
  });
}
