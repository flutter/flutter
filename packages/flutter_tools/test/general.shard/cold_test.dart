// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('cleanupAtFinish()', () {
    MockFlutterDevice mockFlutterDeviceFactory(Device device) {
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(mockFlutterDevice.device).thenReturn(device);
      return mockFlutterDevice;
    }

    testUsingContext('disposes each device', () async {
      final MockDevice mockDevice1 = MockDevice();
      final MockDevice mockDevice2 = MockDevice();
      final MockFlutterDevice mockFlutterDevice1 = mockFlutterDeviceFactory(mockDevice1);
      final MockFlutterDevice mockFlutterDevice2 = mockFlutterDeviceFactory(mockDevice2);

      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice1, mockFlutterDevice2];

      await ColdRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).cleanupAtFinish();

      verify(mockDevice1.dispose());
      verify(mockFlutterDevice1.stopEchoingDeviceLog());
      verify(mockDevice2.dispose());
      verify(mockFlutterDevice2.stopEchoingDeviceLog());
    });
  });

  group('cold run', () {
    testUsingContext('returns 1 if not prebuilt mode & mainPath does not exist', () async {
      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice];
      final int result = await ColdRunner(devices).run();

      expect(result, 1);
      expect(testLogger.errorText, matches(r'Tried to run .*, but that file does not exist\.'));
      expect(testLogger.errorText, matches(r'Consider using the -t option to specify the Dart file to start\.'));
    });

    testUsingContext('calls runCold on attached device', () async {
      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      when(mockFlutterDevice.runCold(
          coldRunner: anyNamed('coldRunner'),
          route: anyNamed('route')
      )).thenAnswer((Invocation invocation) => Future<int>.value(1));
      final List<FlutterDevice> devices = <FlutterDevice>[mockFlutterDevice];
      final MockFile applicationBinary = MockFile();
      final int result = await ColdRunner(
        devices,
        applicationBinary: applicationBinary,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      ).run();

      expect(result, 1);
      verify(mockFlutterDevice.runCold(
          coldRunner: anyNamed('coldRunner'),
          route: anyNamed('route'),
      ));
    });
  });
}

class MockFile extends Mock implements File {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}
