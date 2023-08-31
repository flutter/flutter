// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/aiks_layer.h"

#include <utility>

namespace flutter {

AiksLayer::AiksLayer(const SkPoint& offset,
                     const std::shared_ptr<const impeller::Picture>& picture)
    : offset_(offset), picture_(picture) {
#if IMPELLER_SUPPORTS_RENDERING
  if (picture_) {
    FML_DCHECK(picture_->rtree);
    bounds_ = picture_->rtree->bounds();
  }
#endif
}

bool AiksLayer::IsReplacing(DiffContext* context, const Layer* layer) const {
  auto old_layer = layer->as_aiks_layer();
  return old_layer != nullptr && offset_ == old_layer->offset_ &&
         old_layer->picture_ == picture_;
}

void AiksLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  context->PushTransform(SkMatrix::Translate(offset_.x(), offset_.y()));
  context->AddLayerBounds(bounds_);
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void AiksLayer::Preroll(PrerollContext* frame) {
  // There is no opacity peepholing to do here because Impeller handles that
  // in the Entities, and this layer will never participate in raster caching.
  FML_DCHECK(!frame->raster_cache);
  set_paint_bounds(bounds_);
}

void AiksLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting(context));

  auto mutator = context.state_stack.save();
  mutator.translate(offset_.x(), offset_.y());

  FML_DCHECK(!context.raster_cache);

  SkScalar opacity = context.state_stack.outstanding_opacity();

  if (context.enable_leaf_layer_tracing) {
    // TODO(dnfield): Decide if we need to capture this for Impeller.
    // We can't do this the same way as on the Skia backend, because Impeller
    // does not expose primitives for flushing things down to the GPU without
    // also allocating a texture.
    // https://github.com/flutter/flutter/issues/131941
    FML_LOG(ERROR) << "Leaf layer tracing unsupported for Impeller.";
  }

  context.canvas->DrawImpellerPicture(picture_, opacity);
}

}  // namespace flutter
