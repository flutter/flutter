// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/commands/list.dart';
import 'package:test/test.dart';

import 'src/mocks.dart';

main() => defineTests();

defineTests() {
  group('list', () {
    test('returns 0 when called', () {
      final String mockCommand = Platform.isWindows ? 'cmd /c echo' : 'echo';

      ListCommand command = new ListCommand();
      applyMocksToCommand(command);
      MockDeviceStore mockDevices = command.devices;

      // Avoid relying on adb being installed on the test system.
      // Instead, cause the test to run the echo command.
      when(mockDevices.android.adbPath).thenReturn(mockCommand);

      // Avoid relying on idevice* being installed on the test system.
      // Instead, cause the test to run the echo command.
      when(mockDevices.iOS.informerPath).thenReturn(mockCommand);
      when(mockDevices.iOS.installerPath).thenReturn(mockCommand);
      when(mockDevices.iOS.listerPath).thenReturn(mockCommand);

      // Avoid relying on xcrun being installed on the test system.
      // Instead, cause the test to run the echo command.
      when(mockDevices.iOSSimulator.xcrunPath).thenReturn(mockCommand);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['list']).then((int code) => expect(code, equals(0)));
    });
  });
}
