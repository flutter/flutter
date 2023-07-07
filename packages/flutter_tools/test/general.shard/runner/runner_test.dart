// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_http_client.dart';

const String kCustomBugInstructions = 'These are instructions to report with a custom bug tracker.';

void main() {
  int? firstExitCode;
  late MemoryFileSystem fileSystem;

  group('runner', () {
    setUp(() {
      // Instead of exiting with dart:io exit(), this causes an exception to
      // be thrown, which we catch with the onError callback in the zone below.
      //
      // Tests might trigger exit() multiple times. In real life, exit() would
      // cause the VM to terminate immediately, so only the first one matters.
      firstExitCode = null;
      io.setExitFunctionForTests((int exitCode) {
        firstExitCode ??= exitCode;

        // TODO(jamesderlin): Ideally only the first call to exit() would be
        // honored and subsequent calls would be no-ops, but existing tests
        // rely on all calls to throw.
        throw Exception('test exit');
      });

      Cache.disableLocking();
      fileSystem = MemoryFileSystem.test();
    });

    tearDown(() {
      io.restoreExitFunction();
      Cache.enableLocking();
    });

    testUsingContext('error handling crash report (synchronous crash)', () async {
      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>?>(
        () {
          unawaited(runner.run(
            <String>['crash'],
            () => <FlutterCommand>[
              CrashingFlutterCommand(),
            ],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            reportCrashes: true,
            shutdownHooks: ShutdownHooks(),
          ));
          return null;
        },
        onError: (Object error, StackTrace stack) { // ignore: deprecated_member_use
          expect(firstExitCode, isNotNull);
          expect(firstExitCode, isNot(0));
          expect(error.toString(), 'Exception: test exit');
          completer.complete();
        },
      ));
      await completer.future;

      // This is the main check of this test.
      //
      // We are checking that, even though crash reporting failed with an
      // exception on the first attempt, the second attempt tries to report the
      // *original* crash, and not the crash from the first crash report
      // attempt.
      final CrashingUsage crashingUsage = globals.flutterUsage as CrashingUsage;
      expect(crashingUsage.sentException.toString(), 'Exception: an exception % --');
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_ANALYTICS_LOG_FILE': 'test',
        'FLUTTER_ROOT': '/',
      }),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Usage: () => CrashingUsage(),
      Artifacts: () => Artifacts.test(),
      HttpClientFactory: () => () => FakeHttpClient.any(),
    });

    // This Completer completes when CrashingFlutterCommand.runCommand
    // completes, but ideally we'd want it to complete when execution resumes
    // runner.run. Currently the distinction does not matter, but if it ever
    // does, this test might fail to catch a regression of
    // https://github.com/flutter/flutter/issues/56406.
    final Completer<void> commandCompleter = Completer<void>();
    testUsingContext('error handling crash report (asynchronous crash)', () async {
      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>?>(
        () {
          unawaited(runner.run(
            <String>['crash'],
            () => <FlutterCommand>[
              CrashingFlutterCommand(asyncCrash: true, completer: commandCompleter),
            ],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            reportCrashes: true,
            shutdownHooks: ShutdownHooks(),
          ));
          return null;
        },
        onError: (Object error, StackTrace stack) { // ignore: deprecated_member_use
          expect(firstExitCode, isNotNull);
          expect(firstExitCode, isNot(0));
          expect(error.toString(), 'Exception: test exit');
          completer.complete();
        },
      ));
      await completer.future;
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_ANALYTICS_LOG_FILE': 'test',
        'FLUTTER_ROOT': '/',
      }),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      CrashReporter: () => WaitingCrashReporter(commandCompleter.future),
      Artifacts: () => Artifacts.test(),
      HttpClientFactory: () => () => FakeHttpClient.any(),
    });

    testUsingContext('create local report', () async {
      // Since crash reporting calls the doctor, which checks for the devtools
      // version file in the cache, write a version file to the memory fs.
      Cache.flutterRoot = '/path/to/flutter';
      final Directory devtoolsDir = globals.fs.directory(
        '${Cache.flutterRoot}/bin/cache/dart-sdk/bin/resources/devtools',
      )..createSync(recursive: true);
      devtoolsDir.childFile('version.json').writeAsStringSync(
        '{"version": "1.2.3"}',
      );

      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>?>(
        () {
          unawaited(runner.run(
            <String>['crash'],
            () => <FlutterCommand>[
              CrashingFlutterCommand(),
            ],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            reportCrashes: true,
            shutdownHooks: ShutdownHooks(),
          ));
          return null;
        },
        onError: (Object error, StackTrace stack) { // ignore: deprecated_member_use
          expect(firstExitCode, isNotNull);
          expect(firstExitCode, isNot(0));
          expect(error.toString(), 'Exception: test exit');
          completer.complete();
        },
      ));
      await completer.future;

      final String errorText = testLogger.errorText;
      expect(
        errorText,
        containsIgnoringWhitespace('Oops; flutter has exited unexpectedly: "Exception: an exception % --".\n'),
      );

      final File log = globals.fs.file('/flutter_01.log');
      final String logContents = log.readAsStringSync();
      expect(logContents, contains(kCustomBugInstructions));
      expect(logContents, contains('flutter crash'));
      expect(logContents, contains('Exception: an exception % --'));
      expect(logContents, contains('CrashingFlutterCommand.runCommand'));
      expect(logContents, contains('[!] Flutter'));

      final CrashDetails sentDetails = (globals.crashReporter! as WaitingCrashReporter)._details;
      expect(sentDetails.command, 'flutter crash');
      expect(sentDetails.error.toString(), 'Exception: an exception % --');
      expect(sentDetails.stackTrace.toString(), contains('CrashingFlutterCommand.runCommand'));
      expect(await sentDetails.doctorText.text, contains('[!] Flutter'));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FLUTTER_ANALYTICS_LOG_FILE': 'test',
          'FLUTTER_ROOT': '/',
        }
      ),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      UserMessages: () => CustomBugInstructions(),
      Artifacts: () => Artifacts.test(),
      CrashReporter: () => WaitingCrashReporter(Future<void>.value()),
      HttpClientFactory: () => () => FakeHttpClient.any(),
    });

    group('in directory without permission', () {
      setUp(() {
        bool inTestSetup = true;
        fileSystem = MemoryFileSystem(opHandle: (String context, FileSystemOp operation) {
          if (inTestSetup) {
            // Allow all operations during test setup.
            return;
          }
          const Set<FileSystemOp> disallowedOperations = <FileSystemOp>{
            FileSystemOp.create,
            FileSystemOp.delete,
            FileSystemOp.copy,
            FileSystemOp.write,
          };
          // Make current_directory not writable.
          if (context.startsWith('/current_directory') && disallowedOperations.contains(operation)) {
            throw FileSystemException('No permission, context = $context, operation = $operation');
          }
        });
        final Directory currentDirectory = fileSystem.directory('/current_directory');
        currentDirectory.createSync();
        fileSystem.currentDirectory = currentDirectory;
        inTestSetup = false;
      });
      testUsingContext('create local report in temporary directory', () async {
        // Since crash reporting calls the doctor, which checks for the devtools
        // version file in the cache, write a version file to the memory fs.
        Cache.flutterRoot = '/path/to/flutter';
        final Directory devtoolsDir = globals.fs.directory(
          '${Cache.flutterRoot}/bin/cache/dart-sdk/bin/resources/devtools',
        )..createSync(recursive: true);
        devtoolsDir.childFile('version.json').writeAsStringSync(
          '{"version": "1.2.3"}',
        );

        final Completer<void> completer = Completer<void>();
        // runner.run() asynchronously calls the exit function set above, so we
        // catch it in a zone.
        unawaited(runZoned<Future<void>?>(
          () {
            unawaited(runner.run(
              <String>['crash'],
              () => <FlutterCommand>[
                CrashingFlutterCommand(),
              ],
              // This flutterVersion disables crash reporting.
              flutterVersion: '[user-branch]/',
              reportCrashes: true,
              shutdownHooks: ShutdownHooks(),
            ));
            return null;
          },
          onError: (Object error, StackTrace stack) { // ignore: deprecated_member_use
            expect(firstExitCode, isNotNull);
            expect(firstExitCode, isNot(0));
            expect(error.toString(), 'Exception: test exit');
            completer.complete();
          },
        ));
        await completer.future;

        final String errorText = testLogger.errorText;
        expect(
          errorText,
          containsIgnoringWhitespace('Oops; flutter has exited unexpectedly: "Exception: an exception % --".\n'),
        );

        final File log = globals.fs.systemTempDirectory.childFile('flutter_01.log');
        final String logContents = log.readAsStringSync();
        expect(logContents, contains(kCustomBugInstructions));
        expect(logContents, contains('flutter crash'));
        expect(logContents, contains('Exception: an exception % --'));
        expect(logContents, contains('CrashingFlutterCommand.runCommand'));
        expect(logContents, contains('[!] Flutter'));

        final CrashDetails sentDetails = (globals.crashReporter! as WaitingCrashReporter)._details;
        expect(sentDetails.command, 'flutter crash');
        expect(sentDetails.error.toString(), 'Exception: an exception % --');
        expect(sentDetails.stackTrace.toString(), contains('CrashingFlutterCommand.runCommand'));
        expect(await sentDetails.doctorText.text, contains('[!] Flutter'));
      }, overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{
            'FLUTTER_ANALYTICS_LOG_FILE': 'test',
            'FLUTTER_ROOT': '/',
          }
        ),
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        UserMessages: () => CustomBugInstructions(),
        Artifacts: () => Artifacts.test(),
        CrashReporter: () => WaitingCrashReporter(Future<void>.value()),
        HttpClientFactory: () => () => FakeHttpClient.any(),
      });
    });
  });

  group('unified_analytics', () {
    testUsingContext(
      'runner disable telemetry with flag',
      () async {
        io.setExitFunctionForTests((int exitCode) {});

        expect(globals.analytics.telemetryEnabled, true);
        expect(globals.analytics.shouldShowMessage, true);

        await runner.run(
          <String>['--disable-telemetry'],
          () => <FlutterCommand>[],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
        );

        expect(globals.analytics.telemetryEnabled, false);
      },
      overrides: <Type, Generator>{
        Analytics: () => FakeAnalytics(),
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}

class CrashingFlutterCommand extends FlutterCommand {
  CrashingFlutterCommand({
    bool asyncCrash = false,
    Completer<void>? completer,
  }) :  _asyncCrash = asyncCrash,
        _completer = completer;

  final bool _asyncCrash;
  final Completer<void>? _completer;

  @override
  String get description => '';

  @override
  String get name => 'crash';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Exception error = Exception('an exception % --'); // Test URL encoding.
    if (!_asyncCrash) {
      throw error;
    }

    final Completer<void> completer = Completer<void>();
    Timer.run(() {
      completer.complete();
      throw error;
    });

    await completer.future;
    _completer!.complete();

    return FlutterCommandResult.success();
  }
}

class CrashingUsage implements Usage {
  CrashingUsage() : _impl = Usage(
    versionOverride: '[user-branch]',
    runningOnBot: true,
  );

  final Usage _impl;

  dynamic get sentException => _sentException;
  dynamic _sentException;

  bool _firstAttempt = true;

  // Crash while crashing.
  @override
  void sendException(dynamic exception) {
    if (_firstAttempt) {
      _firstAttempt = false;
      throw Exception('CrashingUsage.sendException');
    }
    _sentException = exception;
  }

  @override
  bool get suppressAnalytics => _impl.suppressAnalytics;

  @override
  set suppressAnalytics(bool value) {
    _impl.suppressAnalytics = value;
  }

  @override
  bool get enabled => _impl.enabled;

  @override
  set enabled(bool value) {
    _impl.enabled = value;
  }

  @override
  String get clientId => _impl.clientId;

  @override
  void sendCommand(String command, {CustomDimensions? parameters}) =>
      _impl.sendCommand(command, parameters: parameters);

  @override
  void sendEvent(
    String category,
    String parameter, {
    String? label,
    int? value,
    CustomDimensions? parameters,
  }) => _impl.sendEvent(
    category,
    parameter,
    label: label,
    value: value,
    parameters: parameters,
  );

  @override
  void sendTiming(
    String category,
    String variableName,
    Duration duration, {
    String? label,
  }) => _impl.sendTiming(category, variableName, duration, label: label);

  @override
  Stream<Map<String, dynamic>> get onSend => _impl.onSend;

  @override
  Future<void> ensureAnalyticsSent() => _impl.ensureAnalyticsSent();

  @override
  void printWelcome() => _impl.printWelcome();
}

class CustomBugInstructions extends UserMessages {
  @override
  String get flutterToolBugInstructions => kCustomBugInstructions;
}

/// A fake [CrashReporter] that waits for a [Future] to complete.
///
/// Used to exacerbate a race between the success and failure paths of
/// [runner.run]. See https://github.com/flutter/flutter/issues/56406.
class WaitingCrashReporter implements CrashReporter {
  WaitingCrashReporter(Future<void> future) : _future = future;

  final Future<void> _future;
  late CrashDetails _details;

  @override
  Future<void> informUser(CrashDetails details, File crashFile) {
    _details = details;
    return _future;
  }
}

/// A fake [Analytics] that will be used to test
/// the --disable-telemetry flag
class FakeAnalytics extends Fake implements Analytics {
  bool _fakeTelemetryStatus = true;
  bool _fakeShowMessage = true;

  @override
  String get getConsentMessage => 'message';

  @override
  bool get shouldShowMessage => _fakeShowMessage;

  @override
  void clientShowedMessage() {
    _fakeShowMessage = false;
  }

  @override
  Future<void> setTelemetry(bool reportingBool) {
    _fakeTelemetryStatus = reportingBool;
    return Future<void>.value();
  }

  @override
  bool get telemetryEnabled => _fakeTelemetryStatus;
}
