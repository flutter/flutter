// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/overscroll_stretch_layer.h"

#include "flutter/display_list/utils/dl_comparable.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache_util.h"

namespace flutter {

OverscrollStretchLayer::OverscrollStretchLayer(
    const std::shared_ptr<DlImageFilter>& filter,
    DlScalar overscroll_x,
    DlScalar overscroll_y,
    DlScalar max_stretch_intensity,
    DlScalar interpolation_strength,
    const DlPoint& offset)
    : CacheableContainerLayer(
          RasterCacheUtil::kMinimumRendersBeforeCachingFilterLayer),
      offset_(offset),
      filter_(filter),
      transformed_filter_(nullptr),
      overscroll_x_(overscroll_x),
      overscroll_y_(overscroll_y),
      max_stretch_intensity_(max_stretch_intensity),
      interpolation_strength_(interpolation_strength) {}

void OverscrollStretchLayer::Diff(DiffContext* context,
                                  const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const OverscrollStretchLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (NotEquals(filter_, prev->filter_) || offset_ != prev->offset_ ||
        overscroll_x_ != prev->overscroll_x_ ||
        overscroll_y_ != prev->overscroll_y_ ||
        max_stretch_intensity_ != prev->max_stretch_intensity_ ||
        interpolation_strength_ != prev->interpolation_strength_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }

  context->PushTransform(DlMatrix::MakeTranslation(offset_));
  if (context->has_raster_cache()) {
    context->WillPaintWithIntegralTransform();
  }

  if (filter_) {
    auto filter = filter_->makeWithLocalMatrix(context->GetMatrix());
    if (filter) {
      context->PushFilterBoundsAdjustment([filter](DlRect rect) {
        DlIRect filter_out_bounds;
        filter->map_device_bounds(DlIRect::RoundOut(rect), DlMatrix(),
                                  filter_out_bounds);
        return DlRect::Make(filter_out_bounds);
      });
    }
  }
  DiffChildren(context, prev);
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void OverscrollStretchLayer::Preroll(PrerollContext* context) {
  auto mutator = context->state_stack.save();
  mutator.translate(offset_);

  if (filter_) {
    mutator.applyOverscrollStretch(DlRect(), filter_, overscroll_x_,
                                   overscroll_y_, max_stretch_intensity_,
                                   interpolation_strength_);
  }

  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);

#if !SLIMPELLER
  AutoCache cache = AutoCache(layer_raster_cache_item_.get(), context,
                              context->state_stack.matrix());
#endif  //  !SLIMPELLER

  DlRect child_bounds;

  PrerollChildren(context, &child_bounds);

  if (!filter_) {
    child_bounds = child_bounds.Shift(offset_);
    set_paint_bounds(child_bounds);
    return;
  }

  context->renderable_state_flags =
      (LayerStateStack::kCallerCanApplyOpacity |
       LayerStateStack::kCallerCanApplyColorFilter);

  const DlIRect filter_in_bounds = DlIRect::RoundOut(child_bounds);
  DlIRect filter_out_bounds;
  filter_->map_device_bounds(filter_in_bounds, DlMatrix(), filter_out_bounds);
  child_bounds = DlRect::Make(filter_out_bounds).Shift(offset_);

  set_paint_bounds(child_bounds);

#if !SLIMPELLER
  layer_raster_cache_item_->MarkNotCacheChildren();
#endif  //  !SLIMPELLER

  transformed_filter_ =
      filter_->makeWithLocalMatrix(context->state_stack.matrix());

#if !SLIMPELLER
  if (transformed_filter_) {
    layer_raster_cache_item_->MarkCacheChildren();
  }
#endif  //  !SLIMPELLER
}

void OverscrollStretchLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting(context));

  auto mutator = context.state_stack.save();

#if !SLIMPELLER
  if (context.raster_cache) {
    if (!layer_raster_cache_item_->IsCacheChildren()) {
      DlPaint paint;
      if (layer_raster_cache_item_->Draw(context,
                                         context.state_stack.fill(paint))) {
        return;
      }
    }
  }
#endif  //  !SLIMPELLER

  mutator.translate(offset_);

#if !SLIMPELLER
  if (context.raster_cache) {
    mutator.integralTransform();
  }

  if (context.raster_cache && layer_raster_cache_item_->IsCacheChildren()) {
    FML_DCHECK(transformed_filter_ != nullptr);
    DlPaint paint;
    context.state_stack.fill(paint);
    paint.setImageFilter(transformed_filter_);
    if (layer_raster_cache_item_->Draw(context, &paint)) {
      return;
    }
  }
#endif  //  !SLIMPELLER

  mutator.applyOverscrollStretch(child_paint_bounds(), filter_, overscroll_x_,
                                 overscroll_y_, max_stretch_intensity_,
                                 interpolation_strength_);

  PaintChildren(context);
}

}  // namespace flutter
