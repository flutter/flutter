// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/target_devices.dart';
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';
import '../ios/devices_test.dart';

void main() {
  testUsingContext('Ensure factory returns MacPlatformTargetDevices on macos', () async {
    final BufferLogger logger = BufferLogger.test();
    final Platform platform = FakePlatform(operatingSystem: 'macos');
    final TestDeviceManager deviceManager = TestDeviceManager(
      logger: logger,
      platform: platform,
    );

    final TargetDevices targetDevices = TargetDevices(
      platform: platform,
      deviceManager: deviceManager,
      logger: logger,
    );

    expect(targetDevices is MacPlatformTargetDevices, true);
  });

  testUsingContext('Ensure factory returns default when OS is not mac', () async {
    final BufferLogger logger = BufferLogger.test();
    final Platform platform = FakePlatform();
    final TestDeviceManager deviceManager = TestDeviceManager(
      logger: logger,
      platform: platform,
    );

    final TargetDevices targetDevices = TargetDevices(
      platform: platform,
      deviceManager: deviceManager,
      logger: logger,
    );

    expect(targetDevices is MacPlatformTargetDevices, false);
  });

  group('Ensure refresh when deviceDiscoveryTimeout is provided', () {
    late Platform platform;
    late BufferLogger logger;
    late TestDeviceManager deviceManager;

    testUsingContext('using TargetDevices', () async {
      platform = FakePlatform();
      logger = BufferLogger.test();
      deviceManager = TestDeviceManager(
        logger: logger,
        platform: platform,
      );
      final FakeDevice device1 = FakeDevice(deviceName: 'device-1');
      final FakeDevice device2 = FakeDevice.wireless(deviceName: 'device-2');
      deviceManager.androidDiscover.deviceList = <Device>[device1];
      deviceManager.androidDiscover.refreshDeviceList = <Device>[device2];

      final TargetDevices targetDevices = TargetDevices(
        platform: platform,
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices(
        flutterProject: FakeFlutterProject(),
        deviceDiscoveryTimeout: const Duration(seconds: 2),
      );

      expect(logger.statusText, equals(''));
      expect(devices, <Device>[device2]);
      expect(deviceManager.androidDiscover.devicesCalled, 2);
      expect(deviceManager.androidDiscover.discoverDevicesCalled, 1);
      expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
    });

    testUsingContext('using MacPlatformTargetDevices', () async {
      platform = FakePlatform(operatingSystem: 'macos');
      logger = BufferLogger.test();
      deviceManager = TestDeviceManager(
        logger: logger,
        platform: platform,
      );
      final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'device-1');
      final FakeIOSDevice device2 = FakeIOSDevice.connectedWireless(deviceName: 'device-2');
      deviceManager.iosDiscovery.deviceList = <Device>[device1];
      deviceManager.iosDiscovery.refreshDeviceList = <Device>[device2];

      final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices(
        flutterProject: FakeFlutterProject(),
        deviceDiscoveryTimeout: const Duration(seconds: 2),
      );

      expect(logger.statusText, equals(''));
      expect(devices, <Device>[device2]);
      expect(deviceManager.androidDiscover.devicesCalled, 2);
      expect(deviceManager.androidDiscover.discoverDevicesCalled, 1);
      expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
    });
  });

  group('Ensure unsupported for projects are included when flutterProject is null', () {
    late Platform platform;
    late BufferLogger logger;
    late TestDeviceManager deviceManager;

    testUsingContext('using TargetDevices', () async {
      platform = FakePlatform();
      logger = BufferLogger.test();
      deviceManager = TestDeviceManager(
        logger: logger,
        platform: platform,
      );
      final FakeDevice device1 = FakeDevice(deviceName: 'device-1', deviceSupportForProject: false);
      final FakeDevice device2 = FakeDevice(deviceName: 'device-2', deviceSupported: false);
      deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

      final TargetDevices targetDevices = TargetDevices(
        platform: platform,
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices();

      expect(devices, <Device>[device1]);
    });

    testUsingContext('using MacPlatformTargetDevices', () async {
      platform = FakePlatform(operatingSystem: 'macos');
      logger = BufferLogger.test();
      deviceManager = TestDeviceManager(
        logger: logger,
        platform: platform,
      );
      final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'device-1', deviceSupportForProject: false);
      final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'device-2', deviceSupported: false);
      deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

      final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices();

      expect(devices, <Device>[device1]);
    });
  });

  group('Finds no devices', () {
    late Platform platform;
    late BufferLogger logger;
    late TestDeviceManager deviceManager;

    group('using TargetDevices', () {
      setUp(() {
        platform = FakePlatform();
        logger = BufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      testUsingContext('when no devices', () async {
        final TargetDevices targetDevices = TargetDevices(
          platform: platform,
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals('''
No supported devices connected.
'''));
        expect(devices, isNull);
        expect(deviceManager.androidDiscover.devicesCalled, 3);
        expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
        expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
      });

      testUsingContext('when device is unsupported by flutter or project', () async {
        final FakeDevice device1 = FakeDevice(deviceName: 'device-1', deviceSupported: false);
        final FakeDevice device2 = FakeDevice(deviceName: 'device-2', deviceSupportForProject: false);
        deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

        final TargetDevices targetDevices = TargetDevices(
          platform: platform,
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals('''
No supported devices connected.

The following devices were found, but are not supported by this project:
device-1 (mobile) • xxx • android • Android 10 (unsupported)
device-2 (mobile) • xxx • android • Android 10
If you would like your app to run on android, consider running `flutter create .` to generate projects for these platforms.
'''));
        expect(devices, isNull);
        expect(deviceManager.androidDiscover.devicesCalled, 3);
        expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
        expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        testUsingContext('when no devices', () async {
          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 4);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('when no devices match', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'no-match-1');
          final FakeDevice device2 = FakeDevice.wireless(deviceName: 'no-match-2');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.

The following devices were found:
no-match-1 (mobile) • xxx • android • Android 10
no-match-2 (mobile) • xxx • android • Android 10
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 4);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching device is unsupported by flutter', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device', deviceSupported: false);
          deviceManager.androidDiscover.deviceList = <Device>[device1];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.

The following devices were found:
target-device (mobile) • xxx • android • Android 10 (unsupported)
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 4);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        group('when deviceConnectionInterface does not match', () {
          testUsingContext('with filtered to wireless', () async {
            final FakeDevice device1 = FakeDevice(deviceName: 'target-device');
            final FakeDevice device2 = FakeDevice.wireless(deviceName: 'not-a-match');
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.wireless,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.

The following devices were found:
not-a-match (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          });

          testUsingContext('with filtered to attached', () async {
            final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device');
            final FakeDevice device2 = FakeDevice(deviceName: 'not-a-match');
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.attached,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.

The following devices were found:
not-a-match (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          });
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('when no devices', () async {
          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 3);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('when devices are either unsupported by flutter or project or all', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'device-1', deviceSupported: false);
          final FakeDevice device2 = FakeDevice(deviceName: 'device-2', deviceSupportForProject: false);
          final FakeDevice device3 = FakeDevice.fuchsia(deviceName: 'device-3');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];
          deviceManager.otherDiscover.deviceList = <Device>[device3];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found.

The following devices were found, but are not supported by this project:
device-1 (mobile) • xxx • android       • Android 10 (unsupported)
device-2 (mobile) • xxx • android       • Android 10
device-3 (mobile) • xxx • fuchsia-arm64 • tester
If you would like your app to run on android or fuchsia, consider running `flutter create .` to generate projects for these platforms.
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 3);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        group('when deviceConnectionInterface does not match', () {
          testUsingContext('with filtered to wireless', () async {
            final FakeDevice device1 = FakeDevice(deviceName: 'target-device-id');
            deviceManager.androidDiscover.deviceList = <Device>[device1];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.wireless,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No devices found.
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 2);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          });

          testUsingContext('with filtered to attached', () async {
            final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device-id');
            deviceManager.androidDiscover.deviceList = <Device>[device1];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.attached,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No devices found.
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 2);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          });
        });
      });
    });

    group('using MacPlatformTargetDevices', () {
      setUp(() {
        platform = FakePlatform(operatingSystem: 'macos');
        logger = TestBufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      testUsingContext('when no devices', () async {
        final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(devices, isNull);
        expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No supported devices connected.
'''));
        expect(deviceManager.iosDiscovery.devicesCalled, 3);
        expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
        expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
      });

      testUsingContext('when device is unsupported by flutter or project', () async {
        final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'device-1', deviceSupported: false);
        final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'device-2', deviceSupported: false);
        final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'device-2', deviceSupported: false);
        final FakeIOSDevice device3 = FakeIOSDevice(deviceName: 'device-3', deviceSupportForProject: false);
        deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3];
        deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2Connected, device3];

        final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No supported devices connected.

The following devices were found, but are not supported by this project:
device-1 (mobile) • xxx • ios • iOS 16 (unsupported)
device-2 (mobile) • xxx • ios • iOS 16 (unsupported)
device-3 (mobile) • xxx • ios • iOS 16
If you would like your app to run on ios, consider running `flutter create .` to generate projects for these platforms.
'''));
        expect(devices, isNull);
        expect(deviceManager.iosDiscovery.devicesCalled, 3);
        expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
        expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        testUsingContext('when no devices', () async {
          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No supported devices found with name or id matching 'target-device'.
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when no names/ids match', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'no-match-1');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'no-match-2');
          final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'no-match-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1,device2Connected];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No supported devices found with name or id matching 'target-device'.

The following devices were found:
no-match-1 (mobile) • xxx • ios • iOS 16
no-match-2 (mobile) • xxx • ios • iOS 16
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when matching device is unsupported by flutter', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device', deviceSupported: false);
          deviceManager.iosDiscovery.deviceList = <Device>[device1];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No supported devices found with name or id matching 'target-device'.

The following devices were found:
target-device (mobile) • xxx • ios • iOS 16 (unsupported)
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when partially matching single not connected wireless device', () async {
          final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
          deviceManager.iosDiscovery.deviceList = <Device>[device1];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No supported devices found with name or id matching 'target-device'.
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        group('when deviceConnectionInterface does not match', () {
          testUsingContext('filtered to attached and no matching wireless', () async {
            final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'not-a-match');
            deviceManager.iosDiscovery.deviceList = <Device>[device1];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.attached,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 0);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
          });

          testUsingContext('filtered to attached with a matching wireless', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'not-a-match');
            final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device');
            final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.attached,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No supported devices found with name or id matching 'target-device'.

The following devices were found:
not-a-match (mobile) • xxx • ios • iOS 16
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 0);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
          });

          testUsingContext('filtered to wireless', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device');
            final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'not-a-match');
            final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'not-a-match');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.wireless,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Checking for wireless devices...

No supported devices found with name or id matching 'target-device'.

The following devices were found:
not-a-match (mobile) • xxx • ios • iOS 16
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          });
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('when no devices', () async {
          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No devices found.
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 3);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when devices are either unsupported by flutter or project or all', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1', deviceSupported: false);
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2', deviceSupported: false);
          final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2', deviceSupported: false);
          final FakeIOSDevice device3 = FakeIOSDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
          final FakeDevice device4 = FakeDevice.fuchsia(deviceName: 'target-device-4');
          deviceManager.otherDiscover.deviceList = <Device>[device4];
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2Connected, device3];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

No devices found.

The following devices were found, but are not supported by this project:
target-device-4 (mobile) • xxx • fuchsia-arm64 • tester
target-device-1 (mobile) • xxx • ios           • iOS 16 (unsupported)
target-device-2 (mobile) • xxx • ios           • iOS 16 (unsupported)
target-device-3 (mobile) • xxx • ios           • iOS 16
If you would like your app to run on fuchsia or ios, consider running `flutter create .` to generate projects for these platforms.
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 3);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        group('when deviceConnectionInterface does not match', () {
          testUsingContext('with filtered to attached', () async {
            final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.attached,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No devices found.
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 2);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 0);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
          });

          testUsingContext('with filtered to wireless', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
              deviceConnectionInterface: DeviceConnectionInterface.wireless,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Checking for wireless devices...

No devices found.
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 2);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
          });
        });
      });
    });
  });

  group('Finds single device', () {
    late Platform platform;
    late BufferLogger logger;
    late TestDeviceManager deviceManager;

    group('using TargetDevices', () {
      setUp(() {
        platform = FakePlatform();
        logger = BufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      testUsingContext('when single wireless device', () async {
        final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device');
        deviceManager.androidDiscover.deviceList = <Device>[device1];

        final TargetDevices targetDevices = TargetDevices(
          platform: platform,
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals(''));
        expect(devices, <Device>[device1]);
        expect(deviceManager.androidDiscover.devicesCalled, 2);
        expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
        expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
      });

      testUsingContext('when single attached device', () async {
        final FakeDevice device1 = FakeDevice(deviceName: 'target-device');
        deviceManager.androidDiscover.deviceList = <Device>[device1];

        final TargetDevices targetDevices = TargetDevices(
          platform: platform,
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals(''));
        expect(devices, <Device>[device1]);
        expect(deviceManager.androidDiscover.devicesCalled, 2);
        expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
        expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
      });

      testUsingContext('when multiple but only one ephemeral', () async {
        final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1', ephemeral: false);
        final FakeDevice device2 = FakeDevice.wireless(deviceName: 'target-device-1');
        deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

        final TargetDevices targetDevices = TargetDevices(
          platform: platform,
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals(''));
        expect(devices, <Device>[device2]);
        expect(deviceManager.androidDiscover.devicesCalled, 2);
        expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
        expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        testUsingContext('when multiple matches but first is unsupported by flutter', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device', deviceSupported: false);
          final FakeDevice device2 = FakeDevice(deviceName: 'target-device');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device2]);
          expect(deviceManager.androidDiscover.devicesCalled, 1);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching device is unsupported by project', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device', deviceSupportForProject: false);
          deviceManager.androidDiscover.deviceList = <Device>[device1];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.androidDiscover.devicesCalled, 1);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching attached device', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device');
          deviceManager.androidDiscover.deviceList = <Device>[device1];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.androidDiscover.devicesCalled, 1);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('when matching wireless device', () async {
          final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device');
          deviceManager.androidDiscover.deviceList = <Device>[device1];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.androidDiscover.devicesCalled, 1);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('when multiple devices match but only one matches deviceConnectionInterface of attached', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice.wireless(deviceName: 'target-device-2');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
            deviceConnectionInterface: DeviceConnectionInterface.attached,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.androidDiscover.devicesCalled, 1);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('when multiple devices match but only one matches deviceConnectionInterface of wireless', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice.wireless(deviceName: 'target-device-2');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
            deviceConnectionInterface: DeviceConnectionInterface.wireless,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device2]);
          expect(deviceManager.androidDiscover.devicesCalled, 1);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });
      });
    });

    group('using MacPlatformTargetDevices', () {
      setUp(() {
        platform = FakePlatform(operatingSystem: 'macos');
        logger = TestBufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      testUsingContext('when single wireless device', () async {
        final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
        final FakeIOSDevice device1Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-1');
        deviceManager.iosDiscovery.deviceList = <Device>[device1];
        deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1Connected];

        final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...
'''));
        expect(devices, <Device>[device1Connected]);
        expect(deviceManager.iosDiscovery.devicesCalled, 2);
        expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
        expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
      });

      testUsingContext('when multiple but only one attached ephemeral', () async {
        final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1', ephemeral: false);
        final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
        final FakeIOSDevice device3 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-3');
        final FakeIOSDevice device3Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-3');
        deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3];
        deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2, device3Connected];

        final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals(''));
        expect(devices, <Device>[device2]);
        expect(deviceManager.iosDiscovery.devicesCalled, 2);
        expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
        expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
      });

      testUsingContext('when only non-ephemeral attached device', () async {
        final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1', ephemeral: false);
        deviceManager.iosDiscovery.deviceList = <Device>[device1];

        final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
          deviceManager: deviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals('''
Checking for wireless devices...
'''));
        expect(devices, <Device>[device1]);
        expect(deviceManager.iosDiscovery.devicesCalled, 2);
        expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
        expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
      });

      testUsingContext('when multiple devices but only one matches deviceConnectionInterface of attached', () async {
        final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
        final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
        deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

        final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
          deviceManager: deviceManager,
          logger: logger,
          deviceConnectionInterface: DeviceConnectionInterface.attached,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices(
          flutterProject: FakeFlutterProject(),
        );

        expect(logger.statusText, equals(''));
        expect(devices, <Device>[device1]);
        expect(deviceManager.iosDiscovery.devicesCalled, 1);
        expect(deviceManager.iosDiscovery.discoverDevicesCalled, 0);
        expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        testUsingContext('when multiple matches but first is unsupported by flutter', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device', deviceSupported: false);
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device2]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when matching device is unsupported by project', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device', deviceSupportForProject: false);
          deviceManager.iosDiscovery.deviceList = <Device>[device1];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when matching attached device', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when matching wireless device', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.setDeviceToWaitFor(device2, IOSDeviceConnectionInterface.network);

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Waiting for target-device to connect...
'''));
          expect(devices, <Device>[device2]);
          expect(devices?.first.isConnected, true);
          expect(devices?.first.connectionInterface, DeviceConnectionInterface.wireless);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when partially matching multiple device but only one', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Checking for wireless devices...
'''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.iosDiscovery.devicesCalled, 3);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('when partially matching single attached device', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          deviceManager.iosDiscovery.deviceList = <Device>[device1];

          final MacPlatformTargetDevices targetDevices = MacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('when multiple devices match but only one matches deviceConnectionInterface of attached', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
            deviceConnectionInterface: DeviceConnectionInterface.attached,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.iosDiscovery.devicesCalled, 1);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 0);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
        });

        testUsingContext('when multiple devices match but only one matches deviceConnectionInterface of wireless', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device',);
          final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2Connected];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
            deviceConnectionInterface: DeviceConnectionInterface.wireless,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Checking for wireless devices...
'''));
          expect(devices, <Device>[device2Connected]);
          expect(deviceManager.iosDiscovery.devicesCalled, 1);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
        });
      });
    });
  });

  group('Finds multiple devices', () {
    late Platform platform;
    late TestDeviceManager deviceManager;

    group('using TargetDevices', () {
      late BufferLogger logger;
      setUp(() {
        platform = FakePlatform();
        logger = BufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      group('with stdinHasTerminal', () {
        late FakeTerminal terminal;

        setUp(() {
          terminal = FakeTerminal();
        });

        testUsingContext('including attached, wireless, unsupported devices', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2', deviceSupported: false);
          final FakeDevice device3 = FakeDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
          final FakeDevice device4 = FakeDevice.wireless(deviceName: 'target-device-4');
          final FakeDevice device5 = FakeDevice.wireless(deviceName: 'target-device-5', deviceSupported: false);
          final FakeDevice device6 = FakeDevice.wireless(deviceName: 'target-device-6', deviceSupportForProject: false);
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2, device3, device4, device5, device6];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '2');
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-4 (mobile) • xxx • android • Android 10

[1]: target-device-1 (xxx)
[2]: target-device-4 (xxx)
'''));
          expect(devices, <Device>[device4]);
          expect(deviceManager.androidDiscover.devicesCalled, 2);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only attached devices', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.androidDiscover.devicesCalled, 2);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only wireless devices', () async {
          final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice.wireless(deviceName: 'target-device-2');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Multiple devices found:

Wirelessly connected devices:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
          expect(devices, <Device>[device1]);
          expect(deviceManager.androidDiscover.devicesCalled, 2);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
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
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2', deviceSupported: false);
          final FakeDevice device3 = FakeDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
          final FakeDevice device4 = FakeDevice.wireless(deviceName: 'target-device-4');
          final FakeDevice device5 = FakeDevice.wireless(deviceName: 'target-device-5', deviceSupported: false);
          final FakeDevice device6 = FakeDevice.wireless(deviceName: 'target-device-6', deviceSupportForProject: false);
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2, device3, device4, device5, device6];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • android • Android 10
target-device-3 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-4 (mobile) • xxx • android • Android 10
target-device-6 (mobile) • xxx • android • Android 10
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 4);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only attached devices', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 4);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only wireless devices', () async {
          final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice.wireless(deviceName: 'target-device-2');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

Wirelessly connected devices:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
'''));
          expect(devices, isNull);
          expect(deviceManager.androidDiscover.devicesCalled, 4);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
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
            final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
            final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2', deviceSupported: false);
            final FakeDevice device3 = FakeDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
            final FakeDevice device4 = FakeDevice.wireless(deviceName: 'target-device-4');
            final FakeDevice device5 = FakeDevice.wireless(deviceName: 'target-device-5', deviceSupported: false);
            final FakeDevice device6 = FakeDevice.wireless(deviceName: 'target-device-6', deviceSupportForProject: false);
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2, device3, device4, device5, device6];

            terminal.setPrompt(<String>['1', '2', '3', '4', 'q', 'Q'], '2');
            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found 4 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-3 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-4 (mobile) • xxx • android • Android 10
target-device-6 (mobile) • xxx • android • Android 10

[1]: target-device-1 (xxx)
[2]: target-device-3 (xxx)
[3]: target-device-4 (xxx)
[4]: target-device-6 (xxx)
'''));
            expect(devices, <Device>[device3]);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
            final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2');
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
            expect(devices, <Device>[device1]);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device-1');
            final FakeDevice device2 = FakeDevice.wireless(deviceName: 'target-device-2');
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:

Wirelessly connected devices:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
            expect(devices, <Device>[device1]);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
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
            final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1', ephemeral: false);
            final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2');
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including matching attached, wireless, unsupported devices', () async {
            final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
            final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2', deviceSupported: false);
            final FakeDevice device3 = FakeDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
            final FakeDevice device4 = FakeDevice.wireless(deviceName: 'target-device-4');
            final FakeDevice device5 = FakeDevice.wireless(deviceName: 'target-device-5', deviceSupported: false);
            final FakeDevice device6 = FakeDevice.wireless(deviceName: 'target-device-6', deviceSupportForProject: false);
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2, device3, device4, device5, device6];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found 4 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-3 (mobile) • xxx • android • Android 10

Wirelessly connected devices:
target-device-4 (mobile) • xxx • android • Android 10
target-device-6 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
            final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2');
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            final FakeDevice device1 = FakeDevice.wireless(deviceName: 'target-device-1');
            final FakeDevice device2 = FakeDevice.wireless(deviceName: 'target-device-2');
            deviceManager.androidDiscover.deviceList = <Device>[device1, device2];

            final TargetDevices targetDevices = TargetDevices(
              platform: platform,
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found 2 devices with name or id matching target-device:

Wirelessly connected devices:
target-device-1 (mobile) • xxx • android • Android 10
target-device-2 (mobile) • xxx • android • Android 10
'''));
            expect(devices, isNull);
            expect(deviceManager.androidDiscover.devicesCalled, 3);
            expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
            expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
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
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeDevice device2 = FakeDevice(deviceName: 'target-device-2', deviceSupported: false);
          final FakeDevice device3 = FakeDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
          final FakeDevice device4 = FakeDevice.wireless(deviceName: 'target-device-4');
          final FakeDevice device5 = FakeDevice.wireless(deviceName: 'target-device-5', deviceSupported: false);
          final FakeDevice device6 = FakeDevice.wireless(deviceName: 'target-device-6', deviceSupportForProject: false);
          final FakeDevice device7 = FakeDevice.fuchsia(deviceName: 'target-device-7');
          deviceManager.androidDiscover.deviceList = <Device>[device1, device2, device3, device4, device5, device6];
          deviceManager.otherDiscover.deviceList = <Device>[device7];

          final TargetDevices targetDevices = TargetDevices(
            platform: platform,
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals(''));
          expect(devices, <Device>[device1, device4]);
          expect(deviceManager.androidDiscover.devicesCalled, 2);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 1);
        });
      });
    });

    group('using MacPlatformTargetDevices', () {
      late TestBufferLogger logger;

      setUp(() {
        platform = FakePlatform(operatingSystem: 'macos');
        logger = TestBufferLogger.test();
        deviceManager = TestDeviceManager(
          logger: logger,
          platform: platform,
        );
      });

      group('with stdinHasTerminal', () {
        late FakeTerminal terminal;

        setUp(() {
          terminal = FakeTerminal(supportsColor: true);
          logger = TestBufferLogger.test(terminal: terminal);
        });

        testUsingContext('including attached, wireless, unsupported devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
          final FakeIOSDevice device3 = FakeIOSDevice(deviceName: 'target-device-3', deviceSupported: false);
          final FakeIOSDevice device4 = FakeIOSDevice(deviceName: 'target-device-4', deviceSupportForProject: false);
          final FakeIOSDevice device5 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-5');
          final FakeIOSDevice device6 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-6', deviceSupported: false);
          final FakeIOSDevice device7 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-7', deviceSupportForProject: false);
          final FakeIOSDevice device5Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-5');
          final FakeIOSDevice device6Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-6', deviceSupported: false);
          final FakeIOSDevice device7Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-7', deviceSupported: false);
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3, device4, device5, device6, device7];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2, device3, device4, device5Connected, device6Connected, device7Connected];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          targetDevices.waitForWirelessBeforeInput = true;
          targetDevices.deviceSelection.input = '3';
          logger.originalStatusText = '''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
''';
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-5 (mobile) • xxx • ios • iOS 16

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
[3]: target-device-5 (xxx)
Please choose one (or "q" to quit): '''));
          expect(devices, <Device>[device5Connected]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only attached devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          targetDevices.waitForWirelessBeforeInput = true;
          targetDevices.deviceSelection.input = '2';
          logger.originalStatusText = '''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
''';
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

No wireless devices were found.

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
Please choose one (or "q" to quit): '''));

          expect(devices, <Device>[device2]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only wireless devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
          final FakeIOSDevice device1Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-1');
          final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1Connected, device2Connected];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          targetDevices.waitForWirelessBeforeInput = true;
          targetDevices.deviceSelection.input = '2';
          terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

Multiple devices found:

Wirelessly connected devices:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
          expect(devices, <Device>[device1Connected]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        group('but no color support', () {
          setUp(() {
            terminal = FakeTerminal();
            logger = TestBufferLogger.test(terminal: terminal);
          });

          testUsingContext('waits for wireless devices to return', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
            final FakeIOSDevice device3 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-3');
            final FakeIOSDevice device3Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-3');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2, device3Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            terminal.setPrompt(<String>['1', '2', '3', 'q', 'Q'], '1');
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Checking for wireless devices...

Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-3 (mobile) • xxx • ios • iOS 16

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
[3]: target-device-3 (xxx)
'''));
            expect(devices, <Device>[device1]);
            expect(deviceManager.iosDiscovery.devicesCalled, 2);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });
        });

        group('with verbose logging', () {
          setUp(() {
            logger = TestBufferLogger.test(terminal: terminal, verbose: true);
          });

          testUsingContext('including only attached devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            targetDevices.waitForWirelessBeforeInput = true;
            targetDevices.deviceSelection.input = '2';
            logger.originalStatusText = '''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
''';
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
No wireless devices were found.
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
Please choose one (or "q" to quit): '''));

            expect(devices, <Device>[device2]);
            expect(deviceManager.iosDiscovery.devicesCalled, 2);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including attached and wireless devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
            final FakeIOSDevice device3 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-3');
            final FakeIOSDevice device3Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-3');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2, device3Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            targetDevices.waitForWirelessBeforeInput = true;
            targetDevices.deviceSelection.input = '2';
            logger.originalStatusText = '''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)

[2]: target-device-2 (xxx)
''';
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
Multiple devices found:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-3 (mobile) • xxx • ios • iOS 16

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
[3]: target-device-3 (xxx)
Please choose one (or "q" to quit): '''));

            expect(devices, <Device>[device2]);
            expect(deviceManager.iosDiscovery.devicesCalled, 2);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });
        });
      });

      group('without stdinHasTerminal', () {
        late FakeTerminal terminal;

        setUp(() {
          terminal = FakeTerminal(stdinHasTerminal: false);
        });

        testUsingContext('but only one wireless ephemeral', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1', ephemeral: false);
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
          final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2Connected];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Checking for wireless devices...

More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-2 (mobile) • xxx • ios • iOS 16
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including attached, wireless, unsupported devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
          final FakeIOSDevice device3 = FakeIOSDevice(deviceName: 'target-device-3', deviceSupported: false);
          final FakeIOSDevice device4 = FakeIOSDevice(deviceName: 'target-device-4', deviceSupportForProject: false);
          final FakeIOSDevice device5 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-5');
          final FakeIOSDevice device6 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-6', deviceSupported: false);
          final FakeIOSDevice device7 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-7', deviceSupportForProject: false);
          final FakeIOSDevice device5Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-5');
          final FakeIOSDevice device6Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-6', deviceSupported: false);
          final FakeIOSDevice device7Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-7', deviceSupportForProject: false);
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3, device4, device5, device6, device7];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2, device3, device4, device5Connected, device6Connected, device7Connected];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Checking for wireless devices...

More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16
target-device-4 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-5 (mobile) • xxx • ios • iOS 16
target-device-7 (mobile) • xxx • ios • iOS 16
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only attached devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Checking for wireless devices...

More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('including only wireless devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
          final FakeIOSDevice device1Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-1');
          final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1Connected, device2Connected];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

Wirelessly connected devices:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16
'''));

          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 4);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('when deviceConnectionInterface is filtered to attached', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
          final FakeIOSDevice device3 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-3');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
            deviceConnectionInterface: DeviceConnectionInterface.attached,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16
'''));
          expect(devices, isNull);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 0);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 1);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });
      });

      group('with hasSpecifiedDeviceId', () {
        setUp(() {
          deviceManager.specifiedDeviceId = 'target-device';
        });

        group('with stdinHasTerminal', () {
          late FakeTerminal terminal;

          setUp(() {
            terminal = FakeTerminal(supportsColor: true);
            logger = TestBufferLogger.test(terminal: terminal);
          });

          testUsingContext('including matching attached, wireless, unsupported devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2', deviceSupported: false);
            final FakeIOSDevice device3 = FakeIOSDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
            final FakeIOSDevice device4 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-4');
            final FakeIOSDevice device5 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-5', deviceSupported: false);
            final FakeIOSDevice device6 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-6', deviceSupportForProject: false);
            final FakeIOSDevice device4Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-4');
            final FakeIOSDevice device5Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-5', deviceSupported: false);
            final FakeIOSDevice device6Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-6', deviceSupportForProject: false);
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3, device4, device5, device6];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2, device3, device4Connected, device5Connected, device6Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            targetDevices.waitForWirelessBeforeInput = true;
            targetDevices.deviceSelection.input = '3';
            logger.originalStatusText = '''
Found multiple devices with name or id matching target-device:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-3 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)
[2]: target-device-3 (xxx)
''';
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found multiple devices with name or id matching target-device:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-3 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-4 (mobile) • xxx • ios • iOS 16
target-device-6 (mobile) • xxx • ios • iOS 16

[1]: target-device-1 (xxx)
[2]: target-device-3 (xxx)
[3]: target-device-4 (xxx)
[4]: target-device-6 (xxx)
Please choose one (or "q" to quit): '''));
            expect(devices, <Device>[device4Connected]);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            targetDevices.waitForWirelessBeforeInput = true;
            targetDevices.deviceSelection.input = '2';
            logger.originalStatusText = '''
Found multiple devices with name or id matching target-device:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

Checking for wireless devices...

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
''';
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Found multiple devices with name or id matching target-device:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

