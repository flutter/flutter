// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include <iostream>
#include <iomanip>

#include "sky/compositor/statistics_layer.h"

namespace sky {
namespace compositor {

StatisticsLayer::StatisticsLayer(uint64_t enabledOptions)
    : options_(enabledOptions) {
}

static void PaintContext_DrawStatisticsText(SkCanvas& canvas,
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
                               SkScalar width,
                               bool show_graph,
                               bool show_labels,
                               std::string label_prefix) {
  const int x = 8;
  const int y = 70;
  const int height = 80;

  if (show_graph) {
    SkRect visualizationRect = SkRect::MakeWH(width, height);
    stopwatch.visualize(canvas, visualizationRect);
  }

  if (show_labels) {
    double msPerFrame = stopwatch.lastLap().InMillisecondsF();
    double fps = 1e3 / msPerFrame;

    std::stringstream stream;
    stream.setf(std::ios::fixed | std::ios::showpoint);
    stream << std::setprecision(2);
    stream << label_prefix << " " << fps << " FPS | " << msPerFrame
           << "ms/frame";
    PaintContext_DrawStatisticsText(canvas, stream.str(), x, y);
  }

  if (show_labels || show_graph) {
    canvas.translate(0, height);
  }
}

void StatisticsLayer::Paint(PaintContext::ScopedFrame& frame) {
  if (!options_.anyEnabled()) {
    return;
  }

  using Opt = CompositorOptions::Option;

  SkScalar width = has_paint_bounds() ? paint_bounds().width() : 0;
  SkAutoCanvasRestore save(&frame.canvas(), true);

  VisualizeStopWatch(frame.canvas(), frame.context().frame_time(), width,
                     options_.isEnabled(Opt::VisualizeRasterizerStatistics),
                     options_.isEnabled(Opt::DisplayRasterizerStatistics),
                     "Rasterizer");

  VisualizeStopWatch(frame.canvas(), frame.context().engine_time(), width,
                     options_.isEnabled(Opt::VisualizeEngineStatistics),
                     options_.isEnabled(Opt::DisplayEngineStatistics),
                     "Engine");
}

}  // namespace compositor
}  // namespace sky
