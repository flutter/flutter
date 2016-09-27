// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

/// Return the test logger. This assumes that the current Logger is a BufferLogger.
BufferLogger get testLogger => context[Logger];

MockDeviceManager get testDeviceManager => context[DeviceManager];
MockDoctor get testDoctor => context[Doctor];

void testUsingContext(String description, dynamic testMethod(), {
  Timeout timeout,
  Map<Type, dynamic> overrides: const <Type, dynamic>{}
}) {
  test(description, () async {
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

    if (!overrides.containsKey(SimControl))
      testContext[SimControl] = new MockSimControl();

    if (!overrides.containsKey(Usage))
      testContext[Usage] = new MockUsage();

    if (!overrides.containsKey(OperatingSystemUtils)) {
      MockOperatingSystemUtils os = new MockOperatingSystemUtils();
      when(os.isWindows).thenReturn(false);
      testContext[OperatingSystemUtils] = os;
    }

    if (!overrides.containsKey(IOSSimulatorUtils)) {
      MockIOSSimulatorUtils mock = new MockIOSSimulatorUtils();
      when(mock.getAttachedDevices()).thenReturn(<IOSSimulator>[]);
      testContext[IOSSimulatorUtils] = mock;
    }

    if (Platform.isMacOS) {
      if (!overrides.containsKey(XCode))
        testContext[XCode] = new XCode();
    }

    try {
      return await testContext.runInZone(testMethod);
    } catch (error) {
      if (testContext[Logger] is BufferLogger) {
        BufferLogger bufferLogger = testContext[Logger];
        if (bufferLogger.errorText.isNotEmpty)
          print(bufferLogger.errorText);
      }
      throw error;
    }

  }, timeout: timeout);
}

class MockDeviceManager implements DeviceManager {
  List<Device> devices = <Device>[];

  @override
  String specifiedDeviceId;

  @override
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  @override
  Future<List<Device>> getAllConnectedDevices() => new Future<List<Device>>.value(devices);

  @override
  Future<List<Device>> getDevicesById(String deviceId) async {
    return devices.where((Device device) => device.id == deviceId).toList();
  }

  @override
  Future<List<Device>> getDevices() async {
    if (specifiedDeviceId == null) {
      return getAllConnectedDevices();
    } else {
      return getDevicesById(specifiedDeviceId);
    }
  }

  void addDevice(Device device) => devices.add(device);
}

class MockDoctor extends Doctor {
  // True for testing.
  @override
  bool get canListAnything => true;

  // True for testing.
  @override
  bool get canLaunchAnything => true;
}

class MockSimControl extends Mock implements SimControl {
  MockSimControl() {
    when(this.getConnectedDevices()).thenReturn(<SimDevice>[]);
  }
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

class MockIOSSimulatorUtils extends Mock implements IOSSimulatorUtils {}

class MockUsage implements Usage {
  @override
  bool get isFirstRun => false;

  @override
  bool get suppressAnalytics => false;

  @override
  set suppressAnalytics(bool value) { }

  @override
  bool get enabled => true;

  @override
  set enabled(bool value) { }

  @override
  void sendCommand(String command) { }

  @override
  void sendEvent(String category, String parameter) { }

  @override
  void sendTiming(String category, String variableName, Duration duration) { }

  @override
  UsageTimer startTimer(String event) => new _MockUsageTimer(event);

  @override
  void sendException(dynamic exception, StackTrace trace) { }

  @override
  Stream<Map<String, dynamic>> get onSend => null;

  @override
  Future<Null> ensureAnalyticsSent() => new Future<Null>.value();

  @override
  void printUsage() { }
}

class _MockUsageTimer implements UsageTimer {
  _MockUsageTimer(this.event);

  @override
  final String event;

  @override
  void finish() { }
}
