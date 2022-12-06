// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/rendering/performance_overlay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Performance overlay smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PerformanceOverlay());
    await tester.pumpWidget(PerformanceOverlay.allEnabled());
  });

  testWidgets('update widget field checkerboardRasterCacheImages',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PerformanceOverlay());
    await tester.pumpWidget(
        const PerformanceOverlay(checkerboardRasterCacheImages: true));
    final Finder finder = find.byType(PerformanceOverlay);
    expect(
        tester
            .renderObject<RenderPerformanceOverlay>(finder)
            .checkerboardRasterCacheImages,
        true);
  });

  testWidgets('update widget field checkerboardOffscreenLayers',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PerformanceOverlay());
    await tester.pumpWidget(
        const PerformanceOverlay(checkerboardOffscreenLayers: true));
    final Finder finder = find.byType(PerformanceOverlay);
    expect(
        tester
            .renderObject<RenderPerformanceOverlay>(finder)
            .checkerboardOffscreenLayers,
        true);
  });
}
