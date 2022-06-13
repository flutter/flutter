// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/image_filter_layer.h"

namespace flutter {

ImageFilterLayer::ImageFilterLayer(sk_sp<SkImageFilter> filter)
    : filter_(std::move(filter)),
      transformed_filter_(nullptr),
      render_count_(1) {}

void ImageFilterLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const ImageFilterLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (filter_ != prev->filter_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context->SetTransform(
      RasterCache::GetIntegralTransCTM(context->GetTransform()));
#endif

  if (filter_) {
    auto filter = filter_->makeWithLocalMatrix(context->GetTransform());
    if (filter) {
      // This transform will be applied to every child rect in the subtree
      context->PushFilterBoundsAdjustment([filter](SkRect rect) {
        return SkRect::Make(
            filter->filterBounds(rect.roundOut(), SkMatrix::I(),
                                 SkImageFilter::kForward_MapDirection));
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

  SkRect child_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_bounds);
  context->subtree_can_inherit_opacity = true;

  // We always paint with a saveLayer (or a cached rendering),
  // so we can always apply opacity in any of those cases.
  context->subtree_can_inherit_opacity = true;

  if (!filter_) {
    set_paint_bounds(child_bounds);
    return;
  }

  const SkIRect filter_input_bounds = child_bounds.roundOut();
  SkIRect filter_output_bounds = filter_->filterBounds(
      filter_input_bounds, SkMatrix::I(), SkImageFilter::kForward_MapDirection);
  child_bounds = SkRect::Make(filter_output_bounds);

  set_paint_bounds(child_bounds);

  SkMatrix child_matrix(matrix);
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  child_matrix = RasterCache::GetIntegralTransCTM(child_matrix);
#endif

  transformed_filter_ = nullptr;
  if (render_count_ >= kMinimumRendersBeforeCachingFilterLayer) {
    // We have rendered this same ImageFilterLayer object enough
    // times to consider its properties and children to be stable
    // from frame to frame so we try to cache the layer itself
    // for maximum performance.
    TryToPrepareRasterCache(context, this, child_matrix,
                            RasterCacheLayerStrategy::kLayer);
  } else {
    // This ImageFilterLayer is not yet considered stable so we
    // increment the count to measure how many times it has been
    // seen from frame to frame.
    render_count_++;

    // Now we will try to pre-render the children into the cache.
    // To apply the filter to pre-rendered children, we must first
    // modify the filter to be aware of the transform under which
    // the cached bitmap was produced. Some SkImageFilter
    // instances can do this operation on some transforms and some
    // (filters or transforms) cannot. We can only cache the children
    // and apply the filter on the fly if this operation succeeds.
    transformed_filter_ = filter_->makeWithLocalMatrix(child_matrix);
    if (transformed_filter_) {
      // With a modified SkImageFilter we can now try to cache the
      // children to avoid their rendering costs if they remain
      // stable between frames and also avoiding a rendering surface
      // switch during the Paint phase even if they are not stable.
      // This benefit is seen most during animations.
      TryToPrepareRasterCache(context, this, matrix,
                              RasterCacheLayerStrategy::kLayerChildren);
    }
  }
}

void ImageFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ImageFilterLayer::Paint");
  FML_DCHECK(needs_painting(context));

  AutoCachePaint cache_paint(context);

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.internal_nodes_canvas->setMatrix(RasterCache::GetIntegralTransCTM(
      context.leaf_nodes_canvas->getTotalMatrix()));
#endif

  if (context.raster_cache) {
    if (context.raster_cache->Draw(this, *context.leaf_nodes_canvas,
                                   RasterCacheLayerStrategy::kLayer,
                                   cache_paint.paint())) {
      return;
    }
    if (transformed_filter_) {
      cache_paint.setImageFilter(transformed_filter_);
      if (context.raster_cache->Draw(this, *context.leaf_nodes_canvas,
                                     RasterCacheLayerStrategy::kLayerChildren,
                                     cache_paint.paint())) {
        return;
      }
    }
  }

  cache_paint.setImageFilter(filter_);

  // Normally a save_layer is sized to the current layer bounds, but in this
  // case the bounds of the child may not be the same as the filtered version
  // so we use the bounds of the child container which do not include any
  // modifications that the filter might apply.
  Layer::AutoSaveLayer save_layer = Layer::AutoSaveLayer::Create(
      context, child_paint_bounds(), cache_paint.paint());
  PaintChildren(context);
}

}  // namespace flutter
