// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/paint_context.h"
#include "base/logging.h"

namespace sky {
namespace compositor {

PaintContext::PaintContext() {
}

void PaintContext::beginFrame(SkCanvas& canvas, GrContext* gr_context) {
  canvas_ = &canvas;         // required
  gr_context_ = gr_context;  // optional

  DCHECK(canvas_);
}

void PaintContext::endFrame() {
  DCHECK(canvas_);

  rasterizer_.PurgeCache();

  canvas_ = nullptr;
  gr_context_ = nullptr;
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
