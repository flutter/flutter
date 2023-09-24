// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/targets/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:native_assets_cli/native_assets_cli.dart' hide BuildMode, Target;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import 'fake_native_assets_build_runner.dart';

void main() {
  group('validateReloadReport', () {
    testUsingContext('invalid', () async {
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{},
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <String, dynamic>{
            'message': 'error',
          },
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': false},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': <String>['error']},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': 'error'},
            <String, dynamic>{'message': <String>['error']},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': 'error'},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': true,
      })), true);
    });

    testWithoutContext('ReasonForCancelling toString has a hint for specific errors', () {
      final ReasonForCancelling reasonForCancelling = ReasonForCancelling(
        message: 'Const class cannot remove fields',
      );

      expect(reasonForCancelling.toString(), contains('Try performing a hot restart instead.'));
    });
  });

  group('hotRestart', () {
    final FakeResidentCompiler residentCompiler = FakeResidentCompiler();
    late FileSystem fileSystem;
    late TestUsage testUsage;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      testUsage = TestUsage();
    });

    group('fails to setup', () {
      late TestHotRunnerConfig failingTestingConfig;
      setUp(() {
        failingTestingConfig = TestHotRunnerConfig(
          successfulHotRestartSetup: false,
          successfulHotReloadSetup: false,
        );
      });

      testUsingContext('setupHotRestart function fails', () async {
        fileSystem.file('.packages')
          ..createSync(recursive: true)
          ..writeAsStringSync('\n');
        final FakeDevice device = FakeDevice();
        final List<FlutterDevice> devices = <FlutterDevice>[
          FlutterDevice(device, generator: residentCompiler, buildInfo: BuildInfo.debug, developmentShaderCompiler: const FakeShaderCompiler())
            ..devFS = FakeDevFs(),
        ];
        final OperationResult result = await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          devtoolsHandler: createNoOpHandler,
        ).restart(fullRestart: true);
        expect(result.isOk, false);
        expect(result.message, 'setupHotRestart failed');
        expect(failingTestingConfig.updateDevFSCompleteCalled, false);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => failingTestingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('setupHotReload function fails', () async {
        fileSystem.file('.packages')
          ..createSync(recursive: true)
          ..writeAsStringSync('\n');
        final FakeDevice device = FakeDevice();
        final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
        final List<FlutterDevice> devices = <FlutterDevice>[
          fakeFlutterDevice,
        ];
        final OperationResult result = await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          devtoolsHandler: createNoOpHandler,
          reassembleHelper: (
            List<FlutterDevice?> flutterDevices,
            Map<FlutterDevice?, List<FlutterView>> viewCache,
            void Function(String message)? onSlow,
            String reloadMessage,
          ) async => ReassembleResult(
              <FlutterView?, FlutterVmService?>{null: null},
              false,
              true,
            ),
        ).restart();
        expect(result.isOk, false);
        expect(result.message, 'setupHotReload failed');
        expect(failingTestingConfig.updateDevFSCompleteCalled, false);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => failingTestingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    group('shutdown hook tests', () {
      late TestHotRunnerConfig shutdownTestingConfig;

      setUp(() {
        shutdownTestingConfig = TestHotRunnerConfig();
      });

      testUsingContext('shutdown hook called after signal', () async {
        fileSystem.file('.packages')
          ..createSync(recursive: true)
          ..writeAsStringSync('\n');
        final FakeDevice device = FakeDevice();
        final List<FlutterDevice> devices = <FlutterDevice>[
          FlutterDevice(device, generator: residentCompiler, buildInfo: BuildInfo.debug, developmentShaderCompiler: const FakeShaderCompiler()),
        ];
        await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
        ).cleanupAfterSignal();
        expect(shutdownTestingConfig.shutdownHookCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => shutdownTestingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('shutdown hook called after app stop', () async {
        fileSystem.file('.packages')
          ..createSync(recursive: true)
          ..writeAsStringSync('\n');
        final FakeDevice device = FakeDevice();
        final List<FlutterDevice> devices = <FlutterDevice>[
          FlutterDevice(device, generator: residentCompiler, buildInfo: BuildInfo.debug, developmentShaderCompiler: const FakeShaderCompiler()),
        ];
        await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
        ).preExit();
        expect(shutdownTestingConfig.shutdownHookCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => shutdownTestingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    group('successful hot restart', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(
          successfulHotRestartSetup: true,
        );
      });
      testUsingContext('correctly tracks time spent for analytics for hot restart', () async {
        final FakeDevice device = FakeDevice();
        final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
        final List<FlutterDevice> devices = <FlutterDevice>[
          fakeFlutterDevice,
        ];

        fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
          success: true,
          invalidatedSourcesCount: 2,
          syncedBytes: 4,
          scannedSourcesCount: 8,
          compileDuration: const Duration(seconds: 16),
          transferDuration: const Duration(seconds: 32),
        );

        final FakeStopwatchFactory fakeStopwatchFactory = FakeStopwatchFactory(
          stopwatches: <String, Stopwatch>{
            'fullRestartHelper': FakeStopwatch()..elapsed = const Duration(seconds: 64),
            'updateDevFS': FakeStopwatch()..elapsed = const Duration(seconds: 128),
          },
        );

        (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

        final OperationResult result = await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          devtoolsHandler: createNoOpHandler,
          stopwatchFactory: fakeStopwatchFactory,
        ).restart(fullRestart: true);

        expect(result.isOk, true);
        expect(testUsage.events, <TestUsageEvent>[
          const TestUsageEvent('hot', 'restart', parameters: CustomDimensions(
            hotEventTargetPlatform: 'flutter-tester',
            hotEventSdkName: 'Tester',
            hotEventEmulator: false,
            hotEventFullRestart: true,
            hotEventOverallTimeInMs: 64000,
            hotEventSyncedBytes: 4,
            hotEventInvalidatedSourcesCount: 2,
            hotEventTransferTimeInMs: 32000,
            hotEventCompileTimeInMs: 16000,
            hotEventFindInvalidatedTimeInMs: 128000,
            hotEventScannedSourcesCount: 8,
          )),
        ]);
        expect(testingConfig.updateDevFSCompleteCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => testingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
        Usage: () => testUsage,
      });
    });

    group('successful hot reload', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(
          successfulHotReloadSetup: true,
        );
      });
      testUsingContext('correctly tracks time spent for analytics for hot reload', () async {
        final FakeDevice device = FakeDevice();
        final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
        final List<FlutterDevice> devices = <FlutterDevice>[
          fakeFlutterDevice,
        ];

        fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
          success: true,
          invalidatedSourcesCount: 6,
          syncedBytes: 8,
          scannedSourcesCount: 16,
          compileDuration: const Duration(seconds: 16),
          transferDuration: const Duration(seconds: 32),
        );

        final FakeStopwatchFactory fakeStopwatchFactory = FakeStopwatchFactory(
          stopwatches: <String, Stopwatch>{
            'updateDevFS': FakeStopwatch()..elapsed = const Duration(seconds: 64),
            'reloadSources:reload': FakeStopwatch()..elapsed = const Duration(seconds: 128),
            'reloadSources:reassemble': FakeStopwatch()..elapsed = const Duration(seconds: 256),
            'reloadSources:vm': FakeStopwatch()..elapsed = const Duration(seconds: 512),
          },
        );

        (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

        final OperationResult result = await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          devtoolsHandler: createNoOpHandler,
          stopwatchFactory: fakeStopwatchFactory,
          reloadSourcesHelper: (
            HotRunner hotRunner,
            List<FlutterDevice?> flutterDevices,
            bool? pause,
            Map<String, dynamic> firstReloadDetails,
            String? targetPlatform,
            String? sdkName,
            bool? emulator,
            String? reason,
            Usage usage,
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
          ) async => ReassembleResult(
              <FlutterView?, FlutterVmService?>{null: null},
              false,
              true,
            ),
        ).restart();

        expect(result.isOk, true);
        expect(testUsage.events, <TestUsageEvent>[
          const TestUsageEvent('hot', 'reload', parameters: CustomDimensions(
            hotEventFinalLibraryCount: 2,
            hotEventSyncedLibraryCount: 3,
            hotEventSyncedClassesCount: 4,
            hotEventSyncedProceduresCount: 5,
            hotEventSyncedBytes: 8,
            hotEventInvalidatedSourcesCount: 6,
            hotEventTransferTimeInMs: 32000,
            hotEventOverallTimeInMs: 128000,
            hotEventTargetPlatform: 'flutter-tester',
            hotEventSdkName: 'Tester',
            hotEventEmulator: false,
            hotEventFullRestart: false,
            hotEventCompileTimeInMs: 16000,
            hotEventFindInvalidatedTimeInMs: 64000,
            hotEventScannedSourcesCount: 16,
            hotEventReassembleTimeInMs: 256000,
            hotEventReloadVMTimeInMs: 512000,
          )),
        ]);
        expect(testingConfig.updateDevFSCompleteCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => testingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
        Usage: () => testUsage,
      });
    });

    group('hot restart that failed to sync dev fs', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(
          successfulHotRestartSetup: true,
        );
      });
      testUsingContext('still calls the devfs complete callback', () async {
        final FakeDevice device = FakeDevice();
        final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
        final List<FlutterDevice> devices = <FlutterDevice>[
          fakeFlutterDevice,
        ];
        fakeFlutterDevice.updateDevFSReportCallback = () async => throw Exception('updateDevFS failed');

        final HotRunner runner = HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          devtoolsHandler: createNoOpHandler,
        );

        await expectLater(runner.restart(fullRestart: true), throwsA(isA<Exception>().having((Exception e) => e.toString(), 'message', 'Exception: updateDevFS failed')));
        expect(testingConfig.updateDevFSCompleteCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => testingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
        Usage: () => testUsage,
      });
    });

    group('hot reload that failed to sync dev fs', () {
      late TestHotRunnerConfig testingConfig;
      setUp(() {
        testingConfig = TestHotRunnerConfig(
          successfulHotReloadSetup: true,
        );
      });
      testUsingContext('still calls the devfs complete callback', () async {
        final FakeDevice device = FakeDevice();
        final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
        final List<FlutterDevice> devices = <FlutterDevice>[
          fakeFlutterDevice,
        ];
        fakeFlutterDevice.updateDevFSReportCallback = () async => throw Exception('updateDevFS failed');

        final HotRunner runner = HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
          devtoolsHandler: createNoOpHandler,
        );

        await expectLater(runner.restart(), throwsA(isA<Exception>().having((Exception e) => e.toString(), 'message', 'Exception: updateDevFS failed')));
        expect(testingConfig.updateDevFSCompleteCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => testingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(),
        ProcessManager: () => FakeProcessManager.any(),
        Usage: () => testUsage,
      });
    });
  });

  group('hot attach', () {
    late FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext('Exits with code 2 when HttpException is thrown '
      'during VM service connection', () async {
      fileSystem.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('\n');

      final FakeResidentCompiler residentCompiler = FakeResidentCompiler();
      final FakeDevice device = FakeDevice();
      final List<FlutterDevice> devices = <FlutterDevice>[
        TestFlutterDevice(
          device: device,
          generator: residentCompiler,
          exception: const HttpException('Connection closed before full header was received, '
              'uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws'),
        ),
      ];

      final int exitCode = await HotRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
      ).attach(needsFullRestart: false);
      expect(exitCode, 2);
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => TestHotRunnerConfig(),
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('hot cleanupAtFinish()', () {
    testUsingContext('disposes each device', () async {
      final FakeDevice device1 = FakeDevice();
      final FakeDevice device2 = FakeDevice();
      final FakeFlutterDevice flutterDevice1 = FakeFlutterDevice(device1);
      final FakeFlutterDevice flutterDevice2 = FakeFlutterDevice(device2);

      final List<FlutterDevice> devices = <FlutterDevice>[
        flutterDevice1,
        flutterDevice2,
      ];

      await HotRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
      ).cleanupAtFinish();

      expect(device1.disposed, true);
      expect(device2.disposed, true);

      expect(flutterDevice1.stoppedEchoingDeviceLog, true);
      expect(flutterDevice2.stoppedEchoingDeviceLog, true);
    });
  });

  group('native assets', () {
    late TestHotRunnerConfig testingConfig;
    late FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      testingConfig = TestHotRunnerConfig(
        successfulHotRestartSetup: true,
      );
    });
    testUsingContext('native assets restart', () async {
      final FakeDevice device = FakeDevice();
      final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
      final List<FlutterDevice> devices = <FlutterDevice>[
        fakeFlutterDevice,
      ];

      fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
        success: true,
        invalidatedSourcesCount: 6,
        syncedBytes: 8,
        scannedSourcesCount: 16,
        compileDuration: const Duration(seconds: 16),
        transferDuration: const Duration(seconds: 32),
      );

      (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

      final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', fileSystem.currentDirectory.uri),
        ],
        dryRunResult: FakeNativeAssetsBuilderResult(
          assets: <Asset>[
            Asset(
              id: 'package:bar/bar.dart',
              linkMode: LinkMode.dynamic,
              target: native_assets_cli.Target.macOSArm64,
              path: AssetAbsolutePath(Uri.file('bar.dylib')),
            ),
          ],
        ),
      );

      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
        buildRunner: buildRunner,
      );
      final OperationResult result = await hotRunner.restart(fullRestart: true);
      expect(result.isOk, true);
      // Hot restart does not require reruning anything for native assets.
      // The previous native assets mapping should be used.
      expect(buildRunner.buildInvocations, 0);
      expect(buildRunner.dryRunInvocations, 0);
      expect(buildRunner.hasPackageConfigInvocations, 0);
      expect(buildRunner.packagesWithNativeAssetsInvocations, 0);
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => testingConfig,
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.empty(),
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
    });

    testUsingContext('native assets run unsupported', () async {
      final FakeDevice device = FakeDevice(targetPlatform: TargetPlatform.android_arm64);
      final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
      final List<FlutterDevice> devices = <FlutterDevice>[
        fakeFlutterDevice,
      ];

      fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
        success: true,
        invalidatedSourcesCount: 6,
        syncedBytes: 8,
        scannedSourcesCount: 16,
        compileDuration: const Duration(seconds: 16),
        transferDuration: const Duration(seconds: 32),
      );

      (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

      final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', fileSystem.currentDirectory.uri),
        ],
        dryRunResult: FakeNativeAssetsBuilderResult(
          assets: <Asset>[
            Asset(
              id: 'package:bar/bar.dart',
              linkMode: LinkMode.dynamic,
              target: native_assets_cli.Target.macOSArm64,
              path: AssetAbsolutePath(Uri.file('bar.dylib')),
            ),
          ],
        ),
      );

      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
        buildRunner: buildRunner,
      );
      expect(
        () => hotRunner.run(),
        throwsToolExit( message:
          'Package(s) bar require the native assets feature. '
          'This feature has not yet been implemented for `TargetPlatform.android_arm64`. '
          'For more info see https://github.com/flutter/flutter/issues/129757.',
        )
      );

    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => testingConfig,
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.empty(),
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
    });
  });
}

