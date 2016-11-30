// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('devices', () {
    testUsingContext('returns 0 when called', () async {
      DevicesCommand command = new DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
    });

    testUsingContext('no error when no connected devices', () async {
      DevicesCommand command = new DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
      expect(testLogger.statusText, contains('No devices detected'));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => null,
      DeviceManager: () => new DeviceManager(),
    });
  });
}
