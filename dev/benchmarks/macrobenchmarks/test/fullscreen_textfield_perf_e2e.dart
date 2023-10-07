// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/common.dart';

import 'util.dart';

void main() {
  macroPerfTestE2E(
    'fullscreen_textfield_perf',
    kFullscreenTextRouteName,
    pageDelay: const Duration(seconds: 1),
    body: (WidgetController controller) async {
      final Finder textfield = find.byKey(const ValueKey<String>('fullscreen-textfield'));
      controller.tap(textfield);
      await Future<void>.delayed(const Duration(milliseconds: 5000));
    },
  );
}
