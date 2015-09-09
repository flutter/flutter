// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/paint_context.h"

namespace sky {
namespace compositor {

PaintContext::PaintContext(PictureRasterzier& rasterizer,
                           GrContext* gr_context,
                           SkCanvas* canvas)
    : rasterizer_(rasterizer), gr_context_(gr_context), canvas_(canvas) {
}

PaintContext::~PaintContext() {
  rasterizer_.PurgeCache();
}

}  // namespace compositor
}  // namespace sky
