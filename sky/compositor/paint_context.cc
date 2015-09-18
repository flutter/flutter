// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/paint_context.h"
#include "base/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace sky {
namespace compositor {

PaintContext::PaintContext() {
}

void PaintContext::beginFrame(ScopedFrame& frame) {
  frame_count_.increment();
  frame_time_.start();
}

void PaintContext::endFrame(ScopedFrame& frame) {
  frame_time_.stop();

  DisplayStatistics(frame);
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

void PaintContext::DisplayStatistics(ScopedFrame& frame) {
  // TODO: We just draw text text on the top left corner for now. Make this
  // better
  const int x = 10;
  int y = 20;
  static const int kLineSpacing = 18;

  if (options_.isEnabled(CompositorOptions::Option::DisplayFrameStatistics)) {
    // Frame (2032): 3.26ms
    std::stringstream stream;
    stream << "Frame (" << frame_count_.count()
           << "): " << frame_time_.lastLap().InMillisecondsF() << "ms";
    PaintContext_DrawStatisticsText(frame.canvas(), stream.str(), x, y);
    y += kLineSpacing;
  }
}

PaintContext::ScopedFrame PaintContext::AcquireFrame(SkCanvas& canvas) {
  return ScopedFrame(*this, canvas);
}

PaintContext::~PaintContext() {
}

}  // namespace compositor
}  // namespace sky
