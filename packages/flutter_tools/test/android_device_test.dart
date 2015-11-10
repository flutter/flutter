// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/device.dart';
import 'package:test/test.dart';

main() => defineTests();

defineTests() {
  group('android_device', () {
    test('uses the correct default ID', () {
      AndroidDevice android = new AndroidDevice();
      expect(android.id, equals(AndroidDevice.defaultDeviceID));
    });

    test('stores the requested id', () {
      String deviceId = '1234';
      AndroidDevice android = new AndroidDevice(id: deviceId);
      expect(android.id, equals(deviceId));
    });

    test('correctly creates only one of each requested device id', () {
      String deviceID = '1234';
      AndroidDevice a1 = new AndroidDevice(id: deviceID);
      AndroidDevice a2 = new AndroidDevice(id: deviceID);
      expect(a1, equals(a2));
    });
  });
}
