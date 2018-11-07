// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iomanip>
#include <iostream>
#include <string>

#include "flutter/flow/layers/performance_overlay_layer.h"

namespace flow {
namespace {

void DrawStatisticsText(SkCanvas& canvas,
                        const std::string& string,
                        int x,
                        int y) {
  SkPaint paint;
  paint.setTextSize(15);
  paint.setLinearText(false);
  paint.setColor(SK_ColorGRAY);
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

void PerformanceOverlayLayer::Paint(PaintContext& context) const {
  const int padding = 8;

  if (!options_)
    return;

  TRACE_EVENT0("flutter", "PerformanceOverlayLayer::Paint");
  SkScalar x = paint_bounds().x() + padding;
  SkScalar y = paint_bounds().y() + padding;
  SkScalar width = paint_bounds().width() - (padding * 2);
  SkScalar height = paint_bounds().height() / 2;
  SkAutoCanvasRestore save(context.canvas, true);

  VisualizeStopWatch(*context.canvas, context.frame_time, x, y, width,
                     height - padding,
                     options_ & kVisualizeRasterizerStatistics,
                     options_ & kDisplayRasterizerStatistics, "GPU");

  VisualizeStopWatch(*context.canvas, context.engine_time, x, y + height, width,
                     height - padding, options_ & kVisualizeEngineStatistics,
                     options_ & kDisplayEngineStatistics, "UI");
}

}  // namespace flow
