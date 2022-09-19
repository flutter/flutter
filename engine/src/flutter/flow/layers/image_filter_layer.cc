// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/image_filter_layer.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache_util.h"

namespace flutter {

ImageFilterLayer::ImageFilterLayer(std::shared_ptr<const DlImageFilter> filter)
    : CacheableContainerLayer(
          RasterCacheUtil::kMinimumRendersBeforeCachingFilterLayer),
      filter_(std::move(filter)),
      transformed_filter_(nullptr) {}

void ImageFilterLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const ImageFilterLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (NotEquals(filter_, prev->filter_)) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }

  if (context->has_raster_cache()) {
    context->SetTransform(
        RasterCacheUtil::GetIntegralTransCTM(context->GetTransform()));
  }

  if (filter_) {
    auto filter = filter_->makeWithLocalMatrix(context->GetTransform());
    if (filter) {
      // This transform will be applied to every child rect in the subtree
      context->PushFilterBoundsAdjustment([filter](SkRect rect) {
        SkIRect filter_out_bounds;
        filter->map_device_bounds(rect.roundOut(), SkMatrix::I(),
                                  filter_out_bounds);
        return SkRect::Make(filter_out_bounds);
      });
    }
  }
  DiffChildren(context, prev);
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void ImageFilterLayer::Preroll(PrerollContext* context,
                               const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ImageFilterLayer::Preroll");

  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);
  SkMatrix child_matrix = matrix;

  AutoCache cache =
      AutoCache(layer_raster_cache_item_.get(), context, child_matrix);

  SkRect child_bounds = SkRect::MakeEmpty();

  PrerollChildren(context, child_matrix, &child_bounds);

  // We always paint with a saveLayer (or a cached rendering),
  // so we can always apply opacity in any of those cases.
  context->subtree_can_inherit_opacity = true;

  if (!filter_) {
    set_paint_bounds(child_bounds);
    return;
  }

  const SkIRect filter_in_bounds = child_bounds.roundOut();
  SkIRect filter_out_bounds;
  filter_->map_device_bounds(filter_in_bounds, SkMatrix::I(),
                             filter_out_bounds);
  child_bounds = SkRect::Make(filter_out_bounds);

  set_paint_bounds(child_bounds);

  // CacheChildren only when the transformed_filter_ doesn't equal null.
  // So in here we reset the LayerRasterCacheItem cache state.
  layer_raster_cache_item_->MarkNotCacheChildren();

  transformed_filter_ = filter_->makeWithLocalMatrix(child_matrix);
  if (transformed_filter_) {
    layer_raster_cache_item_->MarkCacheChildren();
  }
}

void ImageFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ImageFilterLayer::Paint");
  FML_DCHECK(needs_painting(context));

  AutoCachePaint cache_paint(context);
  if (context.raster_cache) {
    context.internal_nodes_canvas->setMatrix(
        RasterCacheUtil::GetIntegralTransCTM(
            context.leaf_nodes_canvas->getTotalMatrix()));
    if (layer_raster_cache_item_->IsCacheChildren()) {
      cache_paint.setImageFilter(transformed_filter_.get());
    }
    if (layer_raster_cache_item_->Draw(context, cache_paint.sk_paint())) {
      return;
    }
  }

  cache_paint.setImageFilter(filter_.get());
  if (context.leaf_nodes_builder) {
    FML_DCHECK(context.builder_multiplexer);
    context.builder_multiplexer->saveLayer(&child_paint_bounds(),
                                           cache_paint.dl_paint());
    PaintChildren(context);
    context.builder_multiplexer->restore();
  } else {
    // Normally a save_layer is sized to the current layer bounds, but in this
    // case the bounds of the child may not be the same as the filtered version
    // so we use the bounds of the child container which do not include any
    // modifications that the filter might apply.
    Layer::AutoSaveLayer save_layer = Layer::AutoSaveLayer::Create(
        context, child_paint_bounds(), cache_paint.sk_paint());
    PaintChildren(context);
  }
}

}  // namespace flutter
