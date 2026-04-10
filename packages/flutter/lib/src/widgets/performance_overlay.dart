// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'app.dart';
library;

import 'package:flutter/rendering.dart';

import 'framework.dart';

/// Displays performance statistics.
///
/// The overlay shows two separate graphs representing the two main threads
/// involved in rendering:
///
/// 1. **UI Thread (Bottom Graph):** Measures the time spent executing Dart code,
///    including building widgets, performing layout, and paint command recording.
/// 2. **Raster Thread (Top Graph):** Measures the time spent by the engine's
///    rasterizer (formerly the GPU thread) to turn the recorded paint commands
///    into actual pixels on the screen.
///
/// **Theoretical Throughput (FPS):**
/// The values shown represent the maximum possible throughput for that thread
/// given the current workload. It does not necessarily reflect the actual
/// number of frames delivered to the screen per second.
///
/// For example, if an app only updates a clock once every sixty seconds, but
/// the UI thread takes 10ms to produce that single frame, the overlay would
/// indicate a capacity for 60 FPS, even though the actual frame rate is one
/// frame per minute. Conversely, if a frame takes 30ms to process, the overlay
/// would report 33 FPS, as that is the theoretical maximum throughput the
/// thread could sustain, regardless of the actual update frequency.
///
/// **Visualizing Performance:**
/// * **Green Vertical Line:** Indicates that the thread's work was completed
///   within the hardware's target frame budget (e.g., < 16.6ms for 60Hz).
/// * **Red Vertical Line:** Indicates the thread exceeded the budget, which
///   would result in visible jank during continuous animation.
///
/// For more detailed analysis, including direct FPS metrics, use Flutter DevTools.
///
/// The simplest way to show the performance overlay is to set
/// [MaterialApp.showPerformanceOverlay] or [WidgetsApp.showPerformanceOverlay]
/// to true.
class PerformanceOverlay extends LeafRenderObjectWidget {
  /// Create a performance overlay that only displays specific statistics. The
  /// mask is created by shifting 1 by the index of the specific
  /// [PerformanceOverlayOption] to enable.
  const PerformanceOverlay({super.key, this.optionsMask = 0});

  /// Create a performance overlay that displays all available statistics.
  PerformanceOverlay.allEnabled({super.key})
    : optionsMask =
          1 << PerformanceOverlayOption.displayRasterizerStatistics.index |
          1 << PerformanceOverlayOption.visualizeRasterizerStatistics.index |
          1 << PerformanceOverlayOption.displayEngineStatistics.index |
          1 << PerformanceOverlayOption.visualizeEngineStatistics.index;

  /// The mask is created by shifting 1 by the index of the specific
  /// [PerformanceOverlayOption] to enable.
  final int optionsMask;

  @override
  RenderPerformanceOverlay createRenderObject(BuildContext context) =>
      RenderPerformanceOverlay(optionsMask: optionsMask);

  @override
  void updateRenderObject(BuildContext context, RenderPerformanceOverlay renderObject) {
    renderObject.optionsMask = optionsMask;
  }
}
