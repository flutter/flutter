// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library list_test;

import 'package:args/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/commands/list.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() => defineTests();

defineTests() {
  group('list', () {
    test('returns 0 when called', () {
      applicationPackageSetup();

      MockAndroidDevice android = new MockAndroidDevice();
      // Avoid relying on adb being installed on the test system.
      // Instead, cause the test to run the echo command.
      when(android.adbPath).thenReturn('echo');

      MockIOSDevice ios = new MockIOSDevice();
      // Avoid relying on idevice* being installed on the test system.
      // Instead, cause the test to run the echo command.
      when(ios.informerPath).thenReturn('echo');
      when(ios.installerPath).thenReturn('echo');
      when(ios.listerPath).thenReturn('echo');

      MockIOSSimulator iosSim = new MockIOSSimulator();
      // Avoid relying on xcrun being installed on the test system.
      // Instead, cause the test to run the echo command.
      when(iosSim.xcrunPath).thenReturn('echo');

      ListCommand command =
          new ListCommand(android: android, ios: ios, iosSim: iosSim);
      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['list']).then((int code) => expect(code, equals(0)));
    });
  });
}
