// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/windows/windows_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(WindowsDevice, () {
    final WindowsDevice device = WindowsDevice();
    final MockPlatform notWindows = MockPlatform();
    when(notWindows.isWindows).thenReturn(false);
    when(notWindows.environment).thenReturn(const <String, String>{});

    test('defaults', () async {
      expect(await device.targetPlatform, TargetPlatform.windows_x64);
      expect(device.name, 'Windows');
    });

    test('unimplemented methods', () {
      expect(() => device.installApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.uninstallApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.isLatestBuildInstalled(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.startApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.stopApp(null), throwsA(isInstanceOf<UnimplementedError>()));
      expect(() => device.isAppInstalled(null), throwsA(isInstanceOf<UnimplementedError>()));
    });

    test('noop port forwarding', () async {
      final WindowsDevice device = WindowsDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await WindowsDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notWindows,
    });
  });
}

class MockPlatform extends Mock implements Platform {}
