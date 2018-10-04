// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/device.dart';

import 'src/common.dart';
import 'src/context.dart';

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
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager(this.allDevices);

  final List<Device> allDevices;

  @override
  Stream<Device> getAllConnectedDevices() {
    return Stream<Device>.fromIterable(allDevices);
  }
}

class _MockDevice extends Device {
  _MockDevice(this.name, String id) : super(id);

  @override
  final String name;

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
