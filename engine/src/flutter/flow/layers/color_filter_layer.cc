// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/color_filter_layer.h"

namespace flow {

ColorFilterLayer::ColorFilterLayer() = default;

ColorFilterLayer::~ColorFilterLayer() = default;

void ColorFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ColorFilterLayer::Paint");
  FML_DCHECK(needs_painting());

  sk_sp<SkColorFilter> color_filter =
      SkColorFilter::MakeModeFilter(color_, blend_mode_);
  SkPaint paint;
  paint.setColorFilter(std::move(color_filter));

  Layer::AutoSaveLayer save =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flow
