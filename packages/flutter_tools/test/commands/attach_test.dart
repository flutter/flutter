// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
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
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('finds observatory port and forwards', () async {
      const int devicePort = 499;
      const int hostPort = 42;
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
      when(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort'))).thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts).thenReturn(<ForwardedPort>[new ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward).thenReturn((ForwardedPort _) async => null);
      testDeviceManager.addDevice(device);

      final AttachCommand command = new AttachCommand();

      await createTestCommandRunner(command).run(<String>['attach']);

      verify(portForwarder.forward(devicePort, hostPort: anyNamed('hostPort'))).called(1);

      mockLogReader.dispose();
    });

    testUsingContext('forwards to given port', () async {
      const int devicePort = 499;
      const int hostPort = 42;
      final MockPortForwarder portForwarder = new MockPortForwarder();
      final MockAndroidDevice device = new MockAndroidDevice();

      when(device.portForwarder).thenReturn(portForwarder);
      when(portForwarder.forward(devicePort)).thenAnswer((_) async => hostPort);
      when(portForwarder.forwardedPorts).thenReturn(<ForwardedPort>[new ForwardedPort(hostPort, devicePort)]);
      when(portForwarder.unforward).thenReturn((ForwardedPort _) async => null);
      testDeviceManager.addDevice(device);

      final AttachCommand command = new AttachCommand();

      await createTestCommandRunner(command).run(<String>['attach', '--debug-port', '$devicePort']);

      verify(portForwarder.forward(devicePort)).called(1);
    });

    testUsingContext('exits when no device connected', () async {
      final AttachCommand command = new AttachCommand();
      await expectLater(
        createTestCommandRunner(command).run(<String>['attach']),
        throwsA(const isInstanceOf<ToolExit>()),
      );
      expect(testLogger.statusText, contains('No connected devices'));
    });

    testUsingContext('exits when multiple devices connected', () async {
      Device aDeviceWithId(String id) {
        final MockAndroidDevice device = new MockAndroidDevice();
        when(device.name).thenReturn('d$id');
        when(device.id).thenReturn(id);
        when(device.isLocalEmulator).thenAnswer((_) async => false);
        when(device.sdkNameAndVersion).thenAnswer((_) async => 'Android 46');
        return device;
      }

      final AttachCommand command = new AttachCommand();
      testDeviceManager.addDevice(aDeviceWithId('xx1'));
      testDeviceManager.addDevice(aDeviceWithId('yy2'));
      await expectLater(
        createTestCommandRunner(command).run(<String>['attach']),
        throwsA(const isInstanceOf<ToolExit>()),
      );
      expect(testLogger.statusText, contains('More than one device'));
      expect(testLogger.statusText, contains('xx1'));
      expect(testLogger.statusText, contains('yy2'));
    });
  });
}

class MockPortForwarder extends Mock implements DevicePortForwarder {}
