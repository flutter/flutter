// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('android_device', () {
    testUsingContext('stores the requested id', () {
      String deviceId = '1234';
      AndroidDevice device = new AndroidDevice(deviceId);
      expect(device.id, equals(deviceId));
    });
  });

  group('getAdbDevices', () {
    testUsingContext('physical devices', () {
      List<AndroidDevice> devices = getAdbDevices(mockAdbOutput: '''
List of devices attached
05a02bac               device usb:336592896X product:razor model:Nexus_7 device:flo

''');
      expect(devices, hasLength(1));
      expect(devices.first.name, 'Nexus 7');
    });

    testUsingContext('emulators and short listings', () {
      List<AndroidDevice> devices = getAdbDevices(mockAdbOutput: '''
List of devices attached
localhost:36790        device
0149947A0D01500C       device usb:340787200X
emulator-5612          host features:shell_2

''');
      expect(devices, hasLength(3));
      expect(devices.first.name, 'localhost:36790');
    });
  });
}
