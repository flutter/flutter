// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fs;
  late Artifacts artifacts;
  late FakeProcessManager processManager;
  late Platform platform;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fs = MemoryFileSystem.test();
    artifacts = Artifacts.test(fileSystem: fs);
    logger = BufferLogger.test();
    platform = FakePlatform();
    processManager = FakeProcessManager.empty();
  });

  testUsingContext('will not build an AAR for a plugin', () async {
    fs.file('pubspec.yaml').writeAsStringSync('''
name: foo_bar

flutter:
  plugin:
    platforms:
      some_platform:
        null
''');

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      artifacts: artifacts,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: fs,
      logger: logger,
      osUtils: FakeOperatingSystemUtils(),
      processUtils: ProcessUtils(
        logger: logger,
        processManager: processManager,
      ),
    );

    expect(
      createTestCommandRunner(command).run(const <String>['build', 'aar', '--no-pub']),
      throwsToolExit(message: 'AARs can only be built from modules'),
    );
    expect(processManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    Platform: () => platform,
    ProcessManager: () => processManager,
  });

  testUsingContext('will build an AAR for a module', () async {
    fs.file('pubspec.yaml').writeAsStringSync('''
name: foo_bar

flutter:
  module:
    foo: bar
''');

    processManager.addCommands(const <FakeCommand>[
      FakeCommand(command: <String>['which', 'java']),
    ]);
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      artifacts: artifacts,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: fs,
      logger: logger,
      osUtils: FakeOperatingSystemUtils(),
      processUtils: ProcessUtils(
        logger: logger,
        processManager: processManager,
      ),
    );

    await createTestCommandRunner(command).run(const <String>['build', 'aar', '--no-pub']);
    expect(processManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    Platform: () => platform,
    ProcessManager: () => processManager,
  });
}
