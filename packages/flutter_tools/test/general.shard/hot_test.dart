// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import '../src/package_config.dart';
import '../src/throwing_pub.dart';
import 'hot_shared.dart';
import 'resident_runner_helpers.dart' show createHotRunner;

void main() {
  group('validateReloadReport', () {
    testWithoutContext('invalid', () {
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{},
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{'notices': <Map<String, dynamic>>[]},
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{
              'notices': <String, dynamic>{'message': 'error'},
            },
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{'notices': <Map<String, dynamic>>[]},
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{
              'notices': <Map<String, dynamic>>[
                <String, dynamic>{'message': false},
              ],
            },
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{
              'notices': <Map<String, dynamic>>[
                <String, dynamic>{
                  'message': <String>['error'],
                },
              ],
            },
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{
              'notices': <Map<String, dynamic>>[
                <String, dynamic>{'message': 'error'},
                <String, dynamic>{
                  'message': <String>['error'],
                },
              ],
            },
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{
            'type': 'ReloadReport',
            'success': false,
            'details': <String, dynamic>{
              'notices': <Map<String, dynamic>>[
                <String, dynamic>{'message': 'error'},
              ],
            },
          }),
        ),
        false,
      );
      expect(
        HotRunner.validateReloadReport(
          vm_service.ReloadReport.parse(<String, dynamic>{'type': 'ReloadReport', 'success': true}),
        ),
        true,
      );
    });

    testWithoutContext('ReasonForCancelling toString has a hint for specific errors', () {
      final reasonForCancelling = ReasonForCancelling(message: 'Const class cannot remove fields');

      expect(reasonForCancelling.toString(), contains('Try performing a hot restart instead.'));
    });
  });

  group('hotRestart', () {
    final residentCompiler = FakeResidentCompiler();
    late MemoryFileSystem fileSystem;
    late FakeAnalytics fakeAnalytics;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    group('fails to setup', () {
      late TestHotRunnerConfig failingTestingConfig;
      setUp(() {
        failingTestingConfig = TestHotRunnerConfig(
          successfulHotRestartSetup: false,
          successfulHotReloadSetup: false,
        );
      });

      testUsingContext(
        'setupHotRestart function fails',
        () async {
          fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: my_app
''');
          writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
          final device = FakeDevice();
          final devices = <FlutterDevice>[FakeFlutterDevice(device)];
          final OperationResult result = await createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            analytics: fakeAnalytics,
            hotRunnerConfig: failingTestingConfig,
          ).restart(fullRestart: true);
          expect(result.isOk, false);
          expect(result.message, 'setupHotRestart failed');
          expect(failingTestingConfig.updateDevFSCompleteCalled, false);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
          Pub: ThrowingPub.new,
        },
      );

      testUsingContext(
        'setupHotReload function fails',
        () async {
          fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: my_app
''');
          writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
          final device = FakeDevice();
          final fakeFlutterDevice = FakeFlutterDevice(device);
          final devices = <FlutterDevice>[fakeFlutterDevice];
          final OperationResult result = await createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            reassembleHelper: (
              List<FlutterDevice?> flutterDevices,
              Map<FlutterDevice?, List<FlutterView>> viewCache,
              void Function(String message)? onSlow,
              String reloadMessage,
            ) async => ReassembleResult(<FlutterView?, FlutterVmService?>{null: null}, false, true),
            analytics: fakeAnalytics,
            hotRunnerConfig: failingTestingConfig,
          ).restart();
          expect(result.isOk, false);
          expect(result.message, 'setupHotReload failed');
          expect(failingTestingConfig.updateDevFSCompleteCalled, false);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
          Pub: ThrowingPub.new,
        },
      );
    });

    group('shutdown hook tests', () {
      late TestHotRunnerConfig shutdownTestingConfig;

      setUp(() {
        shutdownTestingConfig = TestHotRunnerConfig();
      });

      testUsingContext(
        'shutdown hook called after signal',
        () async {
          writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
          final device = FakeDevice();
          final devices = <FlutterDevice>[
            FlutterDevice(
              device,
              toolContext: DelegatingToolContext(artifacts: Artifacts.test()),
              targetPlatform: .unsupported,
              generator: residentCompiler,
              buildInfo: BuildInfo.debug,
              developmentShaderCompiler: const FakeShaderCompiler(),
            ),
          ];
          await createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            analytics: fakeAnalytics,
            hotRunnerConfig: shutdownTestingConfig,
          ).cleanupAfterSignal();
          expect(shutdownTestingConfig.shutdownHookCalled, true);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      testUsingContext(
        'shutdown hook called after app stop',
        () async {
          writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
          final device = FakeDevice();
          final devices = <FlutterDevice>[
            FlutterDevice(
              device,
              toolContext: DelegatingToolContext(artifacts: Artifacts.test()),
              targetPlatform: .unsupported,
              generator: residentCompiler,
              buildInfo: BuildInfo.debug,
              developmentShaderCompiler: const FakeShaderCompiler(),
            ),
          ];
          await createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            analytics: fakeAnalytics,
            hotRunnerConfig: shutdownTestingConfig,
          ).preExit();
          expect(shutdownTestingConfig.shutdownHookCalled, true);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    });

    group('successful hot restart', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(successfulHotRestartSetup: true);
      });
      testUsingContext(
        'correctly tracks time spent for analytics for hot restart',
        () async {
          final device = FakeDevice();
          final fakeFlutterDevice = FakeFlutterDevice(device);
          final devices = <FlutterDevice>[fakeFlutterDevice];

          fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
            success: true,
            invalidatedSourcesCount: 2,
            syncedBytes: 4,
            scannedSourcesCount: 8,
            compileDuration: const Duration(seconds: 16),
            transferDuration: const Duration(seconds: 32),
          );

          final fakeStopwatchFactory = FakeStopwatchFactory(
            stopwatches: <String, Stopwatch>{
              'fullRestartHelper': FakeStopwatch()..elapsed = const Duration(seconds: 64),
              'updateDevFS': FakeStopwatch()..elapsed = const Duration(seconds: 128),
            },
          );

          (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

          final OperationResult result = await createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            stopwatchFactory: fakeStopwatchFactory,
            analytics: fakeAnalytics,
            hotRunnerConfig: testingConfig,
          ).restart(fullRestart: true);

          expect(result.isOk, true);

          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.hotRunnerInfo(
                label: 'restart',
                targetPlatform: 'flutter-tester',
                sdkName: 'Tester',
                emulator: false,
                fullRestart: true,
                syncedBytes: 4,
                invalidatedSourcesCount: 2,
                transferTimeInMs: 32000,
                overallTimeInMs: 64000,
                compileTimeInMs: 16000,
                findInvalidatedTimeInMs: 128000,
                scannedSourcesCount: 8,
              ),
            ),
          );
          expect(testingConfig.updateDevFSCompleteCalled, true);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    });

    group('successful hot reload', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(successfulHotReloadSetup: true);
      });
      testUsingContext(
        'correctly tracks time spent for analytics for hot reload',
        () async {
          final device = FakeDevice();
          final fakeFlutterDevice = FakeFlutterDevice(device);
          final devices = <FlutterDevice>[fakeFlutterDevice];

          fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
            success: true,
            invalidatedSourcesCount: 6,
            syncedBytes: 8,
            scannedSourcesCount: 16,
            compileDuration: const Duration(seconds: 16),
            transferDuration: const Duration(seconds: 32),
          );

          final fakeStopwatchFactory = FakeStopwatchFactory(
            stopwatches: <String, Stopwatch>{
              'updateDevFS': FakeStopwatch()..elapsed = const Duration(seconds: 64),
              'reloadSources:reload': FakeStopwatch()..elapsed = const Duration(seconds: 128),
              'reloadSources:reassemble': FakeStopwatch()..elapsed = const Duration(seconds: 256),
              'reloadSources:vm': FakeStopwatch()..elapsed = const Duration(seconds: 512),
            },
          );

          (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

          final OperationResult result = await createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            stopwatchFactory: fakeStopwatchFactory,
            analytics: fakeAnalytics,
            hotRunnerConfig: testingConfig,
            reloadSourcesHelper:
                (
                  HotRunner hotRunner,
                  List<FlutterDevice?> flutterDevices,
                  bool? pause,
                  Map<String, dynamic> firstReloadDetails,
                  String? targetPlatform,
                  String? sdkName,
                  bool? emulator,
                  String? reason,
                  Analytics? analytics,
                ) async {
                  firstReloadDetails['finalLibraryCount'] = 2;
                  firstReloadDetails['receivedLibraryCount'] = 3;
                  firstReloadDetails['receivedClassesCount'] = 4;
                  firstReloadDetails['receivedProceduresCount'] = 5;
                  return OperationResult.ok;
                },
            reassembleHelper: (
              List<FlutterDevice?> flutterDevices,
              Map<FlutterDevice?, List<FlutterView>> viewCache,
              void Function(String message)? onSlow,
              String reloadMessage,
            ) async => ReassembleResult(<FlutterView?, FlutterVmService?>{null: null}, false, true),
          ).restart();

          expect(result.isOk, true);
          expect(
            fakeAnalytics.sentEvents,
            contains(
              Event.hotRunnerInfo(
                label: 'reload',
                targetPlatform: 'flutter-tester',
                sdkName: 'Tester',
                emulator: false,
                fullRestart: false,
                finalLibraryCount: 2,
                syncedLibraryCount: 3,
                syncedClassesCount: 4,
                syncedProceduresCount: 5,
                syncedBytes: 8,
                invalidatedSourcesCount: 6,
                transferTimeInMs: 32000,
                overallTimeInMs: 128000,
                compileTimeInMs: 16000,
                findInvalidatedTimeInMs: 64000,
                scannedSourcesCount: 16,
                reassembleTimeInMs: 256000,
                reloadVMTimeInMs: 512000,
              ),
            ),
          );
          expect(testingConfig.updateDevFSCompleteCalled, true);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    });

    group('hot restart that failed to sync dev fs', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(successfulHotRestartSetup: true);
      });
      testUsingContext(
        'still calls the devfs complete callback',
        () async {
          final device = FakeDevice();
          final fakeFlutterDevice = FakeFlutterDevice(device);
          final devices = <FlutterDevice>[fakeFlutterDevice];
          fakeFlutterDevice.updateDevFSReportCallback = () async =>
              throw Exception('updateDevFS failed');

          final HotRunner runner = createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            analytics: fakeAnalytics,
            hotRunnerConfig: testingConfig,
          );

          await expectLater(
            runner.restart(fullRestart: true),
            throwsA(
              isA<Exception>().having(
                (Exception e) => e.toString(),
                'message',
                'Exception: updateDevFS failed',
              ),
            ),
          );
          expect(testingConfig.updateDevFSCompleteCalled, true);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    });

    group('hot reload that failed to sync dev fs', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(successfulHotReloadSetup: true);
      });
      testUsingContext(
        'still calls the devfs complete callback',
        () async {
          final device = FakeDevice();
          final fakeFlutterDevice = FakeFlutterDevice(device);
          final devices = <FlutterDevice>[fakeFlutterDevice];
          fakeFlutterDevice.updateDevFSReportCallback = () async =>
              throw Exception('updateDevFS failed');

          final HotRunner runner = createHotRunner(
            devices,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
            target: 'main.dart',
            analytics: fakeAnalytics,
            hotRunnerConfig: testingConfig,
          );

          await expectLater(
            runner.restart(),
            throwsA(
              isA<Exception>().having(
                (Exception e) => e.toString(),
                'message',
                'Exception: updateDevFS failed',
              ),
            ),
          );
          expect(testingConfig.updateDevFSCompleteCalled, true);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.test(),
          FileSystem: () => fileSystem,
          Platform: () => FakePlatform(),
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    });
  });

  group('hot attach', () {
    late MemoryFileSystem fileSystem;
    late FakeAnalytics fakeAnalytics;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    testUsingContext(
      'Exits with code 2 when HttpException is thrown '
      'during VM service connection',
      () async {
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');

        final residentCompiler = FakeResidentCompiler();
        final device = FakeDevice();
        final devices = <FlutterDevice>[
          TestFlutterDevice(
            device: device,
            generator: residentCompiler,
            exception: const HttpException(
              'Connection closed before full header was received, '
              'uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws',
            ),
          ),
        ];

        final int exitCode = await createHotRunner(
          devices,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          target: 'main.dart',
          analytics: fakeAnalytics,
          hotRunnerConfig: TestHotRunnerConfig(),
        ).attach(needsFullRestart: false);
        expect(exitCode, 2);
      },
      overrides: <Type, Generator>{
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });

  group('hot cleanupAtFinish()', () {
    late MemoryFileSystem fileSystem;
    late FakeAnalytics fakeAnalytics;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    testUsingContext('disposes each device', () async {
      final device1 = FakeDevice();
      final device2 = FakeDevice();
      final flutterDevice1 = FakeFlutterDevice(device1);
      final flutterDevice2 = FakeFlutterDevice(device2);

      final devices = <FlutterDevice>[flutterDevice1, flutterDevice2];

      await createHotRunner(
        devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      ).cleanupAtFinish();

      expect(device1.disposed, true);
      expect(device2.disposed, true);

      expect(flutterDevice1.stoppedEchoingDeviceLog, true);
      expect(flutterDevice2.stoppedEchoingDeviceLog, true);
    });
  });

  group('deferred service protocol connection', () {
    testWithoutContext(
      'runs inverted startup sequence, wires callbacks, and propagates reloadSources errors',
      () async {
        final fs = MemoryFileSystem.test();
        fs.file('lib/main.dart').createSync(recursive: true);
        fs.file('pubspec.yaml').writeAsStringSync('name: test_app\n');
        writePackageConfigFiles(directory: fs.currentDirectory, mainLibName: 'test_app');

        final logger = BufferLogger.test();
        final events = <String>[];
        final fakeGenerator = _RecordingResidentCompiler(events);
        final deferredDevice = _DeferredFlutterDevice(
          FakeDevice(),
          events: events,
          generator: fakeGenerator,
        );
        final buildSystem = _RecordingBuildSystem(events);
        final toolContext = FakeToolContext(
          artifacts: Artifacts.test(),
          cache: FakeCache(fileSystem: fs, flutterRoot: '/flutter'),
          fs: fs,
          logger: logger,
        );
        final File vmServiceOutFile = fs.file('vmservice.txt');
        final HotRunner runner = createHotRunner(
          <FlutterDevice>[deferredDevice],
          buildSystem: buildSystem,
          debuggingOptions: DebuggingOptions.enabled(
            const BuildInfo(
              BuildMode.debug,
              '',
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
            vmserviceOutFile: vmServiceOutFile.path,
          ),
          target: 'lib/main.dart',
          toolContext: toolContext,
        );

        final connectionInfoCompleter = Completer<DebugConnectionInfo>();
        final appStartedCompleter = Completer<void>();
        final Future<int> runFuture = runner.run(
          connectionInfoCompleter: connectionInfoCompleter,
          appStartedCompleter: appStartedCompleter,
        );

        await appStartedCompleter.future;

        expect(events, <String>[
          'prepareHotLaunch',
          'runSourceGenerators',
          'updateDevFS',
          'onInitialDevFSUpdate',
          'generator.accept',
          'runHot',
          'attachDeferredConnection',
        ]);
        expect(deferredDevice.capturedReloadSources, isNotNull);

        final connectionInfo = DebugConnectionInfo(
          httpUri: Uri.parse('http://127.0.0.1:8181/'),
          wsUri: Uri.parse('ws://127.0.0.1:8181/ws'),
        );
        deferredDevice.capturedOnConnected!(connectionInfo);
        expect(await connectionInfoCompleter.future, connectionInfo);
        expect(vmServiceOutFile.existsSync(), true);
        expect(vmServiceOutFile.readAsStringSync(), 'ws://127.0.0.1:8181/ws');

        // Reload failure through the reloadSources callback surfaces an RPCError.
        deferredDevice.nextUpdateReport = UpdateFSReport();
        await expectLater(
          deferredDevice.capturedReloadSources!('isolate/1'),
          throwsA(
            isA<vm_service.RPCError>()
                .having(
                  (vm_service.RPCError e) => e.callingMethod,
                  'callingMethod',
                  'Unable to reload sources',
                )
                .having(
                  (vm_service.RPCError e) => e.code,
                  'code',
                  vm_service.RPCErrorKind.kInternalError.code,
                ),
          ),
        );

        // Disconnecting finishes waitForAppToFinish cleanly.
        deferredDevice.capturedOnDisconnected!();
        expect(await runFuture, 0);
        expect(deferredDevice.exitAppsCount, 1);
        expect(logger.statusText, contains('Lost connection to device.'));
      },
    );

    testWithoutContext('throws ToolExit when multiple devices include a deferred device', () async {
      final fs = MemoryFileSystem.test();
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(),
        cache: FakeCache(fileSystem: fs, flutterRoot: '/flutter'),
        fs: fs,
      );
      final deferredDevice = _DeferredFlutterDevice(FakeDevice(), events: <String>[]);
      final nativeDevice = FakeFlutterDevice(FakeDevice());
      final HotRunner runner = createHotRunner(
        <FlutterDevice>[deferredDevice, nativeDevice],
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        stayResident: false,
        target: 'lib/main.dart',
        toolContext: toolContext,
      );

      await expectLater(
        runner.run(),
        throwsToolExit(
          message:
              'Running on multiple devices is not supported when a device requires a '
              'deferred service protocol connection.',
        ),
      );
    });
  });
}

class _RecordingBuildSystem extends Fake implements BuildSystem {
  _RecordingBuildSystem(this.events);

  final List<String> events;

  @override
  Future<BuildResult> buildIncremental(
    Target target,
    Environment environment,
    BuildResult? previousBuild,
  ) async {
    events.add('runSourceGenerators');
    return BuildResult(success: true);
  }
}

class _RecordingResidentCompiler extends Fake implements ResidentCompiler {
  _RecordingResidentCompiler(this.events);

  final List<String> events;

  @override
  void accept() {
    events.add('generator.accept');
  }

  @override
  Future<CompilerOutput?> reject() async {
    events.add('generator.reject');
    return null;
  }
}

class _DeferredVmService extends Fake implements FlutterVmService {
  @override
  Uri get wsAddress => Uri.parse('ws://127.0.0.1:8181/ws');

  @override
  Uri get httpAddress => Uri.parse('http://127.0.0.1:8181/');
}

class _DeferredFlutterDevice extends FakeFlutterDevice {
  _DeferredFlutterDevice(super.device, {required this.events, ResidentCompiler? generator}) {
    this.generator = generator;
  }

  final List<String> events;
  UpdateFSReport nextUpdateReport = UpdateFSReport(success: true, invalidatedSourcesCount: 1);
  int exitAppsCount = 0;
  ReloadSources? capturedReloadSources;
  void Function(DebugConnectionInfo)? capturedOnConnected;
  void Function()? capturedOnDisconnected;

  @override
  Future<void> exitApps({Duration timeoutDelay = const Duration(seconds: 10)}) async {
    exitAppsCount += 1;
  }

  @override
  final FlutterVmService vmService = _DeferredVmService();

  @override
  bool get defersServiceProtocolConnection => true;

  @override
  Future<void> prepareHotLaunch({required HotRunner hotRunner}) async {
    events.add('prepareHotLaunch');
  }

  @override
  Future<UpdateFSReport> updateDevFS({
    Uri? mainUri,
    String? target,
    AssetBundle? bundle,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String? projectRootPath,
    String? pathToReload,
    required String dillOutputPath,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
  }) async {
    events.add('updateDevFS');
    return nextUpdateReport;
  }

  @override
  void onInitialDevFSUpdate(UpdateFSReport report, {required Analytics analytics}) {
    events.add('onInitialDevFSUpdate');
  }

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    events.add('runHot');
    return 0;
  }

  @override
  void attachDeferredConnection({
    required HotRunner hotRunner,
    required void Function(DebugConnectionInfo) onConnected,
    required void Function() onDisconnected,
    ReloadSources? reloadSources,
  }) {
    events.add('attachDeferredConnection');
    capturedReloadSources = reloadSources;
    capturedOnConnected = onConnected;
    capturedOnDisconnected = onDisconnected;
  }
}
