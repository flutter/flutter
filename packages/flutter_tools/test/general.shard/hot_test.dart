// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('validateReloadReport', () {
    testUsingContext('invalid', () async {
      expect(HotRunner.validateReloadReport(<String, dynamic>{}), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{},
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <String, dynamic>{
            'message': 'error',
          },
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': false},
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': <String>['error']},
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': 'error'},
            <String, dynamic>{'message': <String>['error']},
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': 'error'},
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': true,
      }), true);
    });
  });

  group('hotRestart', () {
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    final MockDevFs mockDevFs = MockDevFs();
    MockLocalEngineArtifacts mockArtifacts;

    when(mockDevFs.update(
      mainPath: anyNamed('mainPath'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
    )).thenAnswer((Invocation _) => Future<UpdateFSReport>.value(
        UpdateFSReport(success: true, syncedBytes: 1000, invalidatedSourcesCount: 1)));
    when(mockDevFs.assetPathsToEvict).thenReturn(<String>{});
    when(mockDevFs.baseUri).thenReturn(Uri.file('test'));
    when(mockDevFs.sources).thenReturn(<Uri>[Uri.file('test')]);
    when(mockDevFs.lastCompiled).thenReturn(DateTime.now());

    setUp(() {
      mockArtifacts = MockLocalEngineArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.flutterPatchedSdkPath)).thenReturn('some/path');
    });

    testUsingContext('Does not hot restart when device does not support it', () async {
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart failed.
      expect(result.isOk, false);
      expect(result.message, 'hotRestart not supported');
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
    });

    testUsingContext('Does not hot restart when one of many devices does not support it', () async {
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      final MockDevice mockHotDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockHotDevice.supportsHotReload).thenReturn(true);
      when(mockHotDevice.supportsHotRestart).thenReturn(true);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug)..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart failed.
      expect(result.isOk, false);
      expect(result.message, 'hotRestart not supported');
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
    });

    testUsingContext('Does hot restarts when all devices support it', () async {
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      final MockDevice mockHotDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockHotDevice.supportsHotReload).thenReturn(true);
      when(mockHotDevice.supportsHotRestart).thenReturn(true);
      // Trigger a restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug)..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart was successful.
      expect(result.isOk, true);
      expect(result.message, isNot('hotRestart not supported'));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
    });

    testUsingContext('setup function fails', () async {
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug),
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      expect(result.isOk, false);
      expect(result.message, 'setupHotRestart failed');
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: false),
    });

    testUsingContext('hot restart supported', () async {
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart successful.
      expect(result.isOk, true);
      expect(result.message, isNot('setupHotRestart failed'));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
    });

    group('shutdown hook tests', () {
      TestHotRunnerConfig shutdownTestingConfig;

      setUp(() {
        shutdownTestingConfig = TestHotRunnerConfig(
          successfulSetup: true,
        );
      });

      testUsingContext('shutdown hook called after signal', () async {
        final MockDevice mockDevice = MockDevice();
        when(mockDevice.supportsHotReload).thenReturn(true);
        when(mockDevice.supportsHotRestart).thenReturn(true);
        when(mockDevice.supportsFlutterExit).thenReturn(false);
        final List<FlutterDevice> devices = <FlutterDevice>[
          FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug),
        ];
        await HotRunner(devices).cleanupAfterSignal();
        expect(shutdownTestingConfig.shutdownHookCalled, true);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        HotRunnerConfig: () => shutdownTestingConfig,
      });

      testUsingContext('shutdown hook called after app stop', () async {
        final MockDevice mockDevice = MockDevice();
        when(mockDevice.supportsHotReload).thenReturn(true);
        when(mockDevice.supportsHotRestart).thenReturn(true);
        when(mockDevice.supportsFlutterExit).thenReturn(false);
        final List<FlutterDevice> devices = <FlutterDevice>[
          FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false, buildMode: BuildMode.debug),
        ];
        await HotRunner(devices).preExit();
        expect(shutdownTestingConfig.shutdownHookCalled, true);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        HotRunnerConfig: () => shutdownTestingConfig,
      });
    });
  });

  group('hot attach', () {
    MockResidentCompiler residentCompiler = MockResidentCompiler();
    MockLocalEngineArtifacts mockArtifacts;

    setUp(() {
      residentCompiler = MockResidentCompiler();
      mockArtifacts = MockLocalEngineArtifacts();
    });

    testUsingContext('Prints message when HttpException is thrown - 1', () async {
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation _) async => 'Android 10');

      final List<FlutterDevice> devices = <FlutterDevice>[
        TestFlutterDevice(
          device: mockDevice,
          generator: residentCompiler,
          exception: const HttpException('Connection closed before full header was received, '
              'uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws'),
        ),
      ];

      final int exitCode = await HotRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).attach();
      expect(exitCode, 2);
      expect(testLogger.statusText, contains('If you are using an emulator running Android Q Beta, '
          'consider using an emulator running API level 29 or lower.'));
      expect(testLogger.statusText, contains('Learn more about the status of this issue on '
          'https://issuetracker.google.com/issues/132325318'));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
    });

    testUsingContext('Prints message when HttpException is thrown - 2', () async {
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation _) async => 'Android 10');

      final List<FlutterDevice> devices = <FlutterDevice>[
        TestFlutterDevice(
          device: mockDevice,
          generator: residentCompiler,
          exception: const HttpException(', uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws'),
        ),
      ];

      final int exitCode = await HotRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).attach();
      expect(exitCode, 2);
      expect(testLogger.statusText, contains('If you are using an emulator running Android Q Beta, '
          'consider using an emulator running API level 29 or lower.'));
      expect(testLogger.statusText, contains('Learn more about the status of this issue on '
          'https://issuetracker.google.com/issues/132325318'));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
    });
  });

  group('hot cleanupAtFinish()', () {
    MockFlutterDevice mockFlutterDeviceFactory(Device device) {
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(mockFlutterDevice.device).thenReturn(device);
      return mockFlutterDevice;
    }

    testUsingContext('disposes each device', () async {
      final MockDevice mockDevice1 = MockDevice();
      final MockDevice mockDevice2 = MockDevice();
      final MockFlutterDevice mockFlutterDevice1 = mockFlutterDeviceFactory(mockDevice1);
      final MockFlutterDevice mockFlutterDevice2 = mockFlutterDeviceFactory(mockDevice2);

      final List<FlutterDevice> devices = <FlutterDevice>[
        mockFlutterDevice1,
        mockFlutterDevice2,
      ];

      await HotRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).cleanupAtFinish();

      verify(mockDevice1.dispose());
      verify(mockFlutterDevice1.stopEchoingDeviceLog());
      verify(mockDevice2.dispose());
      verify(mockFlutterDevice2.stopEchoingDeviceLog());
    });
  });
}

class MockDevFs extends Mock implements DevFS {}

class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class MockFlutterDevice extends Mock implements FlutterDevice {}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice({
    @required Device device,
    @required this.exception,
    @required ResidentCompiler generator,
  })  : assert(exception != null),
        super(device, buildMode: BuildMode.debug, generator: generator, trackWidgetCreation: false);

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
  }) async {
    throw exception;
  }
}

class TestHotRunnerConfig extends HotRunnerConfig {
  TestHotRunnerConfig({@required this.successfulSetup});
  bool successfulSetup;
  bool shutdownHookCalled = false;

  @override
  Future<bool> setupHotRestart() async {
    return successfulSetup;
  }

  @override
  Future<void> runPreShutdownOperations() async {
    shutdownHookCalled = true;
  }
}
