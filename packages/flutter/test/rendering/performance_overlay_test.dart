// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RenderPerformanceOverlay intrinsic height respects optionsMask', () {
    const kGraph = 80.0; // Matches implementation default graph height.
    final r = RenderPerformanceOverlay();
    expect(r.computeMinIntrinsicHeight(100.0), 0.0);

    // One engine stat enabled.
    final int engineMask = 1 << PerformanceOverlayOption.displayEngineStatistics.index;
    r.optionsMask = engineMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // One rasterizer stat enabled.
    final int rasterMask = 1 << PerformanceOverlayOption.displayRasterizerStatistics.index;
    r.optionsMask = rasterMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // Both engine and rasterizer graphs.
    r.optionsMask = engineMask | rasterMask;
    expect(r.computeMinIntrinsicHeight(100.0), 2 * kGraph);

    // One visualize engine stat enabled.
    final int visualizeEngineMask = 1 << PerformanceOverlayOption.visualizeEngineStatistics.index;
    r.optionsMask = visualizeEngineMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // One visualize rasterizer stat enabled.
    final int visualizeRasterMask =
        1 << PerformanceOverlayOption.visualizeRasterizerStatistics.index;
    r.optionsMask = visualizeRasterMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // Both display and visualize engine stats enabled.
    r.optionsMask = engineMask | visualizeEngineMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // Both display and visualize rasterizer stats enabled.
    r.optionsMask = rasterMask | visualizeRasterMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // All options enabled.
    r.optionsMask = engineMask | visualizeEngineMask | rasterMask | visualizeRasterMask;
    expect(r.computeMinIntrinsicHeight(100.0), 2 * kGraph);
  });
}
