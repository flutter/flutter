// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  test('Animate for 20 seconds', () async {
    final FlutterDriver driver = await FlutterDriver.connect();
    await driver.forceGC();

    // Just run for 20 seconds to collect memory usage. The widget itself
    // animates during this time.
    await Future<void>.delayed(const Duration(seconds: 20));
    await driver.close();
  });
}
