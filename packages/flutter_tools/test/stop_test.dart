// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stop_test;

import 'package:args/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/stop.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() => defineTests();

defineTests() {
  group('stop', () {
    test('returns 0 when Android is connected and ready to be stopped', () {
      applicationPackageSetup();

      MockAndroidDevice android = new MockAndroidDevice();
      when(android.isConnected()).thenReturn(true);
      when(android.stopApp(any)).thenReturn(true);

      MockIOSDevice ios = new MockIOSDevice();
      when(ios.isConnected()).thenReturn(false);
      when(ios.stopApp(any)).thenReturn(false);

      StopCommand command = new StopCommand(android: android, ios: ios);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['stop']).then((int code) => expect(code, equals(0)));
    });

    test('returns 0 when iOS is connected and ready to be stopped', () {
      applicationPackageSetup();

      MockAndroidDevice android = new MockAndroidDevice();
      when(android.isConnected()).thenReturn(false);
      when(android.stopApp(any)).thenReturn(false);

      MockIOSDevice ios = new MockIOSDevice();
      when(ios.isConnected()).thenReturn(true);
      when(ios.stopApp(any)).thenReturn(true);

      StopCommand command = new StopCommand(android: android, ios: ios);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['stop']).then((int code) => expect(code, equals(0)));
    });
  });
}
