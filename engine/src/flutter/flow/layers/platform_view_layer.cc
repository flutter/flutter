// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/platform_view_layer.h"

namespace flutter {

PlatformViewLayer::PlatformViewLayer(const SkPoint& offset,
                                     const SkSize& size,
                                     int64_t view_id)
    : offset_(offset), size_(size), view_id_(view_id) {}

void PlatformViewLayer::Preroll(PrerollContext* context,
                                const SkMatrix& matrix) {
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  context->child_scene_layer_exists_below = true;
  CheckForChildLayerBelow(context);
#endif

  set_paint_bounds(SkRect::MakeXYWH(offset_.x(), offset_.y(), size_.width(),
                                    size_.height()));

  if (context->view_embedder == nullptr) {
    FML_LOG(ERROR) << "Trying to embed a platform view but the PrerollContext "
                      "does not support embedding";
    return;
  }
  context->has_platform_view = true;
  std::unique_ptr<EmbeddedViewParams> params =
      std::make_unique<EmbeddedViewParams>(matrix, size_,
                                           context->mutators_stack);
  context->view_embedder->PrerollCompositeEmbeddedView(view_id_,
                                                       std::move(params));
}

void PlatformViewLayer::Paint(PaintContext& context) const {
  if (context.view_embedder == nullptr) {
#if !defined(LEGACY_FUCHSIA_EMBEDDER)
    FML_LOG(ERROR) << "Trying to embed a platform view but the PaintContext "
                      "does not support embedding";
#endif
    return;
  }
  SkCanvas* canvas = context.view_embedder->CompositeEmbeddedView(view_id_);
  context.leaf_nodes_canvas = canvas;
}

#if defined(LEGACY_FUCHSIA_EMBEDDER)
void PlatformViewLayer::UpdateScene(SceneUpdateContext& context) {
  context.UpdateScene(view_id_, offset_, size_);
}
#endif

}  // namespace flutter
