// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';

void main() {
  group('devices', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('returns 0 when called', () async {
      final DevicesCommand command = DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
    });

    testUsingContext('no error when no connected devices', () async {
      final DevicesCommand command = DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
      expect(testLogger.statusText, containsIgnoringWhitespace('No devices detected'));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => null,
      DeviceManager: () => DeviceManager(),
      ProcessManager: () => MockProcessManager(),
    });

    testUsingContext('Outputs parsable JSON with --machine flag', () async {
      final DevicesCommand command = DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices', '--machine']);
      expect(
        json.decode(testLogger.statusText),
        <Map<String,Object>>[
          <String, Object>{
            'name': 'ephemeral',
            'id': 'ephemeral',
            'isSupported': true,
            'targetPlatform': 'android-arm',
            'emulator': true,
            'sdk': 'Test SDK (1.2.3)',
            'capabilities': <String, Object>{
              'hotReload': true,
              'hotRestart': true,
              'screenshot': false,
              'fastStart': false,
              'flutterExit': true,
              'hardwareRendering': true,
              'startPaused': true
            }
          },
          <String,Object>{
            'name': 'webby',
            'id': 'webby',
            'isSupported': true,
            'targetPlatform': 'web-javascript',
            'emulator': true,
            'sdk': 'Web SDK (1.2.4)',
            'capabilities': <String, Object>{
              'hotReload': true,
              'hotRestart': true,
              'screenshot': false,
              'fastStart': false,
              'flutterExit': true,
              'hardwareRendering': false,
              'startPaused': true
            }
          }
        ]
      );
    }, overrides: <Type, Generator>{
      DeviceManager: () => _FakeDeviceManager(),
      ProcessManager: () => MockProcessManager(),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {
  @override
  Future<ProcessResult> run(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) async {
    return ProcessResult(0, 0, '', '');
  }

  @override
  ProcessResult runSync(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    return ProcessResult(0, 0, '', '');
  }
}

class _FakeDeviceManager extends DeviceManager {
  _FakeDeviceManager();

  @override
  Future<List<Device>> getAllConnectedDevices() =>
    Future<List<Device>>.value(fakeDevices.map((FakeDeviceJsonData d) => d.dev).toList());

  @override
  Future<List<Device>> refreshAllConnectedDevices({Duration timeout}) =>
    getAllConnectedDevices();

}
