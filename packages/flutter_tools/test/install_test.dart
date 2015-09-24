// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library install_test;

import 'package:args/command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/install.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() => defineTests();

defineTests() {
  group('install', () {
    test('returns 0 when Android is connected and ready for an install', () {
      ApplicationPackageFactory.srcPath = './';
      ApplicationPackageFactory.setBuildPath(
          BuildType.prebuilt, BuildPlatform.android, './');

      MockAndroidDevice android = new MockAndroidDevice();
      when(android.isConnected()).thenReturn(true);
      when(android.installApp(any)).thenReturn(true);
      InstallCommand command = new InstallCommand(android);

      CommandRunner runner = new CommandRunner('test_flutter', '')
          ..addCommand(command);
      runner.run(['install'])
          .then((int code) => expect(code, equals(0)));
    });
  });
}
