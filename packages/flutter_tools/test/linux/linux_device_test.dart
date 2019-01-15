// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/linux/linux_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(LinuxDevice, () {
    final LinuxDevice device = LinuxDevice();
    final MockPlatform notLinux = MockPlatform();
    when(notLinux.isLinux).thenReturn(false);
    when(notLinux.environment).thenReturn(const <String, String>{});

    test('defaults', () async {
      expect(await device.targetPlatform, TargetPlatform.linux_x64);
      expect(device.name, 'Linux');
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
      final LinuxDevice device = LinuxDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await LinuxDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notLinux,
    });
  });
}

class MockPlatform extends Mock implements Platform {}
