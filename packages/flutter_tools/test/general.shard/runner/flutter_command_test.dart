// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';
import 'utils.dart';

void main() {
  group('Flutter Command', () {
    MockCache cache;
    TestUsage usage;
    FakeClock clock;
    MockProcessInfo mockProcessInfo;

    setUp(() {
      Cache.disableLocking();
      cache = MockCache();
      usage = TestUsage();
      clock = FakeClock();
      mockProcessInfo = MockProcessInfo();

      when(mockProcessInfo.maxRss).thenReturn(10);
    });

    tearDown(() {
      Cache.enableLocking();
    });

    testUsingContext('help text contains global options', () {
      final FakeDeprecatedCommand fake = FakeDeprecatedCommand();
      createTestCommandRunner(fake);
      expect(fake.usage, contains('Global options:\n'));
    });

    testUsingContext('honors shouldUpdateCache false', () async {
      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(shouldUpdateCache: false);
      await flutterCommand.run();
      verifyNever(cache.updateAll(any));
      expect(flutterCommand.deprecated, isFalse);
      expect(flutterCommand.hidden, isFalse);
    },
    overrides: <Type, Generator>{
      Cache: () => cache,
    });

    testUsingContext('honors shouldUpdateCache true', () async {
      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(shouldUpdateCache: true);
      await flutterCommand.run();
      // First call for universal, second for the rest
      expect(
        verify(cache.updateAll(captureAny)).captured,
        <Set<DevelopmentArtifact>>[
          <DevelopmentArtifact>{DevelopmentArtifact.universal},
          <DevelopmentArtifact>{},
        ],
      );
    },
    overrides: <Type, Generator>{
      Cache: () => cache,
    });

    testUsingContext('deprecated command should warn', () async {
      final FakeDeprecatedCommand flutterCommand = FakeDeprecatedCommand();
      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['deprecated']);

      expect(testLogger.statusText,
        contains('The "deprecated" command is deprecated and will be removed in '
            'a future version of Flutter.'));
      expect(flutterCommand.usage,
        contains('Deprecated. This command will be removed in a future version '
            'of Flutter.'));
      expect(flutterCommand.deprecated, isTrue);
      expect(flutterCommand.hidden, isTrue);
    });

    testUsingContext('uses the error handling file system', () async {
      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          expect(globals.fs, isA<ErrorHandlingFileSystem>());
          return const FlutterCommandResult(ExitStatus.success);
        }
      );
      await flutterCommand.run();
    });

    testUsingContext('finds the target file with default values', () async {
      globals.fs.file('lib/main.dart').createSync(recursive: true);
      final FakeTargetCommand fakeTargetCommand = FakeTargetCommand();
      final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);
      await runner.run(<String>['test']);

      expect(fakeTargetCommand.cachedTargetFile, 'lib/main.dart');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('finds the target file with specified value', () async {
      globals.fs.file('lib/foo.dart').createSync(recursive: true);
      final FakeTargetCommand fakeTargetCommand = FakeTargetCommand();
      final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);
      await runner.run(<String>['test', '-t', 'lib/foo.dart']);

      expect(fakeTargetCommand.cachedTargetFile, 'lib/foo.dart');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('throws tool exit if specified file does not exist', () async {
      final FakeTargetCommand fakeTargetCommand = FakeTargetCommand();
      final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);

      expect(() async => runner.run(<String>['test', '-t', 'lib/foo.dart']), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    void testUsingCommandContext(String testName, dynamic Function() testBody) {
      testUsingContext(testName, testBody, overrides: <Type, Generator>{
        ProcessInfo: () => mockProcessInfo,
        SystemClock: () => clock,
        Usage: () => usage,
      });
    }

    testUsingCommandContext('reports command that results in success', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.success);
        }
      );
      await flutterCommand.run();

      expect(usage.events, <TestUsageEvent>[
        const TestUsageEvent(
          'tool-command-result',
          'dummy',
          label: 'success',
        ),
        const TestUsageEvent(
          'tool-command-max-rss',
          'dummy',
          label: 'success',
          value: 10,
        ),
      ]);
    });

    testUsingCommandContext('reports command that results in warning', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.warning);
        }
      );
      await flutterCommand.run();

      expect(usage.events, <TestUsageEvent>[
        const TestUsageEvent(
          'tool-command-result',
          'dummy',
          label: 'warning',
        ),
        const TestUsageEvent(
          'tool-command-max-rss',
          'dummy',
          label: 'warning',
          value: 10,
        ),
      ]);
    });

    testUsingCommandContext('reports command that results in failure', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.fail);
        }
      );

      try {
        await flutterCommand.run();
      } on ToolExit {
        verify(usage.sendCommand(
          'dummy',
          parameters: anyNamed('parameters'),
        ));
        verify(usage.sendEvent(
          'tool-command-result',
          'dummy',
          label: 'fail',
          parameters: anyNamed('parameters'),
        ));
        expect(verify(usage.sendEvent(
            'tool-command-max-rss',
            'dummy',
            label: 'fail',
            value: captureAnyNamed('value'),
          )).captured[0],
          10,
        );
      }
    });

    testUsingCommandContext('reports command that results in error', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          throwToolExit('fail');
        }
      );
      try {
        await flutterCommand.run();
        fail('Mock should make this fail');
      } on ToolExit {
        expect(usage.events, <TestUsageEvent>[
          const TestUsageEvent(
            'tool-command-result',
            'dummy',
            label: 'fail',
          ),
          const TestUsageEvent(
            'tool-command-max-rss',
            'dummy',
            label: 'fail',
            value: 10,
          ),
        ]);
      }
    });

    test('FlutterCommandResult.success()', () async {
      expect(FlutterCommandResult.success().exitStatus, ExitStatus.success);
    });

    test('FlutterCommandResult.warning()', () async {
      expect(FlutterCommandResult.warning().exitStatus, ExitStatus.warning);
    });

    testUsingContext('devToolsServerAddress returns parsed uri', () async {
      final DummyFlutterCommand command = DummyFlutterCommand()..addDevToolsOptions(verboseHelp: false);
      await createTestCommandRunner(command).run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        'http://127.0.0.1:9105',
      ]);
      expect(command.devToolsServerAddress.toString(), equals('http://127.0.0.1:9105'));
    });

    testUsingContext('devToolsServerAddress returns null for bad input', () async {
      final DummyFlutterCommand command = DummyFlutterCommand()..addDevToolsOptions(verboseHelp: false);
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        'hello-world',
      ]);
      expect(command.devToolsServerAddress, isNull);

      await runner.run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        '',
      ]);
      expect(command.devToolsServerAddress, isNull);

      await runner.run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        '9101',
      ]);
      expect(command.devToolsServerAddress, isNull);

      await runner.run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        '127.0.0.1:9101',
      ]);
      expect(command.devToolsServerAddress, isNull);
    });

    group('signals tests', () {
      MockIoProcessSignal mockSignal;
      ProcessSignal signalUnderTest;
      StreamController<io.ProcessSignal> signalController;

      setUp(() {
        mockSignal = MockIoProcessSignal();
        signalUnderTest = ProcessSignal(mockSignal);
        signalController = StreamController<io.ProcessSignal>();
        when(mockSignal.watch()).thenAnswer((Invocation invocation) => signalController.stream);
      });

      testUsingContext('reports command that is killed', () async {
        // Crash if called a third time which is unexpected.
        clock.times = <int>[1000, 2000];

        final Completer<void> completer = Completer<void>();
        setExitFunctionForTests((int exitCode) {
          expect(exitCode, 0);
          restoreExitFunction();
          completer.complete();
        });

        final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
          commandFunction: () async {
            final Completer<void> c = Completer<void>();
            await c.future;
            return null; // unreachable
          }
        );

        unawaited(flutterCommand.run());
        signalController.add(mockSignal);
        await completer.future;

        expect(usage.events, <TestUsageEvent>[
          const TestUsageEvent(
            'tool-command-result',
            'dummy',
            label: 'killed',
          ),
          const TestUsageEvent(
            'tool-command-max-rss',
            'dummy',
            label: 'killed',
            value: 10,
          ),
        ]);
      }, overrides: <Type, Generator>{
        ProcessInfo: () => mockProcessInfo,
        Signals: () => FakeSignals(
          subForSigTerm: signalUnderTest,
          exitSignals: <ProcessSignal>[signalUnderTest],
        ),
        SystemClock: () => clock,
        Usage: () => usage,
      });

      testUsingContext('command release lock on kill signal', () async {
        clock.times = <int>[1000, 2000];
        final Completer<void> completer = Completer<void>();
        setExitFunctionForTests((int exitCode) {
          expect(exitCode, 0);
          restoreExitFunction();
          completer.complete();
        });
        final Completer<void> checkLockCompleter = Completer<void>();
        final DummyFlutterCommand flutterCommand =
            DummyFlutterCommand(commandFunction: () async {
          await globals.cache.lock();
          checkLockCompleter.complete();
          final Completer<void> c = Completer<void>();
          await c.future;
          return null; // unreachable
        });

        unawaited(flutterCommand.run());
        await checkLockCompleter.future;

        globals.cache.checkLockAcquired();

        signalController.add(mockSignal);
        await completer.future;

        await globals.cache.lock();
        globals.cache.releaseLock();
      }, overrides: <Type, Generator>{
        ProcessInfo: () => mockProcessInfo,
        Signals: () => FakeSignals(
              subForSigTerm: signalUnderTest,
              exitSignals: <ProcessSignal>[signalUnderTest],
            ),
        Usage: () => usage
      });
    });

    testUsingCommandContext('report execution timing by default', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
      await flutterCommand.run();

      expect(usage.timings, contains(
        const TestTimingEvent(
          'flutter',
          'dummy',
          Duration(milliseconds: 1000),
          label: 'fail',
        )));
    });

    testUsingCommandContext('no timing report without usagePath', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand =
          DummyFlutterCommand(noUsagePath: true);
      await flutterCommand.run();

      expect(usage.timings, isEmpty);
    });

    testUsingCommandContext('report additional FlutterCommandResult data', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final FlutterCommandResult commandResult = FlutterCommandResult(
        ExitStatus.success,
        // nulls should be cleaned up.
        timingLabelParts: <String> ['blah1', 'blah2', null, 'blah3'],
        endTimeOverride: DateTime.fromMillisecondsSinceEpoch(1500),
      );

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async => commandResult
      );
      await flutterCommand.run();

      expect(usage.timings, contains(
        const TestTimingEvent(
          'flutter',
          'dummy',
          Duration(milliseconds: 500),
          label: 'success-blah1-blah2-blah3',
        )));
    });

    testUsingCommandContext('report failed execution timing too', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          throwToolExit('fail');
        },
      );

      try {
        await flutterCommand.run();
        fail('Mock should make this fail');
      } on ToolExit {
        expect(usage.timings, contains(
          const TestTimingEvent(
            'flutter',
            'dummy',
            Duration(milliseconds: 1000),
            label: 'fail',
          )));
      }
    });

    testUsingContext('reports null safety analytics when reportNullSafety is true', () async {
      globals.fs.file('lib/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// @dart=2.12');
      globals.fs.file('pubspec.yaml')
        .writeAsStringSync('name: example\n');
      globals.fs.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "example",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ],
  "generated": "2020-12-02T19:30:53.862346Z",
  "generator": "pub",
  "generatorVersion": "2.12.0-76.0.dev"
}
 ''');
      final FakeReportingNullSafetyCommand command = FakeReportingNullSafetyCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['test']);

      expect(usage.events, containsAll(<TestUsageEvent>[
        const TestUsageEvent(
          NullSafetyAnalysisEvent.kNullSafetyCategory,
          'runtime-mode',
          label: 'NullSafetyMode.sound',
        ),
        const TestUsageEvent(
          NullSafetyAnalysisEvent.kNullSafetyCategory,
          'stats',
          parameters: <String, String>{
            'cd49': '1', 'cd50': '1',
          },
        ),
        const TestUsageEvent(
          NullSafetyAnalysisEvent.kNullSafetyCategory,
          'language-version',
          label: '2.12',
        ),
      ]));
    }, overrides: <Type, Generator>{
      Pub: () => FakePub(),
      Usage: () => usage,
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class FakeDeprecatedCommand extends FlutterCommand {
  @override
  String get description => 'A fake command';

  @override
  String get name => 'deprecated';

  @override
  bool get deprecated => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

class FakeNullSafeCommand extends FlutterCommand {
  FakeNullSafeCommand() {
    addEnableExperimentation(hide: false);
  }

  @override
  String get description => 'test null safety';

  @override
  String get name => 'safety';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

class FakeTargetCommand extends FlutterCommand {
  FakeTargetCommand() {
    usesTargetOption();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    cachedTargetFile = targetFile;
    return FlutterCommandResult.success();
  }

  String cachedTargetFile;

  @override
  String get description => '';

  @override
  String get name => 'test';
}

class FakeReportingNullSafetyCommand extends FlutterCommand {
  FakeReportingNullSafetyCommand() {
    argParser.addFlag('debug');
    argParser.addFlag('release');
    argParser.addFlag('jit-release');
    argParser.addFlag('profile');
  }

  @override
  String get description => 'test';

  @override
  String get name => 'test';

  @override
  bool get shouldRunPub => true;

  @override
  bool get reportNullSafety => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

class MockProcessInfo extends Mock implements ProcessInfo {}
class MockIoProcessSignal extends Mock implements io.ProcessSignal {}

class FakeSignals implements Signals {
  FakeSignals({
    this.subForSigTerm,
    List<ProcessSignal> exitSignals,
  }) : delegate = Signals.test(exitSignals: exitSignals);

  final ProcessSignal subForSigTerm;
  final Signals delegate;

  @override
  Object addHandler(ProcessSignal signal, SignalHandler handler) {
    if (signal == ProcessSignal.sigterm) {
      return delegate.addHandler(subForSigTerm, handler);
    }
    return delegate.addHandler(signal, handler);
  }

  @override
  Future<bool> removeHandler(ProcessSignal signal, Object token) =>
    delegate.removeHandler(signal, token);

  @override
  Stream<Object> get errors => delegate.errors;
}

class FakeClock extends Fake implements SystemClock {
  List<int> times = <int>[];

  @override
  DateTime now() {
    return DateTime.fromMillisecondsSinceEpoch(times.removeAt(0));
  }
}

class MockCache extends Mock implements Cache {}
