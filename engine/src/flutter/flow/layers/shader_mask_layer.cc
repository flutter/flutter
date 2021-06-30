// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/shader_mask_layer.h"

namespace flutter {

ShaderMaskLayer::ShaderMaskLayer(sk_sp<SkShader> shader,
                                 const SkRect& mask_rect,
                                 SkBlendMode blend_mode)
    : shader_(shader), mask_rect_(mask_rect), blend_mode_(blend_mode) {}

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

void ShaderMaskLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const ShaderMaskLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (shader_ != prev->shader_ || mask_rect_ != prev->mask_rect_ ||
        blend_mode_ != prev->blend_mode_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }

  DiffChildren(context, prev);

  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

void ShaderMaskLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);
  ContainerLayer::Preroll(context, matrix);
}

void ShaderMaskLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ShaderMaskLayer::Paint");
  FML_DCHECK(needs_painting(context));

  Layer::AutoSaveLayer save =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), nullptr);
  PaintChildren(context);

  SkPaint paint;
  paint.setBlendMode(blend_mode_);
  paint.setShader(shader_);
  context.leaf_nodes_canvas->translate(mask_rect_.left(), mask_rect_.top());
  context.leaf_nodes_canvas->drawRect(
      SkRect::MakeWH(mask_rect_.width(), mask_rect_.height()), paint);
}

}  // namespace flutter
