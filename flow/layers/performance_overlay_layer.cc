// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include <iostream>
#include <iomanip>

#include "flow/layers/performance_overlay_layer.h"

namespace flow {

PerformanceOverlayLayer::PerformanceOverlayLayer(uint64_t enabledOptions)
    : options_(enabledOptions) {
}

static void DrawStatisticsText(SkCanvas& canvas,
                               const std::string& string,
                               int x,
                               int y) {
  SkPaint paint;
  paint.setTextSize(14);
  paint.setLinearText(false);
  paint.setColor(SK_ColorRED);
  canvas.drawText(string.c_str(), string.size(), x, y, paint);
}

static void VisualizeStopWatch(SkCanvas& canvas,
                               const instrumentation::Stopwatch& stopwatch,
                               SkScalar x,
                               SkScalar y,
                               SkScalar width,
                               SkScalar height,
                               bool show_graph,
                               bool show_labels,
                               std::string label_prefix) {
  const int labelX = 8; // distance from x
  const int labelY = -10; // distance from y+height

  if (show_graph) {
    SkRect visualizationRect = SkRect::MakeXYWH(x, y, width, height);
    stopwatch.visualize(canvas, visualizationRect);
  }

  if (show_labels) {
    double msPerFrame = stopwatch.maxDelta().InMillisecondsF();
    double fps;
    if (msPerFrame < instrumentation::kOneFrameMS) {
      fps = 1e3 / instrumentation::kOneFrameMS; 
    } else {
      fps = 1e3 / msPerFrame;
    }

    std::stringstream stream;
    stream.setf(std::ios::fixed | std::ios::showpoint);
    stream << std::setprecision(1);
    stream << label_prefix << "  " << fps        << " fps  "
                                   << msPerFrame << "ms/frame";
    DrawStatisticsText(canvas, stream.str(), x + labelX, y + height + labelY);
  }
}

void PerformanceOverlayLayer::Paint(PaintContext::ScopedFrame& frame) {
  if (!options_) {
    return;
  }

  SkScalar x = paint_bounds().x();
  SkScalar y = paint_bounds().y();
  SkScalar width = paint_bounds().width();
  SkScalar height = paint_bounds().height() / 2;
  SkAutoCanvasRestore save(&frame.canvas(), true);

  VisualizeStopWatch(frame.canvas(), frame.context().frame_time(),
                     x, y, width, height,
                     options_ & kVisualizeRasterizerStatistics,
                     options_ & kDisplayRasterizerStatistics,
                     "Rasterizer");

  VisualizeStopWatch(frame.canvas(), frame.context().engine_time(),
                     x, y + height, width, height,
                     options_ & kVisualizeEngineStatistics,
                     options_ & kDisplayEngineStatistics,
                     "Engine");
}

}  // namespace flow
