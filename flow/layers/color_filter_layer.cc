// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/color_filter_layer.h"

namespace flutter {

ColorFilterLayer::ColorFilterLayer(SkColor color, SkBlendMode blend_mode)
    : color_(color), blend_mode_(blend_mode) {}

ColorFilterLayer::~ColorFilterLayer() = default;

void ColorFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ColorFilterLayer::Paint");
  FML_DCHECK(needs_painting());

  SkPaint paint;
  paint.setColorFilter(SkColorFilters::Blend(color_, blend_mode_));

  Layer::AutoSaveLayer save =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flutter
