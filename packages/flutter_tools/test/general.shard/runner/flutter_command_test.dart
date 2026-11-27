// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/exit.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/build_targets.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/run.dart' show RunCommand;
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/pre_run_validator.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/web/devfs_config.dart' show WebDevServerConfig;
import 'package:flutter_tools/src/web/web_options.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/testing.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_devices.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';
import 'utils.dart';

void main() {
  group('Flutter Command', () {
    late FakeCache cache;
    late FakeAnalytics fakeAnalytics;
    late FakeClock clock;
    late FakeProcessInfo processInfo;
    late MemoryFileSystem fileSystem;
    late Platform platform;
    late FileSystemUtils fileSystemUtils;
    late BufferLogger logger;
    late FakeProcessManager processManager;
    late PreRunValidator preRunValidator;
    late FakeLockTrackingCache lockTrackingCache;
    late FakeLockCheckingPub lockCheckingPub;

    setUp(() {
      Cache.disableLocking();
      cache = FakeCache();
      clock = FakeClock();
      processInfo = FakeProcessInfo();
      processInfo.maxRss = 10;
      fileSystem = MemoryFileSystem.test();
      platform = FakePlatform();
      fileSystemUtils = FileSystemUtils(fileSystem: fileSystem, platform: platform);
      logger = BufferLogger.test();
      processManager = FakeProcessManager.empty();
      preRunValidator = PreRunValidator(fileSystem: fileSystem, cache: cache);
      lockTrackingCache = FakeLockTrackingCache();
      lockCheckingPub = FakeLockCheckingPub(lockTrackingCache);
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    tearDown(() {
      Cache.enableLocking();
    });

    ToolContext createToolContext({
      Cache? cacheOverride,
      FileSystem? fsOverride,
      FlutterVersion? flutterVersion,
      Logger? loggerOverride,
      OperatingSystemUtils? os,
      PreRunValidator? preRunValidatorOverride,
      ProcessManager? processManagerOverride,
      Signals? signals,
      SystemClock? systemClock,
      AnsiTerminal? terminal,
    }) {
      return FakeToolContext(
        cache: cacheOverride,
        fileSystemUtils: fsOverride == null ? fileSystemUtils : null,
        flutterVersion: flutterVersion,
        fs: fsOverride ?? fileSystem,
        logger: loggerOverride ?? logger,
        os: os,
        platform: platform,
        preRunValidator: preRunValidatorOverride,
        processInfo: processInfo,
        processManager: processManagerOverride ?? processManager,
        signals: signals,
        systemClock: systemClock,
        terminal: terminal,
      );
    }

    test('help text contains global options', () {
      final fake = FakeDeprecatedCommand(toolContext: createToolContext());
      createTestCommandRunner(fake);
      expect(fake.usage, contains('Global options:\n'));
    });

    test('honors shouldUpdateCache false', () async {
      final flutterCommand = DummyFlutterCommand(
        toolContext: createToolContext(cacheOverride: cache),
      );
      await flutterCommand.run();

      expect(cache.artifacts, isEmpty);
      expect(flutterCommand.deprecated, isFalse);
      expect(flutterCommand.hidden, isFalse);
    });

    test('honors shouldUpdateCache true', () async {
      final flutterCommand = DummyFlutterCommand(
        shouldUpdateCache: true,
        toolContext: createToolContext(cacheOverride: cache),
      );
      await flutterCommand.run();
      // First call for universal, second for the rest
      expect(cache.artifacts, <Set<DevelopmentArtifact>>[
        <DevelopmentArtifact>{DevelopmentArtifact.universal},
        <DevelopmentArtifact>{},
      ]);
    });

    test('cache lock is held during pub get', () async {
      final ToolContext toolContext = createToolContext(cacheOverride: lockTrackingCache);
      final flutterCommand = DummyFlutterCommandWithPub(toolContext: toolContext);
      final runner = TestFlutterCommandRunner(pub: lockCheckingPub, toolContext: toolContext)
        ..addCommand(flutterCommand);
      await runner.run(<String>['dummypub']);

      expect(lockCheckingPub.pubGetCalled, isTrue);
      expect(
        lockCheckingPub.lockWasHeldDuringPubGet,
        isTrue,
        reason:
            'The cache lock should still be held when pub.get() is called '
            'during verifyThenRunCommand, to prevent parallel flutter '
            'commands from racing on pub state.',
      );
    });

    test("throws toolExit if flutter_tools source dir doesn't exist", () async {
      final flutterCommand = DummyFlutterCommand(
        toolContext: createToolContext(
          cacheOverride: cache,
          preRunValidatorOverride: preRunValidator,
        ),
      );
      await expectToolExitLater(
        flutterCommand.run(),
        contains('Flutter SDK installation appears corrupted'),
      );
    });

    test('deprecated command should warn', () async {
      final flutterCommand = FakeDeprecatedCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['deprecated']);

      expect(
        logger.warningText,
        contains(
          'The "deprecated" command is deprecated and will be removed in '
          'a future version of Flutter.',
        ),
      );
      expect(
        flutterCommand.usage,
        contains(
          'Deprecated. This command will be removed in a future version '
          'of Flutter.',
        ),
      );
      expect(flutterCommand.deprecated, isTrue);
      expect(flutterCommand.hidden, isTrue);
    });

    test('does not print Intel Mac warning on macOS ARM64', () async {
      final flutterCommand = DummyFlutterCommand(
        toolContext: createToolContext(os: FakeOperatingSystemUtils(hostPlatform: .darwin_arm64)),
      );
      await flutterCommand.run();

      expect(logger.warningText, isEmpty);
    });

    test('prints Intel Mac warning on macOS X64 on every command', () async {
      final flutterCommand = DummyFlutterCommand(
        toolContext: createToolContext(os: FakeOperatingSystemUtils(hostPlatform: .darwin_x64)),
      );

      await flutterCommand.run();

      expect(logger.warningText, contains('Flutter is deprecating support for Intel-based Macs.'));

      // Run the command again, the warning is printed every time.
      await flutterCommand.run();

      // BufferLogger.clear() does not clear warnings, so the second run appends
      // another copy of the warning.
      expect(
        'Flutter is deprecating support for Intel-based Macs.'
            .allMatches(logger.warningText)
            .length,
        2,
      );
    });

    test('Intel Mac warning on macOS X64 is not fatal', () async {
      final flutterCommand = DummyFlutterCommand(
        toolContext: createToolContext(os: FakeOperatingSystemUtils(hostPlatform: .darwin_x64)),
      );
      logger.fatalWarnings = true;

      await flutterCommand.run();

      expect(logger.warningText, contains('Flutter is deprecating support for Intel-based Macs.'));
      expect(logger.hadWarningOutput, isFalse);
      expect(logger.checkForFatalLogs, returnsNormally);
    });

    test('Intel Mac warning on macOS X64 is not fatal in verbose mode', () async {
      final verboseLogger = VerboseLogger(logger);
      final flutterCommand = DummyFlutterCommand(
        toolContext: createToolContext(
          loggerOverride: verboseLogger,
          os: FakeOperatingSystemUtils(hostPlatform: .darwin_x64),
        ),
      );
      verboseLogger.fatalWarnings = true;

      await flutterCommand.run();

      expect(logger.warningText, contains('Flutter is deprecating support for Intel-based Macs.'));
      expect(verboseLogger.hadWarningOutput, isFalse);
      expect(verboseLogger.checkForFatalLogs, returnsNormally);
    });

    test('prints warning when enable-impeller flag is used with release build', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext())
        ..registerOptionBundle(const BuildModeOptionsBundle())
        ..argParser.addDescriptor(DebuggingOptionDescriptors.enableImpeller);

      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy', '--release', '--enable-impeller']);

      expect(
        logger.warningText,
        contains('The "--enable-impeller" flag is ignored in release builds'),
      );
    });

    test('prints warning when no-enable-impeller flag is used with release build', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext())
        ..registerOptionBundle(const BuildModeOptionsBundle())
        ..argParser.addDescriptor(DebuggingOptionDescriptors.enableImpeller);

      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy', '--release', '--no-enable-impeller']);

      expect(
        logger.warningText,
        contains('The "--no-enable-impeller" flag is ignored in release builds'),
      );
    });

    test('does not print warning when enable-impeller flag is used with debug build', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext())
        ..registerOptionBundle(const BuildModeOptionsBundle())
        ..argParser.addDescriptor(DebuggingOptionDescriptors.enableImpeller);

      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy', '--debug', '--enable-impeller']);

      expect(logger.warningText, isEmpty);
    });

    test('does not print warning when no impeller flags are used with release build', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext())
        ..registerOptionBundle(const BuildModeOptionsBundle())
        ..argParser.addDescriptor(DebuggingOptionDescriptors.enableImpeller);

      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy', '--release']);

      expect(logger.warningText, isEmpty);
    });

    test('does not fail or warn on command without build mode flags', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext());

      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy']);

      expect(logger.warningText, isEmpty);
    });

    test('uses the error handling file system', () async {
      final ToolDependencies toolDependencies = await ToolDependencies.bootstrap(
        analytics: fakeAnalytics,
        cache: cache,
        flutterVersion: FakeFlutterVersion(),
        fs: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
        templateRenderer: const MustacheTemplateRenderer(),
      );
      late final DummyFlutterCommand flutterCommand;
      flutterCommand = DummyFlutterCommand(
        toolContext: toolDependencies.toolContext,
        commandFunction: () async {
          expect(flutterCommand.toolContext.fs, isA<ErrorHandlingFileSystem>());
          return const FlutterCommandResult(ExitStatus.success);
        },
      );
      await flutterCommand.run();
    });

    test('finds the target file with default values', () async {
      fileSystem.file('lib/main.dart').createSync(recursive: true);
      final fakeTargetCommand = FakeTargetCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);
      await runner.run(<String>['test']);

      expect(fakeTargetCommand.cachedTargetFile, 'lib/main.dart');
    });

    test('finds the target file with specified value', () async {
      fileSystem.file('lib/foo.dart').createSync(recursive: true);
      final fakeTargetCommand = FakeTargetCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);
      await runner.run(<String>['test', '-t', 'lib/foo.dart']);

      expect(fakeTargetCommand.cachedTargetFile, 'lib/foo.dart');
    });

    test('throws tool exit if specified file does not exist', () async {
      final fakeTargetCommand = FakeTargetCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);

      expect(() async => runner.run(<String>['test', '-t', 'lib/foo.dart']), throwsToolExit());
    });

    test('reports command that results in success', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final ToolContext toolContext = createToolContext(systemClock: clock);
      final flutterCommand = DummyFlutterCommand(
        toolContext: toolContext,
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.success);
        },
      );
      createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);
      await flutterCommand.run();

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.flutterCommandResult(
            commandPath: 'dummy',
            result: 'success',
            commandHasTerminal: false,
            hostArch: flutterCommand.toolContext.os.hostPlatform.cliName,
            maxRss: 10,
          ),
        ),
      );
    });

    test('reports command that results in warning', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final ToolContext toolContext = createToolContext(systemClock: clock);
      final flutterCommand = DummyFlutterCommand(
        toolContext: toolContext,
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.warning);
        },
      );
      createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);
      await flutterCommand.run();

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.flutterCommandResult(
            commandPath: 'dummy',
            result: 'warning',
            commandHasTerminal: false,
            hostArch: flutterCommand.toolContext.os.hostPlatform.cliName,
            maxRss: 10,
          ),
        ),
      );
    });

    test('reports command that results in error', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final ToolContext toolContext = createToolContext(systemClock: clock);
      final flutterCommand = DummyFlutterCommand(
        toolContext: toolContext,
        commandFunction: () async {
          throwToolExit('fail');
        },
      );
      createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);
      await expectLater(() => flutterCommand.run(), throwsToolExit());
      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.flutterCommandResult(
            commandPath: 'dummy',
            result: 'fail',
            commandHasTerminal: false,
            hostArch: flutterCommand.toolContext.os.hostPlatform.cliName,
            maxRss: 10,
          ),
        ),
      );
    });

    test('FlutterCommandResult.success()', () async {
      expect(FlutterCommandResult.success().exitStatus, ExitStatus.success);
    });

    test('FlutterCommandResult.warning()', () async {
      expect(FlutterCommandResult.warning().exitStatus, ExitStatus.warning);
    });

    test('devToolsServerAddress returns parsed uri', () async {
      final command = DummyFlutterCommand(toolContext: createToolContext());
      command.argParser.addDescriptors(<OptionDescriptor<Object?>>[
        DebuggingOptionDescriptors.enableDevTools,
        DebuggingOptionDescriptors.devToolsServerAddress,
      ]);
      await createTestCommandRunner(command).run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        'http://127.0.0.1:9105',
      ]);
      expect(command.devToolsServerAddress.toString(), equals('http://127.0.0.1:9105'));
    });

    test('devToolsServerAddress returns null for bad input', () async {
      final command = DummyFlutterCommand(toolContext: createToolContext());
      command.argParser.addDescriptors(<OptionDescriptor<Object?>>[
        DebuggingOptionDescriptors.enableDevTools,
        DebuggingOptionDescriptors.devToolsServerAddress,
      ]);
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        'hello-world',
      ]);
      expect(command.devToolsServerAddress, isNull);

      await runner.run(<String>['dummy', '--${FlutterCommand.kDevToolsServerAddress}', '']);
      expect(command.devToolsServerAddress, isNull);

      await runner.run(<String>['dummy', '--${FlutterCommand.kDevToolsServerAddress}', '9101']);
      expect(command.devToolsServerAddress, isNull);

      await runner.run(<String>[
        'dummy',
        '--${FlutterCommand.kDevToolsServerAddress}',
        '127.0.0.1:9101',
      ]);
      expect(command.devToolsServerAddress, isNull);
    });

    group('signals tests', () {
      late FakeIoProcessSignal mockSignal;
      late ProcessSignal signalUnderTest;
      late StreamController<io.ProcessSignal> signalController;

      setUp(() {
        mockSignal = FakeIoProcessSignal();
        signalUnderTest = ProcessSignal(mockSignal);
        signalController = StreamController<io.ProcessSignal>();
        mockSignal.stream = signalController.stream;
      });

      test('reports command that is killed', () async {
        // Crash if called a third time which is unexpected.
        clock.times = <int>[1000, 2000];

        final completer = Completer<void>();
        setExitFunctionForTests((int exitCode) {
          expect(exitCode, 0);
          restoreExitFunction();
          completer.complete();
        });

        final ToolContext toolContext = createToolContext(
          signals: FakeSignals(
            subForSigTerm: signalUnderTest,
            exitSignals: <ProcessSignal>[signalUnderTest],
          ),
          systemClock: clock,
        );
        final flutterCommand = DummyFlutterCommand(
          toolContext: toolContext,
          commandFunction: () async {
            final c = Completer<void>();
            await c.future;
            throw UnsupportedError('Unreachable');
          },
        );
        createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);

        unawaited(flutterCommand.run());
        signalController.add(mockSignal);
        await completer.future;

        expect(
          fakeAnalytics.sentEvents,
          contains(
            Event.flutterCommandResult(
              commandPath: 'dummy',
              result: 'killed',
              commandHasTerminal: false,
              hostArch: flutterCommand.toolContext.os.hostPlatform.cliName,
              maxRss: 10,
            ),
          ),
        );
      });
      test('command release lock on kill signal', () async {
        clock.times = <int>[1000, 2000];
        final completer = Completer<void>();
        setExitFunctionForTests((int exitCode) {
          expect(exitCode, 0);
          restoreExitFunction();
          completer.complete();
        });
        final checkLockCompleter = Completer<void>();
        final commandCache = Cache.test(fileSystem: fileSystem, processManager: processManager);
        final toolContext = FakeToolContext(
          cache: commandCache,
          fs: fileSystem,
          processInfo: processInfo,
          processManager: processManager,
          signals: FakeSignals(
            subForSigTerm: signalUnderTest,
            exitSignals: <ProcessSignal>[signalUnderTest],
          ),
          systemClock: clock,
        );
        final flutterCommand = DummyFlutterCommand(
          toolContext: toolContext,
          commandFunction: () async {
            await commandCache.lock();
            checkLockCompleter.complete();
            final c = Completer<void>();
            await c.future;
            throw UnsupportedError('Unreachable');
          },
        );

        unawaited(flutterCommand.run());
        await checkLockCompleter.future;

        commandCache.checkLockAcquired();

        signalController.add(mockSignal);
        await completer.future;
      });
    });

    test('report execution timing by default', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final ToolContext toolContext = createToolContext(systemClock: clock);
      final flutterCommand = DummyFlutterCommand(toolContext: toolContext);
      createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);
      await flutterCommand.run();

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.timing(
            workflow: 'flutter',
            variableName: 'dummy',
            elapsedMilliseconds: 1000,
            label: 'fail',
          ),
        ),
      );
    });

    test('no timing report without usagePath', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final ToolContext toolContext = createToolContext(systemClock: clock);
      final flutterCommand = DummyFlutterCommand(noUsagePath: true, toolContext: toolContext);
      createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);
      await flutterCommand.run();

      var timingEventCounts = 0;
      for (final Event e in fakeAnalytics.sentEvents) {
        if (e.eventName == DashEvent.timing) {
          timingEventCounts += 1;
        }
      }
      expect(
        timingEventCounts,
        0,
        reason:
            'There should not be any timing events sent, there may '
            'be other non-timing events',
      );
    });

    test('report additional FlutterCommandResult data', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final commandResult = FlutterCommandResult(
        ExitStatus.success,
        // nulls should be cleaned up.
        timingLabelParts: <String?>['blah1', 'blah2', null, 'blah3'],
        endTimeOverride: DateTime.fromMillisecondsSinceEpoch(1500),
      );

      final ToolContext toolContext = createToolContext(systemClock: clock);
      final flutterCommand = DummyFlutterCommand(
        toolContext: toolContext,
        commandFunction: () async => commandResult,
      );
      createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);
      await flutterCommand.run();

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.timing(
            workflow: 'flutter',
            variableName: 'dummy',
            elapsedMilliseconds: 500,
            label: 'success-blah1-blah2-blah3',
          ),
        ),
      );
    });

    test('report failed execution timing too', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final ToolContext toolContext = createToolContext(systemClock: clock);
      final flutterCommand = DummyFlutterCommand(
        toolContext: toolContext,
        commandFunction: () async {
          throwToolExit('fail');
        },
      );
      createTestCommandRunner(flutterCommand, fakeAnalytics, toolContext);

      await expectLater(() => flutterCommand.run(), throwsToolExit());
      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.timing(
            workflow: 'flutter',
            variableName: 'dummy',
            elapsedMilliseconds: 1000,
            label: 'fail',
          ),
        ),
      );
    });

    test('use packagesPath to generate BuildInfo', () async {
      final flutterCommand = DummyFlutterCommand(
        packagesPath: 'foo',
        toolContext: createToolContext(),
      );
      final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(buildInfo.packageConfigPath, 'foo');
    });

    test('reports an explicit --[no-]enable-hcpp to gradle so it overrides the manifest', () async {
      final enabledCommand = DummyHcppFlutterCommand(toolContext: createToolContext());
      await createTestCommandRunner(enabledCommand).run(<String>['dummy', '--enable-hcpp']);
      final BuildInfo enabledBuildInfo = await enabledCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(enabledBuildInfo.androidGradleConfig.explicitEnableHcpp, isTrue);
      expect(
        AndroidBuildInfo(enabledBuildInfo).toGradleConfig(),
        contains('-Pexplicit-enable-hcpp=true'),
      );

      // The negation has to be reported too, otherwise gradle cannot tell it apart from the
      // flag being absent and would leave a manifest value of true in place.
      final disabledCommand = DummyHcppFlutterCommand(toolContext: createToolContext());
      await createTestCommandRunner(disabledCommand).run(<String>['dummy', '--no-enable-hcpp']);
      final BuildInfo disabledBuildInfo = await disabledCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(disabledBuildInfo.androidGradleConfig.explicitEnableHcpp, isFalse);
      expect(
        AndroidBuildInfo(disabledBuildInfo).toGradleConfig(),
        contains('-Pexplicit-enable-hcpp=false'),
      );

      // Without the flag nothing is reported, so the manifest decides.
      final defaultCommand = DummyHcppFlutterCommand(toolContext: createToolContext());
      await createTestCommandRunner(defaultCommand).run(<String>['dummy']);
      final BuildInfo defaultBuildInfo = await defaultCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(defaultBuildInfo.androidGradleConfig.explicitEnableHcpp, isNull);
      expect(
        AndroidBuildInfo(defaultBuildInfo).toGradleConfig(),
        isNot(anyElement(contains('-Pexplicit-enable-hcpp'))),
      );
    });

    test('reports --[no-]deprecated-js-interop in BuildInfo only when passed', () async {
      Future<bool?> deprecatedJsInteropFor(List<String> args) async {
        final command = DummyDeprecatedJsInteropFlutterCommand(toolContext: createToolContext());
        await createTestCommandRunner(command).run(<String>['dummy', ...args]);
        final BuildInfo buildInfo = await command.getBuildInfo(forcedBuildMode: BuildMode.debug);
        return buildInfo.deprecatedJsInterop;
      }

      expect(await deprecatedJsInteropFor(<String>['--deprecated-js-interop']), isTrue);
      expect(await deprecatedJsInteropFor(<String>['--no-deprecated-js-interop']), isFalse);
      expect(await deprecatedJsInteropFor(<String>[]), isNull);
    });

    test(
      'preserves hasOption and typed getters when subclass replaces argParser with a copy',
      () async {
        final command = _DummyOverriddenArgParserCommand(toolContext: createToolContext());
        await createTestCommandRunner(command)
            .run(<String>['dummy', '--filesystem-scheme=org-dartlang-app', '--ipv6']);
        expect(command.hasOption(BuildInfoOptions.fileSystemScheme), isTrue);
        expect(command.hasOption(DebuggingOptionDescriptors.ipv6), isTrue);
        expect(command.hasOption(CommonOptions.fatalWarnings), isFalse);
        expect(command.fileSystemScheme, 'org-dartlang-app');
        expect(command.ipv6, isTrue);
      },
    );

    test('reports the enable-hcpp feature flag to gradle as the injected default', () async {
      final ToolContext toolContext = createToolContext();
      final command = DummyHcppFlutterCommand(toolContext: toolContext);
      await createTestCommandRunner(
        command,
        null,
        toolContext,
        TestFeatureFlags(isHcppEnabled: true),
      ).run(<String>['dummy']);
      final BuildInfo buildInfo = await command.getBuildInfo(forcedBuildMode: BuildMode.debug);
      expect(buildInfo.androidGradleConfig.enableHcpp, isTrue);
      expect(AndroidBuildInfo(buildInfo).toGradleConfig(), contains('-Penable-hcpp=true'));
    });

    test('an explicit --[no-]enable-hcpp overrides the enable-hcpp feature flag default', () async {
      final ToolContext toolContext = createToolContext();
      final command = DummyHcppFlutterCommand(toolContext: toolContext);
      await createTestCommandRunner(
        command,
        null,
        toolContext,
        TestFeatureFlags(isHcppEnabled: true),
      ).run(<String>['dummy', '--no-enable-hcpp']);
      final BuildInfo buildInfo = await command.getBuildInfo(forcedBuildMode: BuildMode.debug);
      expect(buildInfo.androidGradleConfig.enableHcpp, isFalse);
      expect(AndroidBuildInfo(buildInfo).toGradleConfig(), contains('-Penable-hcpp=false'));
    });

    test('getBuildInfo defaults when no build options are registered on command', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext());
      await createTestCommandRunner(flutterCommand).run(<String>['dummy']);

      final BuildInfo debugBuildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(debugBuildInfo.trackWidgetCreation, isFalse);
      expect(debugBuildInfo.treeShakeIcons, isFalse);
      expect(debugBuildInfo.androidGradleConfig.gradleDaemon, isTrue);
      expect(debugBuildInfo.androidGradleConfig.skipBuildDependencyValidation, isTrue);

      final BuildInfo releaseBuildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.release,
      );
      expect(releaseBuildInfo.trackWidgetCreation, isFalse);
      expect(releaseBuildInfo.treeShakeIcons, isFalse);
    });

    test('getBuildInfo default flag values with options registered', () async {
      final command = DummyAllBuildOptionsFlutterCommand(toolContext: createToolContext());
      await createTestCommandRunner(command).run(<String>['dummy']);

      final BuildInfo debugBuildInfo = await command.getBuildInfo(forcedBuildMode: BuildMode.debug);
      expect(debugBuildInfo.trackWidgetCreation, isTrue);
      expect(debugBuildInfo.androidGradleConfig.skipBuildDependencyValidation, isFalse);

      final BuildInfo releaseBuildInfo = await command.getBuildInfo(
        forcedBuildMode: BuildMode.release,
      );
      expect(releaseBuildInfo.treeShakeIcons, isTrue);
    });

    test('getBuildInfo parses AndroidGradleConfig options and populates toGradleConfig', () async {
      final command = DummyAllBuildOptionsFlutterCommand(toolContext: createToolContext());
      await createTestCommandRunner(command).run(<String>[
        'dummy',
        '--android-project-arg=x=1',
        '--android-project-cache-dir=/c',
        '--no-android-gradle-daemon',
      ]);

      final BuildInfo buildInfo = await command.getBuildInfo(forcedBuildMode: BuildMode.debug);
      expect(buildInfo.androidGradleConfig.gradleDaemon, isFalse);
      expect(
        AndroidBuildInfo(buildInfo).toGradleConfig(),
        containsAll(<String>['-Px=1', '--project-cache-dir=/c']),
      );
    });

    test(
      'getBuildInfo respects historical ExtraFrontEndOptions and ExtraGenSnapshotOptions aliases',
      () async {
        final command = DummyAllBuildOptionsFlutterCommand(toolContext: createToolContext());
        await createTestCommandRunner(
          command,
        ).run(<String>['dummy', '--ExtraFrontEndOptions=--foo', '--ExtraGenSnapshotOptions=--bar']);

        final BuildInfo buildInfo = await command.getBuildInfo(forcedBuildMode: BuildMode.release);
        expect(buildInfo.extraFrontEndOptions, contains('--foo'));
        expect(buildInfo.extraGenSnapshotOptions, contains('--bar'));
      },
    );

    test('use fileSystemScheme to generate BuildInfo', () async {
      final flutterCommand = DummyFlutterCommand(
        fileSystemScheme: 'foo',
        toolContext: createToolContext(),
      );
      final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(buildInfo.fileSystemScheme, 'foo');
    });

    test('use fileSystemRoots to generate BuildInfo', () async {
      final flutterCommand = DummyFlutterCommand(
        fileSystemRoots: <String>['foo', 'bar'],
        toolContext: createToolContext(),
      );
      final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(buildInfo.fileSystemRoots, <String>['foo', 'bar']);
    });

    test('includes initializeFromDill in BuildInfo', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext());
      flutterCommand.argParser.addDescriptors(const <OptionDescriptor<Object?>>[
        BuildInfoOptions.initializeFromDill,
        BuildInfoOptions.assumeInitializeFromDillUpToDate,
      ], hide: false);
      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy', '--initialize-from-dill=/foo/bar.dill']);
      final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(buildInfo.initializeFromDill, '/foo/bar.dill');
    });

    test('includes assumeInitializeFromDillUpToDate in BuildInfo', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext());
      flutterCommand.argParser.addDescriptors(const <OptionDescriptor<Object?>>[
        BuildInfoOptions.initializeFromDill,
        BuildInfoOptions.assumeInitializeFromDillUpToDate,
      ], hide: false);
      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy', '--assume-initialize-from-dill-up-to-date']);
      final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(buildInfo.assumeInitializeFromDillUpToDate, isTrue);
    });

    test('unsets assumeInitializeFromDillUpToDate in BuildInfo when disabled', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext());
      flutterCommand.argParser.addDescriptors(const <OptionDescriptor<Object?>>[
        BuildInfoOptions.initializeFromDill,
        BuildInfoOptions.assumeInitializeFromDillUpToDate,
      ], hide: false);
      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      await runner.run(<String>['dummy', '--no-assume-initialize-from-dill-up-to-date']);
      final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(buildInfo.assumeInitializeFromDillUpToDate, isFalse);
    });

    test('sets useLocalCanvasKit in BuildInfo', () async {
      final flutterCommand = DummyFlutterCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
      fileSystem.directory('engine/src/out/wasm_release').createSync(recursive: true);
      await runner.run(<String>[
        '--local-web-sdk=wasm_release',
        '--local-engine-src-path=engine/src',
        'dummy',
      ]);
      final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
        forcedBuildMode: BuildMode.debug,
      );
      expect(buildInfo.useLocalCanvasKit, isTrue);
    });

    test('dds options', () async {
      final ddsCommand = FakeDdsCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
      await runner.run(<String>['test', '--dds-port=1']);
      expect(ddsCommand.enableDds, isTrue);
      expect(ddsCommand.ddsPort, 1);
    });

    test('dds options --dds', () async {
      final ddsCommand = FakeDdsCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
      await runner.run(<String>['test', '--dds']);
      expect(ddsCommand.enableDds, isTrue);
    });

    test('dds options --no-dds', () async {
      final ddsCommand = FakeDdsCommand(toolContext: createToolContext());
      final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
      await runner.run(<String>['test', '--no-dds']);
      expect(ddsCommand.enableDds, isFalse);
    });

    group('findTargetDevice', () {
      final device1 = FakeDevice('device1', 'device1');
      final device2 = FakeDevice('device2', 'device2');

      test('no device found', () async {
        final flutterCommand = DummyFlutterCommand(
          deviceManager: FakeDeviceManager(),
          toolContext: createToolContext(),
        );
        final Device? device = await flutterCommand.findTargetDevice();
        expect(device, isNull);
      });

      test('finds single device', () async {
        final deviceManager = FakeDeviceManager()..addAttachedDevice(device1);
        final flutterCommand = DummyFlutterCommand(
          deviceManager: deviceManager,
          toolContext: createToolContext(),
        );
        final Device? device = await flutterCommand.findTargetDevice();
        expect(device, device1);
      });

      test('finds multiple devices', () async {
        final deviceManager = FakeDeviceManager()
          ..addAttachedDevice(device1)
          ..addAttachedDevice(device2)
          ..specifiedDeviceId = 'all';
        final flutterCommand = DummyFlutterCommand(
          deviceManager: deviceManager,
          toolContext: createToolContext(),
        );
        final Device? device = await flutterCommand.findTargetDevice();
        expect(device, isNull);
        expect(logger.statusText, contains(UserMessages().flutterSpecifyDevice));
      });
    });

    group('findAllTargetDevices canPrompt/machine mode interaction', () {
      final device1 = FakeDevice('device1', 'device-1');
      final device2 = FakeDevice('device2', 'device-2');
      late FakeTerminal terminal;

      setUp(() {
        terminal = FakeTerminal();
      });

      test('defaults to prompting when machine mode is false', () async {
        final deviceManager = FakeDeviceManager()
          ..addAttachedDevice(device1)
          ..addAttachedDevice(device2);

        final flutterCommand = DummyFlutterCommand(
          deviceManager: deviceManager,
          toolContext: createToolContext(terminal: terminal),
        );
        final List<Device>? devices = await flutterCommand.findAllTargetDevices();

        // Should prompt the user and print prompt options (so status contains "Connected devices")
        expect(logger.statusText, contains('Connected devices:'));
        expect(devices, <Device>[device1]);
      });

      test('defaults to not prompting when machine mode is true', () async {
        final deviceManager = FakeDeviceManager()
          ..addAttachedDevice(device1)
          ..addAttachedDevice(device2);

        final ToolContext toolContext = createToolContext(terminal: terminal);
        final flutterCommand = DummyMachineFlutterCommand(
          deviceManager: deviceManager,
          toolContext: toolContext,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: deviceManager,
          toolContext: toolContext,
        )..addCommand(flutterCommand);
        await runner.run(<String>['dummy', '--machine']);

        final List<Device>? devices = await flutterCommand.findAllTargetDevices();

        // Should NOT prompt, should print specify device help, and return null
        expect(
          logger.statusText,
          contains('More than one device connected; please specify a device'),
        );
        expect(devices, isNull);
      });

      test('can override default canPrompt when machine mode is true', () async {
        final deviceManager = FakeDeviceManager()
          ..addAttachedDevice(device1)
          ..addAttachedDevice(device2);

        final ToolContext toolContext = createToolContext(terminal: terminal);
        final flutterCommand = DummyMachineFlutterCommand(
          deviceManager: deviceManager,
          toolContext: toolContext,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: deviceManager,
          toolContext: toolContext,
        )..addCommand(flutterCommand);
        await runner.run(<String>['dummy', '--machine']);

        // Explicitly set canPrompt to true, overriding outputMachineFormat default of false.
        final List<Device>? devices = await flutterCommand.findAllTargetDevices(canPrompt: true);

        // Should prompt the user even in machine mode.
        expect(logger.statusText, contains('Connected devices:'));
        expect(devices, <Device>[device1]);
      });

      test('can override default canPrompt when machine mode is false', () async {
        final deviceManager = FakeDeviceManager()
          ..addAttachedDevice(device1)
          ..addAttachedDevice(device2);

        final flutterCommand = DummyFlutterCommand(
          deviceManager: deviceManager,
          toolContext: createToolContext(terminal: terminal),
        );
        final List<Device>? devices = await flutterCommand.findAllTargetDevices(canPrompt: false);

        // Should NOT prompt the user even if machine mode is false.
        expect(
          logger.statusText,
          contains('More than one device connected; please specify a device'),
        );
        expect(devices, isNull);
      });
    });

    group('--dart-define-from-file', () {
      late FlutterCommand dummyCommand;
      late CommandRunner<void> dummyCommandRunner;

      setUp(() {
        dummyCommand = DummyFlutterCommand(toolContext: createToolContext());
        dummyCommand.argParser.addDescriptors(const <OptionDescriptor<Object?>>[
          CommonOptions.dartDefines,
          CommonOptions.dartDefineFromFile,
        ]);
        dummyCommandRunner = createTestCommandRunner(dummyCommand);
      });

      test('parses values from JSON files and includes them in defines list', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        await fileSystem.file('config1.json').writeAsString('''
            {
              "kInt": 1,
              "kDouble": 1.1,
              "name": "denghaizhu",
              "title": "this is title from config json file",
              "nullValue": null,
              "containEqual": "sfadsfv=432f"
            }
          ''');
        await fileSystem.file('config2.json').writeAsString('''
            {
              "body": "this is body from config json file"
            }
          ''');

        await dummyCommandRunner.run(<String>[
          'dummy',
          '--dart-define-from-file=config1.json',
          '--dart-define-from-file=config2.json',
        ]);

        final BuildInfo buildInfo = await dummyCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(
          buildInfo.dartDefines,
          containsAll(const <String>[
            'kInt=1',
            'kDouble=1.1',
            'name=denghaizhu',
            'title=this is title from config json file',
            'nullValue=null',
            'containEqual=sfadsfv=432f',
            'body=this is body from config json file',
          ]),
        );
      });

      test('has values with identical keys from --dart-define take precedence', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('.env').writeAsStringSync('''
            MY_VALUE=VALUE_FROM_ENV_FILE
          ''');

        await dummyCommandRunner.run(<String>[
          'dummy',
          '--dart-define=MY_VALUE=VALUE_FROM_COMMAND',
          '--dart-define-from-file=.env',
        ]);

        final BuildInfo buildInfo = await dummyCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(
          buildInfo.dartDefines,
          containsAll(const <String>[
            'MY_VALUE=VALUE_FROM_ENV_FILE',
            'MY_VALUE=VALUE_FROM_COMMAND',
          ]),
        );
      });

      test('correctly parses a valid env file', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        await fileSystem.file('.env').writeAsString('''
            # comment
            kInt=1
            kDouble=1.1 # should be double

            name=piotrfleury
            title=this is title from config env file
            empty=

            doubleQuotes="double quotes 'value'#=" # double quotes
            singleQuotes='single quotes "value"#=' # single quotes
            backQuotes=`back quotes "value" '#=` # back quotes

            hashString="some-#-hash-string-value"

            # Play around with spaces around the equals sign.
            spaceBeforeEqual =value
            spaceAroundEqual = value
            spaceAfterEqual= value

          ''');
        await fileSystem.file('.env2').writeAsString('''
            # second comment

            body=this is body from config env file
          ''');

        await dummyCommandRunner.run(<String>[
          'dummy',
          '--dart-define-from-file=.env',
          '--dart-define-from-file=.env2',
        ]);

        final BuildInfo buildInfo = await dummyCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(
          buildInfo.dartDefines,
          containsAll(const <String>[
            'kInt=1',
            'kDouble=1.1',
            'name=piotrfleury',
            'title=this is title from config env file',
            'empty=',
            "doubleQuotes=double quotes 'value'#=",
            'singleQuotes=single quotes "value"#=',
            'backQuotes=back quotes "value" \'#=',
            'hashString=some-#-hash-string-value',
            'spaceBeforeEqual=value',
            'spaceAroundEqual=value',
            'spaceAfterEqual=value',
            'body=this is body from config env file',
          ]),
        );
      });

      test('throws a ToolExit when the provided .env file is malformed', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        await fileSystem.file('.env').writeAsString('what is this');

        await dummyCommandRunner.run(<String>['dummy', '--dart-define-from-file=.env']);

        expect(
          dummyCommand.getBuildInfo(forcedBuildMode: BuildMode.debug),
          throwsToolExit(
            message:
                'Unable to parse file provided for '
                '--${FlutterOptions.kDartDefineFromFileOption}.\n'
                'Invalid property line: what is this',
          ),
        );
      });

      test('throws a ToolExit when .env file contains a multiline value', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        await fileSystem.file('.env').writeAsString('''
            # single line value
            name=piotrfleury

            # multi-line value
            multiline = """ Welcome to .env demo
            a simple counter app with .env file support
            for more info, check out the README.md file
            Thanks! """ # This is the welcome message that will be displayed on the counter app

          ''');

        await dummyCommandRunner.run(<String>['dummy', '--dart-define-from-file=.env']);
        expect(
          dummyCommand.getBuildInfo(forcedBuildMode: BuildMode.debug),
          throwsToolExit(
            message: 'Multi-line value is not supported: multiline = """ Welcome to .env demo',
          ),
        );
      });

      test('works with mixed file formats', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        await fileSystem.file('.env').writeAsString('''
            kInt=1
            kDouble=1.1
            name=piotrfleury
            title=this is title from config env file
          ''');
        await fileSystem.file('config.json').writeAsString('''
            {
              "body": "this is body from config json file"
            }
          ''');

        await dummyCommandRunner.run(<String>[
          'dummy',
          '--dart-define-from-file=.env',
          '--dart-define-from-file=config.json',
        ]);

        final BuildInfo buildInfo = await dummyCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(
          buildInfo.dartDefines,
          containsAll(const <String>[
            'kInt=1',
            'kDouble=1.1',
            'name=piotrfleury',
            'title=this is title from config env file',
            'body=this is body from config json file',
          ]),
        );
      });

      test(
        'when files contain entries with duplicate keys, uses the value from the lattermost file',
        () async {
          fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
          fileSystem.file('pubspec.yaml').createSync();
          await fileSystem.file('config1.json').writeAsString('''
            {
              "kInt": 1,
              "kDouble": 1.1,
              "name": "denghaizhu",
              "title": "this is title from config json file"
            }
          ''');
          await fileSystem.file('config2.json').writeAsString('''
            {
              "kInt": "2"
            }
          ''');

          await dummyCommandRunner.run(<String>[
            'dummy',
            '--dart-define-from-file=config1.json',
            '--dart-define-from-file=config2.json',
          ]);
          final BuildInfo buildInfo = await dummyCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );
          expect(
            buildInfo.dartDefines,
            containsAll(const <String>[
              'kInt=2',
              'kDouble=1.1',
              'name=denghaizhu',
              'title=this is title from config json file',
            ]),
          );
        },
      );

      test('throws a ToolExit when the argued path points to a directory', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.directory('config').createSync();

        await dummyCommandRunner.run(<String>['dummy', '--dart-define-from-file=config']);
        expect(
          dummyCommand.getBuildInfo(forcedBuildMode: BuildMode.debug),
          throwsToolExit(
            message: 'Did not find the file passed to "--dart-define-from-file". Path: config',
          ),
        );
      });

      test('parses values from JSON files encoded in UTF-16 LE with BOM', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        final utf16Bytes = <int>[
          0xFF, 0xFE, // UTF-16 LE BOM
          ...'{ "kInt": 1 }'.codeUnits.expand(
            (int codeUnit) => <int>[codeUnit & 0xFF, (codeUnit >> 8) & 0xFF],
          ),
        ];
        fileSystem.file('config.json').writeAsBytesSync(utf16Bytes);

        await dummyCommandRunner.run(<String>['dummy', '--dart-define-from-file=config.json']);

        final BuildInfo buildInfo = await dummyCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.dartDefines, containsAll(const <String>['kInt=1']));
      });

      test('throws a ToolExit when the given file cannot be decoded', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('config.json').writeAsBytesSync(<int>[0xFF, 0xFF, 0xFF, 0xFF, 0x01]);

        await dummyCommandRunner.run(<String>['dummy', '--dart-define-from-file=config.json']);
        expect(
          dummyCommand.getBuildInfo(forcedBuildMode: BuildMode.debug),
          throwsToolExit(
            message:
                'Unable to decode the file at path "config.json". '
                'Ensure that the file is encoded in UTF-8 or UTF-16.\n',
          ),
        );
      });

      test('throws a ToolExit when the given JSON file is malformed', () async {
        fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        await fileSystem.file('config.json').writeAsString('''
            {
              "kInt": 1Error json format
              "kDouble": 1.1,
              "name": "denghaizhu",
              "title": "this is title from config json file"
            }
          ''');

        await dummyCommandRunner.run(<String>['dummy', '--dart-define-from-file=config.json']);
        expect(
          dummyCommand.getBuildInfo(forcedBuildMode: BuildMode.debug),
          throwsToolExit(
            message:
                'Unable to parse the file at path "config.json" due to '
                'a formatting error. Ensure that the file contains valid JSON.\n'
                'Error details: FormatException: Missing expected digit (at line 2, character 25)',
          ),
        );
      });

      test('throws a ToolExit when the provided file does not exist', () async {
        fileSystem.directory('config').createSync();
        await dummyCommandRunner.run(<String>[
          'dummy',
          '--dart-define=k=v',
          '--dart-define-from-file=config',
        ]);
        expect(
          dummyCommand.getBuildInfo(forcedBuildMode: BuildMode.debug),
          throwsToolExit(
            message: 'Did not find the file passed to "--dart-define-from-file". Path: config',
          ),
        );
      });
    });

    group('--flavor', () {
      late FileSystem fileSystem;

      setUp(() {
        fileSystem = MemoryFileSystem.test();
      });

      test('CLI option overrides default flavor from manifest', () async {
        final File pubspec = fileSystem.file('pubspec.yaml');
        await pubspec.create();
        await pubspec.writeAsString('''
name: test
flutter:
  default-flavor: foo
        ''');

        final flutterCommand = DummyFlutterCommand(
          toolContext: createToolContext(
            fsOverride: fileSystem,
            processManagerOverride: FakeProcessManager.empty(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.flavor, 'foo');
      });

      test('tool loads default flavor from manifest, but cli overrides', () async {
        final File pubspec = fileSystem.file('pubspec.yaml');
        await pubspec.create();
        await pubspec.writeAsString('''
name: test
flutter:
  default-flavor: foo
        ''');

        final flutterCommand = DummyFlutterCommand(
          toolContext: createToolContext(
            fsOverride: fileSystem,
            processManagerOverride: FakeProcessManager.empty(),
          ),
          commandFunction: () async {
            return FlutterCommandResult.success();
          },
        );
        flutterCommand.argParser.addDescriptor(BuildInfoOptions.flavor);
        final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
        await runner.run(<String>['dummy', '--flavor', 'bar']);
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.flavor, 'bar');
      });
    });

    test("tool exits when $kAppFlavor is already set in user's environemnt", () async {
      final fs = MemoryFileSystem.test();
      fs.file('lib/main.dart').createSync(recursive: true);
      fs.file('pubspec.yaml').createSync();
      final toolContext = FakeToolContext(
        fs: fs,
        platform: FakePlatform(environment: <String, String>{kAppFlavor: 'AlreadySet'}),
        processManager: FakeProcessManager.empty(),
      );
      final CommandRunner<void> runner = _createValidationRunner(toolContext);
      await expectLater(
        runner.run(<String>['run', '--no-pub', '--no-hot']),
        throwsToolExit(
          message: '$kAppFlavor is used by the framework and cannot be set in the environment.',
        ),
      );
    });

    test('tool exits when $kAppFlavor is set in --dart-define', () async {
      final fs = MemoryFileSystem.test();
      fs.file('lib/main.dart').createSync(recursive: true);
      fs.file('pubspec.yaml').createSync();
      final toolContext = FakeToolContext(fs: fs, processManager: FakeProcessManager.empty());
      final CommandRunner<void> runner = _createValidationRunner(toolContext);
      await expectLater(
        runner.run(<String>['run', '--dart-define=$kAppFlavor=AlreadySet', '--no-pub', '--no-hot']),
        throwsToolExit(
          message: '$kAppFlavor is used by the framework and cannot be set using --dart-define',
        ),
      );
    });

    test('tool exits when $kAppFlavor is set in --dart-define-from-file', () async {
      final fs = MemoryFileSystem.test();
      fs.file('lib/main.dart').createSync(recursive: true);
      fs.file('pubspec.yaml').createSync();
      fs.file('config.json')
        ..createSync()
        ..writeAsStringSync('{"$kAppFlavor": "AlreadySet"}');
      final toolContext = FakeToolContext(fs: fs, processManager: FakeProcessManager.empty());
      final CommandRunner<void> runner = _createValidationRunner(toolContext);
      await expectLater(
        runner.run(<String>['run', '--dart-define-from-file=config.json', '--no-pub', '--no-hot']),
        throwsToolExit(
          message: '$kAppFlavor is used by the framework and cannot be set using --dart-define',
        ),
      );
    });

    group('build name and number', () {
      late FileSystem fileSystem;

      setUp(() {
        fileSystem = MemoryFileSystem.test();
      });

      test('are injected as dart defines from the pubspec version', () async {
        final File pubspec = fileSystem.file('pubspec.yaml');
        await pubspec.create();
        await pubspec.writeAsString('''
name: test
version: 1.2.3+45
        ''');

        final flutterCommand = DummyFlutterCommand(
          toolContext: createToolContext(
            fsOverride: fileSystem,
            processManagerOverride: FakeProcessManager.empty(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.dartDefines, contains('$kAppBuildName=1.2.3'));
        expect(buildInfo.dartDefines, contains('$kAppBuildNumber=45'));
      });

      test('are not injected when the pubspec has no version', () async {
        final File pubspec = fileSystem.file('pubspec.yaml');
        await pubspec.create();
        await pubspec.writeAsString('''
name: test
        ''');

        final flutterCommand = DummyFlutterCommand(
          toolContext: createToolContext(
            fsOverride: fileSystem,
            processManagerOverride: FakeProcessManager.empty(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(
          buildInfo.dartDefines.where(
            (String define) =>
                define.startsWith(kAppBuildName) || define.startsWith(kAppBuildNumber),
          ),
          isEmpty,
        );
      });

      test("tool exits when $kAppBuildName is already set in user's environment", () async {
        final fs = MemoryFileSystem.test();
        fs.file('lib/main.dart').createSync(recursive: true);
        fs.file('pubspec.yaml').createSync();
        final toolContext = FakeToolContext(
          fs: fs,
          platform: FakePlatform(environment: <String, String>{kAppBuildName: '1.0.0'}),
          processManager: FakeProcessManager.empty(),
        );
        final CommandRunner<void> runner = _createValidationRunner(toolContext);
        await expectLater(
          runner.run(<String>['run', '--no-pub', '--no-hot']),
          throwsToolExit(
            message:
                '$kAppBuildName is used by the framework and cannot be set in the environment.',
          ),
        );
      });

      test('tool exits when $kAppBuildNumber is set in --dart-define', () async {
        final fs = MemoryFileSystem.test();
        fs.file('lib/main.dart').createSync(recursive: true);
        fs.file('pubspec.yaml').createSync();
        final toolContext = FakeToolContext(fs: fs, processManager: FakeProcessManager.empty());
        final CommandRunner<void> runner = _createValidationRunner(toolContext);
        await expectLater(
          runner.run(<String>['run', '--dart-define=$kAppBuildNumber=42', '--no-pub', '--no-hot']),
          throwsToolExit(
            message:
                '$kAppBuildNumber is used by the framework and cannot be set using --dart-define',
          ),
        );
      });

      test('user defines sharing a prefix with a reserved key are allowed', () async {
        final fs = MemoryFileSystem.test();
        fs.file('lib/main.dart').createSync(recursive: true);
        fs.file('pubspec.yaml').createSync();
        final toolContext = FakeToolContext(fs: fs, processManager: FakeProcessManager.empty());
        final CommandRunner<void> runner = _createValidationRunner(toolContext);
        await runner.run(<String>[
          'run',
          '--dart-define=${kAppFlavor}_CUSTOM=foo',
          '--dart-define=${kAppBuildName}SPACE=bar',
          '--dart-define=${kAppBuildNumber}_OFFSET=7',
          '--no-pub',
          '--no-hot',
        ]);
      });
    });

    group('Flutter version', () {
      for (final String dartDefine in FlutterCommand.flutterVersionDartDefines) {
        test('tool exits when $dartDefine is set in --dart-define or --dart-define-from-file', () async {
          final fs = MemoryFileSystem.test();
          fs.file('lib/main.dart').createSync(recursive: true);
          fs.file('pubspec.yaml').createSync();
          fs.file('.packages').createSync();
          fs.file('config.json')
            ..createSync()
            ..writeAsStringSync('{"$dartDefine": "AlreadySet"}');
          final toolContext = FakeToolContext(
            flutterVersion: FakeFlutterVersion(),
            fs: fs,
            platform: FakePlatform(),
            processManager: FakeProcessManager.any(),
          );
          final CommandRunner<void> runner = _createValidationRunner(toolContext);

          await expectLater(
            runner.run(<String>[
              'run',
              '--dart-define=$dartDefine=AlreadySet',
              '--no-pub',
              '--no-hot',
            ]),
            throwsToolExit(
              message:
                  '$dartDefine is used by the framework and cannot be set using --dart-define or --dart-define-from-file. '
                  'Use FlutterVersion to access it in Flutter code',
            ),
          );

          await expectLater(
            runner.run(<String>[
              'run',
              '--dart-define-from-file=config.json',
              '--no-pub',
              '--no-hot',
            ]),
            throwsToolExit(
              message:
                  '$dartDefine is used by the framework and cannot be set using --dart-define or --dart-define-from-file. '
                  'Use FlutterVersion to access it in Flutter code',
            ),
          );
        });
      }

      // Regression test for https://github.com/flutter/flutter/issues/164093
      test('tool does not throw when FLUTTER_GIT_URL exists in environment variables', () async {
        final fs = MemoryFileSystem.test();
        fs.file('lib/main.dart').createSync(recursive: true);
        fs.file('pubspec.yaml').createSync();
        fs.file('.packages').createSync();
        final toolContext = FakeToolContext(
          flutterVersion: FakeFlutterVersion(),
          fs: fs,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_GIT_URL': 'git@example.org:fork_of/flutter.git'},
          ),
          processManager: FakeProcessManager.any(),
        );
        final CommandRunner<void> runner = _createValidationRunner(toolContext);

        await expectReturnsNormallyLater(runner.run(<String>['run', '--no-pub', '--no-hot']));
      });

      test('FLUTTER_VERSION is set in dartDefines', () async {
        final flutterCommand = DummyFlutterCommand(
          packagesPath: 'foo',
          toolContext: createToolContext(
            flutterVersion: FakeFlutterVersion(),
            processManagerOverride: FakeProcessManager.any(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.dartDefines, contains('FLUTTER_VERSION=0.0.0'));
      });

      test('FLUTTER_CHANNEL is set in dartDefines', () async {
        final flutterCommand = DummyFlutterCommand(
          packagesPath: 'foo',
          toolContext: createToolContext(
            flutterVersion: FakeFlutterVersion(),
            processManagerOverride: FakeProcessManager.any(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );

        expect(buildInfo.dartDefines, contains('FLUTTER_CHANNEL=master'));
      });

      test('FLUTTER_GIT_URL is set in dartDefines', () async {
        final flutterCommand = DummyFlutterCommand(
          packagesPath: 'foo',
          toolContext: createToolContext(
            flutterVersion: FakeFlutterVersion(),
            processManagerOverride: FakeProcessManager.any(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );

        expect(
          buildInfo.dartDefines,
          contains('FLUTTER_GIT_URL=https://github.com/flutter/flutter.git'),
        );
      });

      test('FLUTTER_FRAMEWORK_REVISION is set in dartDefines', () async {
        final flutterCommand = DummyFlutterCommand(
          packagesPath: 'foo',
          toolContext: createToolContext(
            flutterVersion: FakeFlutterVersion(),
            processManagerOverride: FakeProcessManager.any(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );

        expect(buildInfo.dartDefines, contains('FLUTTER_FRAMEWORK_REVISION=11111'));
      });

      test('FLUTTER_ENGINE_REVISION is set in dartDefines', () async {
        final flutterCommand = DummyFlutterCommand(
          packagesPath: 'foo',
          toolContext: createToolContext(
            flutterVersion: FakeFlutterVersion(),
            processManagerOverride: FakeProcessManager.any(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );

        expect(buildInfo.dartDefines, contains('FLUTTER_ENGINE_REVISION=abcde'));
      });

      test('FLUTTER_DART_VERSION is set in dartDefines', () async {
        final flutterCommand = DummyFlutterCommand(
          packagesPath: 'foo',
          toolContext: createToolContext(
            flutterVersion: FakeFlutterVersion(),
            processManagerOverride: FakeProcessManager.any(),
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );

        expect(buildInfo.dartDefines, contains('FLUTTER_DART_VERSION=12'));
      });
    });

    group('feature flags', () {
      test('tool exits when FLUTTER_ENABLED_FEATURE_FLAGS is set in --dart-define or --dart-define-from-file', () async {
        final fs = MemoryFileSystem.test();
        fs
          ..file('lib/main.dart').createSync(recursive: true)
          ..file('pubspec.yaml').createSync();
        fs.file('config.json')
          ..createSync()
          ..writeAsStringSync('{"FLUTTER_ENABLED_FEATURE_FLAGS": "AlreadySet"}');
        final toolContext = FakeToolContext(
          flutterVersion: FakeFlutterVersion(),
          fs: fs,
          platform: FakePlatform(),
          processManager: FakeProcessManager.any(),
        );
        final CommandRunner<void> runner = _createValidationRunner(toolContext);

        await expectLater(
          runner.run(<String>[
            'run',
            '--dart-define=FLUTTER_ENABLED_FEATURE_FLAGS=AlreadySet',
            '--no-pub',
            '--no-hot',
          ]),
          throwsToolExit(
            message: '''
FLUTTER_ENABLED_FEATURE_FLAGS is used by the framework and cannot be set using --dart-define or --dart-define-from-file.

Use the "flutter config" command to enable feature flags.''',
          ),
        );

        await expectLater(
          runner.run(<String>[
            'run',
            '--dart-define-from-file=config.json',
            '--no-pub',
            '--no-hot',
          ]),
          throwsToolExit(
            message: '''
FLUTTER_ENABLED_FEATURE_FLAGS is used by the framework and cannot be set using --dart-define or --dart-define-from-file.

Use the "flutter config" command to enable feature flags.''',
          ),
        );
      });

      test('FLUTTER_ENABLED_FEATURE_FLAGS is set in dartDefines', () async {
        final ToolContext toolContext = createToolContext(
          processManagerOverride: FakeProcessManager.any(),
        );
        final flutterCommand = DummyFlutterCommand(packagesPath: 'foo', toolContext: toolContext);
        createTestCommandRunner(
          flutterCommand,
          null,
          toolContext,
          const FakeFeatureFlags(
            allFeatures: <FakeFeature>[
              FakeFeature(name: 'Foo', enabled: true),
              FakeFeature(name: 'Bar', runtimeId: 'bar_feature', enabled: false),
              FakeFeature(name: 'Buzz', runtimeId: 'buzz_feature', enabled: true),
            ],
          ),
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.dartDefines, contains('FLUTTER_ENABLED_FEATURE_FLAGS=buzz_feature'));
      });
    });
  });
}

class FakeDeprecatedCommand extends FlutterCommand {
  FakeDeprecatedCommand({required super.toolContext});

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

class FakeTargetCommand extends FlutterCommand {
  FakeTargetCommand({required super.toolContext}) {
    CommonOptions.target.addTo(argParser);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    cachedTargetFile = targetFile;
    return FlutterCommandResult.success();
  }

  String? cachedTargetFile;

  @override
  String get description => '';

  @override
  String get name => 'test';
}

class FakeDdsCommand extends FlutterCommand {
  FakeDdsCommand({required super.toolContext}) {
    registerOptionBundle(const DdsAndDevToolsOptionsBundle(includeDevTools: false));
  }

  @override
  String get description => 'test';

  @override
  String get name => 'test';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

class FakeProcessInfo extends Fake implements ProcessInfo {
  @override
  int maxRss = 0;
}

class FakeIoProcessSignal extends Fake implements io.ProcessSignal {
  late Stream<io.ProcessSignal> stream;

  @override
  Stream<io.ProcessSignal> watch() => stream;
}

class FakeCache extends Fake implements Cache {
  @override
  String get flutterRoot => '/path/to/sdk/flutter';
  @override
  set flutterRoot(String? value) {}
  List<Set<DevelopmentArtifact>> artifacts = <Set<DevelopmentArtifact>>[];

  @override
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts, {bool offline = false}) async {
    artifacts.add(requiredArtifacts.toSet());
  }

  @override
  void releaseLock() {}
}

class FakeSignals implements Signals {
  FakeSignals({required this.subForSigTerm, required List<ProcessSignal> exitSignals})
    : delegate = Signals.test(exitSignals: exitSignals);

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

CommandRunner<void> _createValidationRunner(ToolContext toolContext) {
  final deviceManager = FakeDeviceManager()..attachedDevices = <Device>[FakeDevice('name', 'id')];
  return TestFlutterCommandRunner(
    deviceManager: deviceManager,
    doctor: FakeDoctor(),
    featureFlags: TestFeatureFlags(),
    toolContext: toolContext,
  )..addCommand(
    _TestRunCommandThatOnlyValidates(deviceManager: deviceManager, toolContext: toolContext),
  );
}

class _TestRunCommandThatOnlyValidates extends RunCommand {
  _TestRunCommandThatOnlyValidates({required super.toolContext, super.deviceManager})
    : super(
        appleContext: FakeAppleContext(),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        buildTargets: const NoOpBuildTargets(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
      );

  @override
  Future<WebDevServerConfig?> getWebDevServerConfig() async => null;

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }

  @override
  bool get shouldRunPub => false;
}

class _FakeAssetBundleFactory extends Fake implements AssetBundleFactory {}

class FakeFeature extends Feature {
  const FakeFeature({required super.name, super.runtimeId, required this.enabled});

  final bool enabled;
}

class DummyFlutterCommandWithPub extends FlutterCommand {
  DummyFlutterCommandWithPub({required super.toolContext}) {
    CommonOptions.pub.addTo(argParser);
  }

  @override
  String get description => 'does nothing, with pub';

  @override
  String get name => 'dummypub';

  @override
  bool get regeneratePlatformSpecificToolingDuringVerify => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

class FakeLockTrackingCache extends Fake implements Cache {
  @override
  String get flutterRoot => '/path/to/sdk/flutter';
  @override
  set flutterRoot(String? value) {}
  bool isLockHeld = false;

  @override
  Future<void> lock() async {
    isLockHeld = true;
  }

  @override
  Future<void> updateAll(
    Set<DevelopmentArtifact> requiredArtifacts, {
    bool offline = false,
  }) async {}

  @override
  void releaseLock() {
    isLockHeld = false;
  }
}

class FakeLockCheckingPub extends Fake implements Pub {
  FakeLockCheckingPub(this._cache);

  final FakeLockTrackingCache _cache;
  bool pubGetCalled = false;
  bool lockWasHeldDuringPubGet = false;

  @override
  Future<void> get({
    PubContext? context,
    required FlutterProject project,
    bool upgrade = false,
    bool offline = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool enforceLockfile = false,
    PubOutputMode outputMode = PubOutputMode.all,
  }) async {
    pubGetCalled = true;
    lockWasHeldDuringPubGet = _cache.isLockHeld;
  }
}

class FakeFeatureFlags implements FeatureFlags {
  const FakeFeatureFlags({required this.allFeatures});

  @override
  final List<FakeFeature> allFeatures;

  @override
  bool isEnabled(Feature feature) => (feature as FakeFeature).enabled;

  // Queried by getBuildInfo.
  @override
  bool get isHcppEnabled => false;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTerminal extends Fake implements AnsiTerminal {
  FakeTerminal({this.stdinHasTerminal = true, this.supportsColor = false});

  @override
  final bool stdinHasTerminal;

  @override
  final bool supportsColor;

  @override
  bool get isCliAnimationEnabled => supportsColor;

  @override
  bool usesTerminalUi = true;

  @override
  bool singleCharMode = false;

  @override
  Stream<String> get keystrokes => const Stream<String>.empty();

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger? logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    return '1';
  }
}

class DummyMachineFlutterCommand extends DummyFlutterCommand {
  DummyMachineFlutterCommand({required super.toolContext, super.deviceManager})
    : super(name: 'dummy') {
    CommonOptions.machine.addTo(argParser);
  }
}

class DummyHcppFlutterCommand extends DummyFlutterCommand {
  DummyHcppFlutterCommand({required super.toolContext}) : super(name: 'dummy') {
    DebuggingOptionDescriptors.enableHcpp.addTo(argParser);
  }
}

class DummyDeprecatedJsInteropFlutterCommand extends DummyFlutterCommand {
  DummyDeprecatedJsInteropFlutterCommand({required super.toolContext}) : super(name: 'dummy') {
    WebOptions.deprecatedJsInterop.addTo(argParser);
  }
}

class DummyAllBuildOptionsFlutterCommand extends DummyFlutterCommand {
  DummyAllBuildOptionsFlutterCommand({required super.toolContext}) : super(name: 'dummy') {
    registerOptionBundle(const AndroidGradleOptionsBundle());
    argParser.addDescriptors(const <OptionDescriptor<Object?>>[
      BuildInfoOptions.trackWidgetCreation,
      CommonOptions.treeShakeIcons,
      BuildInfoOptions.extraFrontEndOptions,
      BuildInfoOptions.extraGenSnapshotOptions,
    ]);
  }
}

class _DummyOverriddenArgParserCommand extends FlutterCommand {
  _DummyOverriddenArgParserCommand({required super.toolContext}) {
    registerOptionBundle(const FilesystemOptionsBundle());
    DebuggingOptionDescriptors.ipv6.addTo(argParser);
    final copy = ArgParser(
      allowTrailingOptions: argParser.allowTrailingOptions,
      usageLineLength: argParser.usageLineLength,
    );
    for (final MapEntry<String, Option> entry in argParser.options.entries) {
      final Option option = entry.value;
      if (option.isFlag) {
        copy.addFlag(
          entry.key,
          abbr: option.abbr,
          help: option.help,
          defaultsTo: option.defaultsTo as bool?,
          negatable: option.negatable!,
          hide: option.hide,
        );
      } else if (option.isSingle) {
        copy.addOption(
          entry.key,
          abbr: option.abbr,
          help: option.help,
          valueHelp: option.valueHelp,
          defaultsTo: option.defaultsTo as String?,
          hide: option.hide,
        );
      } else if (option.isMultiple) {
        copy.addMultiOption(
          entry.key,
          abbr: option.abbr,
          help: option.help,
          valueHelp: option.valueHelp,
          defaultsTo: option.defaultsTo as Iterable<String>?,
          splitCommas: option.splitCommas,
          hide: option.hide,
        );
      }
    }
    _overriddenArgParser = copy;
  }

  ArgParser? _overriddenArgParser;

  @override
  ArgParser get argParser => _overriddenArgParser ?? super.argParser;

  @override
  String get description => 'does nothing';

  @override
  String get name => 'dummy';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.success();
}
