// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/test.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:flutter_tools/src/test/watcher.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  Cache.disableLocking();
  MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem();
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.directory('test').childFile('some_test.dart').createSync(recursive: true);
  });

  testUsingContext('Pipes test-randomize-ordering-seed to package:test',
      () async {
    final FakePackageTest fakePackageTest = FakePackageTest();

    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--test-randomize-ordering-seed=random',
      '--no-pub',
    ]);
    expect(
      fakePackageTest.lastArgs,
      contains('--test-randomize-ordering-seed=random'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    Cache: () => FakeCache(),
  });

  testUsingContext('Supports coverage and machine', () async {
    final FakePackageTest fakePackageTest = FakePackageTest();

    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    expect(() => commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--machine',
      '--coverage',
      '--',
      'test/fake_test.dart',
    ]), throwsA(isA<ToolExit>()
      .having((ToolExit toolExit) => toolExit.message, 'message', isNull)));
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    Cache: () => FakeCache(),
  });

  testUsingContext('Pipes start-paused to package:test',
      () async {
    final FakePackageTest fakePackageTest = FakePackageTest();

    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--start-paused',
      '--',
      'test/fake_test.dart',
    ]);
    expect(
      fakePackageTest.lastArgs,
      contains('--pause-after-load'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    Cache: () => FakeCache(),
  });

  testUsingContext('Pipes enable-observatory', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--enable-vmservice',
      '--',
      'test/fake_test.dart',
    ]);
    expect(
      testRunner.lastEnableObservatoryValue,
      true,
    );

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--start-paused',
      '--no-enable-vmservice',
      '--',
      'test/fake_test.dart',
    ]);
    expect(
      testRunner.lastEnableObservatoryValue,
      true,
    );

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--',
      'test/fake_test.dart',
    ]);
    expect(
      testRunner.lastEnableObservatoryValue,
      false,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    Cache: () => FakeCache(),
  });
}

class FakeFlutterTestRunner implements FlutterTestRunner {
  FakeFlutterTestRunner(this.exitCode);

  int exitCode;
  bool lastEnableObservatoryValue;

  @override
  Future<int> runTests(
    TestWrapper testWrapper,
    List<String> testFiles, {
    Directory workDir,
    List<String> names = const <String>[],
    List<String> plainNames = const <String>[],
    String tags,
    String excludeTags,
    bool enableObservatory = false,
    bool startPaused = false,
    bool disableServiceAuthCodes = false,
    bool ipv6 = false,
    bool machine = false,
    String precompiledDillPath,
    Map<String, String> precompiledDillFiles,
    BuildMode buildMode,
    bool trackWidgetCreation = false,
    bool updateGoldens = false,
    TestWatcher watcher,
    int concurrency,
    bool buildTestAssets = false,
    FlutterProject flutterProject,
    String icudtlPath,
    Directory coverageDirectory,
    bool web = false,
    String randomSeed,
    @override List<String> extraFrontEndOptions,
    bool nullAssertions = false,
  }) async {
    lastEnableObservatoryValue = enableObservatory;
    return exitCode;
  }

}

class FakePackageTest implements TestWrapper {
  List<String> lastArgs;

  @override
  Future<void> main(List<String> args) async {
    lastArgs = args;
  }

  @override
  void registerPlatformPlugin(
    Iterable<Runtime> runtimes,
    FutureOr<PlatformPlugin> Function() platforms,
  ) {}
}
