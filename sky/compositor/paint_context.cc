// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/paint_context.h"
#include "base/logging.h"

namespace sky {
namespace compositor {

PaintContext::PaintContext() {
}

void PaintContext::beginFrame() {
  frame_count_.increment();
  frame_time_.start();
}

void PaintContext::endFrame() {
  rasterizer_.PurgeCache();
  frame_time_.stop();
}

PaintContext::ScopedFrame PaintContext::AcquireFrame(SkCanvas& canvas,
                                                     GrContext* gr_context) {
  return ScopedFrame(*this, canvas, gr_context);
}

PaintContext::~PaintContext() {
  rasterizer_.PurgeCache();
}

}  // namespace compositor
}  // namespace sky
