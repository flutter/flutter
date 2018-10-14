// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';

/// Displays performance statistics.
///
/// The overlay show two time series. The first shows how much time was required
/// on this thread to produce each frame. The second shows how much time was
/// required on the GPU thread to produce each frame. Ideally, both these values
/// would be less than the total frame budget for the hardware on which the app
/// is running. For example, if the hardware has a screen that updates at 60 Hz,
/// each thread should ideally spend less than 16ms producing each frame. This
/// ideal condition is indicated by a green vertical line for each thread.
/// Otherwise, the performance overlay shows a red vertical line.
///
/// The simplest way to show the performance overlay is to set
/// [MaterialApp.showPerformanceOverlay] or [WidgetsApp.showPerformanceOverlay]
/// to true.
class PerformanceOverlay extends LeafRenderObjectWidget {
  // TODO(abarth): We should have a page on the web site with a screenshot and
  // an explanation of all the various readouts.

  /// Create a performance overlay that only displays specific statistics. The
  /// mask is created by shifting 1 by the index of the specific
  /// [PerformanceOverlayOption] to enable.
  const PerformanceOverlay({
    Key key,
    this.optionsMask = 0,
    this.rasterizerThreshold = 0,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
  }) : super(key: key);

  /// Create a performance overlay that displays all available statistics
  PerformanceOverlay.allEnabled({ Key key,
                                  this.rasterizerThreshold = 0,
                                  this.checkerboardRasterCacheImages = false,
                                  this.checkerboardOffscreenLayers = false })
    : optionsMask =
        1 << PerformanceOverlayOption.displayRasterizerStatistics.index |
        1 << PerformanceOverlayOption.visualizeRasterizerStatistics.index |
        1 << PerformanceOverlayOption.displayEngineStatistics.index |
        1 << PerformanceOverlayOption.visualizeEngineStatistics.index,
      super(key: key);

  /// The mask is created by shifting 1 by the index of the specific
  /// [PerformanceOverlayOption] to enable.
  final int optionsMask;

  /// The rasterizer threshold is an integer specifying the number of frame
  /// intervals that the rasterizer must miss before it decides that the frame
  /// is suitable for capturing an SkPicture trace for further analysis.
  ///
  /// For example, if you want a trace of all pictures that could not be
  /// rendered by the rasterizer within the frame boundary (and hence caused
  /// jank), specify 1. Specifying 2 will trace all pictures that took more
  /// more than 2 frame intervals to render. Adjust this value to only capture
  /// the particularly expensive pictures while skipping the others. Specifying
  /// 0 disables all capture.
  ///
  /// Captured traces are placed on your device in the application documents
  /// directory in this form "trace_<collection_time>.skp". These can
  /// be viewed in the Skia debugger.
  ///
  /// Notes:
  /// The rasterizer only takes into account the time it took to render
  /// the already constructed picture. This include the Skia calls (which is
  /// also why an SkPicture trace is generated) but not any of the time spent in
  /// dart to construct that picture. To profile that part of your code, use
  /// the instrumentation available in observatory.
  ///
  /// To decide what threshold interval to use, count the number of horizontal
  /// lines displayed in the performance overlay for the rasterizer (not the
  /// engine). That should give an idea of how often frames are skipped (and by
  /// how many frame intervals).
  final int rasterizerThreshold;

  /// Whether the raster cache should checkerboard cached entries.
  ///
  /// The compositor can sometimes decide to cache certain portions of the
  /// widget hierarchy. Such portions typically don't change often from frame to
  /// frame and are expensive to render. This can speed up overall rendering. However,
  /// there is certain upfront cost to constructing these cache entries. And, if
  /// the cache entries are not used very often, this cost may not be worth the
  /// speedup in rendering of subsequent frames. If the developer wants to be certain
  /// that populating the raster cache is not causing stutters, this option can be
  /// set. Depending on the observations made, hints can be provided to the compositor
  /// that aid it in making better decisions about caching.
  final bool checkerboardRasterCacheImages;

  /// Whether the compositor should checkerboard layers that are rendered to offscreen
  /// bitmaps. This can be useful for debugging rendering performance.
  ///
  /// Render target switches are caused by using opacity layers (via a [FadeTransition] or
  /// [Opacity] widget), clips, shader mask layers, etc. Selecting a new render target
  /// and merging it with the rest of the scene has a performance cost. This can sometimes
  /// be avoided by using equivalent widgets that do not require these layers (for example,
  /// replacing an [Opacity] widget with an [widgets.Image] using a [BlendMode]).
  final bool checkerboardOffscreenLayers;

  @override
  RenderPerformanceOverlay createRenderObject(BuildContext context) => RenderPerformanceOverlay(
    optionsMask: optionsMask,
    rasterizerThreshold: rasterizerThreshold,
    checkerboardRasterCacheImages: checkerboardRasterCacheImages,
    checkerboardOffscreenLayers: checkerboardOffscreenLayers,
  );

  @override
  void updateRenderObject(BuildContext context, RenderPerformanceOverlay renderObject) {
    renderObject
      ..optionsMask = optionsMask
      ..rasterizerThreshold = rasterizerThreshold;
  }
}
