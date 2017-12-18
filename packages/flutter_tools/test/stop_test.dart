// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/stop.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  group('stop', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('returns 0 when Android is connected and ready to be stopped', () async {
      final StopCommand command = new StopCommand();
      applyMocksToCommand(command);
      final MockAndroidDevice device = new MockAndroidDevice();
      when(device.stopApp(any)).thenAnswer((Invocation invocation) => new Future<bool>.value(true));
      testDeviceManager.addDevice(device);
      await createTestCommandRunner(command).run(<String>['stop']);
    });

    testUsingContext('returns 0 when iOS is connected and ready to be stopped', () async {
      final StopCommand command = new StopCommand();
      applyMocksToCommand(command);
      final MockIOSDevice device = new MockIOSDevice();
      when(device.stopApp(any)).thenAnswer((Invocation invocation) => new Future<bool>.value(true));
      testDeviceManager.addDevice(device);

      await createTestCommandRunner(command).run(<String>['stop']);
    });
  });
}
