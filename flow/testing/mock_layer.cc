// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_layer.h"

#include <utility>

#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/testing/mock_raster_cache.h"
namespace flutter {
namespace testing {

MockLayer::MockLayer(const SkPath& path, SkPaint paint)
    : fake_paint_path_(path), fake_paint_(std::move(paint)) {}

bool MockLayer::IsReplacing(DiffContext* context, const Layer* layer) const {
  // Similar to PictureLayer, only return true for identical mock layers;
  // That way ContainerLayer::DiffChildren can properly detect mock layer
  // insertion
  auto mock_layer = layer->as_mock_layer();
  return mock_layer && mock_layer->fake_paint_ == fake_paint_ &&
         mock_layer->fake_paint_path_ == fake_paint_path_;
}

void MockLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  context->AddLayerBounds(fake_paint_path_.getBounds());
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void MockLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  parent_mutators_ = context->mutators_stack;
  parent_matrix_ = matrix;
  parent_cull_rect_ = context->cull_rect;

  set_parent_has_platform_view(context->has_platform_view);
  set_parent_has_texture_layer(context->has_texture_layer);

  context->has_platform_view = fake_has_platform_view();
  context->has_texture_layer = fake_has_texture_layer();
  set_paint_bounds(fake_paint_path_.getBounds());
  if (fake_reads_surface()) {
    context->surface_needs_readback = true;
  }
  if (fake_opacity_compatible()) {
    context->subtree_can_inherit_opacity = true;
  }
}

void MockLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting(context));

  if (context.inherited_opacity < SK_Scalar1) {
    SkPaint p;
    p.setAlphaf(context.inherited_opacity);
    context.leaf_nodes_canvas->saveLayer(fake_paint_path_.getBounds(), &p);
  }
  context.leaf_nodes_canvas->drawPath(fake_paint_path_, fake_paint_);
  if (context.inherited_opacity < SK_Scalar1) {
    context.leaf_nodes_canvas->restore();
  }
}

void MockCacheableContainerLayer::Preroll(PrerollContext* context,
                                          const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);
  SkMatrix child_matrix = matrix;
  auto cache = AutoCache(layer_raster_cache_item_.get(), context, child_matrix);

  ContainerLayer::Preroll(context, child_matrix);
}

void MockCacheableLayer::Preroll(PrerollContext* context,
                                 const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);
  SkMatrix child_matrix = matrix;
  auto cache = AutoCache(raster_cache_item_.get(), context, child_matrix);

  MockLayer::Preroll(context, child_matrix);
}

}  // namespace testing
}  // namespace flutter
