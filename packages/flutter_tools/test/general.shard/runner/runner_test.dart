// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/executable.dart';
import 'package:flutter_tools/runner.dart' as runner;

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/exit.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_device_manager.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/pre_run_validator.dart';
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';
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
    late WaitingCrashReporter crashReporter;

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
      crashReporter = WaitingCrashReporter(Future<void>.value());
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
                  (ToolDependencies toolDependencies) => <FlutterCommand>[CrashingFlutterCommand()],
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
              expect(error.toString(), 'ProcessExit: 1');
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
                  (ToolDependencies toolDependencies) => <FlutterCommand>[CrashingFlutterCommand()],
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

    // The artifacts commands are built with are chosen before the command line
    // is parsed, so they have to be rebuilt once a local engine is found.
    testUsingContext(
      'builds commands with the local engine the command line asks for',
      () async {
        fileSystem
            .directory('engine')
            .childDirectory('src')
            .childDirectory('out')
            .childDirectory('host_debug')
            .createSync(recursive: true);
        final ranCommands = <ArtifactsRecordingFlutterCommand>[];

        // Exiting is faked out to throw, so catch that rather than the runner
        // being able to return.
        final completer = Completer<void>();
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>[
                    '--local-engine=host_debug',
                    '--local-engine-host=host_debug',
                    '--local-engine-src-path=./engine/src',
                    'record',
                  ],
                  (ToolDependencies toolDependencies) {
                    final command = ArtifactsRecordingFlutterCommand();
                    ranCommands.add(command);
                    return <FlutterCommand>[command];
                  },
                  flutterVersion: '[user-branch]/',
                  shutdownHooks: ShutdownHooks(),
                ),
              );
              return null;
            },
            (Object error, StackTrace stack) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          ),
        );
        await completer.future;

        final Artifacts? artifacts = ranCommands.singleWhere((command) => command.ran).artifacts;
        expect(artifacts?.localEngineInfo?.targetOutPath, endsWith('engine/src/out/host_debug'));
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
                  (ToolDependencies toolDependencies) => <FlutterCommand>[CrashingFlutterCommand()],
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
                  (ToolDependencies toolDependencies) => <FlutterCommand>[
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
              expect(error.toString(), 'ProcessExit: 1');
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
                  (ToolDependencies toolDependencies) => <FlutterCommand>[command],
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
        final Directory devtoolsDir = fileSystem.directory(
          '/path/to/flutter/bin/cache/dart-sdk/bin/resources/devtools',
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
                  (ToolDependencies toolDependencies) => <FlutterCommand>[CrashingFlutterCommand()],
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
              expect(error.toString(), 'ProcessExit: 1');
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

        final File log = fileSystem.file('/flutter_01.log');
        final String logContents = log.readAsStringSync();
        expect(logContents, contains(kCustomBugInstructions));
        expect(logContents, contains('flutter crash'));
        expect(logContents, contains('Exception: an exception % --'));
        expect(logContents, contains('CrashingFlutterCommand.runCommand'));
        expect(logContents, contains('[!] Flutter'));

        final CrashDetails sentDetails = crashReporter._details;
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
        Cache: () => Cache.test(
          rootOverride: fileSystem.directory('/path/to/flutter'),
          flutterRoot: '/path/to/flutter',
          fileSystem: fileSystem,
          processManager: FakeProcessManager.any(),
        ),
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        FileSystem: () => fileSystem,
        ProcessManager: _NoWhichProcessManager.new,
        UserMessages: () => CustomBugInstructions(),
        Artifacts: () => Artifacts.test(),
        CrashReporter: () => crashReporter,
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
          final Directory devtoolsDir = fileSystem.directory(
            '/path/to/flutter/bin/cache/dart-sdk/bin/resources/devtools',
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
                    (ToolDependencies toolDependencies) => <FlutterCommand>[
                      CrashingFlutterCommand(),
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
                expect(error.toString(), 'ProcessExit: 1');
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

          final File log = fileSystem.systemTempDirectory.childFile('flutter_01.log');
          final String logContents = log.readAsStringSync();
          expect(logContents, contains(kCustomBugInstructions));
          expect(logContents, contains('flutter crash'));
          expect(logContents, contains('Exception: an exception % --'));
          expect(logContents, contains('CrashingFlutterCommand.runCommand'));
          expect(logContents, contains('[!] Flutter'));

          final CrashDetails sentDetails = crashReporter._details;
          expect(sentDetails.command, 'flutter crash');
          expect(sentDetails.error.toString(), 'Exception: an exception % --');
          expect(sentDetails.stackTrace.toString(), contains('CrashingFlutterCommand.runCommand'));
          expect(await sentDetails.doctorText.text, contains('[!] Flutter'));
        },
        overrides: <Type, Generator>{
          Cache: () => Cache.test(
            rootOverride: fileSystem.directory('/path/to/flutter'),
            flutterRoot: '/path/to/flutter',
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
          ),
          Platform: () => FakePlatform(
            environment: <String, String>{
              'FLUTTER_ANALYTICS_LOG_FILE': 'test',
              'FLUTTER_ROOT': '/',
            },
          ),
          FileSystem: () => fileSystem,
          ProcessManager: _NoWhichProcessManager.new,
          UserMessages: () => CustomBugInstructions(),
          Artifacts: () => Artifacts.test(),
          CrashReporter: () => crashReporter,
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
        final logger = BufferLogger.test();
        final command = _GitNotFoundFlutterCommand();

        await runner.run(
          <String>[command.name],
          (ToolDependencies toolDependencies) => <FlutterCommand>[command],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          reportCrashes: false,
          shutdownHooks: ShutdownHooks(),
          overrides: <Type, Generator>{Logger: () => logger},
        );

        expect(
          logger.errorText,
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
        final logger = BufferLogger.test();
        final command = _GitNotFoundFlutterCommand();

        await runner.run(
          <String>[command.name],
          (ToolDependencies toolDependencies) => <FlutterCommand>[command],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          reportCrashes: false,
          shutdownHooks: ShutdownHooks(),
          overrides: <Type, Generator>{Logger: () => logger},
        );

        expect(
          logger.errorText,
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
        final logger = BufferLogger.test();
        await runner.run(
          <String>['--version', '--machine'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
          overrides: <Type, Generator>{Logger: () => logger},
        );

        expect(logger.traceText, isNot(contains('Showed analytics consent message.')));
      },
      overrides: <Type, Generator>{
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
        final loggerFactory = LoggerFactory(
          outputPreferences: OutputPreferences.test(),
          terminal: Terminal.test(),
          stdio: stdio,
        );
        final Logger logger = loggerFactory.createLogger(
          daemon: false,
          // This is set to true when --machine is detected as an argument in
          // executable.dart.
          machine: true,
          verbose: false,
          prefixedErrors: false,
          widgetPreviews: false,
          windows: const LocalPlatform().isWindows,
        );
        await runner.run(
          <String>['devices', '--machine'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[
            DevicesCommand(
              deviceManager: toolDependencies.deviceManager,
              doctor: toolDependencies.doctor,
              toolContext: toolDependencies.toolContext,
            ),
          ],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
          overrides: {
            Cache: () => FakeCache(fs: fs, logger: logger),
            Logger: () => logger,
          },
        );
        expect(stdio.writtenToStdout.join(), isNot(contains('Downloading')));
        expect(stdio.writtenToStderr.join(), isNot(contains('Downloading')));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        BotDetector: () => const FakeBotDetector(true),
      },
    );

    testUsingContext(
      'binds bootstrapped DeviceManager into context for command execution',
      () async {
        late final ToolDependencies capturedDependencies;
        final command = _DeviceManagerRecordingFlutterCommand();
        await runner.run(
          <String>[command.name],
          (ToolDependencies toolDependencies) {
            capturedDependencies = toolDependencies;
            return <FlutterCommand>[command];
          },
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
        );

        expect(capturedDependencies.deviceManager, isA<FlutterDeviceManager>());
        expect(command.deviceManager, same(capturedDependencies.deviceManager));
      },
      overrides: <Type, Generator>{
        DeviceManager: () => null,
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    group('lazy Android dependency evaluation', () {
      var sdkEvaluations = 0;
      var studioEvaluations = 0;
      var gradleEvaluations = 0;
      var javaEvaluations = 0;

      setUp(() {
        sdkEvaluations = 0;
        studioEvaluations = 0;
        gradleEvaluations = 0;
        javaEvaluations = 0;
      });

      testUsingContext(
        'does not eagerly evaluate AndroidSdk, AndroidStudio, GradleUtils, or Java during bootstrap or generateCommands',
        () async {
          late final ToolDependencies capturedDependencies;
          final command = _DeviceManagerRecordingFlutterCommand();
          await runner.run(
            <String>[command.name],
            (ToolDependencies toolDependencies) {
              capturedDependencies = toolDependencies;
              return <FlutterCommand>[
                ...generateCommands(
                  toolDependencies: toolDependencies,
                  verbose: false,
                  verboseHelp: false,
                ),
                command,
              ];
            },
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            shutdownHooks: ShutdownHooks(),
          );

          expect(sdkEvaluations, 0);
          expect(studioEvaluations, 0);
          expect(gradleEvaluations, 0);
          expect(javaEvaluations, 0);

          expect(capturedDependencies.androidContext.androidSdk, isA<FakeAndroidSdk>());
          expect(sdkEvaluations, 1);
          expect(capturedDependencies.androidContext.androidStudio, isA<_FakeAndroidStudio>());
          expect(studioEvaluations, 1);
          expect(capturedDependencies.androidContext.gradleUtils, isA<FakeGradleUtils>());
          expect(gradleEvaluations, 1);
          expect(capturedDependencies.androidContext.java, isA<FakeJava>());
          expect(javaEvaluations, 1);
        },
        overrides: <Type, Generator>{
          AndroidSdk: () {
            sdkEvaluations++;
            return FakeAndroidSdk();
          },
          AndroidStudio: () {
            studioEvaluations++;
            return _FakeAndroidStudio();
          },
          DeviceManager: () => null,
          FileSystem: () => MemoryFileSystem.test(),
          GradleUtils: () {
            gradleEvaluations++;
            return FakeGradleUtils();
          },
          Java: () {
            javaEvaluations++;
            return FakeJava();
          },
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    });

    group('lazy Apple dependency evaluation', () {
      var cocoapodsValidatorEvaluations = 0;
      var iosSimulatorUtilsEvaluations = 0;
      var xcdeviceEvaluations = 0;

      setUp(() {
        cocoapodsValidatorEvaluations = 0;
        iosSimulatorUtilsEvaluations = 0;
        xcdeviceEvaluations = 0;
      });

      testUsingContext(
        'does not eagerly evaluate CocoaPodsValidator, IOSSimulatorUtils, or XCDevice during bootstrap or generateCommands',
        () async {
          late final ToolDependencies capturedDependencies;
          final command = _DeviceManagerRecordingFlutterCommand();
          await runner.run(
            <String>[command.name],
            (ToolDependencies toolDependencies) {
              capturedDependencies = toolDependencies;
              return <FlutterCommand>[
                ...generateCommands(
                  toolDependencies: toolDependencies,
                  verbose: false,
                  verboseHelp: false,
                ),
                command,
              ];
            },
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            shutdownHooks: ShutdownHooks(),
          );

          expect(cocoapodsValidatorEvaluations, 0);
          expect(iosSimulatorUtilsEvaluations, 0);
          expect(xcdeviceEvaluations, 0);

          expect(
            capturedDependencies.appleContext.cocoapodsValidator,
            isA<FakeCocoaPodsValidator>(),
          );
          expect(cocoapodsValidatorEvaluations, 1);
          expect(capturedDependencies.appleContext.iosSimulatorUtils, isA<FakeIOSSimulatorUtils>());
          expect(iosSimulatorUtilsEvaluations, 1);
          expect(capturedDependencies.appleContext.xcdevice, isA<FakeXCDevice>());
          expect(xcdeviceEvaluations, 1);
        },
        overrides: <Type, Generator>{
          CocoaPodsValidator: () {
            cocoapodsValidatorEvaluations++;
            return FakeCocoaPodsValidator();
          },
          DeviceManager: () => null,
          FileSystem: () => MemoryFileSystem.test(),
          IOSSimulatorUtils: () {
            iosSimulatorUtilsEvaluations++;
            return FakeIOSSimulatorUtils();
          },
          ProcessManager: () => FakeProcessManager.any(),
          XCDevice: () {
            xcdeviceEvaluations++;
            return FakeXCDevice();
          },
        },
      );
    });

    test('throws StateError when TemplateRenderer is neither passed nor overridden', () async {
      await expectLater(
        runner.run(
          <String>[],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
          overrides: <Type, Generator>{
            BotDetector: () => const FakeBotDetector(true),
            FileSystem: () => fs,
            ProcessManager: FakeProcessManager.any,
            Signals: FakeSignals.new,
            io.Stdio: FakeStdio.new,
          },
        ),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('TemplateRenderer'),
          ),
        ),
      );
    });

    test('Logger override achieves shared AnsiTerminal and OutputPreferences from bootstrap AppContext', () async {
      AnsiTerminal? loggerTerminal;
      OutputPreferences? loggerOutputPreferences;
      late final ToolDependencies capturedDependencies;
      late final _ContextRecordingFlutterCommand command;
      final int exitCode = await runner.run(
        <String>[_ContextRecordingFlutterCommand.commandName],
        (ToolDependencies toolDependencies) {
          capturedDependencies = toolDependencies;
          command = _ContextRecordingFlutterCommand(toolContext: toolDependencies.toolContext);
          return <FlutterCommand>[command];
        },
        flutterVersion: '[user-branch]/',
        shutdownHooks: ShutdownHooks(),
        templateRenderer: FakeTemplateRenderer(),
        overrides: <Type, Generator>{
          Analytics: () => const NoOpAnalytics(),
          BotDetector: () => const FakeBotDetector(true),
          Config: Config.test,
          DeviceManager: FakeDeviceManager.new,
          FileSystem: () => fs,
          FlutterVersion: FakeFlutterVersion.new,
          Logger: () {
            final AppContext loggerContext = context;
            loggerTerminal = loggerContext.get<AnsiTerminal>();
            loggerOutputPreferences = loggerContext.get<OutputPreferences>();
            return BufferLogger.test(
              terminal: loggerTerminal,
              outputPreferences: loggerOutputPreferences,
            );
          },
          PersistentToolState: () => PersistentToolState.test(
            directory: fs.systemTempDirectory,
            logger: BufferLogger.test(),
          ),
          Platform: () =>
              FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
          ProcessManager: FakeProcessManager.any,
          Signals: FakeSignals.new,
          io.Stdio: FakeStdio.new,
          XcodeProjectInterpreter: FakeXcodeProjectInterpreter.new,
        },
      );

      final ToolContext(
        :Logger logger,
        :OutputPreferences outputPreferences,
        :PreRunValidator preRunValidator,
        :AnsiTerminal terminal,
      ) = capturedDependencies.toolContext;
      expect((logger as BufferLogger).errorText, isEmpty);
      expect(exitCode, 0);
      expect(preRunValidator, isA<NoOpPreRunValidator>());
      expect(loggerTerminal, same(terminal));
      expect(loggerOutputPreferences, same(outputPreferences));
    });

    test('binds lazy AppleContext, AndroidContext, and workflows into inner AppContext', () async {
      var sdkEvaluations = 0;
      var xcdeviceEvaluations = 0;
      var xcodeEvaluations = 0;
      final fakeAndroidSdk = FakeAndroidSdk();
      final fakePlistParser = FakePlistParser();
      final fakeXCDevice = FakeXCDevice();
      final fakeXcode = FakeXcode();
      late final ToolDependencies capturedDependencies;
      late final _ContextRecordingFlutterCommand command;
      final int exitCode = await runner.run(
        <String>[_ContextRecordingFlutterCommand.commandName],
        (ToolDependencies toolDependencies) {
          capturedDependencies = toolDependencies;
          command = _ContextRecordingFlutterCommand(toolContext: toolDependencies.toolContext);
          return <FlutterCommand>[command];
        },
        flutterVersion: '[user-branch]/',
        shutdownHooks: ShutdownHooks(),
        templateRenderer: FakeTemplateRenderer(),
        overrides: <Type, Generator>{
          Analytics: () => const NoOpAnalytics(),
          AndroidSdk: () {
            sdkEvaluations++;
            return fakeAndroidSdk;
          },
          BotDetector: () => const FakeBotDetector(true),
          Config: Config.test,
          DeviceManager: FakeDeviceManager.new,
          FileSystem: () => fs,
          FlutterVersion: FakeFlutterVersion.new,
          Logger: BufferLogger.test,
          PersistentToolState: () => PersistentToolState.test(
            directory: fs.systemTempDirectory,
            logger: BufferLogger.test(),
          ),
          Platform: () =>
              FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
          PlistParser: () => fakePlistParser,
          ProcessManager: FakeProcessManager.any,
          Signals: FakeSignals.new,
          io.Stdio: FakeStdio.new,
          XCDevice: () {
            xcdeviceEvaluations++;
            return fakeXCDevice;
          },
          Xcode: () {
            xcodeEvaluations++;
            return fakeXcode;
          },
          XcodeProjectInterpreter: FakeXcodeProjectInterpreter.new,
        },
      );

      final Logger logger = capturedDependencies.toolContext.logger;
      expect((logger as BufferLogger).errorText, isEmpty);
      expect(exitCode, 0);
      expect(sdkEvaluations, 0);
      expect(xcdeviceEvaluations, 0);
      expect(command.androidWorkflowInstance, same(capturedDependencies.androidWorkflow));
      expect(command.macOSWorkflowInstance, same(capturedDependencies.macOSWorkflow));
      expect(command.windowsWorkflowInstance, same(capturedDependencies.windowsWorkflow));
      expect(command.resolveAndroidSdk(), same(fakeAndroidSdk));
      expect(sdkEvaluations, 1);
      expect(capturedDependencies.androidContext.androidSdk, same(fakeAndroidSdk));
      expect(sdkEvaluations, 1);
      expect(command.resolveXCDevice(), same(fakeXCDevice));
      expect(xcdeviceEvaluations, 1);
      expect(capturedDependencies.appleContext.xcdevice, same(fakeXCDevice));
      expect(xcdeviceEvaluations, 1);
      expect(command.resolveXcode(), same(fakeXcode));
      expect(capturedDependencies.appleContext.xcode, same(fakeXcode));
      expect(xcodeEvaluations, 1);
      expect(command.resolvePlistParser(), same(fakePlistParser));
    });

    test('applies FeatureFlags to AnsiTerminal and honors preRunValidatorBuilder', () async {
      late final ToolDependencies capturedDependencies;
      final int exitCode = await runner.run(
        <String>[_ContextRecordingFlutterCommand.commandName],
        (ToolDependencies toolDependencies) {
          capturedDependencies = toolDependencies;
          return <FlutterCommand>[
            _ContextRecordingFlutterCommand(toolContext: toolDependencies.toolContext),
          ];
        },
        flutterVersion: '[user-branch]/',
        preRunValidatorBuilder: PreRunValidator.new,
        shutdownHooks: ShutdownHooks(),
        templateRenderer: FakeTemplateRenderer(),
        overrides: <Type, Generator>{
          Analytics: () => const NoOpAnalytics(),
          BotDetector: () => const FakeBotDetector(true),
          Config: Config.test,
          DeviceManager: FakeDeviceManager.new,
          FeatureFlags: TestFeatureFlags.new,
          FileSystem: () => fs,
          FlutterVersion: FakeFlutterVersion.new,
          Logger: BufferLogger.test,
          PersistentToolState: () => PersistentToolState.test(
            directory: fs.systemTempDirectory,
            logger: BufferLogger.test(),
          ),
          Platform: () =>
              FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
          ProcessManager: FakeProcessManager.any,
          Signals: FakeSignals.new,
          io.Stdio: FakeStdio.new,
          XcodeProjectInterpreter: FakeXcodeProjectInterpreter.new,
        },
      );

      final ToolContext(:Logger logger, :AnsiTerminal terminal) = capturedDependencies.toolContext;
      expect(terminal.isCliAnimationEnabled, isTrue);
      expect(exitCode, 1);
      expect(
        (logger as BufferLogger).errorText,
        contains('Flutter SDK installation appears corrupted'),
      );
    });
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

        expect(fakeAnalytics.telemetryEnabled, true);

        await runner.run(
          <String>['--disable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
        );

        expect(fakeAnalytics.telemetryEnabled, false);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        // Don't inherit DASH__SUPPRESS_ANALYTICS from the test runner's
        // environment, which would block telemetry changes.
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      '--enable-analytics and --disable-analytics enables/disables telemetry',
      () async {
        setExitFunctionForTests((int exitCode) {});

        expect(fakeAnalytics.telemetryEnabled, true);

        await runner.run(
          <String>['--disable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(fakeAnalytics.telemetryEnabled, false);

        await runner.run(
          <String>['--enable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(fakeAnalytics.telemetryEnabled, true);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        // Don't inherit DASH__SUPPRESS_ANALYTICS from the test runner's
        // environment, which would block telemetry changes.
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      '--enable-analytics and --disable-analytics send an event when telemetry is enabled/disabled',
      () async {
        setExitFunctionForTests((int exitCode) {});
        await fakeAnalytics.setTelemetry(true);

        await runner.run(
          <String>['--disable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(fakeAnalytics.sentEvents, <Event>[Event.analyticsCollectionEnabled(status: false)]);

        fakeAnalytics.sentEvents.clear();
        expect(fakeAnalytics.telemetryEnabled, false);
        await runner.run(
          <String>['--enable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(fakeAnalytics.sentEvents, <Event>[Event.analyticsCollectionEnabled(status: true)]);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        // Don't inherit DASH__SUPPRESS_ANALYTICS from the test runner's
        // environment, which would block telemetry changes.
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      '--enable-analytics and --disable-analytics do not send an event when telemetry is already enabled/disabled',
      () async {
        setExitFunctionForTests((int exitCode) {});

        await fakeAnalytics.setTelemetry(false);
        await runner.run(
          <String>['--disable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(fakeAnalytics.sentEvents, isEmpty);

        await fakeAnalytics.setTelemetry(true);
        await runner.run(
          <String>['--enable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          shutdownHooks: ShutdownHooks(),
        );

        expect(fakeAnalytics.sentEvents, isEmpty);
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        // Don't inherit DASH__SUPPRESS_ANALYTICS from the test runner's
        // environment, which would block telemetry changes.
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'throw error when both flags passed',
      () async {
        setExitFunctionForTests((int exitCode) {});

        expect(fakeAnalytics.telemetryEnabled, true);

        final int exitCode = await runner.run(
          <String>['--disable-analytics', '--enable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          shutdownHooks: ShutdownHooks(),
        );

        expect(exitCode, 1, reason: 'Should return 1 due to conflicting options for telemetry');
        expect(
          fakeAnalytics.telemetryEnabled,
          true,
          reason: 'Should not have changed from initialization',
        );
      },
      overrides: <Type, Generator>{
        Analytics: () => fakeAnalytics,
        FileSystem: () => MemoryFileSystem.test(),
        // Don't inherit DASH__SUPPRESS_ANALYTICS from the test runner's
        // environment, which would block telemetry changes.
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    for (final enable in const <bool>[true, false]) {
      final flag = enable ? '--enable-analytics' : '--disable-analytics';
      testUsingContext(
        '$flag warns and does not change telemetry when DASH__SUPPRESS_ANALYTICS=true',
        () async {
          setExitFunctionForTests((int exitCode) {});
          await fakeAnalytics.setTelemetry(!enable);

          await runner.run(
            <String>[flag],
            (ToolDependencies toolDependencies) => <FlutterCommand>[],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            shutdownHooks: ShutdownHooks(),
          );

          expect(fakeAnalytics.telemetryEnabled, !enable);
          expect(fakeAnalytics.sentEvents, isEmpty);
          expect(testLogger.warningText, contains('DASH__SUPPRESS_ANALYTICS=true is set'));
          expect(testLogger.statusText, isNot(contains('Analytics reporting')));
        },
        overrides: <Type, Generator>{
          Analytics: () => fakeAnalytics,
          FileSystem: () => MemoryFileSystem.test(),
          Platform: () => FakePlatform(
            environment: <String, String>{DashEnvVar.suppressAnalytics.name: 'true'},
          ),
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    }
  });
}

class ArtifactsRecordingFlutterCommand extends FlutterCommand {
  ArtifactsRecordingFlutterCommand({ToolContext? toolContext})
    : super(toolContext: toolContext ?? const DelegatingToolContext());

  Artifacts? artifacts;
  bool ran = false;

  @override
  String get description => '';

  @override
  String get name => 'record';

  @override
  Future<FlutterCommandResult> runCommand() async {
    ran = true;
    artifacts = toolContext.artifacts;
    return FlutterCommandResult.success();
  }
}

class _DeviceManagerRecordingFlutterCommand extends FlutterCommand {
  _DeviceManagerRecordingFlutterCommand({ToolContext? toolContext})
    : super(toolContext: toolContext ?? const DelegatingToolContext());

  DeviceManager? deviceManager;

  @override
  String get description => '';

  @override
  String get name => 'record-device-manager';

  @override
  Future<FlutterCommandResult> runCommand() async {
    deviceManager = super.runner?.deviceManager;
    return FlutterCommandResult.success();
  }
}

class _ContextRecordingFlutterCommand extends FlutterCommand {
  _ContextRecordingFlutterCommand({required super.toolContext});

  static const commandName = 'record-context';

  AndroidWorkflow? androidWorkflowInstance;
  MacOSWorkflow? macOSWorkflowInstance;
  WindowsWorkflow? windowsWorkflowInstance;
  late AndroidSdk? Function() resolveAndroidSdk;
  late PlistParser Function() resolvePlistParser;
  late XCDevice? Function() resolveXCDevice;
  late Xcode? Function() resolveXcode;

  @override
  String get description => '';

  @override
  String get name => commandName;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final AppContext commandContext = context;
    androidWorkflowInstance = commandContext.get<AndroidWorkflow>();
    macOSWorkflowInstance = commandContext.get<MacOSWorkflow>();
    windowsWorkflowInstance = commandContext.get<WindowsWorkflow>();
    resolveAndroidSdk = () => commandContext.get<AndroidSdk>();
    resolvePlistParser = () => commandContext.get<PlistParser>()!;
    resolveXCDevice = () => commandContext.get<XCDevice>();
    resolveXcode = () => commandContext.get<Xcode>();
    return FlutterCommandResult.success();
  }
}

class CrashingFlutterCommand extends FlutterCommand {
  CrashingFlutterCommand({this._asyncCrash = false, this._completer, ToolContext? toolContext})
    : super(toolContext: toolContext ?? const DelegatingToolContext());

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
  MultipleExceptionCrashingFlutterCommand({ToolContext? toolContext})
    : super(toolContext: toolContext ?? const DelegatingToolContext());

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
  _GitNotFoundFlutterCommand({ToolContext? toolContext})
    : super(toolContext: toolContext ?? const DelegatingToolContext());

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

  @override
  io.ProcessResult runSync(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    covariant Object? stdoutEncoding = io.systemEncoding,
    covariant Object? stderrEncoding = io.systemEncoding,
  }) {
    return delegate.runSync(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );
  }
}

class FakeCache extends Fake implements Cache {
  FakeCache({required this._fs, required this._logger});

  final FileSystem _fs;
  final Logger _logger;

  @override
  String get flutterRoot => '/path/to/sdk/flutter';

  @override
  set flutterRoot(String? value) {}

  @override
  Future<void> lock() async {}

  @override
  void releaseLock() {}

  @override
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts, {bool offline = false}) async {
    _logger.startProgress('Downloading package Foo').stop();
  }

  @override
  Directory getArtifactDirectory(String name) => _fs.directory(name);

  @override
  MapEntry<String, String> get dyLdLibEntry =>
      const MapEntry<String, String>('DYLD_LIBRARY_PATH', 'fake_path');
}

class _FakeAndroidStudio extends Fake implements AndroidStudio {}

/// Answers `which` lookups like a host where the binary is not on PATH, and
/// delegates everything else to [FakeProcessManager.any].
class _NoWhichProcessManager extends Fake implements ProcessManager {
  final FakeProcessManager delegate = FakeProcessManager.any();

  @override
  bool canRun(Object? executable, {String? workingDirectory}) =>
      delegate.canRun(executable, workingDirectory: workingDirectory);

  @override
  io.ProcessResult runSync(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    covariant Object? stdoutEncoding = io.systemEncoding,
    covariant Object? stderrEncoding = io.systemEncoding,
  }) {
    if (command.first == 'which') {
      return io.ProcessResult(0, 1, '', '');
    }
    return delegate.runSync(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );
  }
}
