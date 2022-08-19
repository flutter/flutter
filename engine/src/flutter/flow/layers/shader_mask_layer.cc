// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/shader_mask_layer.h"
#include "flutter/flow/raster_cache_util.h"

namespace flutter {

ShaderMaskLayer::ShaderMaskLayer(std::shared_ptr<DlColorSource> shader,
                                 const SkRect& mask_rect,
                                 DlBlendMode blend_mode)
    : CacheableContainerLayer(
          RasterCacheUtil::kMinimumRendersBeforeCachingFilterLayer),
      shader_(std::move(shader)),
      mask_rect_(mask_rect),
      blend_mode_(blend_mode) {}

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

void ShaderMaskLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);

  AutoCache cache = AutoCache(layer_raster_cache_item_.get(), context, matrix);

  ContainerLayer::Preroll(context, matrix);
  // We always paint with a saveLayer (or a cached rendering),
  // so we can always apply opacity in any of those cases.
  context->subtree_can_inherit_opacity = true;
}

void ShaderMaskLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ShaderMaskLayer::Paint");
  FML_DCHECK(needs_painting(context));

  AutoCachePaint cache_paint(context);

  if (context.raster_cache) {
    if (layer_raster_cache_item_->Draw(context, cache_paint.sk_paint())) {
      return;
    }
  }
  auto shader_rect = SkRect::MakeWH(mask_rect_.width(), mask_rect_.height());

  if (context.leaf_nodes_builder) {
    context.builder_multiplexer->saveLayer(&paint_bounds(),
                                           cache_paint.dl_paint());
    PaintChildren(context);

    DlPaint dl_paint;
    dl_paint.setBlendMode(blend_mode_);
    if (shader_) {
      dl_paint.setColorSource(shader_.get());
    }
    context.leaf_nodes_builder->translate(mask_rect_.left(), mask_rect_.top());
    context.leaf_nodes_builder->drawRect(shader_rect, dl_paint);
  } else {
    Layer::AutoSaveLayer save = Layer::AutoSaveLayer::Create(
        context, paint_bounds(), cache_paint.sk_paint());
    PaintChildren(context);
    SkPaint paint;
    paint.setBlendMode(ToSk(blend_mode_));
    if (shader_) {
      paint.setShader(shader_->skia_object());
    }
    context.leaf_nodes_canvas->translate(mask_rect_.left(), mask_rect_.top());
    context.leaf_nodes_canvas->drawRect(shader_rect, paint);
  }
}

}  // namespace flutter
