// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/aot.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
void main() {
  testUsingContext('build aot outputs timing info', () async {
    globals.fs
      .file('.dart_tool/flutter_build/3f206b606f73e08587a94405f2e86fad/app.so')
      .createSync(recursive: true);
    when(globals.buildSystem.build(any, any))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true, performance: <String, PerformanceMeasurement>{
          'kernel_snapshot': PerformanceMeasurement(
            analyicsName: 'kernel_snapshot',
            target: 'kernel_snapshot',
            elapsedMilliseconds: 1000,
            succeeded: true,
            skipped: false,
          ),
          'anything': PerformanceMeasurement(
            analyicsName: 'android_aot',
            target: 'anything',
            elapsedMilliseconds: 1000,
            succeeded: true,
            skipped: false,
          ),
        });
      });

    await AotBuilder().build(
      platform: TargetPlatform.android_arm64,
      outputPath: '/',
      buildInfo: BuildInfo.release,
      mainDartFile: globals.fs.path.join('lib', 'main.dart'),
      reportTimings: true,
    );

    expect(testLogger.statusText, allOf(
      contains('frontend(CompileTime): 1000 ms.'),
      contains('snapshot(CompileTime): 1000 ms.'),
    ));
  }, overrides: <Type, Generator>{
    BuildSystem: () => MockBuildSystem(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockBuildSystem extends Mock implements BuildSystem {}