class FakeDevFs extends Fake implements DevFS {
  @override
  Future<void> destroy() async { }

  @override
  List<Uri> sources = <Uri>[];

  @override
  DateTime? lastCompiled;

  @override
  PackageConfig? lastPackageConfig;

  @override
  Set<String> assetPathsToEvict = <String>{};

  @override
  Set<String> shaderPathsToEvict= <String>{};

  @override
  Set<String> scenePathsToEvict= <String>{};

  @override
  Uri? baseUri;
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeDevice extends Fake implements Device {
  FakeDevice({
    TargetPlatform targetPlatform = TargetPlatform.tester,
  }) : _targetPlatform = targetPlatform;

  final TargetPlatform _targetPlatform;

  bool disposed = false;

  @override
  bool isSupported() => true;

  @override
  bool supportsHotReload = true;

  @override
  bool supportsHotRestart = true;

  @override
  bool supportsFlutterExit = true;

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  Future<String> get sdkNameAndVersion async => 'Tester';

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  String get name => 'Fake Device';

  @override
  Future<bool> stopApp(
    ApplicationPackage? app, {
    String? userIdentifier,
  }) async {
    return true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  FakeFlutterDevice(this.device);

  bool stoppedEchoingDeviceLog = false;
  late Future<UpdateFSReport> Function() updateDevFSReportCallback;

  @override
  final FakeDevice device;

  @override
  Future<void> stopEchoingDeviceLog() async {
    stoppedEchoingDeviceLog = true;
  }

  @override
  DevFS? devFS = FakeDevFs();

  @override
  FlutterVmService get vmService => FakeFlutterVmService();

  @override
  ResidentCompiler? generator;

  @override
  Future<UpdateFSReport> updateDevFS({
    Uri? mainUri,
    String? target,
    AssetBundle? bundle,
    DateTime? firstBuildTime,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String? projectRootPath,
    String? pathToReload,
    required String dillOutputPath,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
  }) => updateDevFSReportCallback();

  @override
  TargetPlatform? get targetPlatform => device._targetPlatform;
}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice({
    required Device device,
    required this.exception,
    required ResidentCompiler generator,
  })  : super(device, buildInfo: BuildInfo.debug, generator: generator, developmentShaderCompiler: const FakeShaderCompiler());

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    ReloadSources? reloadSources,
    Restart? restart,
    CompileExpression? compileExpression,
    GetSkSLMethod? getSkSLMethod,
    FlutterProject? flutterProject,
    PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
    bool disableServiceAuthCodes = false,
    bool enableDds = true,
    bool cacheStartupProfile = false,
    bool? ipv6 = false,
    int? hostVmServicePort,
    int? ddsPort,
    bool allowExistingDdsInstance = false,
  }) async {
    throw exception;
  }
}

