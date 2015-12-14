// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';

/// The options that control whether the statistics overlay displays certain
/// aspects of the compositor
enum StatisticsOption {
  /// Display the frame time and FPS of the last frame rendered. This field is
  /// updated every frame.
  ///
  /// This is the time spent by the rasterizer as it tries
  /// to convert the layer tree obtained from the widgets into OpenGL commands
  /// and tries to flush them onto the screen. When the total time taken by this
  /// step exceeds the frame slice, a frame is lost.
  displayRasterizerStatistics,
  /// Display the rasterizer frame times as they change over a set period of
  /// time in the form of a graph. The y axis of the graph denotes the total
  /// time spent by the rasterizer as a fraction of the total frame slice. When
  /// the bar turns red, a frame is lost.
  visualizeRasterizerStatistics,
  /// Display the frame time and FPS at which the interface can construct a
  /// layer tree for the rasterizer (whose behavior is described above) to
  /// consume.
  ///
  /// This involves all layout, animations, etc. When the total time taken by
  /// this step exceeds the frame slice, a frame is lost.
  displayEngineStatistics,
  /// Display the engine frame times as they change over a set period of time
  /// in the form of a graph. The y axis of the graph denotes the total time
  /// spent by the eninge as a fraction of the total frame slice. When the bar
  /// turns red, a frame is lost.
  visualizeEngineStatistics,
}

/// Displays performance statistics.
class StatisticsOverlay extends LeafRenderObjectWidget {
  // TODO(abarth): We should have a page on the web site with a screenshot and
  // an explanation of all the various readouts.

  /// Create a statistics overlay that only displays specific statistics. The
  /// mask is created by shifting 1 by the index of the specific StatisticOption
  /// to enable.
  StatisticsOverlay({ this.optionsMask, this.rasterizerThreshold: 0, Key key }) : super(key: key);

  /// Create a statistics overaly that displays all available statistics
  StatisticsOverlay.allEnabled({ Key key, this.rasterizerThreshold: 0 })
    : optionsMask = (
        1 << StatisticsOption.displayRasterizerStatistics.index |
        1 << StatisticsOption.visualizeRasterizerStatistics.index |
        1 << StatisticsOption.displayEngineStatistics.index |
        1 << StatisticsOption.visualizeEngineStatistics.index
      ),
      super(key: key);

  final int optionsMask;

  /// The rasterizer threshold is an integer specifying the number of frame
  /// intervals that the rasterizer must miss before it decides that the frame
  /// is suitable for capturing an SkPicture trace for further analysis.
  ///
  /// For example, if you want a trace of all pictures that could not be
  /// renderered by the rasterizer within the frame boundary (and hence caused
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
  /// lines displayed in the statistics overlay for the rasterizer (not the
  /// engine). That should give an idea of how often frames are skipped (and by
  /// how many frame intervals).
  final int rasterizerThreshold;

  RenderStatisticsBox createRenderObject() => new RenderStatisticsBox(
    optionsMask: optionsMask,
    rasterizerThreshold: rasterizerThreshold
  );

  void updateRenderObject(RenderStatisticsBox renderObject, RenderObjectWidget oldWidget) {
    renderObject.optionsMask = optionsMask;
    renderObject.rasterizerThreshold = rasterizerThreshold;
  }
}
