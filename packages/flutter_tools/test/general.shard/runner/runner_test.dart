// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/executable.dart';
import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/exit.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/testing.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_http_client.dart';
import '../../src/fakes.dart';

const kCustomBugInstructions = 'These are instructions to report with a custom bug tracker.';

void main() {
  group('runner (crash reporting)', () {
    int? firstExitCode;
    late MemoryFileSystem fileSystem;
    late FakeAnalytics fakeAnalytics;
    late FakeStdio fakeStdio;

    setUp(() {
      // Instead of exiting with dart:io exit(), this causes an exception to
      // be thrown, which we catch with the onError callback in the zone below.
      //
      // Tests might trigger exit() multiple times. In real life, exit() would
      // cause the VM to terminate immediately, so only the first one matters.
      firstExitCode = null;
      setExitFunctionForTests((int exitCode) {
        firstExitCode ??= exitCode;

        // TODO(jamesderlin): Ideally only the first call to exit() would be
        // honored and subsequent calls would be no-ops, but existing tests
        // rely on all calls to throw.
        throw Exception('test exit');
      });

      Cache.disableLocking();
      fileSystem = MemoryFileSystem.test();

      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
      fakeStdio = FakeStdio();
    });

    tearDown(() {
      restoreExitFunction();
      Cache.enableLocking();
    });

    testUsingContext(
      'error handling crash report (synchronous crash)',
      () async {
        final completer = Completer<void>();
        // runner.run() asynchronously calls the exit function set above, so we
        // catch it in a zone.
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>['crash'],
                  () => <FlutterCommand>[CrashingFlutterCommand()],
                  // This flutterVersion disables crash reporting.
                  flutterVersion: '[user-branch]/',
                  reportCrashes: true,
                  shutdownHooks: ShutdownHooks(),
                ),
              );
              return null;
            },
            (Object error, StackTrace stack) {
              expect(firstExitCode, isNotNull);
              expect(firstExitCode, isNot(0));
              expect(error.toString(), 'Exception: test exit');
              completer.complete();
            },
          ),
        );
        await completer.future;

        // This is the main check of this test.
        //
        // We are checking that, even though crash reporting failed with an
        // exception on the first attempt, the second attempt tries to report the
        // *original* crash, and not the crash from the first crash report
        // attempt.
        expect(fakeAnalytics.sentEvents, contains(Event.exception(exception: '_Exception')));
      },
      overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Artifacts: () => Artifacts.test(),
        HttpClientFactory: () =>
            () => FakeHttpClient.any(),
        Analytics: () => fakeAnalytics,
      },
    );

    testUsingContext(
      'error handling crash report (local engine)',
      () async {
        fileSystem
            .directory('engine')
            .childDirectory('src')
            .childDirectory('out')
            .createSync(recursive: true);

        final completer = Completer<void>();
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>[
                    '--local-engine=host_debug',
                    '--local-engine-src-path=./engine/src',
                    'crash',
                  ],
                  () => <FlutterCommand>[CrashingFlutterCommand()],
                  // This flutterVersion disables crash reporting.
                  flutterVersion: '[user-branch]/',
                  reportCrashes: true,
                  shutdownHooks: ShutdownHooks(),
                ),
              );
              return null;
            },
            (Object error, StackTrace stack) {
              expect(firstExitCode, isNotNull);
              expect(firstExitCode, isNot(0));
              expect(error.toString(), 'Exception: test exit');
              completer.complete();
            },
          ),
        );
        await completer.future;

        expect(
          fakeAnalytics.sentEvents,
          isNot(contains(Event.exception(exception: '_Exception'))),
          reason: 'Does not send a report when using --local-engine',
        );
      },
      overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Artifacts: () => Artifacts.test(),
        HttpClientFactory: () =>
            () => FakeHttpClient.any(),
        Analytics: () => fakeAnalytics,
      },
    );

    testUsingContext(
      'error handling crash report (bot)',
      () async {
        final completer = Completer<void>();
        // runner.run() asynchronously calls the exit function set above, so we
        // catch it in a zone.
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>['crash'],
                  () => <FlutterCommand>[CrashingFlutterCommand()],
                  // This flutterVersion disables crash reporting.
                  flutterVersion: '[user-branch]/',
                  shutdownHooks: ShutdownHooks(),
                ),
              );
              return null;
            },
            (Object error, StackTrace stack) {
              expect(firstExitCode, isNotNull);
              expect(firstExitCode, isNot(0));
              expect(error.toString(), 'Exception: test exit');
              completer.complete();
            },
          ),
        );
        await completer.future;

        expect(
          fakeAnalytics.sentEvents,
          isNot(contains(Event.exception(exception: '_Exception'))),
          reason: 'Does not send a report on a bot',
        );

        expect(
          fakeStdio.writtenToStderr,
          contains(contains('Feature flags enabled:')),
          reason: 'Should emit feature flags (ignore specifics for test stability)',
        );
      },
      overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Artifacts: () => Artifacts.test(),
        HttpClientFactory: () =>
            () => FakeHttpClient.any(),
        Analytics: () => fakeAnalytics,
        BotDetector: () => const FakeBotDetector(true),
        io.Stdio: () => fakeStdio,
      },
    );

    // This Completer completes when CrashingFlutterCommand.runCommand
    // completes, but ideally we'd want it to complete when execution resumes
    // runner.run. Currently the distinction does not matter, but if it ever
    // does, this test might fail to catch a regression of
    // https://github.com/flutter/flutter/issues/56406.
    final commandCompleter = Completer<void>();
    testUsingContext(
      'error handling crash report (asynchronous crash)',
      () async {
        final completer = Completer<void>();
        // runner.run() asynchronously calls the exit function set above, so we
        // catch it in a zone.
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>['crash'],
                  () => <FlutterCommand>[
                    CrashingFlutterCommand(asyncCrash: true, completer: commandCompleter),
                  ],
                  // This flutterVersion disables crash reporting.
                  flutterVersion: '[user-branch]/',
                  reportCrashes: true,
                  shutdownHooks: ShutdownHooks(),
                ),
              );
              return null;
            },
            (Object error, StackTrace stack) {
              expect(firstExitCode, isNotNull);
              expect(firstExitCode, isNot(0));
              expect(error.toString(), 'Exception: test exit');
              completer.complete();
            },
          ),
        );
        await completer.future;
      },
      overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        CrashReporter: () => WaitingCrashReporter(commandCompleter.future),
        Artifacts: () => Artifacts.test(),
        HttpClientFactory: () =>
            () => FakeHttpClient.any(),
      },
    );

    testUsingContext(
      "doesn't send multiple events for additional asynchronous exceptions "
      'thrown during shutdown',
      () async {
        // Regression test for https://github.com/flutter/flutter/issues/178318.
        final command = MultipleExceptionCrashingFlutterCommand();
        var exceptionCount = 0;
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>['crash'],
                  () => <FlutterCommand>[command],
                  // This flutterVersion disables crash reporting.
                  flutterVersion: '[user-branch]/',
                  reportCrashes: true,
                  shutdownHooks: ShutdownHooks(),
                ),
              );
              return null;
            },
            (Object error, StackTrace stack) {
              // Keep track of the number of exceptions thrown to ensure that
              // the count matches the number of exceptions we expect.
              exceptionCount++;
            },
          ),
        );
        await command.doneThrowing;

        // This is the main check of this test.
        //
        // We are checking that, even though multiple asynchronous errors were
        // thrown, only a single crash report is sent. This ensures that a
        // single process crash can't result in multiple crash events.

        // This test only makes sense if we've thrown more than one exception.
        expect(exceptionCount, greaterThan(1));
        expect(exceptionCount, command.exceptionCount);

        // Ensure only a single exception analytics event was sent.
        final List<Event> exceptionEvents = fakeAnalytics.sentEvents
            .where((e) => e.eventName == DashEvent.exception)
            .toList();
        expect(exceptionEvents, hasLength(1));
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        CrashReporter: () => WaitingCrashReporter(Future<void>.value()),
        Artifacts: () => Artifacts.test(),
        HttpClientFactory: () =>
            () => FakeHttpClient.any(),
      },
    );

    testUsingContext(
      'create local report',
      () async {
        // Since crash reporting calls the doctor, which checks for the devtools
        // version file in the cache, write a version file to the memory fs.
        Cache.flutterRoot = '/path/to/flutter';
        final Directory devtoolsDir = globals.fs.directory(
          '${Cache.flutterRoot}/bin/cache/dart-sdk/bin/resources/devtools',
        )..createSync(recursive: true);
        devtoolsDir.childFile('version.json').writeAsStringSync('{"version": "1.2.3"}');

        final completer = Completer<void>();
        // runner.run() asynchronously calls the exit function set above, so we
        // catch it in a zone.
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>['crash'],
                  () => <FlutterCommand>[CrashingFlutterCommand()],
                  // This flutterVersion disables crash reporting.
                  flutterVersion: '[user-branch]/',
                  reportCrashes: true,
                  shutdownHooks: ShutdownHooks(),
                ),
              );
              return null;
            },
            (Object error, StackTrace stack) {
              expect(firstExitCode, isNotNull);
              expect(firstExitCode, isNot(0));
              expect(error.toString(), 'Exception: test exit');
              completer.complete();
            },
          ),
        );
        await completer.future;

        final String errorText = testLogger.errorText;
        expect(
          errorText,
          containsIgnoringWhitespace(
            'Oops; flutter has exited unexpectedly: "Exception: an exception % --".\n',
          ),
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
        expect(
          await sentDetails.doctorText.text,
          stringContainsInOrder(<String>['[!] Flutter', 'Dart version 12']),
          reason: 'Captures flutter doctor -v, which includes Dart version',
        );
      },
      overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        UserMessages: () => CustomBugInstructions(),
        Artifacts: () => Artifacts.test(),
        CrashReporter: () => WaitingCrashReporter(Future<void>.value()),
        HttpClientFactory: () =>
            () => FakeHttpClient.any(),
      },
    );

    group('in directory without permission', () {
      setUp(() {
        var inTestSetup = true;
        fileSystem = MemoryFileSystem(
          opHandle: (String context, FileSystemOp operation) {
            if (inTestSetup) {
              // Allow all operations during test setup.
              return;
            }
            const disallowedOperations = <FileSystemOp>{
              FileSystemOp.create,
              FileSystemOp.delete,
              FileSystemOp.copy,
              FileSystemOp.write,
            };
            // Make current_directory not writable.
            if (context.startsWith('/current_directory') &&
                disallowedOperations.contains(operation)) {
              throw FileSystemException(
                'No permission, context = $context, operation = $operation',
              );
            }
          },
        );
        final Directory currentDirectory = fileSystem.directory('/current_directory');
        currentDirectory.createSync();
        fileSystem.currentDirectory = currentDirectory;
        inTestSetup = false;
      });

      testUsingContext(
        'create local report in temporary directory',
        () async {
          // Since crash reporting calls the doctor, which checks for the devtools
          // version file in the cache, write a version file to the memory fs.
          Cache.flutterRoot = '/path/to/flutter';
          final Directory devtoolsDir = globals.fs.directory(
            '${Cache.flutterRoot}/bin/cache/dart-sdk/bin/resources/devtools',
          )..createSync(recursive: true);
          devtoolsDir.childFile('version.json').writeAsStringSync('{"version": "1.2.3"}');

          final completer = Completer<void>();
          // runner.run() asynchronously calls the exit function set above, so we
          // catch it in a zone.
          unawaited(
            runZonedGuarded<Future<void>?>(
              () {
                unawaited(
                  runner.run(
                    <String>['crash'],
                    () => <FlutterCommand>[CrashingFlutterCommand()],
                    // This flutterVersion disables crash reporting.
                    flutterVersion: '[user-branch]/',
                    reportCrashes: true,
                    shutdownHooks: ShutdownHooks(),
                  ),
                );
                return null;
              },
              (Object error, StackTrace stack) {
                expect(firstExitCode, isNotNull);
                expect(firstExitCode, isNot(0));
                expect(error.toString(), 'Exception: test exit');
                completer.complete();
              },
            ),
          );
          await completer.future;

          final String errorText = testLogger.errorText;
          expect(
            errorText,
            containsIgnoringWhitespace(
              'Oops; flutter has exited unexpectedly: "Exception: an exception % --".\n',
            ),
          );

          final File log = globals.fs.systemTempDirectory.childFile('flutter_01.log');
          final String logContents = log.readAsStringSync();
          expect(logContents, contains(kCustomBugInstructions));
          expect(logContents, contains('flutter crash'));
          expect(logContents, contains('Exception: an exception % --'));
          expect(logContents, contains('CrashingFlutterCommand.runCommand'));
          expect(logContents, contains('[!] Flutter'));

          final CrashDetails sentDetails =
              (globals.crashReporter! as WaitingCrashReporter)._details;
          expect(sentDetails.command, 'flutter crash');
          expect(sentDetails.error.toString(), 'Exception: an exception % --');
          expect(sentDetails.stackTrace.toString(), contains('CrashingFlutterCommand.runCommand'));
          expect(await sentDetails.doctorText.text, contains('[!] Flutter'));
        },
        overrides: <Type, Generator>{
          Platform: () => FakePlatform(
            environment: <String, String>{
              'FLUTTER_ANALYTICS_LOG_FILE': 'test',
              'FLUTTER_ROOT': '/',
            },
          ),
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.any(),
          UserMessages: () => CustomBugInstructions(),
          Artifacts: () => Artifacts.test(),
          CrashReporter: () => WaitingCrashReporter(Future<void>.value()),
          HttpClientFactory: () =>
              () => FakeHttpClient.any(),
        },
      );
    });
  });

  group('runner', () {
    late MemoryFileSystem fs;

    setUp(() {
      setExitFunctionForTests((int exitCode) {});

      fs = MemoryFileSystem.test();

      Cache.disableLocking();
    });

    tearDown(() {
      restoreExitFunction();
      Cache.enableLocking();
    });

    testUsingContext(
      "catches ProcessException calling git because it's not available",
      () async {
        final command = _GitNotFoundFlutterCommand();

        await runner.run(
          <String>[command.name],
          () => <FlutterCommand>[command],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          reportCrashes: false,
          shutdownHooks: ShutdownHooks(),
        );

        expect(
          (globals.logger as BufferLogger).errorText,
          'Failed to find "git" in the search path.\n'
          '\n'
          'An error was encountered when trying to run git.\n'
          "Please ensure git is installed and available in your system's search path. "
          'See https://docs.flutter.dev/get-started for instructions on installing git for your platform.\n',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fs,
        Artifacts: () => Artifacts.test(),
        ProcessManager: () => FakeProcessManager.any()..excludedExecutables.add('git'),
      },
    );

    testUsingContext(
      'handles ProcessException calling git when ProcessManager.canRun fails',
      () async {
        final command = _GitNotFoundFlutterCommand();

        await runner.run(
          <String>[command.name],
          () => <FlutterCommand>[command],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          reportCrashes: false,
          shutdownHooks: ShutdownHooks(),
        );

        expect(
          (globals.logger as BufferLogger).errorText,
          'Failed to find "git" in the search path.\n'
          '\n'
          'An error was encountered when trying to run git.\n'
          "Please ensure git is installed and available in your system's search path. "
          'See https://docs.flutter.dev/get-started for instructions on installing git for your platform.\n',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fs,
        Artifacts: () => Artifacts.test(),
        ProcessManager: () => _ErrorOnCanRunFakeProcessManager(),
      },
    );

    testUsingContext(
      'do not print welcome on bots',
      () async {
        await runner.run(
          <String>['--version', '--machine'],
          () => <FlutterCommand>[],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
        );

        expect(
          (globals.logger as BufferLogger).traceText,
          isNot(contains('Showed analytics consent message.')),
        );
      },
      overrides: <Type, Generator>{
        Logger: () => BufferLogger.test(),
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        BotDetector: () => const FakeBotDetector(true),
      },
    );

    testUsingContext(
      'do not print download messages when --machine is provided',
      () async {
        // Regression test for https://github.com/flutter/flutter/issues/154119.
        final stdio = FakeStdio();
        await runner.run(
          <String>['devices', '--machine'],
          () => <FlutterCommand>[DevicesCommand()],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
          overrides: {
            Logger: () {
              final loggerFactory = LoggerFactory(
                outputPreferences: globals.outputPreferences,
                terminal: globals.terminal,
                stdio: stdio,
              );
              return loggerFactory.createLogger(
                daemon: false,
                // This is set to true when --machine is detected as an argument in
                // executable.dart.
                machine: true,
                verbose: false,
                prefixedErrors: false,
                widgetPreviews: false,
                windows: globals.platform.isWindows,
              );
            },
          },
        );
        expect(stdio.writtenToStdout.join(), isNot(contains('Downloading')));
        expect(stdio.writtenToStderr.join(), isNot(contains('Downloading')));
      },
      overrides: <Type, Generator>{
        Cache: () => FakeCache(),
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        BotDetector: () => const FakeBotDetector(true),
      },
    );
  });

  group('unified_analytics', () {
    late FakeAnalytics fakeAnalytics;
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();

      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fs,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    testUsingContext(
      'runner disable telemetry with flag',
      () async {
        setExitFunctionForTests((int exitCode) {});

        expect(globals.analytics.telemetryEnabled, true);

        await runner.run(
          <String>['--disable-analytics'],
          () => <FlutterCommand>[],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
        );

        expect(globals.analytics.telemetryEnabled, false);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      '--enable-analytics and --disable-analytics enables/disables telemetry',
      () async {
        setExitFunctionForTests((int exitCode) {});

        expect(globals.analytics.telemetryEnabled, true);

        await runner.run(
          <String>['--disable-analytics'],
          () => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(globals.analytics.telemetryEnabled, false);

        await runner.run(
          <String>['--enable-analytics'],
          () => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(globals.analytics.telemetryEnabled, true);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      '--enable-analytics and --disable-analytics send an event when telemetry is enabled/disabled',
      () async {
        setExitFunctionForTests((int exitCode) {});
        await globals.analytics.setTelemetry(true);

        await runner.run(
          <String>['--disable-analytics'],
          () => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect((globals.analytics as FakeAnalytics).sentEvents, <Event>[
          Event.analyticsCollectionEnabled(status: false),
        ]);

        (globals.analytics as FakeAnalytics).sentEvents.clear();
        expect(globals.analytics.telemetryEnabled, false);
        await runner.run(
          <String>['--enable-analytics'],
          () => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect((globals.analytics as FakeAnalytics).sentEvents, <Event>[
          Event.analyticsCollectionEnabled(status: true),
        ]);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      '--enable-analytics and --disable-analytics do not send an event when telemetry is already enabled/disabled',
      () async {
        setExitFunctionForTests((int exitCode) {});

        await globals.analytics.setTelemetry(false);
        await runner.run(
          <String>['--disable-analytics'],
          () => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect((globals.analytics as FakeAnalytics).sentEvents, isEmpty);

        await globals.analytics.setTelemetry(true);
        await runner.run(
          <String>['--enable-analytics'],
          () => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect((globals.analytics as FakeAnalytics).sentEvents, isEmpty);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'throw error when both flags passed',
      () async {
        setExitFunctionForTests((int exitCode) {});

        expect(globals.analytics.telemetryEnabled, true);

        final int exitCode = await runner.run(
          <String>['--disable-analytics', '--enable-analytics'],
          () => <FlutterCommand>[],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
        );

        expect(exitCode, 1, reason: 'Should return 1 due to conflicting options for telemetry');
        expect(
          globals.analytics.telemetryEnabled,
          true,
          reason: 'Should not have changed from initialization',
        );
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}

class CrashingFlutterCommand extends FlutterCommand {
  CrashingFlutterCommand({bool asyncCrash = false, Completer<void>? completer})
    : _asyncCrash = asyncCrash,
      _completer = completer;

  final bool _asyncCrash;
  final Completer<void>? _completer;

  @override
  String get description => '';

  @override
  String get name => 'crash';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final error = Exception('an exception % --'); // Test URL encoding.
    if (!_asyncCrash) {
      throw error;
    }

    final completer = Completer<void>();
    Timer.run(() {
      completer.complete();
      throw error;
    });

    await completer.future;
    _completer!.complete();

    return FlutterCommandResult.success();
  }
}

class MultipleExceptionCrashingFlutterCommand extends FlutterCommand {
  final _completer = Completer<void>();

  @override
  String get description => '';

  @override
  String get name => 'crash';

  Future<void> get doneThrowing => _completer.future;

  int exceptionCount = 0;

  @override
  Future<FlutterCommandResult> runCommand() async {
    Timer.periodic(const Duration(milliseconds: 10), (timer) {
      exceptionCount++;
      if (exceptionCount < 5) {
        throw Exception('ERROR: $exceptionCount');
      }
      timer.cancel();
      _completer.complete();
    });

    return FlutterCommandResult.success();
  }
}

class _GitNotFoundFlutterCommand extends FlutterCommand {
  @override
  String get description => '';

  @override
  String get name => 'git-not-found';

  @override
  Future<FlutterCommandResult> runCommand() {
    throw const io.ProcessException('git', <String>[
      'log',
    ], 'Failed to find "git" in the search path.');
  }
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

class _ErrorOnCanRunFakeProcessManager extends Fake implements FakeProcessManager {
  final delegate = FakeProcessManager.any();
  @override
  bool canRun(dynamic executable, {String? workingDirectory}) {
    if (executable == 'git') {
      throw Exception("oh no, we couldn't check for git!");
    }
    return delegate.canRun(executable, workingDirectory: workingDirectory);
  }
}

class FakeCache extends Fake implements Cache {
  @override
  Future<void> lock() async {}

  @override
  void releaseLock() {}

  @override
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts, {bool offline = false}) async {
    globals.logger.startProgress('Downloading package Foo').stop();
  }
}
