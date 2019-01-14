// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';

void main() {
  group(MacOSDevice, () {
    test('unimplemented methods', () {
      final MacOSDevice macOSDevice = MacOSDevice();
      expect(() => macOSDevice.installApp(null), throwsA(const TypeMatcher<UnimplementedError>()));
      expect(() => macOSDevice.uninstallApp(null), throwsA(const TypeMatcher<UnimplementedError>()));
      expect(() => macOSDevice.isLatestBuildInstalled(null), throwsA(const TypeMatcher<UnimplementedError>()));
      expect(() => macOSDevice.startApp(null), throwsA(const TypeMatcher<UnimplementedError>()));
      expect(() => macOSDevice.stopApp(null), throwsA(const TypeMatcher<UnimplementedError>()));
      expect(() => macOSDevice.isAppInstalled(null), throwsA(const TypeMatcher<UnimplementedError>()));
    });

    test('noop port forwarding', () async {
      final MacOSDevice macOSDevice = MacOSDevice();
      final DevicePortForwarder portForwarder = macOSDevice.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
      expect(() => portForwarder.forward(1, hostPort: 23), throwsA(const TypeMatcher<UnimplementedError>()));
    });
  });
}