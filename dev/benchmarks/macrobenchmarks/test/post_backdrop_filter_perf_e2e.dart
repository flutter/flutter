// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/common.dart';

import 'util.dart';

void main() {
  macroPerfTestE2E(
    'post_backdrop_filter_perf',
    kPostBackdropFilterRouteName,
    pageDelay: const Duration(seconds: 1),
    duration: const Duration(seconds: 10),
    body: (WidgetController controller) async {
      final Finder backdropFilterCheckbox = find.byKey(const ValueKey<String>('bdf-checkbox'));
      await controller.tap(backdropFilterCheckbox);
      await Future<void>.delayed(const Duration(milliseconds: 500)); // BackdropFilter on
      await controller.tap(backdropFilterCheckbox);
      await Future<void>.delayed(const Duration(milliseconds: 500)); // BackdropFilter off

      final Finder animateButton = find.byKey(const ValueKey<String>('bdf-animate'));
      await controller.tap(animateButton);
      await Future<void>.delayed(const Duration(milliseconds: 1000)); // Now animate
    },
  );
}
