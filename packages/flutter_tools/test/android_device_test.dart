// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library android_device_test;

import 'package:sky_tools/src/device.dart';
import 'package:test/test.dart';

main() => defineTests();

defineTests() {
  group('android_device', () {
    test('uses the correct default ID', () {
      AndroidDevice android = new AndroidDevice();
      expect(android.id, equals(AndroidDevice.defaultDeviceID));
    });

    test('stores the requested id', () {
      String deviceID = '1234';
      AndroidDevice android = new AndroidDevice(deviceID);
      expect(android.id, equals(deviceID));
    });

    test('correctly creates only one of each requested device id', () {
      String deviceID = '1234';
      AndroidDevice a1 = new AndroidDevice(deviceID);
      AndroidDevice a2 = new AndroidDevice(deviceID);
      expect(a1, equals(a2));
    });
  });
}
