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
      DeviceManager deviceManager = new DeviceManager();
      _MockDevice device1 = new _MockDevice('Nexus 5', '0553790d0a4e726f');
      _MockDevice device2 = new _MockDevice('Nexus 5X', '01abfc49119c410e');
      _MockDevice device3 = new _MockDevice('iPod touch', '82564b38861a9a5');
      List<Device> devices = <Device>[device1, device2, device3];

      Future<Null> expectDevice(String id, Device expected) async {
        expect(await deviceManager.getDeviceById(id, devices), expected);
      }
      expectDevice('01abfc49119c410e', device2);
      expectDevice('Nexus 5X', device2);
      expectDevice('0553790d0a4e726f', device1);
      expectDevice('Nexus 5', device1);
      expectDevice('0553790', device1);
      expectDevice('Nexus', null);
    });
  });
}

class _MockDevice extends Device {
  @override
  final String name;

  _MockDevice(this.name, String id) : super(id);

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
