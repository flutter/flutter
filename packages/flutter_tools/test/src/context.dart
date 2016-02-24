// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:test/test.dart';

/// Return the test logger. This assumes that the current Logger is a BufferLogger.
BufferLogger get testLogger => context[Logger];

MockDeviceManager get testDeviceManager => context[DeviceManager];
MockDoctor get testDoctor => context[Doctor];

void testUsingContext(String description, dynamic testMethod(), {
  Timeout timeout,
  Map<Type, dynamic> overrides: const <Type, dynamic>{}
}) {
  test(description, () {
    AppContext testContext = new AppContext();

    overrides.forEach((Type type, dynamic value) {
      testContext[type] = value;
    });

    if (!overrides.containsKey(Logger))
      testContext[Logger] = new BufferLogger();

    if (!overrides.containsKey(DeviceManager))
      testContext[DeviceManager] = new MockDeviceManager();

    if (!overrides.containsKey(Doctor))
      testContext[Doctor] = new MockDoctor();

    if (Platform.isMacOS) {
      if (!overrides.containsKey(XCode))
        testContext[XCode] = new XCode();
    }

    return testContext.runInZone(testMethod);
  }, timeout: timeout);
}

class MockDeviceManager implements DeviceManager {
  List<Device> devices = <Device>[];

  String specifiedDeviceId;
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  Future<List<Device>> getAllConnectedDevices() => new Future.value(devices);

  Future<Device> getDeviceById(String deviceId) {
    Device device = devices.firstWhere((Device device) => device.id == deviceId, orElse: () => null);
    return new Future.value(device);
  }

  Future<List<Device>> getDevices() async {
    if (specifiedDeviceId == null) {
      return getAllConnectedDevices();
    } else {
      Device device = await getDeviceById(specifiedDeviceId);
      return device == null ? <Device>[] : <Device>[device];
    }
  }

  void addDevice(Device device) => devices.add(device);
}

class MockDoctor extends Doctor {
  // True for testing.
  bool get canLaunchAnything => true;
}
