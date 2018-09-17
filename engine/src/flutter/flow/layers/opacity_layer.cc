// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

namespace flow {

OpacityLayer::OpacityLayer() = default;

OpacityLayer::~OpacityLayer() = default;

void OpacityLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  FML_DCHECK(needs_painting());

  SkPaint paint;
  paint.setAlpha(alpha_);

  Layer::AutoSaveLayer save =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flow
