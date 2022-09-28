// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fake_async/fake_async.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = '';
  });

  testWithoutContext('Throws a tool exit if pub cannot be run', () async {
    final FakeProcessManager processManager = FakeProcessManager.empty();
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    processManager.excludedExecutables.add('bin/cache/dart-sdk/bin/dart');

    fileSystem.file('pubspec.yaml').createSync();

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await expectLater(() => pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    ), throwsToolExit(message: 'Your Flutter SDK download may be corrupt or missing permissions to run'));
  });

  group('shouldSkipThirdPartyGenerator', () {
    testWithoutContext('does not skip pub get the parameter is false', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ]),
      ]);
      final BufferLogger logger = BufferLogger.test();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();

      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('pubspec.lock').createSync();
      fileSystem.file('version').writeAsStringSync('b');
      fileSystem.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [],
    "generated": "2021-07-08T10:02:49.155589Z",
    "generator": "third-party",
    "generatorVersion": "2.14.0-276.0.dev"
  }
  ''');

      final Pub pub = Pub(
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        usage: TestUsage(),
        platform: FakePlatform(),
        botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      );

      await pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.pubGet,
        checkUpToDate: true,
        shouldSkipThirdPartyGenerator: false,
      );

      expect(processManager, hasNoRemainingExpectations);
      expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
    });

    testWithoutContext('does not skip pub get if package_config.json has "generator": "pub"', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ]),
      ]);
      final BufferLogger logger = BufferLogger.test();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();

      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('pubspec.lock').createSync();
      fileSystem.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [],
    "generated": "2021-07-08T10:02:49.155589Z",
    "generator": "pub",
    "generatorVersion": "2.14.0-276.0.dev"
  }
  ''');
      fileSystem.file('.dart_tool/version').writeAsStringSync('a');
      fileSystem.file('version').writeAsStringSync('b');

      final Pub pub = Pub(
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        usage: TestUsage(),
        platform: FakePlatform(),
        botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      );

      await pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.pubGet,
        checkUpToDate: true,
      );

      expect(processManager, hasNoRemainingExpectations);
      expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
    });

    testWithoutContext('does not skip pub get if package_config.json has "generator": "pub"', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ]),
      ]);
      final BufferLogger logger = BufferLogger.test();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();

      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('pubspec.lock').createSync();
      fileSystem.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [],
    "generated": "2021-07-08T10:02:49.155589Z",
    "generator": "pub",
    "generatorVersion": "2.14.0-276.0.dev"
  }
  ''');
      fileSystem.file('.dart_tool/version').writeAsStringSync('a');
      fileSystem.file('version').writeAsStringSync('b');

      final Pub pub = Pub(
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        usage: TestUsage(),
        platform: FakePlatform(),
        botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      );

      await pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.pubGet,
        checkUpToDate: true,
      );

      expect(processManager, hasNoRemainingExpectations);
      expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
    });

    testWithoutContext('skips pub get if the package config "generator" is '
      'different than "pub"', () async {
      final FakeProcessManager processManager = FakeProcessManager.empty();
      final BufferLogger logger = BufferLogger.test();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();

      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('pubspec.lock').createSync();
      fileSystem.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"generator": "third-party"}');

      final Pub pub = Pub(
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        usage: TestUsage(),
        platform: FakePlatform(),
        botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      );

      await pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.pubGet,
        checkUpToDate: true,
      );

      expect(
        logger.traceText,
        contains('Skipping pub get: generated by third-party.'),
      );
    });
  });

  testWithoutContext('checkUpToDate skips pub get if the package config is newer than the pubspec '
    'and the current framework version is the same as the last version', () async {
    final FakeProcessManager processManager = FakeProcessManager.empty();
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('pubspec.lock').createSync();
    fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
    fileSystem.file('.dart_tool/version').writeAsStringSync('a');
    fileSystem.file('version').writeAsStringSync('a');

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    );

    expect(logger.traceText, contains('Skipping pub get: version match.'));
  });

  testWithoutContext('checkUpToDate does not skip pub get if the package config is newer than the pubspec '
    'but the current framework version is not the same as the last version', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
      ]),
    ]);
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('pubspec.lock').createSync();
    fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
    fileSystem.file('.dart_tool/version').writeAsStringSync('a');
    fileSystem.file('version').writeAsStringSync('b');

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
  });

  testWithoutContext('checkUpToDate does not skip pub get if the package config is newer than the pubspec '
    'but the current framework version does not exist yet', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
           'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
      ]),
    ]);
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('pubspec.lock').createSync();
    fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
    fileSystem.file('version').writeAsStringSync('b');

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
  });

  testWithoutContext('checkUpToDate does not skip pub get if the package config does not exist', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(command: const <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
      ], onRun: () {
        fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
      }),
    ]);
    final BufferLogger logger = BufferLogger.test();

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('pubspec.lock').createSync();
    fileSystem.file('version').writeAsStringSync('b');

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
  });

  testWithoutContext('checkUpToDate does not skip pub get if the pubspec.lock does not exist', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
      ]),
    ]);
    final BufferLogger logger = BufferLogger.test();

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('version').writeAsStringSync('b');
    fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);
    fileSystem.file('.dart_tool/version').writeAsStringSync('b');

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
  });

  testWithoutContext('checkUpToDate does not skip pub get if the package config is older that the pubspec', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
      ]),
    ]);
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('pubspec.lock').createSync();
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..setLastModifiedSync(DateTime(1991));
    fileSystem.file('version').writeAsStringSync('b');

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
  });

  testWithoutContext('checkUpToDate does not skip pub get if the pubspec.lock is older that the pubspec', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
      ]),
    ]);
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('pubspec.lock')
      ..createSync()
      ..setLastModifiedSync(DateTime(1991));
    fileSystem.file('.dart_tool/package_config.json')
      .createSync(recursive: true);
    fileSystem.file('version').writeAsStringSync('b');
    fileSystem.file('.dart_tool/version').writeAsStringSync('b');

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.pubGet,
      checkUpToDate: true,
    );

    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file('.dart_tool/version').readAsStringSync(), 'b');
  });

  testWithoutContext('pub get 69', () async {
    String? error;

    const FakeCommand pubGetCommand = FakeCommand(
      command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
      ],
      exitCode: 69,
      environment: <String, String>{'FLUTTER_ROOT': '', 'PUB_ENVIRONMENT': 'flutter_cli:flutter_tests'},
    );
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
      pubGetCommand,
    ]);
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    FakeAsync().run((FakeAsync time) {
      expect(logger.statusText, '');
      pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests,
      ).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(logger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n',
      );

      time.elapse(const Duration(milliseconds: 500));
      expect(logger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n',
      );
      time.elapse(const Duration(seconds: 1));
      expect(logger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n',
      );
      time.elapse(const Duration(seconds: 100)); // from t=0 to t=100
      expect(logger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 3 in 4 seconds...\n' // at t=1
        'pub get failed (server unavailable) -- attempting retry 4 in 8 seconds...\n' // at t=5
        'pub get failed (server unavailable) -- attempting retry 5 in 16 seconds...\n' // at t=13
        'pub get failed (server unavailable) -- attempting retry 6 in 32 seconds...\n' // at t=29
        'pub get failed (server unavailable) -- attempting retry 7 in 64 seconds...\n', // at t=61
      );
      time.elapse(const Duration(seconds: 200)); // from t=0 to t=200
      expect(logger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 3 in 4 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 4 in 8 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 5 in 16 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 6 in 32 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 7 in 64 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 8 in 64 seconds...\n' // at t=39
        'pub get failed (server unavailable) -- attempting retry 9 in 64 seconds...\n' // at t=103
        'pub get failed (server unavailable) -- attempting retry 10 in 64 seconds...\n', // at t=167
      );
    });
    expect(logger.errorText, isEmpty);
    expect(error, isNull);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('pub get offline does not retry', () async {
    String? error;

    const FakeCommand pubGetCommand = FakeCommand(
      command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--offline',
          '--example',
      ],
      exitCode: 69,
      environment: <String, String>{'FLUTTER_ROOT': '', 'PUB_ENVIRONMENT': 'flutter_cli:flutter_tests'},
    );
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      pubGetCommand,
    ]);
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      usage: TestUsage(),
      platform: FakePlatform(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    FakeAsync().run((FakeAsync time) {
      expect(logger.statusText, '');
      pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests,
        offline: true
      ).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(logger.statusText,
        'Running "flutter pub get" in /...\n'
      );
    });
    expect(logger.errorText, isEmpty);
    expect(error, contains('test failed unexpectedly: Exception: pub get failed'));
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('pub get 66 shows message from pub', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();

    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        exitCode: 66,
        stderr: 'err1\nerr2\nerr3\n',
        stdout: 'out1\nout2\nout3\n',
        environment: <String, String>{'FLUTTER_ROOT': '', 'PUB_ENVIRONMENT': 'flutter_cli:flutter_tests'},
      ),
    ]);
    final FakeStdio mockStdio = FakeStdio();
    final Pub pub = Pub(
      platform: FakePlatform(),
      fileSystem: fileSystem,
      logger: logger,
      usage: TestUsage(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: mockStdio,
      processManager: processManager,
    );
    const String toolExitMessage = '''
