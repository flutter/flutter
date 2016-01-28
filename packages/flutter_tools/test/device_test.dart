// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/device.dart';
import 'package:test/test.dart';

main() => defineTests();

defineTests() {
  group('DeviceManager', () {
    test('getDevices', () async {
      // Test that DeviceManager.getDevices() doesn't throw.
      DeviceManager deviceManager = new DeviceManager();
      List<Device> devices = await deviceManager.getDevices();
      expect(devices, isList);
    });
  });
}
