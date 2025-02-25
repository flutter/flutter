// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/run.dart' show RunCommand;
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/pre_run_validator.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/testing.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/fakes.dart';
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
    late Logger logger;
    late FakeProcessManager processManager;
    late PreRunValidator preRunValidator;

    setUpAll(() {
      Cache.flutterRoot = '/path/to/sdk/flutter';
    });

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
      preRunValidator = PreRunValidator(fileSystem: fileSystem);
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    tearDown(() {
      Cache.enableLocking();
    });

    testUsingContext('help text contains global options', () {
      final FakeDeprecatedCommand fake = FakeDeprecatedCommand();
      createTestCommandRunner(fake);
      expect(fake.usage, contains('Global options:\n'));
    });

    testUsingContext(
      'honors shouldUpdateCache false',
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
        await flutterCommand.run();

        expect(cache.artifacts, isEmpty);
        expect(flutterCommand.deprecated, isFalse);
        expect(flutterCommand.hidden, isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Cache: () => cache,
      },
    );

    testUsingContext(
      'honors shouldUpdateCache true',
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand(shouldUpdateCache: true);
        await flutterCommand.run();
        // First call for universal, second for the rest
        expect(cache.artifacts, <Set<DevelopmentArtifact>>[
          <DevelopmentArtifact>{DevelopmentArtifact.universal},
          <DevelopmentArtifact>{},
        ]);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Cache: () => cache,
      },
    );

    testUsingContext(
      "throws toolExit if flutter_tools source dir doesn't exist",
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
        await expectToolExitLater(
          flutterCommand.run(),
          contains('Flutter SDK installation appears corrupted'),
        );
      },
      overrides: <Type, Generator>{
        Cache: () => cache,
        FileSystem: () => fileSystem,
        PreRunValidator: () => preRunValidator,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'deprecated command should warn',
      () async {
        final FakeDeprecatedCommand flutterCommand = FakeDeprecatedCommand();
        final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
        await runner.run(<String>['deprecated']);

        expect(
          testLogger.warningText,
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
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'uses the error handling file system',
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
          commandFunction: () async {
            expect(globals.fs, isA<ErrorHandlingFileSystem>());
            return const FlutterCommandResult(ExitStatus.success);
          },
        );
        await flutterCommand.run();
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'finds the target file with default values',
      () async {
        globals.fs.file('lib/main.dart').createSync(recursive: true);
        final FakeTargetCommand fakeTargetCommand = FakeTargetCommand();
        final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);
        await runner.run(<String>['test']);

        expect(fakeTargetCommand.cachedTargetFile, 'lib/main.dart');
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'finds the target file with specified value',
      () async {
        globals.fs.file('lib/foo.dart').createSync(recursive: true);
        final FakeTargetCommand fakeTargetCommand = FakeTargetCommand();
        final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);
        await runner.run(<String>['test', '-t', 'lib/foo.dart']);

        expect(fakeTargetCommand.cachedTargetFile, 'lib/foo.dart');
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'throws tool exit if specified file does not exist',
      () async {
        final FakeTargetCommand fakeTargetCommand = FakeTargetCommand();
        final CommandRunner<void> runner = createTestCommandRunner(fakeTargetCommand);

        expect(() async => runner.run(<String>['test', '-t', 'lib/foo.dart']), throwsToolExit());
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    @isTest
    void testUsingCommandContext(String testName, dynamic Function() testBody) {
      testUsingContext(
        testName,
        testBody,
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessInfo: () => processInfo,
          ProcessManager: () => processManager,
          SystemClock: () => clock,
          Analytics: () => fakeAnalytics,
        },
      );
    }

    testUsingCommandContext('reports command that results in success', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.success);
        },
      );
      await flutterCommand.run();

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.flutterCommandResult(
            commandPath: 'dummy',
            result: 'success',
            maxRss: 10,
            commandHasTerminal: false,
          ),
        ),
      );
    });

    testUsingCommandContext('reports command that results in warning', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          return const FlutterCommandResult(ExitStatus.warning);
        },
      );
      await flutterCommand.run();

      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.flutterCommandResult(
            commandPath: 'dummy',
            result: 'warning',
            maxRss: 10,
            commandHasTerminal: false,
          ),
        ),
      );
    });

    testUsingCommandContext('reports command that results in error', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          throwToolExit('fail');
        },
      );
      await expectLater(() => flutterCommand.run(), throwsToolExit());
      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.flutterCommandResult(
            commandPath: 'dummy',
            result: 'fail',
            maxRss: 10,
            commandHasTerminal: false,
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

    testUsingContext(
      'devToolsServerAddress returns parsed uri',
      () async {
        final DummyFlutterCommand command =
            DummyFlutterCommand()..addDevToolsOptions(verboseHelp: false);
        await createTestCommandRunner(command).run(<String>[
          'dummy',
          '--${FlutterCommand.kDevToolsServerAddress}',
          'http://127.0.0.1:9105',
        ]);
        expect(command.devToolsServerAddress.toString(), equals('http://127.0.0.1:9105'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'devToolsServerAddress returns null for bad input',
      () async {
        final DummyFlutterCommand command =
            DummyFlutterCommand()..addDevToolsOptions(verboseHelp: false);
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
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

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

      testUsingContext(
        'reports command that is killed',
        () async {
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
              throw UnsupportedError('Unreachable');
            },
          );

          unawaited(flutterCommand.run());
          signalController.add(mockSignal);
          await completer.future;

          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.flutterCommandResult(
                commandPath: 'dummy',
                result: 'killed',
                maxRss: 10,
                commandHasTerminal: false,
              ),
            ),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => processManager,
          ProcessInfo: () => processInfo,
          Signals:
              () => FakeSignals(
                subForSigTerm: signalUnderTest,
                exitSignals: <ProcessSignal>[signalUnderTest],
              ),
          SystemClock: () => clock,
          Analytics: () => fakeAnalytics,
        },
      );

      testUsingContext(
        'command release lock on kill signal',
        () async {
          clock.times = <int>[1000, 2000];
          final Completer<void> completer = Completer<void>();
          setExitFunctionForTests((int exitCode) {
            expect(exitCode, 0);
            restoreExitFunction();
            completer.complete();
          });
          final Completer<void> checkLockCompleter = Completer<void>();
          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
            commandFunction: () async {
              await globals.cache.lock();
              checkLockCompleter.complete();
              final Completer<void> c = Completer<void>();
              await c.future;
              throw UnsupportedError('Unreachable');
            },
          );

          unawaited(flutterCommand.run());
          await checkLockCompleter.future;

          globals.cache.checkLockAcquired();

          signalController.add(mockSignal);
          await completer.future;
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => processManager,
          ProcessInfo: () => processInfo,
          Signals:
              () => FakeSignals(
                subForSigTerm: signalUnderTest,
                exitSignals: <ProcessSignal>[signalUnderTest],
              ),
        },
      );
    });

    testUsingCommandContext('report execution timing by default', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
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

    testUsingCommandContext('no timing report without usagePath', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(noUsagePath: true);
      await flutterCommand.run();

      int timingEventCounts = 0;
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

    testUsingCommandContext('report additional FlutterCommandResult data', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final FlutterCommandResult commandResult = FlutterCommandResult(
        ExitStatus.success,
        // nulls should be cleaned up.
        timingLabelParts: <String?>['blah1', 'blah2', null, 'blah3'],
        endTimeOverride: DateTime.fromMillisecondsSinceEpoch(1500),
      );

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async => commandResult,
      );
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

    testUsingCommandContext('report failed execution timing too', () async {
      // Crash if called a third time which is unexpected.
      clock.times = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          throwToolExit('fail');
        },
      );

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

    testUsingContext(
      'use packagesPath to generate BuildInfo',
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand(packagesPath: 'foo');
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.packageConfigPath, 'foo');
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'use fileSystemScheme to generate BuildInfo',
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand(fileSystemScheme: 'foo');
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.fileSystemScheme, 'foo');
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'use fileSystemRoots to generate BuildInfo',
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
          fileSystemRoots: <String>['foo', 'bar'],
        );
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.fileSystemRoots, <String>['foo', 'bar']);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'includes initializeFromDill in BuildInfo',
      () async {
        final DummyFlutterCommand flutterCommand =
            DummyFlutterCommand()..usesInitializeFromDillOption(hide: false);
        final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
        await runner.run(<String>['dummy', '--initialize-from-dill=/foo/bar.dill']);
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.initializeFromDill, '/foo/bar.dill');
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'includes assumeInitializeFromDillUpToDate in BuildInfo',
      () async {
        final DummyFlutterCommand flutterCommand =
            DummyFlutterCommand()..usesInitializeFromDillOption(hide: false);
        final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
        await runner.run(<String>['dummy', '--assume-initialize-from-dill-up-to-date']);
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.assumeInitializeFromDillUpToDate, isTrue);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'unsets assumeInitializeFromDillUpToDate in BuildInfo when disabled',
      () async {
        final DummyFlutterCommand flutterCommand =
            DummyFlutterCommand()..usesInitializeFromDillOption(hide: false);
        final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
        await runner.run(<String>['dummy', '--no-assume-initialize-from-dill-up-to-date']);
        final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
          forcedBuildMode: BuildMode.debug,
        );
        expect(buildInfo.assumeInitializeFromDillUpToDate, isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'sets useLocalCanvasKit in BuildInfo',
      () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
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
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'dds options',
      () async {
        final FakeDdsCommand ddsCommand = FakeDdsCommand();
        final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
        await runner.run(<String>['test', '--dds-port=1']);
        expect(ddsCommand.enableDds, isTrue);
        expect(ddsCommand.ddsPort, 1);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'dds options --dds',
      () async {
        final FakeDdsCommand ddsCommand = FakeDdsCommand();
        final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
        await runner.run(<String>['test', '--dds']);
        expect(ddsCommand.enableDds, isTrue);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'dds options --no-dds',
      () async {
        final FakeDdsCommand ddsCommand = FakeDdsCommand();
        final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
        await runner.run(<String>['test', '--no-dds']);
        expect(ddsCommand.enableDds, isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'dds options --disable-dds',
      () async {
        final FakeDdsCommand ddsCommand = FakeDdsCommand();
        final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
        await runner.run(<String>['test', '--disable-dds']);
        expect(ddsCommand.enableDds, isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'dds options --no-disable-dds',
      () async {
        final FakeDdsCommand ddsCommand = FakeDdsCommand();
        final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
        await runner.run(<String>['test', '--no-disable-dds']);
        expect(ddsCommand.enableDds, isTrue);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'dds options --dds --disable-dds',
      () async {
        final FakeDdsCommand ddsCommand = FakeDdsCommand();
        final CommandRunner<void> runner = createTestCommandRunner(ddsCommand);
        await runner.run(<String>['test', '--dds', '--disable-dds']);
        expect(() => ddsCommand.enableDds, throwsToolExit());
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );

    group('findTargetDevice', () {
      final FakeDevice device1 = FakeDevice('device1', 'device1');
      final FakeDevice device2 = FakeDevice('device2', 'device2');

      testUsingContext('no device found', () async {
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
        final Device? device = await flutterCommand.findTargetDevice();
        expect(device, isNull);
      });

      testUsingContext('finds single device', () async {
        testDeviceManager.addAttachedDevice(device1);
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
        final Device? device = await flutterCommand.findTargetDevice();
        expect(device, device1);
      });

      testUsingContext('finds multiple devices', () async {
        testDeviceManager.addAttachedDevice(device1);
        testDeviceManager.addAttachedDevice(device2);
        testDeviceManager.specifiedDeviceId = 'all';
        final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
        final Device? device = await flutterCommand.findTargetDevice();
        expect(device, isNull);
        expect(testLogger.statusText, contains(UserMessages().flutterSpecifyDevice));
      });
    });

    group('--dart-define-from-file', () {
      late FlutterCommand dummyCommand;
      late CommandRunner<void> dummyCommandRunner;

      setUp(() {
        dummyCommand = DummyFlutterCommand()..usesDartDefineOption();
        dummyCommandRunner = createTestCommandRunner(dummyCommand);
      });

      testUsingContext(
        'parses values from JSON files and includes them in defines list',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'has values with identical keys from --dart-define take precedence',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'correctly parses a valid env file',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'throws a ToolExit when the provided .env file is malformed',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'throws a ToolExit when .env file contains a multiline value',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'works with mixed file formats',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
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
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'throws a ToolExit when the argued path points to a directory',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'throws a ToolExit when the given JSON file is malformed',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );

      testUsingContext(
        'throws a ToolExit when the provided file does not exist',
        () async {
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
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          Logger: () => logger,
          FileSystemUtils: () => fileSystemUtils,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );
    });

    group('--flavor', () {
      late FileSystem fileSystem;

      setUp(() {
        fileSystem = MemoryFileSystem.test();
      });

      testUsingContext(
        'CLI option overrides default flavor from manifest',
        () async {
          final File pubspec = fileSystem.file('pubspec.yaml');
          await pubspec.create();
          await pubspec.writeAsString('''
name: test
flutter:
  default-flavor: foo
        ''');

          final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );
          expect(buildInfo.flavor, 'foo');
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.empty(),
        },
      );

      testUsingContext(
        'tool loads default flavor from manifest, but cli overrides',
        () async {
          final File pubspec = fileSystem.file('pubspec.yaml');
          await pubspec.create();
          await pubspec.writeAsString('''
name: test
flutter:
  default-flavor: foo
        ''');

          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
            commandFunction: () async {
              return FlutterCommandResult.success();
            },
          );
          flutterCommand.usesFlavorOption();
          final CommandRunner<void> runner = createTestCommandRunner(flutterCommand);
          await runner.run(<String>['dummy', '--flavor', 'bar']);
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );
          expect(buildInfo.flavor, 'bar');
        },
        overrides: <Type, Generator>{
          FileSystem: () => fileSystem,
          ProcessManager: () => FakeProcessManager.empty(),
        },
      );
    });

    group('Flutter version', () {
      for (final String dartDefine in FlutterCommand.flutterVersionDartDefines) {
        testUsingContext(
          "tool exits when $dartDefine is already set in user's environment",
          () async {
            final CommandRunner<void> runner = createTestCommandRunner(
              _TestRunCommandThatOnlyValidates(),
            );

            await expectLater(
              runner.run(<String>['run', '--no-pub', '--no-hot']),
              throwsToolExit(
                message:
                    '$dartDefine is used by the framework and cannot be set in the environment. '
                    'Use FlutterVersion to access it in Flutter code',
              ),
            );
          },
          overrides: <Type, Generator>{
            DeviceManager:
                () => FakeDeviceManager()..attachedDevices = <Device>[FakeDevice('name', 'id')],
            Platform:
                () => FakePlatform(environment: <String, String>{dartDefine: 'I was already set'}),
            Cache: () => Cache.test(processManager: FakeProcessManager.any()),
            FileSystem: () {
              return MemoryFileSystem.test()
                ..file('lib/main.dart').createSync(recursive: true)
                ..file('pubspec.yaml').createSync()
                ..file('.packages').createSync();
            },
            ProcessManager: () => FakeProcessManager.any(),
            FlutterVersion: () => FakeFlutterVersion(),
          },
        );

        testUsingContext(
          'tool exits when $dartDefine is set in --dart-define or --dart-define-from-file',
          () async {
            final CommandRunner<void> runner = createTestCommandRunner(
              _TestRunCommandThatOnlyValidates(),
            );

            expect(
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

            expect(
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
          },
          overrides: <Type, Generator>{
            DeviceManager:
                () => FakeDeviceManager()..attachedDevices = <Device>[FakeDevice('name', 'id')],
            Platform: () => FakePlatform(),
            Cache: () => Cache.test(processManager: FakeProcessManager.any()),
            FileSystem: () {
              final MemoryFileSystem fileSystem = MemoryFileSystem.test();
              fileSystem.file('lib/main.dart').createSync(recursive: true);
              fileSystem.file('pubspec.yaml').createSync();
              fileSystem.file('.packages').createSync();
              fileSystem.file('config.json')
                ..createSync()
                ..writeAsStringSync('{"$dartDefine": "AlreadySet"}');
              return fileSystem;
            },
            ProcessManager: () => FakeProcessManager.any(),
            FlutterVersion: () => FakeFlutterVersion(),
          },
        );
      }

      testUsingContext(
        'FLUTTER_VERSION is set in dartDefines',
        () async {
          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(packagesPath: 'foo');
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );
          expect(buildInfo.dartDefines, contains('FLUTTER_VERSION=0.0.0'));
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          FlutterVersion: () => FakeFlutterVersion(),
        },
      );

      testUsingContext(
        'FLUTTER_CHANNEL is set in dartDefines',
        () async {
          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(packagesPath: 'foo');
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );

          expect(buildInfo.dartDefines, contains('FLUTTER_CHANNEL=master'));
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          FlutterVersion: () => FakeFlutterVersion(),
        },
      );

      testUsingContext(
        'FLUTTER_GIT_URL is set in dartDefines',
        () async {
          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(packagesPath: 'foo');
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );

          expect(
            buildInfo.dartDefines,
            contains('FLUTTER_GIT_URL=https://github.com/flutter/flutter.git'),
          );
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          FlutterVersion: () => FakeFlutterVersion(),
        },
      );

      testUsingContext(
        'FLUTTER_FRAMEWORK_REVISION is set in dartDefines',
        () async {
          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(packagesPath: 'foo');
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );

          expect(buildInfo.dartDefines, contains('FLUTTER_FRAMEWORK_REVISION=11111'));
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          FlutterVersion: () => FakeFlutterVersion(),
        },
      );

      testUsingContext(
        'FLUTTER_ENGINE_REVISION is set in dartDefines',
        () async {
          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(packagesPath: 'foo');
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );

          expect(buildInfo.dartDefines, contains('FLUTTER_ENGINE_REVISION=abcde'));
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          FlutterVersion: () => FakeFlutterVersion(),
        },
      );

      testUsingContext(
        'FLUTTER_DART_VERSION is set in dartDefines',
        () async {
          final DummyFlutterCommand flutterCommand = DummyFlutterCommand(packagesPath: 'foo');
          final BuildInfo buildInfo = await flutterCommand.getBuildInfo(
            forcedBuildMode: BuildMode.debug,
          );

          expect(buildInfo.dartDefines, contains('FLUTTER_DART_VERSION=12'));
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          FlutterVersion: () => FakeFlutterVersion(),
        },
      );
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

class FakeTargetCommand extends FlutterCommand {
  FakeTargetCommand() {
    usesTargetOption();
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
  FakeDdsCommand() {
    addDdsOptions(verboseHelp: false);
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

class _TestRunCommandThatOnlyValidates extends RunCommand {
  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }

  @override
  bool get shouldRunPub => false;
}
