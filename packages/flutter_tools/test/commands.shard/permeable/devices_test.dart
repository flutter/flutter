// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FakeDeviceManager deviceManager;
  late BufferLogger logger;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    deviceManager = FakeDeviceManager();
    logger = BufferLogger.test();
  });

  testWithoutContext('devices can display no connected devices with the --machine flag', () async {
    final command = DevicesCommand(
      deviceManager: deviceManager,
      doctor: _FakeDoctor(),
      toolContext: FakeToolContext(logger: logger),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['devices', '--machine']);

    expect(json.decode(logger.statusText), isEmpty);
  });

  testWithoutContext('devices can display via the --machine flag', () async {
    deviceManager.devices = <Device>[WebServerDevice(logger: logger)];
    final command = DevicesCommand(
      deviceManager: deviceManager,
      doctor: _FakeDoctor(),
      toolContext: FakeToolContext(logger: logger),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['devices', '--machine']);

    expect(
      json.decode(logger.statusText),
      contains(
        equals(<String, Object>{
          'name': 'Web Server',
          'id': 'web-server',
          'isSupported': true,
          'targetPlatform': 'web-javascript',
          'cpuArch': 'unknown',
          'emulator': false,
          'sdk': 'Flutter Tools',
          'capabilities': <String, Object>{
            'hotReload': true,
            'hotRestart': true,
            'screenshot': false,
            'flutterExit': false,
            'hardwareRendering': false,
            'startPaused': true,
          },
        }),
      ),
    );
  });
}

class FakeDeviceManager extends Fake implements DeviceManager {
  List<Device> devices = <Device>[];

  @override
  String? specifiedDeviceId;

  @override
  Future<List<Device>> getAllDevices({DeviceDiscoveryFilter? filter}) async {
    return devices;
  }

  @override
  Future<List<Device>> refreshAllDevices({Duration? timeout, DeviceDiscoveryFilter? filter}) async {
    return devices;
  }
}

class _FakeDoctor extends Fake implements Doctor {
  @override
  bool get canListAnything => true;
}
