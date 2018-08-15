// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/context.dart';

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
    final List<FlutterDevice> devices = <FlutterDevice>[];

    setUp(() {
      devices.add(new FlutterDevice(new MockDevice(),
          previewDart2: false, trackWidgetCreation: false));
    });

    testUsingContext('no setup', () async {
      expect((await new HotRunner(devices).restart(fullRestart: true)).isOk,
          true);
    });

    testUsingContext('setup function succeeds', () async {
      expect((await new HotRunner(devices).restart(fullRestart: true)).isOk,
          true);
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => new TestHotRunnerConfig(successfulSetup: true),
    });

    testUsingContext('setup function fails', () async {
      expect((await new HotRunner(devices).restart(fullRestart: true)).isOk,
          false);
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => new TestHotRunnerConfig(successfulSetup: false),
    });
  });
}

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
