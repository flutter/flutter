// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:process/process.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
// import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/commands/environment.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import '../src/test_build_system.dart';
import '../src/test_flutter_command_runner.dart';
import 'test_data/basic_project.dart';

void main() {
  Cache.disableLocking();
  Cache.flutterRoot = 'test/flutter/root';

  late Directory projectDir;
  late FileSystem fileSystem;
  final BasicProjectWithFlutterGen project = BasicProjectWithFlutterGen();
  // late FlutterRunTestDriver flutter;

  setUp(() async {
    fileSystem = MemoryFileSystem.test();
    projectDir = globals.fs.directory('/test');
    await project.setUpIn(projectDir);
    // flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    // await flutter.stop();
    tryToDelete(projectDir);
  });

  testUsingContext('environment produces expected values', () async {
    // final CommandRunner<void> createCommandRunner = createTestCommandRunner(CreateCommand(
    //   verboseHelp: true,
    // ));
    // await createCommandRunner.run(<String>['create', '/test']);

    final CommandRunner<void> envCommandRunner = createTestCommandRunner(EnvironmentCommand(
      fileSystem: fileSystem,
      logger: testLogger,
      terminal: Terminal.test(),
      platform: globals.platform,
    ));
    // envCommandRunner.workingDirectory = '/test';
    await envCommandRunner.run(<String>['environment', 'project-directory=/test']);

    print(testLogger.statusText);
    // expect(testLogger.traceText, contains('build succeeded.'));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}
