// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/platform_view_layer.h"

namespace flow {

PlatformViewLayer::PlatformViewLayer() = default;

PlatformViewLayer::~PlatformViewLayer() = default;

void PlatformViewLayer::Preroll(PrerollContext* context,
                                const SkMatrix& matrix) {
  set_paint_bounds(SkRect::MakeXYWH(offset_.x(), offset_.y(), size_.width(),
                                    size_.height()));
}

void PlatformViewLayer::Paint(PaintContext& context) const {
  if (context.view_embedder == nullptr) {
    FML_LOG(ERROR) << "Trying to embed a platform view but the PaintContext "
                      "does not support embedding";
    return;
  }
  EmbeddedViewParams params;
  SkMatrix transform = context.canvas.getTotalMatrix();
  params.offsetPixels =
      SkPoint::Make(transform.getTranslateX(), transform.getTranslateY());
  params.sizePoints = size_;

  context.view_embedder->CompositeEmbeddedView(view_id_, params);
}
}  // namespace flow
