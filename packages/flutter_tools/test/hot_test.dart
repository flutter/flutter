// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

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
            <String, dynamic>{ 'message': false, }
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{ 'message': <String>['error'], },
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{ 'message': 'error', },
            <String, dynamic>{ 'message': <String>['error'], },
          ],
        },
      }), false);
      expect(HotRunner.validateReloadReport(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{ 'message': 'error', },
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
      bundleDirty: anyNamed('bundleDirty'),
      fileFilter: anyNamed('fileFilter'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
    )).thenAnswer((Invocation _) => Future<int>.value(1000));
    when(mockDevFs.assetPathsToEvict).thenReturn(Set<String>());
    when(mockDevFs.baseUri).thenReturn(Uri.file('test'));

    setUp(() {
      mockArtifacts = MockLocalEngineArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.flutterPatchedSdkPath)).thenReturn('some/path');
    });

    testUsingContext('no setup', () async {
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false),
      ];
      expect((await HotRunner(devices).restart(fullRestart: true)).isOk, false);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
    });

    testUsingContext('Does not hot restart when device does not support it', () async {
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false)..devFS = mockDevFs
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart failed.
      expect(result.isOk, false);
      expect(result.message, 'hotRestart not supported');
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true, computeDartDependencies: false),
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
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false)..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, trackWidgetCreation: false)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart failed.
      expect(result.isOk, false);
      expect(result.message, 'hotRestart not supported');
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true, computeDartDependencies: false),
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
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false)..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, trackWidgetCreation: false)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart was successful.
      expect(result.isOk, true);
      expect(result.message, isNot('hotRestart not supported'));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true, computeDartDependencies: false),
    });

    testUsingContext('setup function fails', () async {
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false)
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
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, trackWidgetCreation: false)..devFS = mockDevFs
      ];
      final OperationResult result = await HotRunner(devices).restart(fullRestart: true);
      // Expect hot restart successful.
      expect(result.isOk, true);
      expect(result.message, isNot('setupHotRestart failed'));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true, computeDartDependencies: false),
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

class TestHotRunnerConfig extends HotRunnerConfig {
  TestHotRunnerConfig({@required this.successfulSetup, bool computeDartDependencies = true}) {
    this.computeDartDependencies = computeDartDependencies;
  }

  bool successfulSetup;

  @override
  Future<bool> setupHotRestart() async {
    return successfulSetup;
  }
}
