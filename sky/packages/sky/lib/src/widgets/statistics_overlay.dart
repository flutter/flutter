// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/rendering/statistics_box.dart';

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

class StatisticsOverlay extends LeafRenderObjectWidget {

  /// Create a statistics overlay that only displays specific statistics. The
  /// mask is created by shifting 1 by the index of the specific StatisticOption
  /// to enable.
  StatisticsOverlay({ this.optionsMask, this.rasterizerThreshold: 0, Key key }) : super(key: key);

  /// Create a statistics overaly that displays all available statistics
  StatisticsOverlay.allEnabled({ Key key, this.rasterizerThreshold: 0 }) : super(key: key), optionsMask = (
    1 << StatisticsOption.displayRasterizerStatistics.index |
    1 << StatisticsOption.visualizeRasterizerStatistics.index |
    1 << StatisticsOption.displayEngineStatistics.index |
    1 << StatisticsOption.visualizeEngineStatistics.index
  );

  final int optionsMask;
  final int rasterizerThreshold;

  StatisticsBox createRenderObject() => new StatisticsBox(
    optionsMask: optionsMask,
    rasterizerThreshold: rasterizerThreshold
  );

  void updateRenderObject(StatisticsBox renderObject, RenderObjectWidget oldWidget) {
    renderObject.optionsMask = optionsMask;
    renderObject.rasterizerThreshold = rasterizerThreshold;
  }
}
