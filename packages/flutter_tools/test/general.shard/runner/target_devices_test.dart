// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/target_devices.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('findAllTargetDevices', () {
    late Platform platform;

    final FakeDevice attachedAndroidDevice1 = FakeDevice(deviceName: 'target-device-1');
    final FakeDevice attachedAndroidDevice2 = FakeDevice(deviceName: 'target-device-2');
    final FakeDevice attachedUnsupportedAndroidDevice = FakeDevice(deviceName: 'target-device-3', deviceSupported: false);
    final FakeDevice attachedUnsupportedForProjectAndroidDevice = FakeDevice(deviceName: 'target-device-4', deviceSupportForProject: false);

    final FakeDevice wirelessAndroidDevice1 = FakeDevice.wireless(deviceName: 'target-device-5');
    final FakeDevice wirelessAndroidDevice2 = FakeDevice.wireless(deviceName: 'target-device-6');
    final FakeDevice wirelessUnsupportedAndroidDevice = FakeDevice.wireless(deviceName: 'target-device-7', deviceSupported: false);
    final FakeDevice wirelessUnsupportedForProjectAndroidDevice = FakeDevice.wireless(deviceName: 'target-device-8', deviceSupportForProject: false);

    final FakeDevice nonEphemeralDevice = FakeDevice(deviceName: 'target-device-9', ephemeral: false);
    final FakeDevice fuchsiaDevice = FakeDevice.fuchsia(deviceName: 'target-device-10');

    final FakeDevice exactMatchAndroidDevice = FakeDevice(deviceName: 'target-device');
    final FakeDevice exactMatchWirelessAndroidDevice = FakeDevice.wireless(deviceName: 'target-device');
    final FakeDevice exactMatchattachedUnsupportedAndroidDevice = FakeDevice(deviceName: 'target-device', deviceSupported: false);
    final FakeDevice exactMatchUnsupportedByProjectDevice = FakeDevice(deviceName: 'target-device', deviceSupportForProject: false);

    setUp(() {
      platform = FakePlatform();
    });

    group('when cannot launch anything', () {
      late BufferLogger logger;
      late FakeDoctor doctor;

      setUp(() {
        logger = BufferLogger.test();
        doctor = FakeDoctor(canLaunchAnything: false);
      });

      testUsingContext('does not search for devices', () async {
        final TestDeviceManager deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
        deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1];

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(logger.errorText, equals('''
Unable to locate a development device; please run 'flutter doctor' for information about installing additional components.
'''));
        expect(devices, isNull);
        expect(deviceManager.androidDiscoverer.devicesCalled, 0);
        expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
      }, overrides: <Type, Generator>{
        Doctor: () => doctor,
      });
    });

    testUsingContext('ensure refresh when deviceDiscoveryTimeout is provided', () async {
      final BufferLogger logger = BufferLogger.test();
      final TestDeviceManager deviceManager = TestDeviceManager(
        logger: logger,
        platform: platform,
      );
      deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1];
      deviceManager.androidDiscoverer.refreshDeviceList = <Device>[attachedAndroidDevice1, wirelessAndroidDevice1];
      deviceManager.hasSpecifiedAllDevices = true;

      final TargetDevices targetDevices = TargetDevices(
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices(
        deviceDiscoveryTimeout: const Duration(seconds: 2),
      );

      expect(logger.statusText, equals(''));
      expect(devices, <Device>[attachedAndroidDevice1, wirelessAndroidDevice1]);
      expect(deviceManager.androidDiscoverer.devicesCalled, 2);
      expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 1);
      expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
    });

    group('finds no devices', () {
      late BufferLogger logger;
      late TestDeviceManager deviceManager;

      setUp(() {
        logger = BufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      group('when device not specified', () {
        testUsingContext('when no devices', () async {
          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals('''
No supported devices connected.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscoverer.devicesCalled, 3);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when device is unsupported by flutter or project', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[
            attachedUnsupportedAndroidDevice,
            attachedUnsupportedForProjectAndroidDevice,
          ];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals('''
No supported devices connected.

The following devices were found, but are not supported by this project:
target-device-3 (mobile) • xxx • android • Android 10 (unsupported)
target-device-4 (mobile) • xxx • android • Android 10
If you would like your app to run on android, consider running `flutter create .` to generate projects for these platforms.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscoverer.devicesCalled, 3);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        testUsingContext('when no devices', () async {
          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscoverer.devicesCalled, 4);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when no devices match', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'no-match-1');
          final FakeDevice device2 = FakeDevice.wireless(deviceName: 'no-match-2');
          deviceManager.androidDiscoverer.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.

The following devices were found:
no-match-1 (mobile) • xxx • android • Android 10
no-match-2 (mobile) • xxx • android • Android 10
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscoverer.devicesCalled, 4);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching device is unsupported by flutter', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[exactMatchattachedUnsupportedAndroidDevice];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.

The following devices were found:
target-device (mobile) • xxx • android • Android 10 (unsupported)
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscoverer.devicesCalled, 4);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('when no devices', () async {
          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals('''
No devices found.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscoverer.devicesCalled, 3);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when devices are either unsupported by flutter or project or all', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[
            attachedUnsupportedAndroidDevice,
            attachedUnsupportedForProjectAndroidDevice,
          ];
          deviceManager.otherDiscoverer.deviceList = <Device>[fuchsiaDevice];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals('''
No devices found.

The following devices were found, but are not supported by this project:
target-device-3 (mobile)  • xxx • android       • Android 10 (unsupported)
target-device-4 (mobile)  • xxx • android       • Android 10
target-device-10 (mobile) • xxx • fuchsia-arm64 • tester
If you would like your app to run on android or fuchsia, consider running `flutter create .` to generate projects for these platforms.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscoverer.devicesCalled, 3);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

      });

    });

    group('finds single device', () {
      late BufferLogger logger;
      late TestDeviceManager deviceManager;

      setUp(() {
        logger = BufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      group('when device not specified', () {
        testUsingContext('when single attached device', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[attachedAndroidDevice1]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 2);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when single wireless device', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[wirelessAndroidDevice1];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[wirelessAndroidDevice1]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 2);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when multiple but only one ephemeral', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[nonEphemeralDevice, wirelessAndroidDevice1];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[wirelessAndroidDevice1]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 2);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        testUsingContext('when multiple matches but first is unsupported by flutter', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[
            exactMatchattachedUnsupportedAndroidDevice,
            exactMatchAndroidDevice,
          ];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[exactMatchAndroidDevice]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 1);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching device is unsupported by project', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[exactMatchUnsupportedByProjectDevice];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[exactMatchUnsupportedByProjectDevice]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 1);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching attached device', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[exactMatchAndroidDevice];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[exactMatchAndroidDevice]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 1);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching wireless device', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[exactMatchWirelessAndroidDevice];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[exactMatchWirelessAndroidDevice]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 1);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });

        testUsingContext('when exact match attached device and partial match wireless device', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[exactMatchAndroidDevice, wirelessAndroidDevice1];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[exactMatchAndroidDevice]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 1);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('when only one device', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[attachedAndroidDevice1]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 2);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });
      });

    });

    group('Finds multiple devices', () {
      late BufferLogger logger;
      late TestDeviceManager deviceManager;

      setUp(() {
        logger = BufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      group('when device not specified', () {
        group('with stdinHasTerminal', () {
          late FakeTerminal terminal;

          setUp(() {
            terminal = FakeTerminal();
          });

          testUsingContext('including attached, wireless, unsupported devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[
              attachedAndroidDevice1,
              attachedUnsupportedAndroidDevice,
              attachedUnsupportedForProjectAndroidDevice,
              wirelessAndroidDevice1,
              wirelessUnsupportedAndroidDevice,
              wirelessUnsupportedForProjectAndroidDevice,
            ];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '2');
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10

[1]: target-device-1 (xxx)
[2]: target-device-5 (xxx)
'''));
            expect(devices, <Device>[wirelessAndroidDevice1]);
            expect(deviceManager.androidDiscoverer.devicesCalled, 2);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1, attachedAndroidDevice2];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
            expect(devices, <Device>[attachedAndroidDevice1]);
            expect(deviceManager.androidDiscoverer.devicesCalled, 2);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[wirelessAndroidDevice1, wirelessAndroidDevice2];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Multiple devices found:

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10
target-device-6 (mobile) • xxx • android • Android 10

[1]: target-device-5 (xxx)
[2]: target-device-6 (xxx)
'''));
            expect(devices, <Device>[wirelessAndroidDevice1]);
            expect(deviceManager.androidDiscoverer.devicesCalled, 2);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

        });

        group('without stdinHasTerminal', () {
          late FakeTerminal terminal;

          setUp(() {
            terminal = FakeTerminal(stdinHasTerminal: false);
          });

          testUsingContext('including attached, wireless, unsupported devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[
              attachedAndroidDevice1,
              attachedUnsupportedAndroidDevice,
              attachedUnsupportedForProjectAndroidDevice,
              wirelessAndroidDevice1,
              wirelessUnsupportedAndroidDevice,
              wirelessUnsupportedForProjectAndroidDevice,
            ];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • android • Android 10
target-device-4 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10
target-device-8 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscoverer.devicesCalled, 4);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1, attachedAndroidDevice2];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscoverer.devicesCalled, 4);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[wirelessAndroidDevice1, wirelessAndroidDevice2];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10
target-device-6 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscoverer.devicesCalled, 4);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });
        });
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        group('with stdinHasTerminal', () {
          late FakeTerminal terminal;

          setUp(() {
            terminal = FakeTerminal();
          });

          testUsingContext('including attached, wireless, unsupported devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[
              attachedAndroidDevice1,
              attachedUnsupportedAndroidDevice,
              attachedUnsupportedForProjectAndroidDevice,
              wirelessAndroidDevice1,
              wirelessUnsupportedAndroidDevice,
              wirelessUnsupportedForProjectAndroidDevice,
            ];

            terminal.setPrompt(<String>['1', '2', '3', '4', 'q', 'Q'], '2');
            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Found 4 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-4 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10
target-device-8 (mobile) • xxx • android • Android 10

[1]: target-device-1 (xxx)
[2]: target-device-4 (xxx)
[3]: target-device-5 (xxx)
[4]: target-device-8 (xxx)
'''));
            expect(devices, <Device>[attachedUnsupportedForProjectAndroidDevice]);
            expect(deviceManager.androidDiscoverer.devicesCalled, 3);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1, attachedAndroidDevice2];

            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
            expect(devices, <Device>[attachedAndroidDevice1]);
            expect(deviceManager.androidDiscoverer.devicesCalled, 3);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[wirelessAndroidDevice1, wirelessAndroidDevice2];

            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10
target-device-6 (mobile) • xxx • android • Android 10

[1]: target-device-5 (xxx)
[2]: target-device-6 (xxx)
'''));
            expect(devices, <Device>[wirelessAndroidDevice1]);
            expect(deviceManager.androidDiscoverer.devicesCalled, 3);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });
        });

        group('without stdinHasTerminal', () {
          late FakeTerminal terminal;

          setUp(() {
            terminal = FakeTerminal(stdinHasTerminal: false);
          });

          testUsingContext('including only one ephemeral', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[nonEphemeralDevice, attachedAndroidDevice1];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:
target-device-9 (mobile) • xxx • android • Android 10
target-device-1 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscoverer.devicesCalled, 3);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including matching attached, wireless, unsupported devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[
              attachedAndroidDevice1,
              attachedUnsupportedAndroidDevice,
              attachedUnsupportedForProjectAndroidDevice,
              wirelessAndroidDevice1,
              wirelessUnsupportedAndroidDevice,
              wirelessUnsupportedForProjectAndroidDevice,
            ];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Found 4 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-4 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10
target-device-8 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscoverer.devicesCalled, 3);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[attachedAndroidDevice1, attachedAndroidDevice2];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscoverer.devicesCalled, 3);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            deviceManager.androidDiscoverer.deviceList = <Device>[wirelessAndroidDevice1, wirelessAndroidDevice2];

            final TargetDevices targetDevices = TargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:

