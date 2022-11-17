// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/test.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/test/test_time_recorder.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:flutter_tools/src/test/watcher.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/logging_logger.dart';
import '../../src/test_flutter_command_runner.dart';

const String _pubspecContents = '''
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter''';
final String _packageConfigContents = json.encode(<String, Object>{
  'configVersion': 2,
  'packages': <Map<String, Object>>[
    <String, String>{
      'name': 'test_api',
      'rootUri': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dartlang.org/test_api-0.2.19',
      'packageUri': 'lib/',
      'languageVersion': '2.12',
    },
    <String, String>{
      'name': 'integration_test',
      'rootUri': 'file:///path/to/flutter/packages/integration_test',
      'packageUri': 'lib/',
      'languageVersion': '2.12',
    },
  ],
  'generated': '2021-02-24T07:55:20.084834Z',
  'generator': 'pub',
  'generatorVersion': '2.13.0-68.0.dev',
});

void main() {
  Cache.disableLocking();
  late MemoryFileSystem fs;
  late LoggingLogger logger;

  setUp(() {
    fs = MemoryFileSystem.test();
    fs.file('/package/pubspec.yaml').createSync(recursive: true);
    fs.file('/package/pubspec.yaml').writeAsStringSync(_pubspecContents);
    (fs.directory('/package/.dart_tool')
        .childFile('package_config.json')
      ..createSync(recursive: true))
        .writeAsString(_packageConfigContents);
    fs.directory('/package/test').childFile('some_test.dart').createSync(recursive: true);
    fs.directory('/package/integration_test').childFile('some_integration_test.dart').createSync(recursive: true);

    fs.currentDirectory = '/package';

    logger = LoggingLogger();
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
    Logger: () => logger,
  });

  testUsingContext('Missing dependencies in pubspec for integration tests',
      () async {
    // Only use the flutter_test dependency, integration_test is deliberately
    // absent.
    fs.file('pubspec.yaml').writeAsStringSync('''
dev_dependencies:
  flutter_test:
    sdk: flutter
    ''');
    fs.directory('.dart_tool').childFile('package_config.json').writeAsStringSync(json.encode(<String, Object>{
      'configVersion': 2,
      'packages': <Map<String, Object>>[
        <String, String>{
          'name': 'test_api',
          'rootUri': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dartlang.org/test_api-0.2.19',
          'packageUri': 'lib/',
          'languageVersion': '2.12',
        },
      ],
      'generated': '2021-02-24T07:55:20.084834Z',
      'generator': 'pub',
      'generatorVersion': '2.13.0-68.0.dev',
    }));
    final FakePackageTest fakePackageTest = FakePackageTest();
    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    expect(() => commandRunner.run(const <String>[
      'test',
      '--no-pub',
      'integration_test',
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

  testUsingContext(
      'Confirmation that the reporter and timeout args are not set by default',
      () async {
    final FakePackageTest fakePackageTest = FakePackageTest();

    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
    ]);

    expect(fakePackageTest.lastArgs, isNot(contains('-r')));
    expect(fakePackageTest.lastArgs, isNot(contains('compact')));
    expect(fakePackageTest.lastArgs, isNot(contains('--timeout')));
    expect(fakePackageTest.lastArgs, isNot(contains('30s')));
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
    ]), throwsA(isA<ToolExit>().having((ToolExit toolExit) => toolExit.message, 'message', isNull)));
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

  testUsingContext('Verbose prints phase timings', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0, const Duration(milliseconds: 1));

    final TestCommand testCommand = TestCommand(testRunner: testRunner, verbose: true);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--',
      'test/fake_test.dart',
    ]);

    // Expect one message for each phase.
    final List<String> logPhaseMessages = logger.messages.where((String m) => m.startsWith('Runtime for phase ')).toList();
    expect(logPhaseMessages, hasLength(TestTimePhases.values.length));

    // As we force the `runTests` command to take at least 1 ms expect at least
    // one phase to take a non-zero amount of time.
    final List<String> logPhaseMessagesNonZero = logPhaseMessages.where((String m) => !m.contains(Duration.zero.toString())).toList();
    expect(logPhaseMessagesNonZero, isNotEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    Logger: () => logger,
  });

  testUsingContext('Non-verbose does not prints phase timings', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0, const Duration(milliseconds: 1));

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner =
        createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--',
      'test/fake_test.dart',
    ]);

    final List<String> logPhaseMessages = logger.messages.where((String m) => m.startsWith('Runtime for phase ')).toList();
    expect(logPhaseMessages, isEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    Logger: () => logger,
  });

  testUsingContext('Pipes different args when running Integration Tests', () async {
    final FakePackageTest fakePackageTest = FakePackageTest();

    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      'integration_test',
    ]);

    expect(fakePackageTest.lastArgs, contains('--concurrency=1'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[
      FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
    ]),
  });

  testUsingContext('Overrides concurrency when running Integration Tests', () async {
    final FakePackageTest fakePackageTest = FakePackageTest();

    final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--concurrency=100',
      'integration_test',
    ]);

    expect(fakePackageTest.lastArgs, contains('--concurrency=1'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[
      FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
    ]),
  });

  group('Detecting Integration Tests', () {
    testUsingContext('when integration_test is not passed', () async {
      final FakePackageTest fakePackageTest = FakePackageTest();

      final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
      ]);

      expect(testCommand.isIntegrationTest, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => _FakeDeviceManager(<Device>[
        FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
      ]),
    });

    testUsingContext('when integration_test is passed', () async {
      final FakePackageTest fakePackageTest = FakePackageTest();

      final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
        'integration_test',
      ]);

      expect(testCommand.isIntegrationTest, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => _FakeDeviceManager(<Device>[
        FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
      ]),
    });

    testUsingContext('when relative path to integration test is passed', () async {
      final FakePackageTest fakePackageTest = FakePackageTest();

      final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
        'integration_test/some_integration_test.dart',
      ]);

      expect(testCommand.isIntegrationTest, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => _FakeDeviceManager(<Device>[
        FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
      ]),
    });

    testUsingContext('when absolute path to integration test is passed', () async {
      final FakePackageTest fakePackageTest = FakePackageTest();

      final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
        '/package/integration_test/some_integration_test.dart',
      ]);

      expect(testCommand.isIntegrationTest, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => _FakeDeviceManager(<Device>[
        FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
      ]),
    });

    testUsingContext('when absolute unnormalized path to integration test is passed', () async {
      final FakePackageTest fakePackageTest = FakePackageTest();

      final TestCommand testCommand = TestCommand(testWrapper: fakePackageTest);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
        '/package/../package/integration_test/some_integration_test.dart',
      ]);

      expect(testCommand.isIntegrationTest, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => _FakeDeviceManager(<Device>[
        FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
      ]),
    });

    testUsingContext('when both test and integration test are passed', () async {
      final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

      final TestCommand testCommand = TestCommand(testRunner: testRunner);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      expect(() => commandRunner.run(const <String>[
        'test',
        '--no-pub',
        'test/some_test.dart',
        'integration_test/some_integration_test.dart',
      ]), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('Required artifacts', () {
    testUsingContext('for default invocation', () async {
      final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

      final TestCommand testCommand = TestCommand(testRunner: testRunner);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
      ]);

      expect(await testCommand.requiredArtifacts, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('when platform is chrome', () async {
      final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

      final TestCommand testCommand = TestCommand(testRunner: testRunner);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
        '--platform=chrome',
      ]);

      expect(await testCommand.requiredArtifacts, <DevelopmentArtifact>[DevelopmentArtifact.web]);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('when running integration tests', () async {
      final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

      final TestCommand testCommand = TestCommand(testRunner: testRunner);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
        'integration_test',
      ]);

      expect(await testCommand.requiredArtifacts, <DevelopmentArtifact>[
        DevelopmentArtifact.universal,
        DevelopmentArtifact.androidGenSnapshot,
      ]);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => _FakeDeviceManager(<Device>[
        FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
      ]),
    });
  });

  testUsingContext('Integration tests when no devices are connected', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    expect(() => commandRunner.run(const <String>[
      'test',
      '--no-pub',
      'integration_test',
    ]), throwsToolExit());
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[]),
  });

  // TODO(jiahaog): Remove this when web is supported. https://github.com/flutter/flutter/issues/66264
  testUsingContext('Integration tests when only web devices are connected', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    expect(() => commandRunner.run(const <String>[
      'test',
      '--no-pub',
      'integration_test',
    ]), throwsToolExit());
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[
      FakeDevice('ephemeral', 'ephemeral'),
    ]),
  });

  testUsingContext('Integration tests set the correct dart-defines', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      'integration_test',
    ]);

    expect(
      testRunner.lastDebuggingOptionsValue.buildInfo.dartDefines,
      contains('INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[
      FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
    ]),
  });

  testUsingContext('Integration tests given flavor', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--flavor',
      'dev',
      'integration_test',
    ]);

    expect(
      testRunner.lastDebuggingOptionsValue.buildInfo.flavor,
      contains('dev'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[
      FakeDevice('ephemeral', 'ephemeral', type: PlatformType.android),
    ]),
  });

  testUsingContext('Builds the asset manifest by default', () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
    ]);

    final bool fileExists = await fs.isFile('build/unit_test_assets/AssetManifest.json');
    expect(fileExists, true);

  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[]),
  });

  testUsingContext("Don't build the asset manifest if --no-test-assets if informed", () async {
    final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

    final TestCommand testCommand = TestCommand(testRunner: testRunner);
    final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

    await commandRunner.run(const <String>[
      'test',
      '--no-pub',
      '--no-test-assets',
    ]);

    final bool fileExists = await fs.isFile('build/unit_test_assets/AssetManifest.json');
    expect(fileExists, false);

  }, overrides: <Type, Generator>{
    FileSystem: () => fs,
    ProcessManager: () => FakeProcessManager.any(),
    DeviceManager: () => _FakeDeviceManager(<Device>[]),
  });

  group('Fatal Logs', () {
    testUsingContext("doesn't fail when --fatal-warnings is set and no warning output", () async {
      final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

      final TestCommand testCommand = TestCommand(testRunner: testRunner);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      try {
        await commandRunner.run(const <String>[
          'test',
          '--no-pub',
          '--${FlutterOptions.kFatalWarnings}',
        ]);
      } on Exception {
        fail('Unexpected exception thrown');
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });
    testUsingContext('fails if --fatal-warnings specified and warnings emitted', () async {
      final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

      final TestCommand testCommand = TestCommand(testRunner: testRunner);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      testLogger.printWarning('Warning: Mild annoyance, Will Robinson!');
      expect(commandRunner.run(const <String>[
        'test',
        '--no-pub',
        '--${FlutterOptions.kFatalWarnings}',
      ]), throwsToolExit(message: 'Logger received warning output during the run, and "--${FlutterOptions.kFatalWarnings}" is enabled.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });
    testUsingContext('fails when --fatal-warnings is set and only errors emitted', () async {
      final FakeFlutterTestRunner testRunner = FakeFlutterTestRunner(0);

      final TestCommand testCommand = TestCommand(testRunner: testRunner);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);

      testLogger.printError('Error: Danger Will Robinson!');
      expect(commandRunner.run(const <String>[
        'test',
        '--no-pub',
        '--${FlutterOptions.kFatalWarnings}',
      ]), throwsToolExit(message: 'Logger received error output during the run, and "--${FlutterOptions.kFatalWarnings}" is enabled.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class FakeFlutterTestRunner implements FlutterTestRunner {
  FakeFlutterTestRunner(this.exitCode, [this.leastRunTime]);

  int exitCode;
  Duration? leastRunTime;
  bool? lastEnableObservatoryValue;
  late DebuggingOptions lastDebuggingOptionsValue;
  String? lastReporterOption;

  @override
  Future<int> runTests(
    TestWrapper testWrapper,
    List<String> testFiles, {
    required DebuggingOptions debuggingOptions,
    List<String> names = const <String>[],
    List<String> plainNames = const <String>[],
    String? tags,
    String? excludeTags,
    bool enableObservatory = false,
    bool ipv6 = false,
    bool machine = false,
    String? precompiledDillPath,
    Map<String, String>? precompiledDillFiles,
    bool updateGoldens = false,
    TestWatcher? watcher,
    required int? concurrency,
    String? testAssetDirectory,
    FlutterProject? flutterProject,
    String? icudtlPath,
    Directory? coverageDirectory,
    bool web = false,
    String? randomSeed,
    String? reporter,
    String? timeout,
    bool runSkipped = false,
    int? shardIndex,
    int? totalShards,
    Device? integrationTestDevice,
    String? integrationTestUserIdentifier,
    TestTimeRecorder? testTimeRecorder,
  }) async {
    lastEnableObservatoryValue = enableObservatory;
    lastDebuggingOptionsValue = debuggingOptions;
    lastReporterOption = reporter;

    if (leastRunTime != null) {
      await Future<void>.delayed(leastRunTime!);
    }

    return exitCode;
  }
}

class FakePackageTest implements TestWrapper {
  List<String>? lastArgs;

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

class _FakeDeviceManager extends DeviceManager {
  _FakeDeviceManager(this._connectedDevices) : super(logger: testLogger);

  final List<Device> _connectedDevices;

  @override
  Future<List<Device>> getAllConnectedDevices() async => _connectedDevices;

  @override
  List<DeviceDiscovery> get deviceDiscoverers => <DeviceDiscovery>[];
}
