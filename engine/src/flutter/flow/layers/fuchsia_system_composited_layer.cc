// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/fuchsia_system_composited_layer.h"

namespace flutter {

FuchsiaSystemCompositedLayer::FuchsiaSystemCompositedLayer(SkColor color,
                                                           SkAlpha opacity,
                                                           float elevation)
    : ElevatedContainerLayer(elevation), color_(color), opacity_(opacity) {}

void FuchsiaSystemCompositedLayer::Preroll(PrerollContext* context,
                                           const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "FuchsiaSystemCompositedLayer::Preroll");

  const float parent_is_opaque = context->is_opaque;
  context->mutators_stack.PushOpacity(opacity_);
  context->is_opaque = parent_is_opaque && (opacity_ == SK_AlphaOPAQUE);
  ElevatedContainerLayer::Preroll(context, matrix);
  context->is_opaque = parent_is_opaque;
  context->mutators_stack.Pop();
}

void FuchsiaSystemCompositedLayer::UpdateScene(SceneUpdateContext& context) {
  FML_DCHECK(needs_system_composite());

  // Retained rendering: speedup by reusing a retained entity node if
  // possible. When an entity node is reused, no paint layer is added to the
  // frame so we won't call Paint.
  LayerRasterCacheKey key(unique_id(), context.Matrix());
  if (context.HasRetainedNode(key)) {
    TRACE_EVENT_INSTANT0("flutter", "retained layer cache hit");
    const scenic::EntityNode& retained_node = context.GetRetainedNode(key);
    FML_DCHECK(context.top_entity());
    FML_DCHECK(retained_node.session() == context.session());
    context.top_entity()->embedder_node().AddChild(retained_node);
    return;
  }

  TRACE_EVENT_INSTANT0("flutter", "retained cache miss, creating");
  // If we can't find an existing retained surface, create one.
  SceneUpdateContext::Frame frame(context, rrect_, color_, opacity_ / 255.0f,
                                  elevation(), this);
  for (auto& layer : layers()) {
    if (layer->needs_painting()) {
      frame.AddPaintLayer(layer.get());
    }
  }

  ElevatedContainerLayer::UpdateScene(context);
}

}  // namespace flutter
