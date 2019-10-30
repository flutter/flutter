// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

#include "flutter/flow/layers/transform_layer.h"

namespace flutter {

OpacityLayer::OpacityLayer(int alpha, const SkPoint& offset)
    : alpha_(alpha), offset_(offset) {}

OpacityLayer::~OpacityLayer() = default;

void OpacityLayer::EnsureSingleChild() {
  FML_DCHECK(layers().size() > 0);  // OpacityLayer should never be a leaf

  if (layers().size() == 1) {
    return;
  }

  // Be careful: SkMatrix's default constructor doesn't initialize the matrix to
  // identity. Hence we have to explicitly call SkMatrix::setIdentity.
  SkMatrix identity;
  identity.setIdentity();
  auto new_child = std::make_shared<flutter::TransformLayer>(identity);

  for (auto& child : layers()) {
    new_child->Add(child);
  }
  ClearChildren();
  Add(new_child);
}

void OpacityLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  EnsureSingleChild();
  SkMatrix child_matrix = matrix;
  child_matrix.postTranslate(offset_.fX, offset_.fY);
  context->mutators_stack.PushTransform(
      SkMatrix::MakeTrans(offset_.fX, offset_.fY));
  context->mutators_stack.PushOpacity(alpha_);
  ContainerLayer::Preroll(context, child_matrix);
  context->mutators_stack.Pop();
  context->mutators_stack.Pop();
  set_paint_bounds(paint_bounds().makeOffset(offset_.fX, offset_.fY));
  // See |EnsureSingleChild|.
  FML_DCHECK(layers().size() == 1);
  if (context->view_embedder == nullptr && context->raster_cache &&
      SkRect::Intersects(context->cull_rect, paint_bounds())) {
    Layer* child = layers()[0].get();
    SkMatrix ctm = child_matrix;
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    ctm = RasterCache::GetIntegralTransCTM(ctm);
#endif
    context->raster_cache->Prepare(context, child, ctm);
  }
}

void OpacityLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  FML_DCHECK(needs_painting());

  SkPaint paint;
  paint.setAlpha(alpha_);

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->translate(offset_.fX, offset_.fY);

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.internal_nodes_canvas->setMatrix(RasterCache::GetIntegralTransCTM(
      context.leaf_nodes_canvas->getTotalMatrix()));
#endif

  // See |EnsureSingleChild|.
  FML_DCHECK(layers().size() == 1);

  // Embedded platform views are changing the canvas in the middle of the paint
  // traversal. To make sure we paint on the right canvas, when the embedded
  // platform views preview is enabled (context.view_embedded is not null) we
  // don't use the cache.
  if (context.view_embedder == nullptr && context.raster_cache) {
    const SkMatrix& ctm = context.leaf_nodes_canvas->getTotalMatrix();
    RasterCacheResult child_cache =
        context.raster_cache->Get(layers()[0].get(), ctm);
    if (child_cache.is_valid()) {
      child_cache.draw(*context.leaf_nodes_canvas, &paint);
      return;
    }
  }

  // Skia may clip the content with saveLayerBounds (although it's not a
  // guaranteed clip). So we have to provide a big enough saveLayerBounds. To do
  // so, we first remove the offset from paint bounds since it's already in the
  // matrix. Then we round out the bounds because of our
  // RasterCache::GetIntegralTransCTM optimization.
  //
  // Note that the following lines are only accessible when the raster cache is
  // not available (e.g., when we're using the software backend in golden
  // tests).
  SkRect saveLayerBounds;
  paint_bounds()
      .makeOffset(-offset_.fX, -offset_.fY)
      .roundOut(&saveLayerBounds);

  Layer::AutoSaveLayer save_layer =
      Layer::AutoSaveLayer::Create(context, saveLayerBounds, &paint);
  PaintChildren(context);
}

}  // namespace flutter
