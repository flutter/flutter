// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/hook_runner_native.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/test_build_system.dart';

void main() {
  late FileSystem fs;

  setUp(() {
    fs = MemoryFileSystem.test();
  });

  testUsingContext(
    'FlutterHookRunnerNative uses a separate output directory',
    () async {
      final hookRunner = FlutterHookRunnerNative();
      final environment = Environment.test(
        fs.currentDirectory,
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        fileSystem: fs,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        defines: {},
      );

      await hookRunner.runHooks(
        targetPlatform: TargetPlatform.linux_x64,
        environment: environment,
        logger: environment.logger,
      );
    },
    overrides: <Type, Generator>{
      BuildSystem: () =>
          TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
            expect(
              fs.path.basename(environment.outputDir.path),
              FlutterHookRunnerNative.kHooksOutputDirectory,
            );
          }),
    },
  );
}
