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

void StatisticsLayer::Paint(PaintContext::ScopedFrame& frame) {
  const int x = 8;
  int y = 70;
  static const int kLineSpacing = 18;

  const PaintContext& context = frame.context();

  if (options_.isEnabled(CompositorOptions::Option::VisualizeFrameStatistics)) {
    SkRect visualizationRect = SkRect::MakeWH(paint_bounds().width(), 80);
    context.frame_time().visualize(frame.canvas(), visualizationRect);
  }

  if (options_.isEnabled(CompositorOptions::Option::DisplayFrameStatistics)) {
    // Frame (2032): 3.26ms
    double msPerFrame = context.frame_time().lastLap().InMillisecondsF();
    double fps = 1e3 / msPerFrame;

    std::stringstream stream;
    stream.setf(std::ios::fixed | std::ios::showpoint);
    stream << std::setprecision(2);
    stream << fps << " FPS | " << msPerFrame << "ms/frame";
    PaintContext_DrawStatisticsText(frame.canvas(), stream.str(), x, y);
    y += kLineSpacing;
  }
}

}  // namespace compositor
}  // namespace sky
