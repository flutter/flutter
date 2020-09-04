// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import 'utils.dart';

void main() {
  group('Flutter Command', () {
    MockitoCache cache;
    MockitoUsage usage;
    MockClock clock;
    MockProcessInfo mockProcessInfo;
    List<int> mockTimes;

    setUp(() {
      Cache.disableLocking();
      cache = MockitoCache();
      usage = MockitoUsage();
      clock = MockClock();
      mockProcessInfo = MockProcessInfo();

      when(usage.isFirstRun).thenReturn(false);
      when(clock.now()).thenAnswer(
        (Invocation _) => DateTime.fromMillisecondsSinceEpoch(mockTimes.removeAt(0))
      );
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
      verifyZeroInteractions(cache);
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

    testUsingContext('null-safety is surfaced in command usage analytics', () async {
      final FakeNullSafeCommand fake = FakeNullSafeCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(fake);

      await commandRunner.run(<String>['safety', '--enable-experiment=non-nullable']);

      final VerificationResult resultA = verify(usage.sendCommand(
        'safety',
        parameters: captureAnyNamed('parameters'),
      ));
      expect(resultA.captured.first, containsPair('cd47', 'true'));
      reset(usage);

      await commandRunner.run(<String>['safety', '--enable-experiment=foo']);

      final VerificationResult resultB = verify(usage.sendCommand(
        'safety',
        parameters: captureAnyNamed('parameters'),
      ));
      expect(resultB.captured.first, containsPair('cd47', 'false'));
    }, overrides: <Type, Generator>{
      Usage: () => usage,
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

    void testUsingCommandContext(String testName, dynamic Function() testBody) {
      testUsingContext(testName, testBody, overrides: <Type, Generator>{
        ProcessInfo: () => mockProcessInfo,
        SystemClock: () => clock,
        Usage: () => usage,
      });
    }

    testUsingCommandContext('reports command that results in success', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.success);
        }
      );
      await flutterCommand.run();

      verify(usage.sendCommand(
        'dummy',
        parameters: anyNamed('parameters'),
      ));
      verify(usage.sendEvent(
        'tool-command-result',
        'dummy',
        label: 'success',
        parameters: anyNamed('parameters'),
      ));
      expect(verify(usage.sendEvent(
          'tool-command-max-rss',
          'dummy',
          label: 'success',
          value: captureAnyNamed('value'),
        )).captured[0],
        10,
      );
    });

    testUsingCommandContext('reports command that results in warning', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.warning);
        }
      );
      await flutterCommand.run();

      verify(usage.sendCommand(
        'dummy',
        parameters: anyNamed('parameters'),
      ));
      verify(usage.sendEvent(
        'tool-command-result',
        'dummy',
        label: 'warning',
        parameters: anyNamed('parameters'),
      ));
      expect(verify(usage.sendEvent(
          'tool-command-max-rss',
          'dummy',
          label: 'warning',
          value: captureAnyNamed('value'),
        )).captured[0],
        10,
      );
    });

    testUsingCommandContext('reports command that results in failure', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

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
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          throwToolExit('fail');
          return null; // unreachable
        }
      );

      try {
        await flutterCommand.run();
        fail('Mock should make this fail');
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

    test('FlutterCommandResult.success()', () async {
      expect(FlutterCommandResult.success().exitStatus, ExitStatus.success);
    });

    test('FlutterCommandResult.warning()', () async {
      expect(FlutterCommandResult.warning().exitStatus, ExitStatus.warning);
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
        mockTimes = <int>[1000, 2000];

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

        verify(usage.sendCommand(
          'dummy',
          parameters: anyNamed('parameters'),
        ));
        verify(usage.sendEvent(
          'tool-command-result',
          'dummy',
          label: 'killed',
          parameters: anyNamed('parameters'),
        ));
        expect(verify(usage.sendEvent(
            'tool-command-max-rss',
            'dummy',
            label: 'killed',
            value: captureAnyNamed('value'),
          )).captured[0],
          10,
        );
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
        mockTimes = <int>[1000, 2000];
        final Completer<void> completer = Completer<void>();
        setExitFunctionForTests((int exitCode) {
          expect(exitCode, 0);
          restoreExitFunction();
          completer.complete();
        });
        final Completer<void> checkLockCompleter = Completer<void>();
        final DummyFlutterCommand flutterCommand =
            DummyFlutterCommand(commandFunction: () async {
          await Cache.lock();
          checkLockCompleter.complete();
          final Completer<void> c = Completer<void>();
          await c.future;
          return null; // unreachable
        });

        unawaited(flutterCommand.run());
        await checkLockCompleter.future;

        Cache.checkLockAcquired();

        signalController.add(mockSignal);
        await completer.future;

        await Cache.lock();
        Cache.releaseLock();
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
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
      await flutterCommand.run();
      verify(clock.now()).called(2);

      expect(
        verify(usage.sendTiming(
                captureAny, captureAny, captureAny,
                label: captureAnyNamed('label'))).captured,
        <dynamic>[
          'flutter',
          'dummy',
          const Duration(milliseconds: 1000),
          'fail',
        ],
      );
    });

    testUsingCommandContext('no timing report without usagePath', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand =
          DummyFlutterCommand(noUsagePath: true);
      await flutterCommand.run();
      verify(clock.now()).called(2);
      verifyNever(usage.sendTiming(
                   any, any, any,
                   label: anyNamed('label')));
    });

    testUsingCommandContext('report additional FlutterCommandResult data', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

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
      verify(clock.now()).called(2);
      expect(
        verify(usage.sendTiming(
                captureAny, captureAny, captureAny,
                label: captureAnyNamed('label'))).captured,
        <dynamic>[
          'flutter',
          'dummy',
          const Duration(milliseconds: 500), // FlutterCommandResult's end time used instead.
          'success-blah1-blah2-blah3',
        ],
      );
    });

    testUsingCommandContext('report failed execution timing too', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          throwToolExit('fail');
          return null; // unreachable
        },
      );

      try {
        await flutterCommand.run();
        fail('Mock should make this fail');
      } on ToolExit {
        // Should have still checked time twice.
        verify(clock.now()).called(2);

        expect(
          verify(usage.sendTiming(
                  captureAny, captureAny, captureAny,
                  label: captureAnyNamed('label'))).captured,
          <dynamic>[
            'flutter',
            'dummy',
            const Duration(milliseconds: 1000),
            'fail',
          ],
        );
      }
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

class MockVersion extends Mock implements FlutterVersion {}
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
    if (signal == ProcessSignal.SIGTERM) {
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
