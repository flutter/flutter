// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/executable.dart';
import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/exit.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_device_manager.dart';
import 'package:flutter_tools/src/hook_runner.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/web/web_runner.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/testing.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_http_client.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

const kCustomBugInstructions = 'These are instructions to report with a custom bug tracker.';

Future<ToolDependencies> _bootstrapForTest({
  required FileSystem fs,
  Analytics? analytics,
  AndroidSdk? androidSdk,
  Artifacts? artifacts,
  BotDetector? botDetector,
  Cache? cache,
  CrashReporter? crashReporter,
  DeviceManager? deviceManager,
  bool enablePreRunValidator = false,
  FeatureFlags? featureFlags,
  FlutterHookRunner? flutterHookRunner,
  Logger? logger,
  OutputPreferences? outputPreferences,
  Platform? platform,
  PlistParser? plistParser,
  ProcessManager? processManager,
  ShutdownHooks? shutdownHooks,
  io.Stdio? stdio,
  AnsiTerminal? terminal,
  UserMessages? userMessages,
  WebRunnerFactory? webRunnerFactory,
  XCDevice? xcdevice,
  Xcode? xcode,
}) {
  final Platform resolvedPlatform =
      platform ?? FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'});
  final ProcessManager resolvedProcessManager = processManager ?? FakeProcessManager.any();
  final io.Stdio resolvedStdio = stdio ?? FakeStdio();
  final AnsiTerminal resolvedTerminal =
      terminal ?? AnsiTerminal(platform: resolvedPlatform, stdio: resolvedStdio);
  final OutputPreferences resolvedOutputPreferences = outputPreferences ?? OutputPreferences.test();
  final Logger resolvedLogger =
      logger ??
      BufferLogger(terminal: resolvedTerminal, outputPreferences: resolvedOutputPreferences);
  final Directory configDir = fs.systemTempDirectory.createTempSync('flutter_config_dir_test.');
  return ToolDependencies.bootstrap(
    analytics: analytics ?? const NoOpAnalytics(),
    androidSdk: androidSdk,
    artifacts: artifacts,
    botDetector: botDetector ?? const FakeBotDetector(true),
    cache: cache,
    config: Config.test(
      name: Config.kFlutterSettings,
      directory: configDir,
      logger: resolvedLogger,
    ),
    crashReporter: crashReporter ?? const NoopCrashReporter(),
    deviceManager: deviceManager,
    enablePreRunValidator: enablePreRunValidator,
    featureFlags: featureFlags,
    flutterHookRunner: flutterHookRunner,
    flutterVersion: FakeFlutterVersion(),
    fs: fs,
    httpClientFactory: FakeHttpClient.any,
    iosSimulatorUtils: const NoopIOSSimulatorUtils(),
    logger: resolvedLogger,
    outputPreferences: resolvedOutputPreferences,
    persistentToolState: PersistentToolState.test(directory: configDir, logger: resolvedLogger),
    platform: resolvedPlatform,
    plistParser: plistParser ?? FakePlistParser(),
    processManager: resolvedProcessManager,
    shutdownHooks: shutdownHooks,
    signals: FakeSignals(),
    stdio: resolvedStdio,
    templateRenderer: FakeTemplateRenderer(),
    terminal: resolvedTerminal,
    userMessages: userMessages ?? UserMessages(),
    webRunnerFactory: webRunnerFactory,
    xcdevice: xcdevice,
    xcode: xcode,
    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
  );
}

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

    test('error handling crash report (synchronous crash)', () async {
      final completer = Completer<void>();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        artifacts: Artifacts.test(),
        fs: fileSystem,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
      );
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(
        runZonedGuarded<Future<void>?>(
          () {
            unawaited(
              runner.run(
                <String>['crash'],
                (ToolDependencies toolDependencies) => <FlutterCommand>[
                  CrashingFlutterCommand(toolContext: toolDependencies.toolContext),
                ],
                // This flutterVersion disables crash reporting.
                flutterVersion: '[user-branch]/',
                reportCrashes: true,
                toolDependencies: toolDependencies,
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
    });

    test('error handling crash report (local engine)', () async {
      fileSystem
          .directory('engine')
          .childDirectory('src')
          .childDirectory('out')
          .createSync(recursive: true);

      final completer = Completer<void>();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        artifacts: Artifacts.test(),
        fs: fileSystem,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
      );
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
                (ToolDependencies toolDependencies) => <FlutterCommand>[
                  CrashingFlutterCommand(toolContext: toolDependencies.toolContext),
                ],
                // This flutterVersion disables crash reporting.
                flutterVersion: '[user-branch]/',
                reportCrashes: true,
                toolDependencies: toolDependencies,
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
    });

    // The artifacts commands are built with are chosen before the command line
    // is parsed, so they have to be rebuilt once a local engine is found.
    test('builds commands with the local engine the command line asks for', () async {
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
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        fs: fileSystem,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
      );
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
                  final command = ArtifactsRecordingFlutterCommand(
                    toolContext: toolDependencies.toolContext,
                  );
                  ranCommands.add(command);
                  return <FlutterCommand>[command];
                },
                flutterVersion: '[user-branch]/',
                toolDependencies: toolDependencies,
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
    });

    test('error handling crash report (bot)', () async {
      final completer = Completer<void>();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        artifacts: Artifacts.test(),
        botDetector: const FakeBotDetector(true),
        fs: fileSystem,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        stdio: fakeStdio,
      );
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(
        runZonedGuarded<Future<void>?>(
          () {
            unawaited(
              runner.run(
                <String>['crash'],
                (ToolDependencies toolDependencies) => <FlutterCommand>[
                  CrashingFlutterCommand(toolContext: toolDependencies.toolContext),
                ],
                // This flutterVersion disables crash reporting.
                flutterVersion: '[user-branch]/',
                toolDependencies: toolDependencies,
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
    });

    // This Completer completes when CrashingFlutterCommand.runCommand
    // completes, but ideally we'd want it to complete when execution resumes
    // runner.run. Currently the distinction does not matter, but if it ever
    // does, this test might fail to catch a regression of
    // https://github.com/flutter/flutter/issues/56406.
    final commandCompleter = Completer<void>();
    test('error handling crash report (asynchronous crash)', () async {
      final completer = Completer<void>();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        artifacts: Artifacts.test(),
        crashReporter: WaitingCrashReporter(commandCompleter.future),
        fs: fileSystem,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
      );
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(
        runZonedGuarded<Future<void>?>(
          () {
            unawaited(
              runner.run(
                <String>['crash'],
                (ToolDependencies toolDependencies) => <FlutterCommand>[
                  CrashingFlutterCommand(
                    asyncCrash: true,
                    completer: commandCompleter,
                    toolContext: toolDependencies.toolContext,
                  ),
                ],
                // This flutterVersion disables crash reporting.
                flutterVersion: '[user-branch]/',
                reportCrashes: true,
                toolDependencies: toolDependencies,
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
    });

    test("doesn't send multiple events for additional asynchronous exceptions "
        'thrown during shutdown', () async {
      // Regression test for https://github.com/flutter/flutter/issues/178318.
      var exceptionCount = 0;
      final exitCompleter = Completer<void>();
      final crashReportComplete = Completer<void>();
      final crashReporter = WaitingCrashReporter(crashReportComplete.future);
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        artifacts: Artifacts.test(),
        crashReporter: crashReporter,
        deviceManager: FakeDeviceManager(),
        fs: fileSystem,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
      );
      final command = MultipleExceptionCrashingFlutterCommand(
        toolContext: toolDependencies.toolContext,
      );
      unawaited(
        runZonedGuarded<Future<void>?>(
          () {
            unawaited(
              runner.run(
                <String>['crash'],
                (ToolDependencies _) => <FlutterCommand>[command],
                // This flutterVersion disables crash reporting.
                flutterVersion: '[user-branch]/',
                reportCrashes: true,
                toolDependencies: toolDependencies,
              ),
            );
            return null;
          },
          (Object error, StackTrace stack) {
            // Keep track of the number of exceptions thrown to ensure that
            // the count matches the number of exceptions we expect.
            exceptionCount++;
            if (!exitCompleter.isCompleted) {
              exitCompleter.complete();
            }
          },
        ),
      );
      await command.doneThrowing;
      crashReportComplete.complete();
      await exitCompleter.future;
      // Flush remaining microtask continuations from the shared crash-handling future.
      await Future<void>(() {});

      // This is the main check of this test.
      //
      // We are checking that, even though multiple asynchronous errors were
      // thrown, only a single crash report is sent. This ensures that a
      // single process crash can't result in multiple crash events.

      // This test only makes sense if we've thrown more than one exception.
      expect(firstExitCode, 1);
      expect(crashReporter._details.error.toString(), 'Exception: ERROR: 1');
      expect(exceptionCount, greaterThan(1));
      expect(exceptionCount, command.exceptionCount);

      // Ensure only a single exception analytics event was sent.
      final List<Event> exceptionEvents = fakeAnalytics.sentEvents
          .where((e) => e.eventName == DashEvent.exception)
          .toList();
      expect(exceptionEvents, hasLength(1));
    });

    test('create local report', () async {
      // Since crash reporting calls the doctor, which checks for the devtools
      // version file in the cache, write a version file to the memory fs.
      final Directory devtoolsDir = fileSystem.directory(
        '/path/to/flutter/bin/cache/dart-sdk/bin/resources/devtools',
      )..createSync(recursive: true);
      devtoolsDir.childFile('version.json').writeAsStringSync('{"version": "1.2.3"}');

      final completer = Completer<void>();
      final crashReporter = WaitingCrashReporter(Future<void>.value());
      final logger = BufferLogger.test();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        artifacts: Artifacts.test(),
        cache: Cache.test(
          rootOverride: fileSystem.directory('/path/to/flutter'),
          flutterRoot: '/path/to/flutter',
          fileSystem: fileSystem,
          processManager: FakeProcessManager.any(),
        ),
        crashReporter: crashReporter,
        fs: fileSystem,
        logger: logger,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ANALYTICS_LOG_FILE': 'test', 'FLUTTER_ROOT': '/'},
        ),
        processManager: _NoWhichProcessManager(),
        userMessages: CustomBugInstructions(),
      );
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(
        runZonedGuarded<Future<void>?>(
          () {
            unawaited(
              runner.run(
                <String>['crash'],
                (ToolDependencies toolDependencies) => <FlutterCommand>[
                  CrashingFlutterCommand(toolContext: toolDependencies.toolContext),
                ],
                // This flutterVersion disables crash reporting.
                flutterVersion: '[user-branch]/',
                reportCrashes: true,
                toolDependencies: toolDependencies,
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

      final String errorText = logger.errorText;
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
    });

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

      test('create local report in temporary directory', () async {
        // Since crash reporting calls the doctor, which checks for the devtools
        // version file in the cache, write a version file to the memory fs.
        final Directory devtoolsDir = fileSystem.directory(
          '/path/to/flutter/bin/cache/dart-sdk/bin/resources/devtools',
        )..createSync(recursive: true);
        devtoolsDir.childFile('version.json').writeAsStringSync('{"version": "1.2.3"}');

        final completer = Completer<void>();
        final crashReporter = WaitingCrashReporter(Future<void>.value());
        final logger = BufferLogger.test();
        final ToolDependencies toolDependencies = await _bootstrapForTest(
          artifacts: Artifacts.test(),
          cache: Cache.test(
            rootOverride: fileSystem.directory('/path/to/flutter'),
            flutterRoot: '/path/to/flutter',
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
          ),
          crashReporter: crashReporter,
          fs: fileSystem,
          logger: logger,
          platform: FakePlatform(
            environment: <String, String>{
              'FLUTTER_ANALYTICS_LOG_FILE': 'test',
              'FLUTTER_ROOT': '/',
            },
          ),
          processManager: _NoWhichProcessManager(),
          userMessages: CustomBugInstructions(),
        );
        // runner.run() asynchronously calls the exit function set above, so we
        // catch it in a zone.
        unawaited(
          runZonedGuarded<Future<void>?>(
            () {
              unawaited(
                runner.run(
                  <String>['crash'],
                  (ToolDependencies toolDependencies) => <FlutterCommand>[
                    CrashingFlutterCommand(toolContext: toolDependencies.toolContext),
                  ],
                  // This flutterVersion disables crash reporting.
                  flutterVersion: '[user-branch]/',
                  reportCrashes: true,
                  toolDependencies: toolDependencies,
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

        final String errorText = logger.errorText;
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
      });
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

    test("catches ProcessException calling git because it's not available", () async {
      final logger = BufferLogger.test();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        artifacts: Artifacts.test(),
        fs: fs,
        logger: logger,
        processManager: FakeProcessManager.any()..excludedExecutables.add('git'),
      );
      await runner.run(
        <String>[_GitNotFoundFlutterCommand.commandName],
        (ToolDependencies toolDependencies) => <FlutterCommand>[
          _GitNotFoundFlutterCommand(toolContext: toolDependencies.toolContext),
        ],
        // This flutterVersion disables crash reporting.
        flutterVersion: '[user-branch]/',
        reportCrashes: false,
        toolDependencies: toolDependencies,
      );

      expect(
        logger.errorText,
        'Failed to find "git" in the search path.\n'
        '\n'
        'An error was encountered when trying to run git.\n'
        "Please ensure git is installed and available in your system's search path. "
        'See https://docs.flutter.dev/get-started for instructions on installing git for your platform.\n',
      );
    });

    test('handles ProcessException calling git when ProcessManager.canRun fails', () async {
      final logger = BufferLogger.test();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        artifacts: Artifacts.test(),
        fs: fs,
        logger: logger,
        processManager: _ErrorOnCanRunFakeProcessManager(),
      );
      await runner.run(
        <String>[_GitNotFoundFlutterCommand.commandName],
        (ToolDependencies toolDependencies) => <FlutterCommand>[
          _GitNotFoundFlutterCommand(toolContext: toolDependencies.toolContext),
        ],
        // This flutterVersion disables crash reporting.
        flutterVersion: '[user-branch]/',
        reportCrashes: false,
        toolDependencies: toolDependencies,
      );

      expect(
        logger.errorText,
        'Failed to find "git" in the search path.\n'
        '\n'
        'An error was encountered when trying to run git.\n'
        "Please ensure git is installed and available in your system's search path. "
        'See https://docs.flutter.dev/get-started for instructions on installing git for your platform.\n',
      );
    });

    test('do not print welcome on bots', () async {
      final logger = BufferLogger.test();
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        botDetector: const FakeBotDetector(true),
        fs: fs,
        logger: logger,
      );
      await runner.run(
        <String>['--version', '--machine'],
        (ToolDependencies toolDependencies) => <FlutterCommand>[],
        // This flutterVersion disables crash reporting.
        flutterVersion: '[user-branch]/',
        toolDependencies: toolDependencies,
      );

      expect(logger.traceText, isNot(contains('Showed analytics consent message.')));
    });

    test('do not print download messages when --machine is provided', () async {
      // Regression test for https://github.com/flutter/flutter/issues/154119.
      final stdio = FakeStdio();
      final platform = FakePlatform(
        environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'},
      );
      final terminal = AnsiTerminal(stdio: stdio, platform: platform);
      final outputPreferences = OutputPreferences.test();
      final loggerFactory = LoggerFactory(
        outputPreferences: outputPreferences,
        terminal: terminal,
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
        windows: platform.isWindows,
      );
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        botDetector: const FakeBotDetector(true),
        cache: FakeCache(fs: fs, logger: logger),
        fs: fs,
        logger: logger,
        outputPreferences: outputPreferences,
        platform: platform,
        stdio: stdio,
        terminal: terminal,
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
        toolDependencies: toolDependencies,
      );
      expect(stdio.writtenToStdout.join(), isNot(contains('Downloading')));
      expect(stdio.writtenToStderr.join(), isNot(contains('Downloading')));
    });

    test('binds bootstrapped DeviceManager into runner for command execution', () async {
      late final _DeviceManagerRecordingFlutterCommand command;
      final ToolDependencies toolDependencies = await _bootstrapForTest(fs: fs);
      await runner.run(
        <String>[_DeviceManagerRecordingFlutterCommand.commandName],
        (ToolDependencies toolDependencies) {
          command = _DeviceManagerRecordingFlutterCommand(
            toolContext: toolDependencies.toolContext,
          );
          return <FlutterCommand>[command];
        },
        // This flutterVersion disables crash reporting.
        flutterVersion: '[user-branch]/',
        toolDependencies: toolDependencies,
      );

      expect(toolDependencies.deviceManager, isA<FlutterDeviceManager>());
      expect(command.deviceManager, same(toolDependencies.deviceManager));
    });

    test('does not eagerly evaluate AndroidSdk, AndroidStudio, or Java during bootstrap or generateCommands', () async {
      fs.directory('/sdk/packages/flutter_tools').createSync(recursive: true);
      fs.directory('/opt/android-studio/jbr/bin').createSync(recursive: true);
      final strictProcessManager = FakeProcessManager.empty();
      late final _DeviceManagerRecordingFlutterCommand command;
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        fs: fs,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/home/user'},
        ),
        processManager: strictProcessManager,
      );
      final int exitCode = await runner.run(
        <String>[_DeviceManagerRecordingFlutterCommand.commandName],
        (ToolDependencies toolDependencies) {
          command = _DeviceManagerRecordingFlutterCommand(
            toolContext: toolDependencies.toolContext,
          );
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
        toolDependencies: toolDependencies,
      );

      expect(exitCode, 0);
      expect(strictProcessManager, hasNoRemainingExpectations);

      // Creating the SDK directory after runner.run proves AndroidSdk was not
      // evaluated during bootstrap, generateCommands, or runner.run (otherwise
      // locateAndroidSdk would have run `which -a aapt` on strictProcessManager).
      fs.directory('/home/user/Android/Sdk/licenses').createSync(recursive: true);
      strictProcessManager.addCommand(
        const FakeCommand(
          command: <String>['/opt/android-studio/jbr/bin/java', '-version'],
          stderr: 'openjdk version "17.0.8"\nOpenJDK Runtime Environment',
        ),
      );

      expect(toolDependencies.androidContext.androidSdk, isNotNull);
      expect(toolDependencies.androidContext.java?.javaHome, '/opt/android-studio/jbr');
      expect(toolDependencies.androidContext.androidStudio?.directory, '/opt/android-studio');
      expect(strictProcessManager, hasNoRemainingExpectations);
    });

    test('does not eagerly evaluate XCDevice during bootstrap or generateCommands', () async {
      final shutdownHooks = ShutdownHooks();
      late final _DeviceManagerRecordingFlutterCommand command;
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        fs: fs,
        shutdownHooks: shutdownHooks,
      );
      final int hooksAfterBootstrap = shutdownHooks.registeredHooks.length;
      final int exitCode = await runner.run(
        <String>[_DeviceManagerRecordingFlutterCommand.commandName],
        (ToolDependencies toolDependencies) {
          command = _DeviceManagerRecordingFlutterCommand(
            toolContext: toolDependencies.toolContext,
          );
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
        toolDependencies: toolDependencies,
      );

      expect(exitCode, 0);
      expect(shutdownHooks.registeredHooks, hasLength(hooksAfterBootstrap));

      final XCDevice xcdevice = toolDependencies.appleContext.xcdevice;
      expect(shutdownHooks.registeredHooks, hasLength(hooksAfterBootstrap + 1));
      expect(toolDependencies.appleContext.xcdevice, same(xcdevice));
      expect(shutdownHooks.registeredHooks, hasLength(hooksAfterBootstrap + 1));
    });

    test('applies FeatureFlags to AnsiTerminal and honors enablePreRunValidator', () async {
      final ToolDependencies toolDependencies = await _bootstrapForTest(
        deviceManager: FakeDeviceManager(),
        enablePreRunValidator: true,
        featureFlags: TestFeatureFlags(),
        fs: fs,
      );
      final int exitCode = await runner.run(
        <String>[_DeviceManagerRecordingFlutterCommand.commandName],
        (ToolDependencies toolDependencies) => <FlutterCommand>[
          _DeviceManagerRecordingFlutterCommand(toolContext: toolDependencies.toolContext),
        ],
        flutterVersion: '[user-branch]/',
        toolDependencies: toolDependencies,
      );

      final ToolContext(:Logger logger, :AnsiTerminal terminal) = toolDependencies.toolContext;
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

    test('runner disable telemetry with flag', () async {
      setExitFunctionForTests((int exitCode) {});

      expect(fakeAnalytics.telemetryEnabled, true);

      final ToolDependencies toolDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        fs: fs,
        // Don't inherit DASH__SUPPRESS_ANALYTICS from the test runner's
        // environment, which would block telemetry changes.
        platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
      );
      await runner.run(
        <String>['--disable-analytics'],
        (ToolDependencies toolDependencies) => <FlutterCommand>[],
        // This flutterVersion disables crash reporting.
        flutterVersion: '[user-branch]/',
        toolDependencies: toolDependencies,
      );

      expect(fakeAnalytics.telemetryEnabled, false);
    });

    test('--enable-analytics and --disable-analytics enables/disables telemetry', () async {
      setExitFunctionForTests((int exitCode) {});

      expect(fakeAnalytics.telemetryEnabled, true);

      final ToolDependencies firstDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        fs: fs,
        platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
      );
      await runner.run(
        <String>['--disable-analytics'],
        (ToolDependencies toolDependencies) => <FlutterCommand>[],
        toolDependencies: firstDependencies,
      );

      expect(fakeAnalytics.telemetryEnabled, false);

      final ToolDependencies secondDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        fs: fs,
        platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
      );
      await runner.run(
        <String>['--enable-analytics'],
        (ToolDependencies toolDependencies) => <FlutterCommand>[],
        toolDependencies: secondDependencies,
      );

      expect(fakeAnalytics.telemetryEnabled, true);
    });

    test(
      '--enable-analytics and --disable-analytics send an event when telemetry is enabled/disabled',
      () async {
        setExitFunctionForTests((int exitCode) {});
        await fakeAnalytics.setTelemetry(true);

        final ToolDependencies firstDependencies = await _bootstrapForTest(
          analytics: fakeAnalytics,
          fs: fs,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'},
          ),
        );
        await runner.run(
          <String>['--disable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          toolDependencies: firstDependencies,
        );

        expect(fakeAnalytics.sentEvents, <Event>[Event.analyticsCollectionEnabled(status: false)]);

        fakeAnalytics.sentEvents.clear();
        expect(fakeAnalytics.telemetryEnabled, false);
        final ToolDependencies secondDependencies = await _bootstrapForTest(
          analytics: fakeAnalytics,
          fs: fs,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'},
          ),
        );
        await runner.run(
          <String>['--enable-analytics'],
          (ToolDependencies toolDependencies) => <FlutterCommand>[],
          toolDependencies: secondDependencies,
        );

        expect(fakeAnalytics.sentEvents, <Event>[Event.analyticsCollectionEnabled(status: true)]);
      },
    );

    test('--enable-analytics and --disable-analytics do not send an event when telemetry is already enabled/disabled', () async {
      setExitFunctionForTests((int exitCode) {});

      await fakeAnalytics.setTelemetry(false);
      final ToolDependencies firstDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        fs: fs,
        platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
      );
      await runner.run(
        <String>['--disable-analytics'],
        (ToolDependencies toolDependencies) => <FlutterCommand>[],
        toolDependencies: firstDependencies,
      );

      expect(fakeAnalytics.sentEvents, isEmpty);

      await fakeAnalytics.setTelemetry(true);
      final ToolDependencies secondDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        fs: fs,
        platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
      );
      await runner.run(
        <String>['--enable-analytics'],
        (ToolDependencies toolDependencies) => <FlutterCommand>[],
        toolDependencies: secondDependencies,
      );

      expect(fakeAnalytics.sentEvents, isEmpty);
    });

    test('throw error when both flags passed', () async {
      setExitFunctionForTests((int exitCode) {});

      expect(fakeAnalytics.telemetryEnabled, true);

      final ToolDependencies toolDependencies = await _bootstrapForTest(
        analytics: fakeAnalytics,
        fs: fs,
        platform: FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/sdk', 'HOME': '/'}),
      );
      final int exitCode = await runner.run(
        <String>['--disable-analytics', '--enable-analytics'],
        (ToolDependencies toolDependencies) => <FlutterCommand>[],
        // This flutterVersion disables crash reporting.
        flutterVersion: '[user-branch]/',
        toolDependencies: toolDependencies,
      );

      expect(exitCode, 1, reason: 'Should return 1 due to conflicting options for telemetry');
      expect(
        fakeAnalytics.telemetryEnabled,
        true,
        reason: 'Should not have changed from initialization',
      );
    });

    for (final enable in const <bool>[true, false]) {
      final flag = enable ? '--enable-analytics' : '--disable-analytics';
      test(
        '$flag warns and does not change telemetry when DASH__SUPPRESS_ANALYTICS=true',
        () async {
          setExitFunctionForTests((int exitCode) {});
          await fakeAnalytics.setTelemetry(!enable);

          final logger = BufferLogger.test();
          final ToolDependencies toolDependencies = await _bootstrapForTest(
            analytics: fakeAnalytics,
            fs: fs,
            logger: logger,
            platform: FakePlatform(
              environment: <String, String>{
                'FLUTTER_ROOT': '/sdk',
                'HOME': '/',
                DashEnvVar.suppressAnalytics.name: 'true',
              },
            ),
          );
          await runner.run(
            <String>[flag],
            (ToolDependencies toolDependencies) => <FlutterCommand>[],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            toolDependencies: toolDependencies,
          );

          expect(fakeAnalytics.telemetryEnabled, !enable);
          expect(fakeAnalytics.sentEvents, isEmpty);
          expect(logger.warningText, contains('DASH__SUPPRESS_ANALYTICS=true is set'));
          expect(logger.statusText, isNot(contains('Analytics reporting')));
        },
      );
    }
  });
}

class ArtifactsRecordingFlutterCommand extends FlutterCommand {
  ArtifactsRecordingFlutterCommand({required super.toolContext});

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
  _DeviceManagerRecordingFlutterCommand({required super.toolContext});

  static const commandName = 'record-device-manager';

  DeviceManager? deviceManager;

  @override
  String get description => '';

  @override
  String get name => commandName;

  @override
  Future<FlutterCommandResult> runCommand() async {
    deviceManager = super.runner?.deviceManager;
    return FlutterCommandResult.success();
  }
}

class CrashingFlutterCommand extends FlutterCommand {
  CrashingFlutterCommand({required super.toolContext, this._asyncCrash = false, this._completer});

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
  MultipleExceptionCrashingFlutterCommand({required super.toolContext});

  static const _targetExceptionCount = 5;

  final _completer = Completer<void>();

  @override
  String get description => '';

  @override
  String get name => 'crash';

  Future<void> get doneThrowing => _completer.future;

  int exceptionCount = 0;

  @override
  Future<FlutterCommandResult> runCommand() async {
    void throwNext() {
      if (exceptionCount < _targetExceptionCount) {
        exceptionCount++;
        Timer.run(throwNext);
        throw Exception('ERROR: $exceptionCount');
      }
      _completer.complete();
    }

    Timer.run(throwNext);
    await _completer.future;
    return FlutterCommandResult.success();
  }
}

class _GitNotFoundFlutterCommand extends FlutterCommand {
  _GitNotFoundFlutterCommand({required super.toolContext});

  static const commandName = 'git-not-found';

  @override
  String get description => '';

  @override
  String get name => commandName;

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
  WaitingCrashReporter(this._future);

  final Future<void> _future;
  late CrashDetails _details;

  @override
  Future<void> informUser(CrashDetails details, File crashFile) {
    _details = details;
    return _future;
  }
}

class _ErrorOnCanRunFakeProcessManager extends Fake implements ProcessManager {
  final delegate = FakeProcessManager.any();
  @override
  bool canRun(Object? executable, {String? workingDirectory}) {
    if (executable == 'git') {
      throw Exception("oh no, we couldn't check for git!");
    }
    return delegate.canRun(executable, workingDirectory: workingDirectory);
  }

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
