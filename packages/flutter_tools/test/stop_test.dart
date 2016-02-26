// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/stop.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

main() => defineTests();

defineTests() {
  group('stop', () {
    testUsingContext('returns 0 when Android is connected and ready to be stopped', () {
      StopCommand command = new StopCommand();
      applyMocksToCommand(command);
      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.stopApp(any)).thenReturn(true);
      when(mockDevices.iOS.stopApp(any)).thenReturn(false);
      when(mockDevices.iOSSimulator.stopApp(any)).thenReturn(false);

      return createTestCommandRunner(command).run(['stop']).then((int code) {
        expect(code, equals(0));
      });
    });

    testUsingContext('returns 0 when iOS is connected and ready to be stopped', () {
      StopCommand command = new StopCommand();
      applyMocksToCommand(command);
      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.stopApp(any)).thenReturn(false);
      when(mockDevices.iOS.stopApp(any)).thenReturn(true);
      when(mockDevices.iOSSimulator.stopApp(any)).thenReturn(false);

      return createTestCommandRunner(command).run(['stop']).then((int code) {
        expect(code, equals(0));
      });
    });
  });
}
