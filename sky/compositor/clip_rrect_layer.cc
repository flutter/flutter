// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/clip_rrect_layer.h"

namespace sky {
namespace compositor {

ClipRRectLayer::ClipRRectLayer() {
}

ClipRRectLayer::~ClipRRectLayer() {
}

void ClipRRectLayer::Paint(PaintContext::ScopedFrame& frame) {
  SkCanvas& canvas = frame.canvas();
  canvas.saveLayer(&clip_rrect_.getBounds(), nullptr);
  canvas.clipRRect(clip_rrect_);
  PaintChildren(frame);
  canvas.restore();
}

}  // namespace compositor
}  // namespace sky
