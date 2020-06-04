// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_device.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('AndroidDevice.stopApp handles a null ApplicationPackage', () async {
    final AndroidDevice androidDevice = AndroidDevice('2');

    expect(await androidDevice.stopApp(null), false);
  });
}
