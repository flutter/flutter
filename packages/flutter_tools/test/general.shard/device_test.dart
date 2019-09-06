// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('DeviceManager', () {
    testUsingContext('getDevices', () async {
      // Test that DeviceManager.getDevices() doesn't throw.
      final DeviceManager deviceManager = DeviceManager();
      final List<Device> devices = await deviceManager.getDevices().toList();
      expect(devices, isList);
    });

    testUsingContext('getDeviceById', () async {
      final _MockDevice device1 = _MockDevice('Nexus 5', '0553790d0a4e726f');
      final _MockDevice device2 = _MockDevice('Nexus 5X', '01abfc49119c410e');
      final _MockDevice device3 = _MockDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];
      final DeviceManager deviceManager = TestDeviceManager(devices);

      Future<void> expectDevice(String id, List<Device> expected) async {
        expect(await deviceManager.getDevicesById(id).toList(), expected);
      }
      await expectDevice('01abfc49119c410e', <Device>[device2]);
      await expectDevice('Nexus 5X', <Device>[device2]);
      await expectDevice('0553790d0a4e726f', <Device>[device1]);
      await expectDevice('Nexus 5', <Device>[device1]);
      await expectDevice('0553790', <Device>[device1]);
      await expectDevice('Nexus', <Device>[device1, device2]);
    });
  });

  group('Filter devices', () {
    _MockDevice ephemeral;
    _MockDevice nonEphemeralOne;
    _MockDevice nonEphemeralTwo;
    _MockDevice unsupported;
    _MockDevice webDevice;
    _MockDevice fuchsiaDevice;

    setUp(() {
      ephemeral = _MockDevice('ephemeral', 'ephemeral', true);
      nonEphemeralOne = _MockDevice('nonEphemeralOne', 'nonEphemeralOne', false);
      nonEphemeralTwo = _MockDevice('nonEphemeralTwo', 'nonEphemeralTwo', false);
      unsupported = _MockDevice('unsupported', 'unsupported', true, false);
      webDevice = _MockDevice('webby', 'webby')
        ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.web_javascript);
      fuchsiaDevice = _MockDevice('fuchsiay', 'fuchsiay')
        ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.fuchsia);
    });

    testUsingContext('chooses ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeral,
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered.single, ephemeral);
    });

    testUsingContext('does not remove all non-ephemeral', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ]);
    });

    testUsingContext('Removes a single unsupported device', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[]);
    });

    testUsingContext('Removes web and fuchsia from --all', () async {
      final List<Device> devices = <Device>[
        webDevice,
        fuchsiaDevice,
      ];
      final DeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[]);
    });

    testUsingContext('Removes unsupported devices from --all', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];
      final DeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ]);
    });

    testUsingContext('uses DeviceManager.isDeviceSupportedForProject instead of device.isSupportedForProject', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];
      final TestDeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.isAlwaysSupportedOverride = true;

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        unsupported,
      ]);
    });
  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager(this.allDevices);

  final List<Device> allDevices;
  bool isAlwaysSupportedOverride;

  @override
  Stream<Device> getAllConnectedDevices() {
    return Stream<Device>.fromIterable(allDevices);
  }

  @override
  bool isDeviceSupportedForProject(Device device, FlutterProject flutterProject) {
    if (isAlwaysSupportedOverride != null) {
      return isAlwaysSupportedOverride;
    }
    return super.isDeviceSupportedForProject(device, flutterProject);
  }
}

class _MockDevice extends Device {
  _MockDevice(this.name, String id, [bool ephemeral = true, this._isSupported = true]) : super(
      id,
      platformType: PlatformType.web,
      category: Category.mobile,
      ephemeral: ephemeral,
  );

  final bool _isSupported;

  @override
  final String name;

  @override
  Future<TargetPlatform> targetPlatform = Future<TargetPlatform>.value(TargetPlatform.android_arm);

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => _isSupported;
}
