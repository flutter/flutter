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
}