No wireless devices were found.

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
Please choose one (or "q" to quit): '''));
            expect(devices, <Device>[device2]);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
            final FakeIOSDevice device1Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-1');
            final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1Connected, device2Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            targetDevices.waitForWirelessBeforeInput = true;
            targetDevices.deviceSelection.input = '2';
            terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

Found 2 devices with name or id matching target-device:

Wirelessly connected devices:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16

[1]: target-device-1 (xxx)
[2]: target-device-2 (xxx)
'''));
            expect(devices, <Device>[device1Connected]);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });
        });

        group('without stdinHasTerminal', () {
          late FakeTerminal terminal;

          setUp(() {
            terminal = FakeTerminal(stdinHasTerminal: false);
          });

          testUsingContext('including only one attached ephemeral', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
            final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Checking for wireless devices...

Found 2 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-2 (mobile) • xxx • ios • iOS 16
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including matching attached, wireless, unsupported devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2', deviceSupported: false);
            final FakeIOSDevice device3 = FakeIOSDevice(deviceName: 'target-device-3', deviceSupportForProject: false);
            final FakeIOSDevice device4 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-4');
            final FakeIOSDevice device5 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-5', deviceSupported: false);
            final FakeIOSDevice device6 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-6', deviceSupportForProject: false);
            final FakeIOSDevice device4Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-4');
            final FakeIOSDevice device5Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-5', deviceSupported: false);
            final FakeIOSDevice device6Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-6', deviceSupportForProject: false);
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2, device3, device4, device5, device6];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1, device2, device3, device4Connected, device5Connected, device6Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Checking for wireless devices...

Found 4 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-3 (mobile) • xxx • ios • iOS 16

Wirelessly connected devices:
target-device-4 (mobile) • xxx • ios • iOS 16
target-device-6 (mobile) • xxx • ios • iOS 16
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only attached devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
Checking for wireless devices...

Found 2 devices with name or id matching target-device:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

          testUsingContext('including only wireless devices', () async {
            final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
            final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
            final FakeIOSDevice device1Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-1');
            final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2');
            deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
            deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1Connected, device2Connected];

            final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
              deviceManager: deviceManager,
              logger: logger,
            );
            final List<Device>? devices = await targetDevices.findAllTargetDevices(
              flutterProject: FakeFlutterProject(),
            );

            expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...

Found 2 devices with name or id matching target-device:

Wirelessly connected devices:
target-device-1 (mobile) • xxx • ios • iOS 16
target-device-2 (mobile) • xxx • ios • iOS 16
'''));
            expect(devices, isNull);
            expect(deviceManager.iosDiscovery.devicesCalled, 3);
            expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
            expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });
        });
      });

      group('with hasSpecifiedAllDevices', () {
        setUp(() {
          deviceManager.hasSpecifiedAllDevices = true;
        });

        testUsingContext('including matching attached, wireless, unsupported devices', () async {
          final FakeDevice device1 = FakeDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
          final FakeIOSDevice device3 = FakeIOSDevice(deviceName: 'target-device-3', deviceSupported: false);
          final FakeIOSDevice device4 = FakeIOSDevice(deviceName: 'target-device-4', deviceSupportForProject: false);
          final FakeIOSDevice device5 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-5');
          final FakeIOSDevice device6 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-6', deviceSupported: false);
          final FakeIOSDevice device7 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-7', deviceSupportForProject: false);
          final FakeDevice device8 = FakeDevice.fuchsia(deviceName: 'target-device-8');
          final FakeIOSDevice device5Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-5');
          final FakeIOSDevice device6Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-6', deviceSupported: false);
          final FakeIOSDevice device7Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-7', deviceSupported: false);
          deviceManager.androidDiscover.deviceList = <Device>[device1];
          deviceManager.androidDiscover.refreshDeviceList = <Device>[device1];
          deviceManager.iosDiscovery.deviceList = <Device>[device2, device3, device4, device5, device6, device7];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device2, device3, device4, device5Connected, device6Connected, device7Connected];
          deviceManager.otherDiscover.deviceList = <Device>[device8];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Checking for wireless devices...
'''));
          expect(devices, <Device>[device1, device2, device5Connected]);
          expect(deviceManager.androidDiscover.devicesCalled, 2);
          expect(deviceManager.androidDiscover.discoverDevicesCalled, 1);
          expect(deviceManager.androidDiscover.numberOfTimesPolled, 2);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
          expect(deviceManager.otherDiscover.devicesCalled, 2);
          expect(deviceManager.otherDiscover.discoverDevicesCalled, 0);
          expect(deviceManager.otherDiscover.numberOfTimesPolled, 1);
        });

        testUsingContext('including only attached devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
Checking for wireless devices...
'''));
          expect(devices, <Device>[device1, device2]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
        });

        testUsingContext('including only wireless devices', () async {
          final FakeIOSDevice device1 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-1');
          final FakeIOSDevice device2 = FakeIOSDevice.notConnectedWireless(deviceName: 'target-device-2');
          final FakeIOSDevice device1Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-1');
          final FakeIOSDevice device2Connected = FakeIOSDevice.connectedWireless(deviceName: 'target-device-2');
          deviceManager.iosDiscovery.deviceList = <Device>[device1, device2];
          deviceManager.iosDiscovery.refreshDeviceList = <Device>[device1Connected, device2Connected];

          final TestMacPlatformTargetDevices targetDevices = TestMacPlatformTargetDevices(
            deviceManager: deviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices(
            flutterProject: FakeFlutterProject(),
          );

          expect(logger.statusText, equals('''
No devices found yet. Checking for wireless devices...
'''));
          expect(devices, <Device>[device1Connected, device2Connected]);
          expect(deviceManager.iosDiscovery.devicesCalled, 2);
          expect(deviceManager.iosDiscovery.discoverDevicesCalled, 1);
          expect(deviceManager.iosDiscovery.numberOfTimesPolled, 2);
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

  final TestPollingDeviceDiscovery androidDiscover = TestPollingDeviceDiscovery(
    'android',
    supportsWirelessDevices: true,
  );
  final TestPollingDeviceDiscovery otherDiscover = TestPollingDeviceDiscovery(
    'other',
  );

  TestIOSDeviceDiscovery? _iosDiscovery;
  TestIOSDeviceDiscovery get iosDiscovery {
    _iosDiscovery ??= TestIOSDeviceDiscovery(
      platform: platform,
      xcdevice: FakeXcdevice(),
      iosWorkflow: FakeIOSWorkflow(),
      logger: logger,
    );
    return _iosDiscovery!;
  }

  void setDeviceToWaitFor(
    IOSDevice device,
    IOSDeviceConnectionInterface interfaceType,
  ) {
    final XCDeviceEventInterface eventInterface =
        interfaceType == IOSDeviceConnectionInterface.network
            ? XCDeviceEventInterface.wifi
            : XCDeviceEventInterface.usb;
    iosDiscovery.xcdevice.waitForDeviceEvent = XCDeviceEventNotification(
      XCDeviceEventType.attach,
      eventInterface,
      device.id,
    );
  }

  @override
  List<DeviceDiscovery> get deviceDiscoverers {
    return <DeviceDiscovery>[
      androidDiscover,
      otherDiscover,
      iosDiscovery,
    ];
  }
}

class TestPollingDeviceDiscovery extends PollingDeviceDiscovery {
  TestPollingDeviceDiscovery(
    super.name, {
    this.supportsWirelessDevices = false,
  });

  List<Device> deviceList = <Device>[];
  List<Device> refreshDeviceList = <Device>[];
  int devicesCalled = 0;
  int discoverDevicesCalled = 0;
  int numberOfTimesPolled = 0;

  @override
  bool get supportsPlatform => true;

  @override
  final bool supportsWirelessDevices;

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

class TestIOSDeviceDiscovery extends IOSDevices {
  TestIOSDeviceDiscovery({
    required super.platform,
    required FakeXcdevice xcdevice,
    required super.iosWorkflow,
    required super.logger,
  })  : _platform = platform,
        _xcdevice = xcdevice,
        super(xcdevice: xcdevice);

  final Platform _platform;
  List<Device> deviceList = <Device>[];
  List<Device> refreshDeviceList = <Device>[];
  int devicesCalled = 0;
  int discoverDevicesCalled = 0;
  int numberOfTimesPolled = 0;

  final FakeXcdevice _xcdevice;

  @override
  FakeXcdevice get xcdevice => _xcdevice;

  @override
  Future<List<Device>> pollingGetDevices({Duration? timeout}) async {
    numberOfTimesPolled++;
    if (!_platform.isMacOS) {
      throw UnsupportedError(
        'Control of iOS devices or simulators only supported on macOS.',
      );
    }
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
  bool supportsHotReload = false;

  @override
  bool supportsHotRestart = false;

  @override
  Future<String> get sdkNameAndVersion async => _sdkNameAndVersion;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Category? get category => Category.mobile;

  @override
  Future<String> get targetPlatformDisplayName async =>
      getNameForTargetPlatform(await targetPlatform);

  bool wasDisposed = false;

  @override
  Future<void> dispose() async {
    wasDisposed = true;
  }
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeIOSDevice extends Fake implements IOSDevice {
  FakeIOSDevice({
    String? deviceId,
    String? deviceName,
    bool deviceSupported = true,
    bool deviceSupportForProject = true,
    this.ephemeral = true,
    this.isConnected = true,
    this.platformType = PlatformType.ios,
    this.interfaceType = IOSDeviceConnectionInterface.usb,
  })  : id = deviceId ?? 'xxx',
        name = deviceName ?? 'test',
        _isSupported = deviceSupported,
        _isSupportedForProject = deviceSupportForProject;

  FakeIOSDevice.notConnectedWireless({
    String? deviceId,
    String? deviceName,
    bool deviceSupported = true,
    bool deviceSupportForProject = true,
    this.ephemeral = true,
    this.isConnected = false,
    this.platformType = PlatformType.ios,
    this.interfaceType = IOSDeviceConnectionInterface.usb,
  })  : id = deviceId ?? 'xxx',
        name = deviceName ?? 'test',
        _isSupported = deviceSupported,
        _isSupportedForProject = deviceSupportForProject;

  FakeIOSDevice.connectedWireless({
    String? deviceId,
    String? deviceName,
    bool deviceSupported = true,
    bool deviceSupportForProject = true,
    this.ephemeral = true,
    this.isConnected = true,
    this.platformType = PlatformType.ios,
    this.interfaceType = IOSDeviceConnectionInterface.network,
  })  : id = deviceId ?? 'xxx',
        name = deviceName ?? 'test',
        _isSupported = deviceSupported,
        _isSupportedForProject = deviceSupportForProject;

  final bool _isSupported;
  final bool _isSupportedForProject;

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
  DeviceConnectionInterface get connectionInterface {
    return interfaceType == IOSDeviceConnectionInterface.network
        ? DeviceConnectionInterface.wireless
        : DeviceConnectionInterface.attached;
  }

  @override
  IOSDeviceConnectionInterface interfaceType;

  @override
  bool isConnected;

  @override
  final PlatformType? platformType;

  @override
  bool supportsHotReload = false;

  @override
  bool supportsHotRestart = false;

  @override
  Future<String> get sdkNameAndVersion async => 'iOS 16';

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Category? get category => Category.mobile;

  @override
  Future<String> get targetPlatformDisplayName async => 'ios';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.tester;

  bool wasDisposed = false;

  @override
  Future<void> dispose() async {
    wasDisposed = true;
  }
}

class FakeIOSWorkflow extends Fake implements IOSWorkflow {}

class FakeFlutterProject extends Fake implements FlutterProject {}

class TestMacPlatformTargetDevices extends MacPlatformTargetDevices {
  TestMacPlatformTargetDevices({
    required super.deviceManager,
    required super.logger,
    super.deviceConnectionInterface,
  }) : deviceSelection = TestTargetDeviceSelection(logger);

  @override
  final TestTargetDeviceSelection deviceSelection;
}

class TestTargetDeviceSelection extends TargetDeviceSelection {
  TestTargetDeviceSelection(super.logger);

  late String input;

  @override
  Future<String> readUserInput() async {
    return input;
  }
}

class FakeTerminal extends Fake implements AnsiTerminal {
  FakeTerminal({
    this.stdinHasTerminal = true,
    this.supportsColor = false,
  });

  @override
  final bool stdinHasTerminal;

  @override
  final bool supportsColor;

  @override
  bool usesTerminalUi = true;

  @override
  bool singleCharMode = false;

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

  @override
  String clearLines(int numberOfLines) {
    return 'CLEAR_LINES_$numberOfLines';
  }
}

class TestBufferLogger extends BufferLogger {
  TestBufferLogger.test({
    super.terminal,
    super.outputPreferences,
    super.verbose,
  }) : super.test();

  String originalStatusText = '';

  @override
  void printStatus(
    String message, {
    bool? emphasis,
    TerminalColor? color,
    bool? newline,
    int? indent,
    int? hangingIndent,
    bool? wrap,
  }) {
    if (message.startsWith('CLEAR_LINES_')) {
      expect(statusText, equals(originalStatusText));
      final int numberOfLinesToRemove =
          int.parse(message.split('CLEAR_LINES_')[1]) - 1;
      final List<String> lines = LineSplitter.split(statusText).toList();
      // Clear string buffer and re-add lines not removed
      clear();
      for (int lineNumber = 0; lineNumber < lines.length - numberOfLinesToRemove; lineNumber++) {
        super.printStatus(lines[lineNumber]);
      }
    } else {
      super.printStatus(
        message,
        emphasis: emphasis,
        color: color,
        newline: newline,
        indent: indent,
        hangingIndent: hangingIndent,
        wrap: wrap,
      );
    }
  }
}