Wirelessly connected devices:
target-device-5 (mobile) • xxx • android • Android 10
target-device-6 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscoverer.devicesCalled, 3);
            expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('including attached, wireless, unsupported devices', () async {
          deviceManager.androidDiscoverer.deviceList = <Device>[
            attachedAndroidDevice1,
            attachedUnsupportedAndroidDevice,
            attachedUnsupportedForProjectAndroidDevice,
            wirelessAndroidDevice1,
            wirelessUnsupportedAndroidDevice,
            wirelessUnsupportedForProjectAndroidDevice,
          ];
          deviceManager.otherDiscoverer.deviceList = <Device>[fuchsiaDevice];

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[attachedAndroidDevice1, wirelessAndroidDevice1]);
          expect(deviceManager.androidDiscoverer.devicesCalled, 2);
          expect(deviceManager.androidDiscoverer.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscoverer.numberOfTimesPolled, 1);
        });
      });
    });

  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager({
    required this.logger,
    required this.platform,
  }) : super(logger: logger);

  final Logger logger;
  final Platform platform;

  @override
  String? specifiedDeviceId;

  @override
  bool hasSpecifiedAllDevices = false;

  final TestPollingDeviceDiscovery androidDiscoverer = TestPollingDeviceDiscovery(
    'android',
  );
  final TestPollingDeviceDiscovery otherDiscoverer = TestPollingDeviceDiscovery(
    'other',
  );
  final TestPollingDeviceDiscovery iosDiscoverer = TestPollingDeviceDiscovery(
    'ios',
  );

  @override
  List<DeviceDiscovery> get deviceDiscoverers {
    return <DeviceDiscovery>[
      androidDiscoverer,
      otherDiscoverer,
      iosDiscoverer,
    ];
  }
}

