// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/color_filter_layer.h"

#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/display_list_paint.h"
#include "flutter/flow/raster_cache_item.h"
#include "flutter/flow/raster_cache_util.h"

namespace flutter {

ColorFilterLayer::ColorFilterLayer(std::shared_ptr<const DlColorFilter> filter)
    : CacheableContainerLayer(
          RasterCacheUtil::kMinimumRendersBeforeCachingFilterLayer,
          true),
      filter_(std::move(filter)) {}

void ColorFilterLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const ColorFilterLayer*>(old_layer);
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

  DiffChildren(context, prev);

  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void ColorFilterLayer::Preroll(PrerollContext* context,
                               const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);
  SkMatrix child_matrix = matrix;
  AutoCache cache =
      AutoCache(layer_raster_cache_item_.get(), context, child_matrix);

  ContainerLayer::Preroll(context, child_matrix);
  // We always use a saveLayer (or a cached rendering), so we
  // can always apply opacity in those cases.
  context->subtree_can_inherit_opacity = true;
}

void ColorFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ColorFilterLayer::Paint");
  FML_DCHECK(needs_painting(context));

  if (context.raster_cache) {
    context.internal_nodes_canvas->setMatrix(
        RasterCacheUtil::GetIntegralTransCTM(
            context.leaf_nodes_canvas->getTotalMatrix()));
    AutoCachePaint cache_paint(context);
    if (layer_raster_cache_item_->IsCacheChildren()) {
      cache_paint.setColorFilter(filter_.get());
    }
    if (layer_raster_cache_item_->Draw(context, cache_paint.sk_paint())) {
      return;
    }
  }

  AutoCachePaint cache_paint(context);
  cache_paint.setColorFilter(filter_.get());
  if (context.leaf_nodes_builder) {
    FML_DCHECK(context.builder_multiplexer);
    context.builder_multiplexer->saveLayer(&paint_bounds(),
                                           cache_paint.dl_paint());
    PaintChildren(context);
    context.builder_multiplexer->restore();
  } else {
    Layer::AutoSaveLayer save = Layer::AutoSaveLayer::Create(
        context, paint_bounds(), cache_paint.sk_paint());
    PaintChildren(context);
  }
}

}  // namespace flutter
