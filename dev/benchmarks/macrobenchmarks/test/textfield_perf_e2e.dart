// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/common.dart';

import 'util.dart';

void main() {
  macroPerfTestE2E(
    'textfield_perf',
    kTextRouteName,
    // The driver version doesn't have this delay because the delay caused
    // by the communication between the host and the test device is long enough
    // for the driver test, but there isn't such delay in this host independent
    // test.
    pageDelay: const Duration(milliseconds: 50),
    body: (WidgetController controller) async {
      final Finder textfield = find.byKey(const ValueKey<String>('basic-textfield'));
      controller.tap(textfield);
      // Caret should be cached, so repeated blinking should not require recompute.
      await Future<void>.delayed(const Duration(milliseconds: 5000));
    },
  );
}
