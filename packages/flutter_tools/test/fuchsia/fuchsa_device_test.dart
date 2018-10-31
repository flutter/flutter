// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/fuchsia/fuchsia_device.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('fuchsia device', () {
    testUsingContext('stores the requested id and name', () {
      const String deviceId = 'e80::0000:a00a:f00f:2002/3';
      const String name = 'halfbaked';
      final FuchsiaDevice device = FuchsiaDevice(deviceId, name: name);
      expect(device.id, deviceId);
      expect(device.name, name);
    });

    test('parse netls log output', () {
      const String example = 'device lilia-shore-only-last (fe80::0000:a00a:f00f:2002/3)';
      final List<FuchsiaDevice> devices = parseFuchsiaDeviceOutput(example);

      expect(devices.length, 1);
      expect(devices.first.id, 'fe80::0000:a00a:f00f:2002/3');
      expect(devices.first.name, 'lilia-shore-only-last');
    });
  });
}
