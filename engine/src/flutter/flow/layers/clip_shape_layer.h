// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CLIP_SHAPE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CLIP_SHAPE_LAYER_H_

#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/paint_utils.h"

namespace flutter {

template <class T>
class ClipShapeLayer : public ContainerLayer {
 public:
  using ClipShape = T;
  ClipShapeLayer(const ClipShape& clip_shape, Clip clip_behavior)
      : clip_shape_(clip_shape),
        clip_behavior_(clip_behavior),
        render_count_(1) {
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
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    if (UsesSaveLayer()) {
      context->SetTransform(
          RasterCache::GetIntegralTransCTM(context->GetTransform()));
    }
#endif
    if (context->PushCullRect(clip_shape_bounds())) {
      DiffChildren(context, prev);
    }
    context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
  }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override {
    SkRect previous_cull_rect = context->cull_rect;
    if (!context->cull_rect.intersect(clip_shape_bounds())) {
      context->cull_rect.setEmpty();
    }
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
    if (UsesSaveLayer()) {
      context->subtree_can_inherit_opacity = true;
      if (render_count_ >= kMinimumRendersBeforeCachingLayer) {
        SkMatrix child_matrix(matrix);
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
        child_matrix = RasterCache::GetIntegralTransCTM(child_matrix);
#endif
        TryToPrepareRasterCache(context, this, child_matrix,
                                RasterCacheLayerStrategy::kLayer);
      } else {
        render_count_++;
      }
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

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    context.internal_nodes_canvas->setMatrix(RasterCache::GetIntegralTransCTM(
        context.leaf_nodes_canvas->getTotalMatrix()));
#endif

    AutoCachePaint cache_paint(context);
    if (context.raster_cache &&
        context.raster_cache->Draw(this, *context.leaf_nodes_canvas,
                                   RasterCacheLayerStrategy::kLayer,
                                   cache_paint.paint())) {
      return;
    }

    Layer::AutoSaveLayer save_layer = Layer::AutoSaveLayer::Create(
        context, paint_bounds(), cache_paint.paint());
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

  static constexpr int kMinimumRendersBeforeCachingLayer = 3;
  int render_count_;

  FML_DISALLOW_COPY_AND_ASSIGN(ClipShapeLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CLIP_SHAPE_LAYER_H_
