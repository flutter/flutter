// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library trace_test;

import 'package:args/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/trace.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() => defineTests();

defineTests() {
  group('trace', () {
    test('returns 1 when no Android device is connected', () {
      ApplicationPackageFactory.srcPath = './';
      ApplicationPackageFactory.setBuildPath(
          BuildType.prebuilt, BuildPlatform.android, './');

      MockAndroidDevice android = new MockAndroidDevice();
      when(android.isConnected()).thenReturn(false);
      TraceCommand command = new TraceCommand(android);

      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      runner.run(['trace']).then((int code) => expect(code, equals(1)));
    });
  });
}
