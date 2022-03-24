// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:macrobenchmarks/common.dart';

import 'util.dart';

void main() {
  macroPerfTest(
    'post_backdrop_filter_perf',
    kPostBackdropFilterRouteName,
    pageDelay: const Duration(seconds: 2),
    duration: const Duration(seconds: 10),
    setupOps: (FlutterDriver driver) async {
      final SerializableFinder backdropFilterCheckbox = find.byValueKey('bdf-checkbox');
      await driver.tap(backdropFilterCheckbox);
      await Future<void>.delayed(const Duration(milliseconds: 500)); // BackdropFilter on
      await driver.tap(backdropFilterCheckbox);
      await Future<void>.delayed(const Duration(milliseconds: 500)); // BackdropFilter off

      final SerializableFinder animateButton = find.byValueKey('bdf-animate');
      await driver.tap(animateButton);
      await Future<void>.delayed(const Duration(milliseconds: 10000)); // Now animate
    },
  );
}
