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
  set_paint_bounds(SkRect::MakeXYWH(offset_.x(), offset_.y(), size_.width(),
                                    size_.height()));

  if (context->view_embedder == nullptr) {
    FML_LOG(ERROR) << "Trying to embed a platform view but the PrerollContext "
                      "does not support embedding";
    return;
  }
  context->has_platform_view = true;
  set_subtree_has_platform_view(true);
  std::unique_ptr<EmbeddedViewParams> params =
      std::make_unique<EmbeddedViewParams>(matrix, size_,
                                           context->mutators_stack,
                                           context->display_list_enabled);
  context->view_embedder->PrerollCompositeEmbeddedView(view_id_,
                                                       std::move(params));
  context->view_embedder->PushVisitedPlatformView(view_id_);
}

void PlatformViewLayer::Paint(PaintContext& context) const {
  if (context.view_embedder == nullptr) {
    FML_LOG(ERROR) << "Trying to embed a platform view but the PaintContext "
                      "does not support embedding";
    return;
  }
  EmbedderPaintContext embedder_context =
      context.view_embedder->CompositeEmbeddedView(view_id_);
  context.leaf_nodes_canvas = embedder_context.canvas;
  context.leaf_nodes_builder = embedder_context.builder;
}

}  // namespace flutter
