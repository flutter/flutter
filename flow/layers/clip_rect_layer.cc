// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/clip_rect_layer.h"

namespace flow {

ClipRectLayer::ClipRectLayer() {
}

ClipRectLayer::~ClipRectLayer() {
}

void ClipRectLayer::Paint(PaintContext::ScopedFrame& frame) {
  SkCanvas& canvas = frame.canvas();
  SkAutoCanvasRestore save(&canvas, true);
  canvas.clipRect(clip_rect_);
  PaintChildren(frame);
}

}  // namespace flow
