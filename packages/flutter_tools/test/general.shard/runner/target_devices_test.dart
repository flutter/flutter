// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/runner/target_devices.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';

void main() {
   group('When cannot launch anything', () {
    late BufferLogger logger;
    late FakeDoctor doctor;
    final FakeDevice device1 = FakeDevice('device1', 'device1');

    setUp(() {
      logger = BufferLogger.test();
      doctor = FakeDoctor(logger, canLaunchAnything: false);
    });

    testUsingContext('does not search for devices', () async {
      final MockDeviceDiscovery deviceDiscovery = MockDeviceDiscovery()
        ..deviceValues = <Device>[device1];

      final DeviceManager deviceManager = TestDeviceManager(
        <Device>[],
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          deviceDiscovery,
        ],
        logger: logger,
      );

      final TargetDevices targetDevices = TargetDevices(
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices();

      expect(logger.errorText, contains(UserMessages().flutterNoDevelopmentDevice));
      expect(devices, isNull);
      expect(deviceDiscovery.devicesCalled, 0);
      expect(deviceDiscovery.discoverDevicesCalled, 0);
    }, overrides: <Type, Generator>{
      Doctor: () => doctor,
    });
  });

  group('Ensure refresh when deviceDiscoveryTimeout is provided', () {
    late BufferLogger logger;
    final FakeDevice device1 = FakeDevice('device1', 'device1');

    setUp(() {
      logger = BufferLogger.test();
    });

    testUsingContext('does not refresh device cache without a timeout', () async {
      final MockDeviceDiscovery deviceDiscovery = MockDeviceDiscovery()
        ..deviceValues = <Device>[device1];

      final DeviceManager deviceManager = TestDeviceManager(
        <Device>[],
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          deviceDiscovery,
        ],
        logger: logger,
      );
      deviceManager.specifiedDeviceId = device1.id;

      final TargetDevices targetDevices = TargetDevices(
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices();

      expect(devices?.single, device1);
      expect(deviceDiscovery.devicesCalled, 1);
      expect(deviceDiscovery.discoverDevicesCalled, 0);
    });

    testUsingContext('refreshes device cache with a timeout', () async {
      final MockDeviceDiscovery deviceDiscovery = MockDeviceDiscovery()
        ..deviceValues = <Device>[device1];

      final DeviceManager deviceManager = TestDeviceManager(
        <Device>[],
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          deviceDiscovery,
        ],
        logger: BufferLogger.test(),
      );
      deviceManager.specifiedDeviceId = device1.id;

      const Duration timeout = Duration(seconds: 2);
      final TargetDevices targetDevices = TargetDevices(
        deviceManager: deviceManager,
        logger: logger,
      );
      final List<Device>? devices = await targetDevices.findAllTargetDevices(
        deviceDiscoveryTimeout: timeout,
      );

      expect(devices?.single, device1);
      expect(deviceDiscovery.devicesCalled, 1);
      expect(deviceDiscovery.discoverDevicesCalled, 1);
    });
  });

  group('findAllTargetDevices', () {
    late BufferLogger logger;
    final FakeDevice device1 = FakeDevice('device1', 'device1');
    final FakeDevice device2 = FakeDevice('device2', 'device2');

    setUp(() {
      logger = BufferLogger.test();
    });

    group('when specified device id', () {
      testUsingContext('returns device when device is found', () async {
        testDeviceManager.specifiedDeviceId = 'device1';
        testDeviceManager.addDevice(device1);

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, <Device>[device1]);
      });

      testUsingContext('show error when no device found', () async {
        testDeviceManager.specifiedDeviceId = 'device-id';

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, null);
        expect(logger.statusText, contains(UserMessages().flutterNoMatchingDevice('device-id')));
      });

      testUsingContext('show error when multiple devices found', () async {
        testDeviceManager.specifiedDeviceId = 'device';
        testDeviceManager.addDevice(device1);
        testDeviceManager.addDevice(device2);

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, null);
        expect(logger.statusText, contains(UserMessages().flutterFoundSpecifiedDevices(2, 'device')));
      });
    });

    group('when specified all', () {
      testUsingContext('can return one device', () async {
        testDeviceManager.specifiedDeviceId = 'all';
        testDeviceManager.addDevice(device1);

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, <Device>[device1]);
      });

      testUsingContext('can return multiple devices', () async {
        testDeviceManager.specifiedDeviceId = 'all';
        testDeviceManager.addDevice(device1);
        testDeviceManager.addDevice(device2);

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, <Device>[device1, device2]);
      });

      testUsingContext('show error when no device found', () async {
        testDeviceManager.specifiedDeviceId = 'all';

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, null);
        expect(logger.statusText, contains(UserMessages().flutterNoDevicesFound));
      });
    });

    group('when device not specified', () {
      testUsingContext('returns one device when only one device connected', () async {
        testDeviceManager.addDevice(device1);

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, <Device>[device1]);
      });

      testUsingContext('show error when no device found', () async {
        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, null);
        expect(logger.statusText, contains(UserMessages().flutterNoSupportedDevices));
      });

      testUsingContext('show error when multiple devices found and not connected to terminal', () async {
        testDeviceManager.addDevice(device1);
        testDeviceManager.addDevice(device2);

        final TargetDevices targetDevices = TargetDevices(
          deviceManager: testDeviceManager,
          logger: logger,
        );
        final List<Device>? devices = await targetDevices.findAllTargetDevices();

        expect(devices, null);
        expect(logger.statusText, contains(UserMessages().flutterSpecifyDeviceWithAllOption));
      }, overrides: <Type, Generator>{
        AnsiTerminal: () => FakeTerminal(stdinHasTerminal: false),
      });

      // Prompt to choose device when multiple devices found and connected to terminal
      group('show prompt', () {
        late FakeTerminal terminal;
        setUp(() {
          terminal = FakeTerminal();
        });

        testUsingContext('choose first device', () async {
          testDeviceManager.addDevice(device1);
          testDeviceManager.addDevice(device2);
          terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '1');

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: testDeviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

          expect(devices, <Device>[device1]);
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });

        testUsingContext('choose second device', () async {
          testDeviceManager.addDevice(device1);
          testDeviceManager.addDevice(device2);
          terminal.setPrompt(<String>['1', '2', 'q', 'Q'], '2');

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: testDeviceManager,
            logger: logger,
          );
          final List<Device>? devices = await targetDevices.findAllTargetDevices();

            expect(devices, <Device>[device2]);
          }, overrides: <Type, Generator>{
            AnsiTerminal: () => terminal,
          });

        testUsingContext('exits without choosing device', () async {
          testDeviceManager.addDevice(device1);
          testDeviceManager.addDevice(device2);
          terminal.setPrompt(<String>['1', '2', 'q', 'Q'], 'q');

          final TargetDevices targetDevices = TargetDevices(
            deviceManager: testDeviceManager,
            logger: logger,
          );

          await expectLater(
            targetDevices.findAllTargetDevices(),
            throwsToolExit(),
          );
        }, overrides: <Type, Generator>{
          AnsiTerminal: () => terminal,
        });
      });
    });
  });

  group('Filter devices', () {
    late BufferLogger logger;
    final FakeDevice ephemeralOne = FakeDevice('ephemeralOne', 'ephemeralOne');
    final FakeDevice ephemeralTwo = FakeDevice('ephemeralTwo', 'ephemeralTwo');
    final FakeDevice nonEphemeralOne = FakeDevice('nonEphemeralOne', 'nonEphemeralOne', ephemeral: false);

    setUp(() {
      logger = BufferLogger.test();
    });

    testUsingContext('chooses ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        nonEphemeralOne,
      ];
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: logger,
      );

      final TargetDevices targetDevices = TargetDevices(deviceManager: deviceManager, logger: logger);
      final List<Device> filtered = await targetDevices.getDevices();

      expect(filtered, <Device>[ephemeralOne]);
    });

    testUsingContext('returns all devices when multiple non ephemeral devices are found', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
        nonEphemeralOne,
      ];
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: logger,
      );

      final TargetDevices targetDevices = TargetDevices(deviceManager: deviceManager, logger: logger);
      final List<Device> filtered = await targetDevices.getDevices();

      expect(filtered, <Device>[
        ephemeralOne,
        ephemeralTwo,
        nonEphemeralOne,
      ]);
    });
  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager(
    List<Device> allDevices, {
    List<DeviceDiscovery>? deviceDiscoveryOverrides,
    required super.logger,
    String? wellKnownId,
    FakePollingDeviceDiscovery? fakeDiscoverer,
  }) : _fakeDeviceDiscoverer = fakeDiscoverer ?? FakePollingDeviceDiscovery(),
       _deviceDiscoverers = <DeviceDiscovery>[],
       super() {
    if (wellKnownId != null) {
      _fakeDeviceDiscoverer.wellKnownIds.add(wellKnownId);
    }
    _deviceDiscoverers.add(_fakeDeviceDiscoverer);
    if (deviceDiscoveryOverrides != null) {
      _deviceDiscoverers.addAll(deviceDiscoveryOverrides);
    }
    resetDevices(allDevices);
  }
  @override
  List<DeviceDiscovery> get deviceDiscoverers => _deviceDiscoverers;
  final List<DeviceDiscovery> _deviceDiscoverers;
  final FakePollingDeviceDiscovery _fakeDeviceDiscoverer;

  void resetDevices(List<Device> allDevices) {
    _fakeDeviceDiscoverer.setDevices(allDevices);
  }
}

