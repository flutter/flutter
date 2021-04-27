// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:macrobenchmarks/common.dart';

import 'util.dart';

void main() {
  macroPerfTest(
    'scroll_jump_perf',
    kScrollJumpRouteName,
    pageDelay: const Duration(seconds: 1),
    driverOps: (FlutterDriver driver) async {
      for (int i = 0; i < 10; i++) {
        await driver.tap(find.byValueKey('jump'));
        final SerializableFinder line = find.text('70 Hello world');
        if (i.isOdd) {
          await driver.waitFor(line);
        } else {
          await driver.waitForAbsent(line);
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    },
  );
}
