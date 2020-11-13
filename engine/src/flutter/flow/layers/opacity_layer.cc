// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace flutter {

OpacityLayer::OpacityLayer(SkAlpha alpha, const SkPoint& offset)
    : alpha_(alpha), offset_(offset) {}

void OpacityLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "OpacityLayer::Preroll");
  FML_DCHECK(!GetChildContainer()->layers().empty());  // We can't be a leaf.

  SkMatrix child_matrix = matrix;
  child_matrix.preTranslate(offset_.fX, offset_.fY);

  // Similar to what's done in TransformLayer::Preroll, we have to apply the
  // reverse transformation to the cull rect to properly cull child layers.
  context->cull_rect = context->cull_rect.makeOffset(-offset_.fX, -offset_.fY);

  context->mutators_stack.PushTransform(
      SkMatrix::Translate(offset_.fX, offset_.fY));
  context->mutators_stack.PushOpacity(alpha_);
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);
  ContainerLayer::Preroll(context, child_matrix);
  context->mutators_stack.Pop();
  context->mutators_stack.Pop();

  {
    set_paint_bounds(paint_bounds().makeOffset(offset_.fX, offset_.fY));
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    child_matrix = RasterCache::GetIntegralTransCTM(child_matrix);
#endif
    TryToPrepareRasterCache(context, GetCacheableChild(), child_matrix);
  }

  // Restore cull_rect
  context->cull_rect = context->cull_rect.makeOffset(offset_.fX, offset_.fY);
}

void OpacityLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  FML_DCHECK(needs_painting(context));

  SkPaint paint;
  paint.setAlpha(alpha_);

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->translate(offset_.fX, offset_.fY);

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.internal_nodes_canvas->setMatrix(RasterCache::GetIntegralTransCTM(
      context.leaf_nodes_canvas->getTotalMatrix()));
#endif

  if (context.raster_cache &&
      context.raster_cache->Draw(GetCacheableChild(),
                                 *context.leaf_nodes_canvas, &paint)) {
    return;
  }

  // Skia may clip the content with saveLayerBounds (although it's not a
  // guaranteed clip). So we have to provide a big enough saveLayerBounds. To do
  // so, we first remove the offset from paint bounds since it's already in the
  // matrix. Then we round out the bounds.
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

#if defined(LEGACY_FUCHSIA_EMBEDDER)

void OpacityLayer::UpdateScene(std::shared_ptr<SceneUpdateContext> context) {
  float saved_alpha = context->alphaf();
  context->set_alphaf(context->alphaf() * (alpha_ / 255.f));
  ContainerLayer::UpdateScene(context);
  context->set_alphaf(saved_alpha);
}

#endif

}  // namespace flutter
