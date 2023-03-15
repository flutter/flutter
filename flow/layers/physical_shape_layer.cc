// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "flutter/flow/paint_utils.h"

namespace flutter {

PhysicalShapeLayer::PhysicalShapeLayer(DlColor color,
                                       DlColor shadow_color,
                                       float elevation,
                                       const SkPath& path,
                                       Clip clip_behavior)
    : color_(color),
      shadow_color_(shadow_color),
      elevation_(elevation),
      path_(path),
      clip_behavior_(clip_behavior) {}

void PhysicalShapeLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const PhysicalShapeLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (color_ != prev->color_ || shadow_color_ != prev->shadow_color_ ||
        elevation_ != prev->elevation() || path_ != prev->path_ ||
        clip_behavior_ != prev->clip_behavior_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }

  SkRect bounds;
  if (elevation_ == 0) {
    bounds = path_.getBounds();
  } else {
    bounds = DlCanvas::ComputeShadowBounds(path_, elevation_,
                                           context->frame_device_pixel_ratio(),
                                           context->GetTransform3x3());
  }

  context->AddLayerBounds(bounds);

  // Only push cull rect if there is clip.
  if (clip_behavior_ == Clip::none || context->PushCullRect(bounds)) {
    DiffChildren(context, prev);
  }
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void PhysicalShapeLayer::Preroll(PrerollContext* context) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context, UsesSaveLayer());

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, &child_paint_bounds);
  context->renderable_state_flags =
      UsesSaveLayer() ? Layer::kSaveLayerRenderFlags : 0;

  SkRect paint_bounds;
  if (elevation_ == 0) {
    paint_bounds = path_.getBounds();
  } else {
    // We will draw the shadow in Paint(), so add some margin to the paint
    // bounds to leave space for the shadow.
    paint_bounds = DlCanvas::ComputeShadowBounds(
        path_, elevation_, context->frame_device_pixel_ratio,
        context->state_stack.transform_3x3());
  }

  if (clip_behavior_ == Clip::none) {
    paint_bounds.join(child_paint_bounds);
  }

  set_paint_bounds(paint_bounds);
}

void PhysicalShapeLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting(context));

  if (elevation_ != 0) {
    context.canvas->DrawShadow(path_, shadow_color_, elevation_,
                               SkColorGetA(color_) != 0xff,
                               context.frame_device_pixel_ratio);
  }

  // Call drawPath without clip if possible for better performance.
  DlPaint paint;
  paint.setColor(color_);
  paint.setAntiAlias(true);
  if (clip_behavior_ != Clip::antiAliasWithSaveLayer) {
    context.canvas->DrawPath(path_, paint);
  }

  auto mutator = context.state_stack.save();
  switch (clip_behavior_) {
    case Clip::hardEdge:
      mutator.clipPath(path_, false);
      break;
    case Clip::antiAlias:
      mutator.clipPath(path_, true);
      break;
    case Clip::antiAliasWithSaveLayer: {
      TRACE_EVENT0("flutter", "Canvas::saveLayer");
      mutator.clipPath(path_, true);
      mutator.saveLayer(paint_bounds());
    } break;
    case Clip::none:
      break;
  }

  if (UsesSaveLayer()) {
    // If we want to avoid the bleeding edge artifact
    // (https://github.com/flutter/flutter/issues/18057#issue-328003931)
    // using saveLayer, we have to call drawPaint instead of drawPath as
    // anti-aliased drawPath will always have such artifacts.
    context.canvas->DrawPaint(paint);
  }

  PaintChildren(context);
}

}  // namespace flutter
