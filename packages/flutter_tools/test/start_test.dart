// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/commands/start.dart';
import 'package:test/test.dart';

import 'src/mocks.dart';

main() => defineTests();

defineTests() {
  group('start', () {
    test('returns 0 when Android is connected and ready to be started', () {
      StartCommand command = new StartCommand();
      applyMocksToCommand(command);
      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.isConnected()).thenReturn(true);
      when(mockDevices.android.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.android.installApp(any)).thenReturn(true);
      when(mockDevices.android.startBundle(any, any, any, any)).thenReturn(true);
      when(mockDevices.android.stopApp(any)).thenReturn(true);

      when(mockDevices.iOS.isConnected()).thenReturn(false);
      when(mockDevices.iOS.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOS.installApp(any)).thenReturn(false);
      when(mockDevices.iOS.startApp(any)).thenReturn(false);
      when(mockDevices.iOS.stopApp(any)).thenReturn(false);

      when(mockDevices.iOSSimulator.isConnected()).thenReturn(false);
      when(mockDevices.iOSSimulator.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.installApp(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.startApp(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.stopApp(any)).thenReturn(false);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['start']).then((int code) => expect(code, equals(0)));
    });

    test('returns 0 when iOS is connected and ready to be started', () {
      StartCommand command = new StartCommand();
      applyMocksToCommand(command);
      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.isConnected()).thenReturn(false);
      when(mockDevices.android.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.android.installApp(any)).thenReturn(false);
      when(mockDevices.android.startBundle(any, any, any, any)).thenReturn(false);
      when(mockDevices.android.stopApp(any)).thenReturn(false);

      when(mockDevices.iOS.isConnected()).thenReturn(true);
      when(mockDevices.iOS.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOS.installApp(any)).thenReturn(true);
      when(mockDevices.iOS.startApp(any)).thenReturn(true);
      when(mockDevices.iOS.stopApp(any)).thenReturn(false);

      when(mockDevices.iOSSimulator.isConnected()).thenReturn(false);
      when(mockDevices.iOSSimulator.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.installApp(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.startApp(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.stopApp(any)).thenReturn(false);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['start']).then((int code) => expect(code, equals(0)));
    });
  });
}
