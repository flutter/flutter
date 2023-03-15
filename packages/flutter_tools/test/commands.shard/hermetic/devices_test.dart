// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('devices', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    late Cache cache;
    late Platform platform;

    setUp(() {
      cache = Cache.test(processManager: FakeProcessManager.any());
      platform = FakePlatform();
    });

    testUsingContext('returns 0 when called', () async {
      final DevicesCommand command = DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
    }, overrides: <Type, Generator>{
      Cache: () => cache,
      Artifacts: () => Artifacts.test(),
    });

    testUsingContext('no error when no connected devices', () async {
      final DevicesCommand command = DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
      expect(
          testLogger.statusText,
          equals('''
No devices detected.

Run "flutter emulators" to list and start any available device emulators.

If you expected your device to be detected, please run "flutter doctor" to diagnose potential issues. You may also try increasing the time to wait for connected devices with the --device-timeout flag. Visit https://flutter.dev/setup/ for troubleshooting tips.
'''),
        );
    }, overrides: <Type, Generator>{
      AndroidSdk: () => null,
      DeviceManager: () => NoDevicesManager(),
      ProcessManager: () => FakeProcessManager.any(),
      Cache: () => cache,
      Artifacts: () => Artifacts.test(),
    });

    group('when includes both attached and wireless devices', () {
      List<FakeDeviceJsonData>? deviceList;
      setUp(() {
        deviceList = <FakeDeviceJsonData>[
          fakeDevices[0],
          fakeDevices[1],
          fakeDevices[2],
        ];
      });

      testUsingContext("get devices' platform types", () async {
        final List<String> platformTypes = Device.devicesPlatformTypes(
          await globals.deviceManager!.getAllDevices(),
        );
        expect(platformTypes, <String>['android', 'web']);
      }, overrides: <Type, Generator>{
        DeviceManager: () => _FakeDeviceManager(devices: deviceList),
        ProcessManager: () => FakeProcessManager.any(),
        Cache: () => cache,
        Artifacts: () => Artifacts.test(),
        Platform: () => platform,
      });

      testUsingContext('Outputs parsable JSON with --machine flag', () async {
        final DevicesCommand command = DevicesCommand();
        await createTestCommandRunner(command).run(<String>['devices', '--machine']);
        expect(
          json.decode(testLogger.statusText),
          <Map<String, Object>>[
            fakeDevices[0].json,
            fakeDevices[1].json,
            fakeDevices[2].json,
          ],
        );
      }, overrides: <Type, Generator>{
        DeviceManager: () => _FakeDeviceManager(devices: deviceList),
        ProcessManager: () => FakeProcessManager.any(),
        Cache: () => cache,
        Artifacts: () => Artifacts.test(),
        Platform: () => platform,
      });

      testUsingContext('available devices and diagnostics', () async {
        final DevicesCommand command = DevicesCommand();
        await createTestCommandRunner(command).run(<String>['devices']);
        expect(testLogger.statusText, '''
2 connected devices:

ephemeral (mobile) • ephemeral • android-arm    • Test SDK (1.2.3) (emulator)
webby (mobile)     • webby     • web-javascript • Web SDK (1.2.4) (emulator)

1 wirelessly connected device:

wireless android (mobile) • wireless-android • android-arm • Test SDK (1.2.3) (emulator)

• Cannot connect to device ABC
''');
      }, overrides: <Type, Generator>{
        DeviceManager: () => _FakeDeviceManager(devices: deviceList),
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
      });
    });

    group('when includes only attached devices', () {
      List<FakeDeviceJsonData>? deviceList;
      setUp(() {
        deviceList = <FakeDeviceJsonData>[
          fakeDevices[0],
          fakeDevices[1],
        ];
      });

      testUsingContext('available devices and diagnostics', () async {
        final DevicesCommand command = DevicesCommand();
        await createTestCommandRunner(command).run(<String>['devices']);
        expect(testLogger.statusText, '''
2 connected devices:

ephemeral (mobile) • ephemeral • android-arm    • Test SDK (1.2.3) (emulator)
webby (mobile)     • webby     • web-javascript • Web SDK (1.2.4) (emulator)

• Cannot connect to device ABC
''');
      }, overrides: <Type, Generator>{
        DeviceManager: () => _FakeDeviceManager(devices: deviceList),
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
      });
    });

    group('when includes only wireless devices', () {
      List<FakeDeviceJsonData>? deviceList;
      setUp(() {
        deviceList = <FakeDeviceJsonData>[
          fakeDevices[2],
        ];
      });

      testUsingContext('available devices and diagnostics', () async {
        final DevicesCommand command = DevicesCommand();
        await createTestCommandRunner(command).run(<String>['devices']);
        expect(testLogger.statusText, '''
1 wirelessly connected device:

wireless android (mobile) • wireless-android • android-arm • Test SDK (1.2.3) (emulator)

• Cannot connect to device ABC
''');
      }, overrides: <Type, Generator>{
        DeviceManager: () => _FakeDeviceManager(devices: deviceList),
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
      });
    });
  });
}

class _FakeDeviceManager extends DeviceManager {
  _FakeDeviceManager({
    List<FakeDeviceJsonData>? devices,
  })  : fakeDevices = devices ?? <FakeDeviceJsonData>[],
        super(logger: testLogger);

  List<FakeDeviceJsonData> fakeDevices = <FakeDeviceJsonData>[];

  @override
  Future<List<Device>> getAllDevices({DeviceDiscoveryFilter? filter}) async {
    final List<Device> devices = <Device>[];
    for (final FakeDeviceJsonData deviceJson in fakeDevices) {
      if (filter?.deviceConnectionInterface == null ||
          deviceJson.dev.connectionInterface == filter?.deviceConnectionInterface) {
        devices.add(deviceJson.dev);
      }
    }
    return devices;
  }

  @override
  Future<List<Device>> refreshAllDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
  }) => getAllDevices(filter: filter);

  @override
  Future<List<String>> getDeviceDiagnostics() => Future<List<String>>.value(
    <String>['Cannot connect to device ABC']
  );

  @override
  List<DeviceDiscovery> get deviceDiscoverers => <DeviceDiscovery>[];
}

class NoDevicesManager extends DeviceManager {
  NoDevicesManager() : super(logger: testLogger);

  @override
  Future<List<Device>> getAllDevices({
    DeviceDiscoveryFilter? filter,
  }) async => <Device>[];

  @override
  Future<List<Device>> refreshAllDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
  }) =>
    getAllDevices();

  @override
  List<DeviceDiscovery> get deviceDiscoverers => <DeviceDiscovery>[];
}
