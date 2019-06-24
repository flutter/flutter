// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/install.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('install', () {
    testUsingContext('returns 0 when Android is connected and ready for an install', () async {
      final InstallCommand command = InstallCommand();
      applyMocksToCommand(command);

      final MockAndroidDevice device = MockAndroidDevice();
      when(device.isAppInstalled(any)).thenAnswer((_) async => false);
      when(device.installApp(any)).thenAnswer((_) async => true);
      testDeviceManager.addDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
    });

    testUsingContext('returns 0 when iOS is connected and ready for an install', () async {
      final InstallCommand command = InstallCommand();
      applyMocksToCommand(command);

      final MockIOSDevice device = MockIOSDevice();
      when(device.isAppInstalled(any)).thenAnswer((_) async => false);
      when(device.installApp(any)).thenAnswer((_) async => true);
      testDeviceManager.addDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
    });
  });
}
