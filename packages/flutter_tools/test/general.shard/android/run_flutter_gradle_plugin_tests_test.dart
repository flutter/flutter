// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/globals.dart';

import '../../integration.shard/test_utils.dart';
import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testUsingContext('AdbLogReader ignores spam from SurfaceSyncer', () async {
    final Directory flutterGradlePluginDirectory = fileSystem.directory(getFlutterRoot())
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childDirectory('gradle');
    gradleUtils?.injectGradleWrapperIfNeeded(flutterGradlePluginDirectory);
    final RunResult runResult = await processUtils.run(['./gradlew', 'test'], workingDirectory: flutterGradlePluginDirectory.path);
    expect(runResult.exitCode, 0);
  });
}
