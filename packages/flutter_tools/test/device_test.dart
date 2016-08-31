// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/device.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('DeviceManager', () {
    testUsingContext('getDevices', () async {
      // Test that DeviceManager.getDevices() doesn't throw.
      DeviceManager deviceManager = new DeviceManager();
      List<Device> devices = await deviceManager.getDevices();
      expect(devices, isList);
    });

    testUsingContext('getDeviceById', () async {
      _MockDevice device1 = new _MockDevice('Nexus 5', '0553790d0a4e726f');
      _MockDevice device2 = new _MockDevice('Nexus 5X', '01abfc49119c410e');
      _MockDevice device3 = new _MockDevice('iPod touch', '82564b38861a9a5');
      List<Device> devices = <Device>[device1, device2, device3];
      DeviceManager deviceManager = new TestDeviceManager(devices);

      Future<Null> expectDevice(String id, List<Device> expected) async {
        expect(await deviceManager.getDevicesById(id), expected);
      }
      expectDevice('01abfc49119c410e', <Device>[device2]);
      expectDevice('Nexus 5X', <Device>[device2]);
      expectDevice('0553790d0a4e726f', <Device>[device1]);
      expectDevice('Nexus 5', <Device>[device1]);
      expectDevice('0553790', <Device>[device1]);
      expectDevice('Nexus', <Device>[device1, device2]);
    });
  });
}

class TestDeviceManager extends DeviceManager {
  final List<Device> allDevices;

  TestDeviceManager(this.allDevices);

  @override
  Future<List<Device>> getAllConnectedDevices() async {
    return allDevices;
  }
}

class _MockDevice extends Device {
  @override
  final String name;

  _MockDevice(this.name, String id) : super(id);

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
