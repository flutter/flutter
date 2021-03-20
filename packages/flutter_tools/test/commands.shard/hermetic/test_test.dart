// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/test.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:flutter_tools/src/test/watcher.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

const String _pubspecContents = '''
dev_dependencies:
  flutter_test:
    sdk: flutter''';
final String _packageConfigContents = json.encode(<String, Object>{
  'configVersion': 2,
  'packages': <Map<String, Object>>[
    <String, String>{
      'name': 'test_api',
      'rootUri': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dartlang.org/test_api-0.2.19',
      'packageUri': 'lib/',
      'languageVersion': '2.12'
    }
  ],
  'generated': '2021-02-24T07:55:20.084834Z',
  'generator': 'pub',
  'generatorVersion': '2.13.0-68.0.dev'
});

void main() {
  Cache.disableLocking();
  MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem.test();
    fs.file('pubspec.yaml').createSync();
    fs.file('pubspec.yaml').writeAsStringSync(_pubspecContents);
    (fs.directory('.dart_tool')
        .childFile('package_config.json')
      ..createSync(recursive: true))
        .writeAsString(_packageConfigContents);
    fs.directory('test').childFile('some_test.dart').createSync(recursive: true);
  });

  testUsingContext('Missing dependencies in pubspec',
      () async {
    // Clear the dependencies already added in [setUp].
    fs.file('pubspec.yaml').writeAsStringSync('');
    fs.directory('.dart_tool').childFile('package_config.json').writeAsStringSync('');

    final FakePackageTest fakePackageTest = FakePackageTest();
    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner =
    createTestCommandRunner(testCommand);

    expect(() => commandRunner.run(const <String>[
      'test',
      '--no-pub',
    ]), throwsToolExit());
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
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
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
  });

  group('shard-index and total-shards', () {
    testUsingContext('with the params they are Piped to package:test',
        () async {
      final FakePackageTest fakePackageTest = FakePackageTest();

      final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
      final CommandRunner<void> commandRunner =
          createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--total-shards=1',
        '--shard-index=2',
        '--no-pub',
      ]);

      expect(fakePackageTest.lastArgs, contains('--total-shards=1'));
      expect(fakePackageTest.lastArgs, contains('--shard-index=2'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    });

    testUsingContext('without the params they not Piped to package:test',
        () async {
      final FakePackageTest fakePackageTest = FakePackageTest();

      final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
      final CommandRunner<void> commandRunner =
          createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
      ]);

      expect(fakePackageTest.lastArgs, isNot(contains('--total-shards')));
      expect(fakePackageTest.lastArgs, isNot(contains('--shard-index')));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    });
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
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
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
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
  });

  testUsingContext('Pipes run-skipped to package:test',
      () async {
    final FakePackageTest fakePackageTest = FakePackageTest();

    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--run-skipped',
      '--',
      'test/fake_test.dart',
    ]);
    expect(
      fakePackageTest.lastArgs,
      contains('--run-skipped'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
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
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
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
    @required DebuggingOptions debuggingOptions,
    Directory workDir,
    List<String> names = const <String>[],
    List<String> plainNames = const <String>[],
    String tags,
    String excludeTags,
    bool enableObservatory = false,
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
    String reporter,
    String timeout,
    bool runSkipped = false,
    int shardIndex,
    int totalShards,
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
