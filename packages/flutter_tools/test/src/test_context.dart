// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/test.dart';

void testUsingContext(String description, dynamic testMethod(), { Timeout timeout }) {
  test(description, () {
    AppContext testContext = new AppContext();

    testContext[Logger] = new BufferLogger();
    testContext[DeviceManager] = new MockDeviceManager();

    return testContext.runInZone(testMethod);
  }, timeout: timeout);
}

class MockDeviceManager implements DeviceManager {
  String specifiedDeviceId;
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  Future<List<Device>> getAllConnectedDevices() => new Future.value(<Device>[]);
  Future<Device> getDeviceById(String deviceId) => new Future.value(null);
  Future<List<Device>> getDevices() => getAllConnectedDevices();
}
