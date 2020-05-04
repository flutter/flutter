// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_info.dart';
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

const FakeVmServiceRequest listViews = FakeVmServiceRequest(
  method: kListViewsMethod,
  jsonResponse: <String, Object>{
    'views': <Object>[],
  }
);

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
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
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
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)..devFS = mockDevFs,
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
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)..devFS = mockDevFs,
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
      final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
        listViews,
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson()
        ),
        listViews,
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson()
        ),
        listViews,
        listViews,
      ]);
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      final MockDevice mockHotDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockHotDevice.supportsHotReload).thenReturn(true);
      when(mockHotDevice.supportsHotRestart).thenReturn(true);
      // Trigger a restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)
          ..vmService = fakeVmServiceHost.vmService
          ..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)
          ..vmService = fakeVmServiceHost.vmService
          ..devFS = mockDevFs,
      ];
      final HotRunner hotRunner = HotRunner(devices);
      final OperationResult result = await hotRunner.restart(fullRestart: true);
      // Expect hot restart was successful.
      expect(hotRunner.uri, mockDevFs.baseUri);
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
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug),
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
      final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(
          method: kListViewsMethod,
          jsonResponse: <String, Object>{
            'views': <Object>[],
          }
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson()
        ),
        const FakeVmServiceRequest(
          method: kListViewsMethod,
          jsonResponse: <String, Object>{
            'views': <Object>[],
          }
        ),
      ]);
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)
          ..vmService = fakeVmServiceHost.vmService
          ..devFS = mockDevFs,
      ];
      final HotRunner hotRunner = HotRunner(devices);
      final OperationResult result = await hotRunner.restart(fullRestart: true);
      // Expect hot restart successful.
      expect(hotRunner.uri, mockDevFs.baseUri);
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
          FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug),
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
          FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug),
        ];
        await HotRunner(devices).preExit();
        expect(shutdownTestingConfig.shutdownHookCalled, true);
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        HotRunnerConfig: () => shutdownTestingConfig,
      });
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
