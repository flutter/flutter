// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library install_test;

import 'package:args/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/commands/install.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() => defineTests();

defineTests() {
  group('install', () {
    test('returns 0 when Android is connected and ready for an install', () {
      applicationPackageSetup();

      MockAndroidDevice android = new MockAndroidDevice();
      when(android.isConnected()).thenReturn(true);
      when(android.installApp(any)).thenReturn(true);

      MockIOSDevice ios = new MockIOSDevice();
      when(ios.isConnected()).thenReturn(false);
      when(ios.installApp(any)).thenReturn(false);

      MockIOSSimulator iosSim = new MockIOSSimulator();
      when(iosSim.isConnected()).thenReturn(false);
      when(iosSim.installApp(any)).thenReturn(false);

      InstallCommand command = new InstallCommand(android: android, ios: ios);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['install']).then((int code) => expect(code, equals(0)));
    });

    test('returns 0 when iOS is connected and ready for an install', () {
      applicationPackageSetup();

      MockAndroidDevice android = new MockAndroidDevice();
      when(android.isConnected()).thenReturn(false);
      when(android.installApp(any)).thenReturn(false);

      MockIOSDevice ios = new MockIOSDevice();
      when(ios.isConnected()).thenReturn(true);
      when(ios.installApp(any)).thenReturn(true);

      MockIOSSimulator iosSim = new MockIOSSimulator();
      when(iosSim.isConnected()).thenReturn(false);
      when(iosSim.installApp(any)).thenReturn(false);

      InstallCommand command =
          new InstallCommand(android: android, ios: ios, iosSim: iosSim);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['install']).then((int code) => expect(code, equals(0)));
    });
  });
}
