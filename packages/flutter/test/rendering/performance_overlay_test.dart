// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RenderPerformanceOverlay intrinsic height respects optionsMask', () {
    const double kGraph = 80.0; // matches implementation default graph height
    final RenderPerformanceOverlay r = RenderPerformanceOverlay(optionsMask: 0);
    expect(r.computeMinIntrinsicHeight(100.0), 0.0);

    // One engine stat enabled
    final int engineMask = 1 << PerformanceOverlayOption.displayEngineStatistics.index;
    r.optionsMask = engineMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // One rasterizer stat enabled
    final int rasterMask = 1 << PerformanceOverlayOption.displayRasterizerStatistics.index;
    r.optionsMask = rasterMask;
    expect(r.computeMinIntrinsicHeight(100.0), kGraph);

    // Both engine and rasterizer graphs
    r.optionsMask = engineMask | rasterMask;
    expect(r.computeMinIntrinsicHeight(100.0), 2 * kGraph);
  });
}