pub get failed
command: "bin/cache/dart-sdk/bin/dart __deprecated_pub --directory . get --example"
pub env: {
  "FLUTTER_ROOT": "",
  "PUB_ENVIRONMENT": "flutter_cli:flutter_tests",
}
exit code: 66
last line of pub output: "err3"
''';
    await expectLater(
      () => pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests,
      ),
      throwsA(isA<ToolExit>().having((ToolExit error) => error.message, 'message', toolExitMessage)),
    );
    expect(logger.statusText, 'Running "flutter pub get" in /...\n');
    expect(
      mockStdio.stdout.writes.map(utf8.decode),
      <String>[
        'out1\n',
        'out2\n',
        'out3\n',
      ]
    );
    expect(
      mockStdio.stderr.writes.map(utf8.decode),
      <String>[
        'err1\n',
        'err2\n',
        'err3\n',
      ]
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('pub get shows working directory on process exception', () async {
    final BufferLogger logger = BufferLogger.test();
    final FileSystem fileSystem = MemoryFileSystem.test();

    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        onRun: () {
          throw const ProcessException(
            'bin/cache/dart-sdk/bin/dart',
            <String>[
              '__deprecated_pub',
              '--directory',
              '.',
              'get',
              '--example',
            ],
            'message',
            1,
          );
        },
        exitCode: 66,
        stderr: 'err1\nerr2\nerr3\n',
        stdout: 'out1\nout2\nout3\n',
        environment: const <String, String>{'FLUTTER_ROOT': '', 'PUB_ENVIRONMENT': 'flutter_cli:flutter_tests'},
      ),
    ]);

    final Pub pub = Pub(
      platform: FakePlatform(),
      fileSystem: fileSystem,
      logger: logger,
      usage: TestUsage(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      processManager: processManager,
    );
    await expectLater(
      () => pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests,
      ),
      throwsA(
        isA<ProcessException>().having(
          (ProcessException error) => error.message,
          'message',
          contains('Working directory: "/"'),
        ).having(
          (ProcessException error) => error.message,
          'message',
          contains('"PUB_ENVIRONMENT": "flutter_cli:flutter_tests"'),
        ),
      ),
    );
    expect(logger.statusText,
      'Running "flutter pub get" in /...\n'
    );
    expect(logger.errorText, isEmpty);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('pub cache in flutter root is ignored', () async {
    String? error;
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        exitCode: 69,
        environment: <String, String>{
          'FLUTTER_ROOT': '',
          'PUB_ENVIRONMENT': 'flutter_cli:flutter_tests',
        },
      ),
    ]);

    final Pub pub = Pub(
      platform: FakePlatform(),
      usage: TestUsage(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: processManager,
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    FakeAsync().run((FakeAsync time) {
      pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests
      ).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(error, isNull);
      expect(processManager, hasNoRemainingExpectations);
    });
  });

  testWithoutContext('pub cache local is merge to global', () async {
    String? error;
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Directory local = fileSystem.currentDirectory.childDirectory('.pub-cache');
    final Directory global = fileSystem.currentDirectory.childDirectory('/global');
    global.createSync();
    for (final Directory dir in <Directory>[global.childDirectory('.pub-cache'), local]) {
      dir.createSync();
      dir.childDirectory('hosted').createSync();
      dir.childDirectory('hosted').childDirectory('pub.dartlang.org').createSync();
    }

    final Directory globalHosted = global.childDirectory('.pub-cache').childDirectory('hosted').childDirectory('pub.dartlang.org');
    globalHosted.childFile('first.file').createSync();
    globalHosted.childDirectory('dir').createSync();

    final Directory localHosted = local.childDirectory('hosted').childDirectory('pub.dartlang.org');
    localHosted.childFile('second.file').writeAsBytesSync(<int>[0]);
    localHosted.childDirectory('dir').createSync();
    localHosted.childDirectory('dir').childFile('third.file').writeAsBytesSync(<int>[0]);
    localHosted.childDirectory('dir_2').createSync();
    localHosted.childDirectory('dir_2').childFile('fourth.file').writeAsBytesSync(<int>[0]);

    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        exitCode: 69,
        environment: <String, String>{
          'FLUTTER_ROOT': '',
          'PUB_CACHE': '/global/.pub-cache',
          'PUB_ENVIRONMENT': 'flutter_cli:flutter_tests',
        },
      ),
    ]);

    final Platform platform = FakePlatform(
      environment: <String, String>{'HOME': '/global'}
    );
    final Pub pub = Pub(
      platform: platform,
      usage: TestUsage(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: processManager,
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );

    FakeAsync().run((FakeAsync time) {
      pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests,
      ).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = thrownError.toString();
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(error, isNull);
      expect(processManager, hasNoRemainingExpectations);
      expect(local.existsSync(), false);
      expect(globalHosted.childFile('second.file').existsSync(), false);
      expect(
          globalHosted.childDirectory('dir').childFile('third.file').existsSync(), false
      ); // do not copy dependencies that are already downloaded
      expect(globalHosted.childDirectory('dir_2').childFile('fourth.file').existsSync(), true);
    });
  });

  testWithoutContext('pub cache in environment is used', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory('custom/pub-cache/path').createSync(recursive: true);
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        exitCode: 69,
        environment: <String, String>{
          'FLUTTER_ROOT': '',
          'PUB_ENVIRONMENT': 'flutter_cli:flutter_tests',
          'PUB_CACHE': 'custom/pub-cache/path',
        },
      ),
    ]);
    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: processManager,
      usage: TestUsage(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      platform: FakePlatform(
        environment: const <String, String>{
          'PUB_CACHE': 'custom/pub-cache/path',
        },
      ),
    );

    FakeAsync().run((FakeAsync time) {
      String? error;
      pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(error, isNull);
      expect(processManager, hasNoRemainingExpectations);
    });
  });

  testWithoutContext('analytics sent on success', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final TestUsage usage = TestUsage();
    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      usage: usage,
      platform: FakePlatform(
        environment: const <String, String>{
          'PUB_CACHE': 'custom/pub-cache/path',
        }
      ),
    );
    fileSystem.file('version').createSync();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2,"packages": []}');

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.flutterTests,
    );
    expect(usage.events, contains(
      const TestUsageEvent('pub-result', 'flutter-tests', label: 'success'),
    ));
  });

  testWithoutContext('package_config_subset file is generated from packages and not timestamp', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final TestUsage usage = TestUsage();
    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      usage: usage,
      platform: FakePlatform(
        environment: const <String, String>{
          'PUB_CACHE': 'custom/pub-cache/path',
        }
      ),
    );
    fileSystem.file('version').createSync();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
      {"configVersion": 2,"packages": [
        {
          "name": "flutter_tools",
          "rootUri": "../",
          "packageUri": "lib/",
          "languageVersion": "2.7"
        }
      ],"generated":"some-time"}
''');

    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.flutterTests,
    );

    expect(
      fileSystem.file('.dart_tool/package_config_subset').readAsStringSync(),
      'flutter_tools\n'
      '2.7\n'
      'file:///\n'
      'file:///lib/\n'
      '2\n',
    );
  });

  testWithoutContext('analytics sent on failure', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory('custom/pub-cache/path').createSync(recursive: true);
    final TestUsage usage = TestUsage();

    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        exitCode: 1,
      ),
    ]);

    final Pub pub = Pub(
      usage: usage,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: processManager,
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
      platform: FakePlatform(
        environment: const <String, String>{
          'PUB_CACHE': 'custom/pub-cache/path',
        },
      ),
    );
    try {
      await pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests,
      );
    } on ToolExit {
      // Ignore.
    }

    expect(usage.events, contains(
      const TestUsageEvent('pub-result', 'flutter-tests', label: 'failure'),
    ));
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('analytics sent on failed version solve', () async {
    final TestUsage usage = TestUsage();
    final FileSystem fileSystem = MemoryFileSystem.test();


    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        exitCode: 1,
        stderr: 'version solving failed',
      ),
    ]);

    final Pub pub = Pub(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: processManager,
      platform: FakePlatform(
        environment: <String, String>{
          'PUB_CACHE': 'custom/pub-cache/path',
        },
      ),
      usage: usage,
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio(),
    );
    fileSystem.file('pubspec.yaml').writeAsStringSync('name: foo');

    try {
      await pub.get(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        context: PubContext.flutterTests
      );
    } on ToolExit {
      // Ignore.
    }

    expect(usage.events, contains(
      const TestUsageEvent('pub-result', 'flutter-tests', label: 'version-solving-failed'),
    ));
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Pub error handling', () async {
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        onRun: () {
          fileSystem.file('.dart_tool/package_config.json')
            .setLastModifiedSync(DateTime(2002));
        }
      ),
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
      ),
      FakeCommand(
        command: const <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
        onRun: () {
          fileSystem.file('pubspec.yaml')
            .setLastModifiedSync(DateTime(2002));
        }
      ),
      const FakeCommand(
        command: <String>[
          'bin/cache/dart-sdk/bin/dart',
          '__deprecated_pub',
          '--directory',
          '.',
          'get',
          '--example',
        ],
      ),
    ]);
    final Pub pub = Pub(
      usage: TestUsage(),
      fileSystem: fileSystem,
      logger: logger,
      processManager: processManager,
      platform: FakePlatform(
        environment: <String, String>{},
      ),
      botDetector: const BotDetectorAlwaysNo(),
      stdio: FakeStdio()
    );

    fileSystem.file('version').createSync();
    // the good scenario: .packages is old, pub updates the file.
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..setLastModifiedSync(DateTime(2000));
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..setLastModifiedSync(DateTime(2001));
    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.flutterTests,
    ); // pub sets date of .packages to 2002

    expect(logger.statusText, 'Running "flutter pub get" in /...\n');
    expect(logger.errorText, isEmpty);
    expect(fileSystem.file('pubspec.yaml').lastModifiedSync(), DateTime(2001)); // because nothing should touch it
    logger.clear();

    // bad scenario 1: pub doesn't update file; doesn't matter, because we do instead
    fileSystem.file('.dart_tool/package_config.json')
      .setLastModifiedSync(DateTime(2000));
    fileSystem.file('pubspec.yaml')
      .setLastModifiedSync(DateTime(2001));
    await pub.get(
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      context: PubContext.flutterTests,
    ); // pub does nothing

    expect(logger.statusText, 'Running "flutter pub get" in /...\n');
    expect(logger.errorText, isEmpty);
    expect(fileSystem.file('pubspec.yaml').lastModifiedSync(), DateTime(2001)); // because nothing should touch it
    logger.clear();
  });
}

class BotDetectorAlwaysNo implements BotDetector {
  const BotDetectorAlwaysNo();

  @override
  Future<bool> get isRunningOnBot async => false;
}