class MockDeviceDiscovery extends Fake implements DeviceDiscovery {
  int devicesCalled = 0;
  int discoverDevicesCalled = 0;

  @override
  bool supportsPlatform = true;

  List<Device> deviceValues = <Device>[];

  @override
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter}) async {
    devicesCalled += 1;
    return deviceValues;
  }

  @override
  Future<List<Device>> discoverDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
  }) async {
    discoverDevicesCalled += 1;
    return deviceValues;
  }

  @override
  List<String> get wellKnownIds => <String>[];
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

class FakeDoctor extends Doctor {
  FakeDoctor(
    Logger logger, {
    this.canLaunchAnything = true,
  }) : super(logger: logger);

  // True for testing.
  @override
  bool get canListAnything => true;

  // True for testing.
  @override
  bool canLaunchAnything;

  @override
  /// Replaces the android workflow with a version that overrides licensesAccepted,
  /// to prevent individual tests from having to mock out the process for
  /// the Doctor.
  List<DoctorValidator> get validators {
    final List<DoctorValidator> superValidators = super.validators;
    return superValidators.map<DoctorValidator>((DoctorValidator v) {
      if (v is AndroidLicenseValidator) {
        return FakeAndroidLicenseValidator();
      }
      return v;
    }).toList();
  }
}
