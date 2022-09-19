// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CLIP_SHAPE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CLIP_SHAPE_LAYER_H_

#include "flutter/flow/layers/cacheable_layer.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/paint_utils.h"

namespace flutter {

template <class T>
class ClipShapeLayer : public CacheableContainerLayer {
 public:
  using ClipShape = T;
  ClipShapeLayer(const ClipShape& clip_shape, Clip clip_behavior)
      : CacheableContainerLayer(),
        clip_shape_(clip_shape),
        clip_behavior_(clip_behavior) {
    FML_DCHECK(clip_behavior != Clip::none);
  }

  void Diff(DiffContext* context, const Layer* old_layer) override {
    DiffContext::AutoSubtreeRestore subtree(context);
    auto* prev = static_cast<const ClipShapeLayer<ClipShape>*>(old_layer);
    if (!context->IsSubtreeDirty()) {
      FML_DCHECK(prev);
      if (clip_behavior_ != prev->clip_behavior_ ||
          clip_shape_ != prev->clip_shape_) {
        context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
      }
    }
    if (UsesSaveLayer() && context->has_raster_cache()) {
      context->SetTransform(
          RasterCacheUtil::GetIntegralTransCTM(context->GetTransform()));
    }
    if (context->PushCullRect(clip_shape_bounds())) {
      DiffChildren(context, prev);
    }
    context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
  }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override {
    SkRect previous_cull_rect = context->cull_rect;
    bool uses_save_layer = UsesSaveLayer();

    if (!context->cull_rect.intersect(clip_shape_bounds())) {
      context->cull_rect.setEmpty();
    }
    SkMatrix child_matrix = matrix;
    // We can use the raster_cache for children only when the use_save_layer is
    // true so if use_save_layer is false we pass the layer_raster_item is
    // nullptr which mean we don't do raster cache logic.
    AutoCache cache =
        AutoCache(uses_save_layer ? layer_raster_cache_item_.get() : nullptr,
                  context, child_matrix);

    Layer::AutoPrerollSaveLayerState save =
        Layer::AutoPrerollSaveLayerState::Create(context, UsesSaveLayer());
    OnMutatorsStackPushClipShape(context->mutators_stack);

    // Collect inheritance information on our children in Preroll so that
    // we can pass it along by default.
    context->subtree_can_inherit_opacity = true;

    SkRect child_paint_bounds = SkRect::MakeEmpty();
    PrerollChildren(context, matrix, &child_paint_bounds);
    if (child_paint_bounds.intersect(clip_shape_bounds())) {
      set_paint_bounds(child_paint_bounds);
    }

    // If we use a SaveLayer then we can accept opacity on behalf
    // of our children and apply it in the saveLayer.
    if (uses_save_layer) {
      context->subtree_can_inherit_opacity = true;
    }

    context->mutators_stack.Pop();
    context->cull_rect = previous_cull_rect;
  }

  void Paint(PaintContext& context) const override {
    FML_DCHECK(needs_painting(context));

    SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
    OnCanvasClipShape(context.internal_nodes_canvas);

    if (!UsesSaveLayer()) {
      PaintChildren(context);
      return;
    }

    AutoCachePaint cache_paint(context);
    if (context.raster_cache) {
      context.internal_nodes_canvas->setMatrix(
          RasterCacheUtil::GetIntegralTransCTM(
              context.leaf_nodes_canvas->getTotalMatrix()));
      if (layer_raster_cache_item_->Draw(context, cache_paint.sk_paint())) {
        return;
      }
    }

    Layer::AutoSaveLayer save_layer = Layer::AutoSaveLayer::Create(
        context, paint_bounds(), cache_paint.sk_paint());
    PaintChildren(context);
  }

  bool UsesSaveLayer() const {
    return clip_behavior_ == Clip::antiAliasWithSaveLayer;
  }

 protected:
  virtual const SkRect& clip_shape_bounds() const = 0;
  virtual void OnMutatorsStackPushClipShape(MutatorsStack& mutators_stack) = 0;
  virtual void OnCanvasClipShape(SkCanvas* canvas) const = 0;
  virtual ~ClipShapeLayer() = default;

  const ClipShape& clip_shape() const { return clip_shape_; }
  Clip clip_behavior() const { return clip_behavior_; }

 private:
  const ClipShape clip_shape_;
  Clip clip_behavior_;

  FML_DISALLOW_COPY_AND_ASSIGN(ClipShapeLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CLIP_SHAPE_LAYER_H_
