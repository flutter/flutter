// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace flutter {

// The OpacityLayer has no real "elevation", but we want to avoid Z-fighting
// when using the system compositor.  Choose a small but non-zero value for
// this.
constexpr float kOpacityElevationWhenUsingSystemCompositor = 0.01f;

#if !defined(OS_FUCHSIA)
void OpacityLayerBase::Preroll(PrerollContext* context,
                               const SkMatrix& matrix) {
  const float parent_is_opaque = context->is_opaque;

  context->mutators_stack.PushOpacity(opacity_);
  context->is_opaque = parent_is_opaque && (opacity_ == SK_AlphaOPAQUE);
  ContainerLayer::Preroll(context, matrix);
  context->is_opaque = parent_is_opaque;
  context->mutators_stack.Pop();
}
#endif

OpacityLayer::OpacityLayer(SkAlpha opacity, const SkPoint& offset)
    : OpacityLayerBase(SK_ColorTRANSPARENT,
                       opacity,
                       kOpacityElevationWhenUsingSystemCompositor),
      offset_(offset) {
  // Ensure OpacityLayer has only one direct child.
  //
  // This is needed to ensure that retained rendering can always be applied to
  // save the costly saveLayer.
  //
  // Any children will be actually added as children of this empty
  // ContainerLayer.
  ContainerLayer::Add(std::make_shared<ContainerLayer>());
}

void OpacityLayer::Add(std::shared_ptr<Layer> layer) {
  GetChildContainer()->Add(std::move(layer));
}

void OpacityLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "OpacityLayer::Preroll");

  ContainerLayer* container = GetChildContainer();
  FML_DCHECK(!container->layers().empty());  // OpacityLayer can't be a leaf.

  // Factor in the offset during Preroll.  |OpacityLayerBase| will handle the
  // opacity.
  SkMatrix child_matrix = matrix;
  child_matrix.postTranslate(offset_.fX, offset_.fY);
  context->mutators_stack.PushTransform(
      SkMatrix::MakeTrans(offset_.fX, offset_.fY));
  OpacityLayerBase::Preroll(context, child_matrix);
  context->mutators_stack.Pop();

  // When using the system compositor, do not include the offset since we are
  // rendering as a separate piece of geometry and the offset will be baked into
  // that geometry's transform.
  if (OpacityLayerBase::can_system_composite()) {
    set_dimensions(SkRRect::MakeRect(paint_bounds()));
    set_needs_system_composite(true);
  } else {
    set_paint_bounds(paint_bounds().makeOffset(offset_.fX, offset_.fY));

    if (!context->has_platform_view && context->raster_cache &&
        SkRect::Intersects(context->cull_rect, paint_bounds())) {
      SkMatrix ctm = child_matrix;
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
      ctm = RasterCache::GetIntegralTransCTM(ctm);
#endif
      context->raster_cache->Prepare(context, container, ctm);
    }
  }
}

#if defined(OS_FUCHSIA)

void OpacityLayer::UpdateScene(SceneUpdateContext& context) {
  SceneUpdateContext::Transform transform(
      context, SkMatrix::MakeTrans(offset_.fX, offset_.fY));

  // OpacityLayerBase will handle applying the opacity itself.
  OpacityLayerBase::UpdateScene(context);
}

#endif

void OpacityLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  FML_DCHECK(needs_painting());

  SkPaint paint;
  paint.setAlpha(opacity());

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->translate(offset_.fX, offset_.fY);

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.internal_nodes_canvas->setMatrix(RasterCache::GetIntegralTransCTM(
      context.leaf_nodes_canvas->getTotalMatrix()));
#endif

  if (context.raster_cache) {
    ContainerLayer* container = GetChildContainer();
    const SkMatrix& ctm = context.leaf_nodes_canvas->getTotalMatrix();
    RasterCacheResult child_cache = context.raster_cache->Get(container, ctm);
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
  // not available, or when a cache miss occurs.
  SkRect saveLayerBounds;
  paint_bounds()
      .makeOffset(-offset_.fX, -offset_.fY)
      .roundOut(&saveLayerBounds);

  Layer::AutoSaveLayer save_layer =
      Layer::AutoSaveLayer::Create(context, saveLayerBounds, &paint);
  OpacityLayerBase::Paint(context);
}

ContainerLayer* OpacityLayer::GetChildContainer() const {
  FML_DCHECK(layers().size() == 1);

  return static_cast<ContainerLayer*>(layers()[0].get());
}

}  // namespace flutter
