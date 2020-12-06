// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Performance overlay smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PerformanceOverlay());
    await tester.pumpWidget(PerformanceOverlay.allEnabled());
  });
}
