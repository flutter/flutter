// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
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
    final MockResidentCompiler residentCompiler = new MockResidentCompiler();
    MockLocalEngineArtifacts mockArtifacts;

    setUp(() {
      mockArtifacts = new MockLocalEngineArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.flutterPatchedSdkPath)).thenReturn('some/path');
    });

    testUsingContext('no setup', () async {
      final List<FlutterDevice> devices = <FlutterDevice>[new FlutterDevice(new MockDevice(), generator: residentCompiler, trackWidgetCreation: false)];
      expect((await new HotRunner(devices).restart(fullRestart: true)).isOk, true);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
    });

    testUsingContext('setup function succeeds', () async {
      final List<FlutterDevice> devices = <FlutterDevice>[new FlutterDevice(new MockDevice(), generator: residentCompiler, trackWidgetCreation: false)];
      expect((await new HotRunner(devices).restart(fullRestart: true)).isOk, true);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => new TestHotRunnerConfig(successfulSetup: true),
    });

    testUsingContext('setup function fails', () async {
      final List<FlutterDevice> devices = <FlutterDevice>[new FlutterDevice(new MockDevice(), generator: residentCompiler, trackWidgetCreation: false)];
      expect((await new HotRunner(devices).restart(fullRestart: true)).isOk, false);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      HotRunnerConfig: () => new TestHotRunnerConfig(successfulSetup: false),
    });
  });
}

class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class TestHotRunnerConfig extends HotRunnerConfig {
  bool successfulSetup;

  TestHotRunnerConfig({@required this.successfulSetup});

  @override
  Future<bool> setupHotRestart() async {
    return successfulSetup;
  }
}