class TestPollingDeviceDiscovery extends PollingDeviceDiscovery {
  TestPollingDeviceDiscovery(super.name);

  List<Device> deviceList = <Device>[];
  List<Device> refreshDeviceList = <Device>[];
  int devicesCalled = 0;
  int discoverDevicesCalled = 0;
  int numberOfTimesPolled = 0;

  @override
  bool get supportsPlatform => true;

  @override
  List<String> get wellKnownIds => const <String>[];

  @override
  Future<List<Device>> pollingGetDevices({Duration? timeout}) async {
    numberOfTimesPolled++;
    return deviceList;
  }

  @override
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter}) async {
    devicesCalled += 1;
    return super.devices(filter: filter);
  }

  @override
  Future<List<Device>> discoverDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
  }) {
    discoverDevicesCalled++;
    if (refreshDeviceList.isNotEmpty) {
      deviceList = refreshDeviceList;
    }
    return super.discoverDevices(timeout: timeout, filter: filter);
  }

  @override
  bool get canListAnything => true;
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeDevice extends Fake implements Device {
  FakeDevice({
    String? deviceId,
    String? deviceName,
    bool deviceSupported = true,
    bool deviceSupportForProject = true,
    this.ephemeral = true,
    this.isConnected = true,
    this.connectionInterface = DeviceConnectionInterface.attached,
    this.platformType = PlatformType.android,
    TargetPlatform deviceTargetPlatform = TargetPlatform.android,
  })  : id = deviceId ?? 'xxx',
        name = deviceName ?? 'test',
        _isSupported = deviceSupported,
        _isSupportedForProject = deviceSupportForProject,
        _targetPlatform = deviceTargetPlatform;

  FakeDevice.wireless({
    String? deviceId,
    String? deviceName,
    bool deviceSupported = true,
    bool deviceSupportForProject = true,
    this.ephemeral = true,
    this.isConnected = true,
    this.connectionInterface = DeviceConnectionInterface.wireless,
    this.platformType = PlatformType.android,
    TargetPlatform deviceTargetPlatform = TargetPlatform.android,
  })  : id = deviceId ?? 'xxx',
        name = deviceName ?? 'test',
        _isSupported = deviceSupported,
        _isSupportedForProject = deviceSupportForProject,
        _targetPlatform = deviceTargetPlatform;

  FakeDevice.fuchsia({
    String? deviceId,
    String? deviceName,
    bool deviceSupported = true,
    bool deviceSupportForProject = true,
    this.ephemeral = true,
    this.isConnected = true,
    this.connectionInterface = DeviceConnectionInterface.attached,
    this.platformType = PlatformType.fuchsia,
    TargetPlatform deviceTargetPlatform = TargetPlatform.fuchsia_arm64,
  })  : id = deviceId ?? 'xxx',
        name = deviceName ?? 'test',
        _isSupported = deviceSupported,
        _isSupportedForProject = deviceSupportForProject,
        _targetPlatform = deviceTargetPlatform,
        _sdkNameAndVersion = 'tester';

  final bool _isSupported;
  final bool _isSupportedForProject;
  final TargetPlatform _targetPlatform;
  String _sdkNameAndVersion = 'Android 10';

  @override
  String name;

  @override
  final bool ephemeral;

  @override
  String id;

  @override
  bool isSupported() => _isSupported;

  @override
  bool isSupportedForProject(FlutterProject project) => _isSupportedForProject;

  @override
  DeviceConnectionInterface connectionInterface;

  @override
  bool isConnected;

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  final PlatformType? platformType;

  @override
  Future<String> get sdkNameAndVersion async => _sdkNameAndVersion;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Category? get category => Category.mobile;

  @override
  Future<String> get targetPlatformDisplayName async =>
      getNameForTargetPlatform(await targetPlatform);
}

class FakeTerminal extends Fake implements AnsiTerminal {
  FakeTerminal({this.stdinHasTerminal = true});

  @override
  final bool stdinHasTerminal;

  @override
  bool usesTerminalUi = true;

  void setPrompt(List<String> characters, String result) {
    _nextPrompt = characters;
    _nextResult = result;
  }

  List<String>? _nextPrompt;
  late String _nextResult;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger? logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    expect(acceptedCharacters, _nextPrompt);
    return _nextResult;
  }
}

class FakeDoctor extends Fake implements Doctor {
  FakeDoctor({
    this.canLaunchAnything = true,
  });

  @override
  bool canLaunchAnything;
}
