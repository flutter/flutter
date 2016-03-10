// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/install.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  group('install', () {
    testUsingContext('returns 0 when Android is connected and ready for an install', () {
      InstallCommand command = new InstallCommand();
      applyMocksToCommand(command);
      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.android.installApp(any)).thenReturn(true);

      when(mockDevices.iOS.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOS.installApp(any)).thenReturn(false);

      when(mockDevices.iOSSimulator.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.installApp(any)).thenReturn(false);

      testDeviceManager.addDevice(mockDevices.android);

      return createTestCommandRunner(command).run(['install']).then((int code) {
        expect(code, equals(0));
      });
    });

    testUsingContext('returns 0 when iOS is connected and ready for an install', () {
      InstallCommand command = new InstallCommand();
      applyMocksToCommand(command);
      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.android.installApp(any)).thenReturn(false);

      when(mockDevices.iOS.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOS.installApp(any)).thenReturn(true);

      when(mockDevices.iOSSimulator.isAppInstalled(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.installApp(any)).thenReturn(false);

      testDeviceManager.addDevice(mockDevices.iOS);

      return createTestCommandRunner(command).run(['install']).then((int code) {
        expect(code, equals(0));
      });
    });
  });
}
