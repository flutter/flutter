// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:macrobenchmarks/common.dart';

import 'util.dart';

void main() {
  macroPerfTest(
    'fullscreen_textfield_perf',
    kFullscreenTextRouteName,
    driverOps: (FlutterDriver driver) async {
      final SerializableFinder textfield = find.byValueKey('fullscreen-textfield');
      driver.tap(textfield);
      await Future<void>.delayed(const Duration(milliseconds: 5000));
    },
  );
}
