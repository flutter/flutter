// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  const int x = 10;
  int y = 20;
  static const int kLineSpacing = 18;

  const PaintContext& context = frame.context();

  if (options_.isEnabled(CompositorOptions::Option::DisplayFrameStatistics)) {
    // Frame (2032): 3.26ms
    std::stringstream stream;
    stream << "Frame (" << context.frame_count().count()
           << "): " << context.frame_time().lastLap().InMillisecondsF() << "ms";
    PaintContext_DrawStatisticsText(frame.canvas(), stream.str(), x, y);
    y += kLineSpacing;
  }
}

}  // namespace compositor
}  // namespace sky
