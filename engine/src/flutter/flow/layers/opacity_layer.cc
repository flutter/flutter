// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

namespace flutter {

#if defined(OS_FUCHSIA)
constexpr bool kRenderOpacityUsingSystemCompositor = true;
#else
constexpr bool kRenderOpacityUsingSystemCompositor = false;
#endif
constexpr float kOpacityElevationWhenUsingSystemCompositor = 0.01f;

OpacityLayer::OpacityLayer(int alpha, const SkPoint& offset)
    : ContainerLayer(true), alpha_(alpha), offset_(offset) {
#if !defined(OS_FUCHSIA)
  static_assert(!kRenderOpacityUsingSystemCompositor,
                "Delegation of OpacityLayer to the system compositor is only "
                "allowed on Fuchsia");
#endif

  if (kRenderOpacityUsingSystemCompositor) {
    set_elevation(kOpacityElevationWhenUsingSystemCompositor);
  }
}

void OpacityLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkMatrix child_matrix = matrix;
  float parent_is_opaque = context->is_opaque;
  child_matrix.postTranslate(offset_.fX, offset_.fY);
  context->mutators_stack.PushTransform(
      SkMatrix::MakeTrans(offset_.fX, offset_.fY));
  context->mutators_stack.PushOpacity(alpha_);
  context->is_opaque = parent_is_opaque && (alpha_ == 255);
  ContainerLayer::Preroll(context, child_matrix);
  context->is_opaque = parent_is_opaque;
  context->mutators_stack.Pop();
  context->mutators_stack.Pop();

  // When using the system compositor, do not include the offset or use the
  // raster cache, since we are rendering as a separate piece of geometry.
  if (kRenderOpacityUsingSystemCompositor) {
    set_needs_system_composite(true);
    set_frame_properties(SkRRect::MakeRect(paint_bounds()), SK_ColorTRANSPARENT,
                         alpha_ / 255.0f);

    // If the frame behind us is opaque, don't punch a hole in it for group
    // opacity.
    if (context->is_opaque) {
      set_paint_bounds(SkRect());
    }
  } else {
    set_paint_bounds(paint_bounds().makeOffset(offset_.fX, offset_.fY));
    if (context->raster_cache &&
        SkRect::Intersects(context->cull_rect, paint_bounds())) {
      Layer* child = layers()[0].get();
      SkMatrix ctm = child_matrix;
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
      ctm = RasterCache::GetIntegralTransCTM(ctm);
#endif
      context->raster_cache->Prepare(context, child, ctm);
    }
  }
}

void OpacityLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  FML_DCHECK(needs_painting());

  // The compositor will paint this layer (which is |Sk_ColorWHITE| scaled by
  // opacity) via the model color on |SceneUpdateContext::Frame|.
  //
  // The child layers will be painted into the texture used by the Frame, so
  // painting them here would actually cause them to be painted on the display
  // twice -- once into the current canvas (which may be inside of another
  // Frame) and once into the Frame's texture (which is then drawn on top of the
  // current canvas).
  if (kRenderOpacityUsingSystemCompositor) {
#if defined(OS_FUCHSIA)
    // On Fuchsia, If we are being rendered into our own frame using the system
    // compositor, then it is neccesary to "punch a hole" in the canvas/frame
    // behind us so that single-pass group opacity looks correct.
    SkPaint paint;
    paint.setColor(SK_ColorTRANSPARENT);
    paint.setBlendMode(SkBlendMode::kSrc);
    context.leaf_nodes_canvas->drawRect(paint_bounds(), paint);
#endif
    return;
  }

  SkPaint paint;
  paint.setAlpha(alpha_);

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->translate(offset_.fX, offset_.fY);

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.internal_nodes_canvas->setMatrix(RasterCache::GetIntegralTransCTM(
      context.leaf_nodes_canvas->getTotalMatrix()));
#endif

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
  ContainerLayer::Paint(context);
}

void OpacityLayer::UpdateScene(SceneUpdateContext& context) {
#if defined(OS_FUCHSIA)
  SceneUpdateContext::Transform transform(
      context, SkMatrix::MakeTrans(offset_.fX, offset_.fY));

  ContainerLayer::UpdateScene(context);
#endif
}

}  // namespace flutter
