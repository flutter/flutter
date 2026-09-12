// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('foundation debug variables can be reset with addTearDown', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    debugDoublePrecision = 3;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      debugDoublePrecision = null;
    });

    expect(defaultTargetPlatform, TargetPlatform.macOS);
    expect(debugDoublePrecision, 3);
  });
}
