// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('attach', () {
    DeviceManager mockDeviceManager;
    DeviceLogReader mockLogReader;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      mockDeviceManager = new MockDeviceManager();
      mockLogReader = new MockDeviceLogReader();
    });

    testUsingContext('finds observatory port and forwards', () async {
      final int devicePort = 499;
      final int hostPort = 42;
      final MockDeviceLogReader mockLogReader = new MockDeviceLogReader();
      final MockPortForwarder portForwarder = new MockPortForwarder();
      final MockAndroidDevice device = new MockAndroidDevice();
      when(device.getLogReader()).thenAnswer((_) {
        // Now that the reader is used, start writing messages to it.
        Timer.run(() {
          mockLogReader.addLine('Foo');
          mockLogReader.addLine('Observatory listening on http://127.0.0.1:$devicePort');
        });

        return mockLogReader;
      });
      when(device.portForwarder).thenReturn(portForwarder);
      when(portForwarder.forward(devicePort, hostPort: any)).thenAnswer((_) => new Future<int>.value(hostPort));
      when(portForwarder.forwardedPorts).thenReturn([new ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward).thenReturn((ForwardedPort _) => new Future<Null>.value(null));
      testDeviceManager.addDevice(device);

      final AttachCommand command = new AttachCommand();

      await createTestCommandRunner(command).run(<String>['attach']);

      verify(portForwarder.forward(devicePort, hostPort: any)).called(1);

      mockLogReader.dispose();
    });

    testUsingContext('forwards to given port', () async {
      final int devicePort = 499;
      final int hostPort = 42;
      final MockPortForwarder portForwarder = new MockPortForwarder();
      final MockAndroidDevice device = new MockAndroidDevice();

      when(device.portForwarder).thenReturn(portForwarder);
      when(portForwarder.forward(devicePort)).thenAnswer((_) => new Future<int>.value(hostPort));
      when(portForwarder.forwardedPorts).thenReturn([new ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward).thenReturn((ForwardedPort _) => new Future<Null>.value(null));
      testDeviceManager.addDevice(device);

      final AttachCommand command = new AttachCommand();

      await createTestCommandRunner(command).run(<String>['attach', '--debug-port', '$devicePort']);

      verify(portForwarder.forward(devicePort)).called(1);
    });
  });
}

class MockPortForwarder extends Mock implements DevicePortForwarder {}
