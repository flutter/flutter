// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include <iostream>
#include <iomanip>

#include "flutter/flow/layers/performance_overlay_layer.h"

namespace flow {
namespace {

void DrawStatisticsText(SkCanvas& canvas,
                        const std::string& string,
                        int x,
                        int y) {
  SkPaint paint;
  paint.setTextSize(14);
  paint.setLinearText(false);
  paint.setColor(SK_ColorRED);
  canvas.drawText(string.c_str(), string.size(), x, y, paint);
}

void VisualizeStopWatch(SkCanvas& canvas,
                        const Stopwatch& stopwatch,
                        SkScalar x,
                        SkScalar y,
                        SkScalar width,
                        SkScalar height,
                        bool show_graph,
                        bool show_labels,
                        const std::string& label_prefix) {
  const int label_x = 8;    // distance from x
  const int label_y = -10;  // distance from y+height

  if (show_graph) {
    SkRect visualization_rect = SkRect::MakeXYWH(x, y, width, height);
    stopwatch.Visualize(canvas, visualization_rect);
  }

  if (show_labels) {
    double ms_per_frame = stopwatch.MaxDelta().ToMillisecondsF();
    double fps;
    if (ms_per_frame < kOneFrameMS) {
      fps = 1e3 / kOneFrameMS;
    } else {
      fps = 1e3 / ms_per_frame;
    }

    std::stringstream stream;
    stream.setf(std::ios::fixed | std::ios::showpoint);
    stream << std::setprecision(1);
    stream << label_prefix << "  " << fps << " fps  " << ms_per_frame
           << "ms/frame";
    DrawStatisticsText(canvas, stream.str(), x + label_x, y + height + label_y);
  }
}

}  // namespace

PerformanceOverlayLayer::PerformanceOverlayLayer(uint64_t options)
    : options_(options) {}

void PerformanceOverlayLayer::Paint(PaintContext& context) {
  if (!options_)
    return;

  TRACE_EVENT0("flutter", "PerformanceOverlayLayer::Paint");
  SkScalar x = paint_bounds().x();
  SkScalar y = paint_bounds().y();
  SkScalar width = paint_bounds().width();
  SkScalar height = paint_bounds().height() / 2;
  SkAutoCanvasRestore save(&context.canvas, true);

  VisualizeStopWatch(context.canvas, context.frame_time, x, y, width, height,
                     options_ & kVisualizeRasterizerStatistics,
                     options_ & kDisplayRasterizerStatistics, "Rasterizer");

  VisualizeStopWatch(context.canvas, context.engine_time, x, y + height, width,
                     height, options_ & kVisualizeEngineStatistics,
                     options_ & kDisplayEngineStatistics, "Engine");
}

}  // namespace flow
