// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/overscroll_stretch_layer.h"
#include "flutter/flow/layers/layer.h"

namespace flutter {

OverscrollStretchLayer::OverscrollStretchLayer(
    const std::shared_ptr<DlImageFilter>& filter,
    double x_stretch,
    double y_stretch,
    const DlRect& viewport_rect,
    const DlPoint& offset)
    : ImageFilterLayer(filter, offset),
      x_stretch_(x_stretch),
      y_stretch_(y_stretch),
      viewport_rect_(viewport_rect) {}

void OverscrollStretchLayer::Preroll(PrerollContext* context) {
  // The viewport is supplied in this layer's local/paint space. The stretch is
  // applied to platform views (and the surrounding content) in screen space, so
  // map the viewport through the current transform, which has not yet had this
  // layer's own offset applied.
  const DlRect viewport_screen_rect =
      viewport_rect_.TransformAndClipBounds(context->state_stack.matrix());

  auto mutator = context->state_stack.save();
  mutator.applyOverscrollStretch(x_stretch_, y_stretch_, viewport_screen_rect);

  if (context->view_embedder != nullptr) {
    context->view_embedder->PushOverscrollStretchToVisitedPlatformViews(
        x_stretch_, y_stretch_, viewport_screen_rect);
  }

  ImageFilterLayer::Preroll(context);
}

}  // namespace flutter
