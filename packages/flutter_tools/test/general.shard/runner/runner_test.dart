// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String kCustomBugInstructions = 'These are instructions to report with a custom bug tracker.';

void main() {
  int firstExitCode;

  group('runner', () {
    setUp(() {
      // Instead of exiting with dart:io exit(), this causes an exception to
      // be thrown, which we catch with the onError callback in the zone below.
      //
      // Tests might trigger exit() multiple times.  In real life, exit() would
      // cause the VM to terminate immediately, so only the first one matters.
      firstExitCode = null;
      io.setExitFunctionForTests((int exitCode) {
        firstExitCode ??= exitCode;

        // TODO(jamesderlin): Ideally only the first call to exit() would be
        // honored and subsequent calls would be no-ops, but existing tests
        // rely on all calls to throw.
        throw 'test exit';
      });

      Cache.disableLocking();
    });

    tearDown(() {
      io.restoreExitFunction();
      Cache.enableLocking();
    });

    testUsingContext('error handling crash report (synchronous crash)', () async {
      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>>(
        () {
          unawaited(runner.run(
            <String>['crash'],
            () => <FlutterCommand>[
              CrashingFlutterCommand(),
            ],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            reportCrashes: true,
          ));
          return null;
        },
        onError: (Object error, StackTrace stack) { // ignore: deprecated_member_use
          expect(firstExitCode, isNotNull);
          expect(firstExitCode, isNot(0));
          expect(error, 'test exit');
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
      expect(crashingUsage.sentException, 'an exception % --');
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_ANALYTICS_LOG_FILE': 'test',
        'FLUTTER_ROOT': '/',
      }),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Usage: () => CrashingUsage(),
      Artifacts: () => Artifacts.test(),
    });

    // This Completer completes when CrashingFlutterCommand.runCommand
    // completes, but ideally we'd want it to complete when execution resumes
    // runner.run.  Currently the distinction does not matter, but if it ever
    // does, this test might fail to catch a regression of
    // https://github.com/flutter/flutter/issues/56406.
    final Completer<void> commandCompleter = Completer<void>();
    testUsingContext('error handling crash report (asynchronous crash)', () async {
      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>>(
        () {
          unawaited(runner.run(
            <String>['crash'],
            () => <FlutterCommand>[
              CrashingFlutterCommand(asyncCrash: true, completer: commandCompleter),
            ],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            reportCrashes: true,
          ));
          return null;
        },
        onError: (Object error, StackTrace stack) { // ignore: deprecated_member_use
          expect(firstExitCode, isNotNull);
          expect(firstExitCode, isNot(0));
          expect(error, 'test exit');
          completer.complete();
        },
      ));
      await completer.future;
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_ANALYTICS_LOG_FILE': 'test',
        'FLUTTER_ROOT': '/',
      }),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      CrashReporter: () => WaitingCrashReporter(commandCompleter.future),
      Artifacts: () => Artifacts.test(),
    });

    testUsingContext('create local report', () async {
      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>>(
        () {
        unawaited(runner.run(
          <String>['crash'],
          () => <FlutterCommand>[
            CrashingFlutterCommand(),
          ],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          reportCrashes: true,
        ));
        return null;
        },
        onError: (Object error, StackTrace stack) { // ignore: deprecated_member_use
          expect(firstExitCode, isNotNull);
          expect(firstExitCode, isNot(0));
          expect(error, 'test exit');
          completer.complete();
        },
      ));
      await completer.future;

      final String errorText = testLogger.errorText;
      expect(
        errorText,
        containsIgnoringWhitespace('Oops; flutter has exited unexpectedly: "an exception % --".\n'),
      );

      final File log = globals.fs.file('/flutter_01.log');
      final String logContents = log.readAsStringSync();
      expect(logContents, contains(kCustomBugInstructions));
      expect(logContents, contains('flutter crash'));
      expect(logContents, contains('String: an exception % --'));
      expect(logContents, contains('CrashingFlutterCommand.runCommand'));
      expect(logContents, contains('[✓] Flutter'));
      print(globals.crashReporter.runtimeType);

      final CrashDetails sentDetails = (globals.crashReporter as WaitingCrashReporter)._details;
      expect(sentDetails.command, 'flutter crash');
      expect(sentDetails.error, 'an exception % --');
      expect(sentDetails.stackTrace.toString(), contains('CrashingFlutterCommand.runCommand'));
      expect(sentDetails.doctorText, contains('[✓] Flutter'));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FLUTTER_ANALYTICS_LOG_FILE': 'test',
          'FLUTTER_ROOT': '/',
        },
        operatingSystem: 'linux'
      ),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      UserMessages: () => CustomBugInstructions(),
      Artifacts: () => Artifacts.test(),
      CrashReporter: () => WaitingCrashReporter(Future<void>.value())
    });
  });
}

class CrashingFlutterCommand extends FlutterCommand {
  CrashingFlutterCommand({
    bool asyncCrash = false,
    Completer<void> completer,
  }) :  _asyncCrash = asyncCrash,
        _completer = completer;

  final bool _asyncCrash;
  final Completer<void> _completer;

  @override
  String get description => null;

  @override
  String get name => 'crash';

  @override
  Future<FlutterCommandResult> runCommand() async {
    const String error = 'an exception % --'; // Test URL encoding.
    if (!_asyncCrash) {
      throw error;
    }

    final Completer<void> completer = Completer<void>();
    Timer.run(() {
      completer.complete();
      throw error;
    });

    await completer.future;
    _completer.complete();

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
      throw 'CrashingUsage.sendException';
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
  void sendCommand(String command, {CustomDimensions parameters}) =>
      _impl.sendCommand(command, parameters: parameters);

  @override
  void sendEvent(
    String category,
    String parameter, {
    String label,
    int value,
    CustomDimensions parameters,
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
    String label,
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
/// [runner.run].  See https://github.com/flutter/flutter/issues/56406.
class WaitingCrashReporter implements CrashReporter {
  WaitingCrashReporter(Future<void> future) : _future = future;

  final Future<void> _future;
  CrashDetails _details;

  @override
  Future<void> informUser(CrashDetails details, File crashFile) {
    _details = details;
    return _future;
  }
}