class TestHotRunnerConfig extends HotRunnerConfig {
  TestHotRunnerConfig({this.successfulHotRestartSetup, this.successfulHotReloadSetup});
  bool? successfulHotRestartSetup;
  bool? successfulHotReloadSetup;
  bool shutdownHookCalled = false;
  bool updateDevFSCompleteCalled = false;

  @override
  Future<bool?> setupHotRestart() async {
    assert(successfulHotRestartSetup != null, 'setupHotRestart is not expected to be called in this test.');
    return successfulHotRestartSetup;
  }

  @override
  Future<bool?> setupHotReload() async {
    assert(successfulHotReloadSetup != null, 'setupHotReload is not expected to be called in this test.');
    return successfulHotReloadSetup;
  }

  @override
  void updateDevFSComplete() {
    updateDevFSCompleteCalled = true;
  }

  @override
  Future<void> runPreShutdownOperations() async {
    shutdownHookCalled = true;
  }
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  @override
  void accept() {}
}

class FakeFlutterVmService extends Fake implements FlutterVmService {
  @override
  vm_service.VmService get service => FakeVmService();

  @override
  Future<List<FlutterView>> getFlutterViews({bool returnEarly = false, Duration delay = const Duration(milliseconds: 50)}) async {
    return <FlutterView>[];
  }
}

class FakeVmService extends Fake implements vm_service.VmService {
  @override
  Future<vm_service.VM> getVM() async => FakeVm();
}

class FakeVm extends Fake implements vm_service.VM {
  @override
  List<vm_service.IsolateRef> get isolates => <vm_service.IsolateRef>[];
}

class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler();

  @override
  void configureCompiler(
    TargetPlatform? platform, {
    required ImpellerStatus impellerStatus,
  }) { }

  @override
  Future<DevFSContent> recompileShader(DevFSContent inputShader) {
    throw UnimplementedError();
  }
}
