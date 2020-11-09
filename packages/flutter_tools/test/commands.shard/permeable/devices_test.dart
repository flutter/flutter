// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  testUsingContext('devices can display no connected devices with the --machine flag', () async {
    final BufferLogger logger = context.get<Logger>() as BufferLogger;
    final DevicesCommand command = DevicesCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['devices', '--machine']);

    expect(
      json.decode(logger.statusText),
      isEmpty,
    );
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
  });

  testUsingContext('devices can display via the --machine flag', () async {
    when(globals.deviceManager.refreshAllConnectedDevices()).thenAnswer((Invocation invocation) async {
      return <Device>[
        WebServerDevice(logger: BufferLogger.test()),
      ];
    });

    final BufferLogger logger = context.get<Logger>() as BufferLogger;
    final DevicesCommand command = DevicesCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['devices', '--machine']);

    expect(
      json.decode(logger.statusText),
      contains(equals(
        <String, Object>{
          'name': 'Web Server',
          'id': 'web-server',
          'isSupported': true,
          'targetPlatform': 'web-javascript',
          'emulator': false,
          'sdk': 'Flutter Tools',
          'capabilities': <String, Object>{
            'hotReload': true,
            'hotRestart': true,
            'screenshot': false,
            'fastStart': false,
            'flutterExit': false,
            'hardwareRendering': false,
            'startPaused': true
          }
        }
      )),
    );
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    DeviceManager: () => MockDeviceManager(),
  });
}

class MockDeviceManager extends Mock implements DeviceManager {

}
