// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_model_layer.h"

#include "third_party/skia/include/utils/SkShadowUtils.h"

#if defined(OS_FUCHSIA)
#include "apps/mozart/lib/skia/type_converters.h"
#include "apps/mozart/services/composition/nodes.fidl.h"
#endif  // defined(OS_FUCHSIA)

namespace flow {

PhysicalModelLayer::PhysicalModelLayer()
    : rrect_(SkRRect::MakeEmpty()) {}

PhysicalModelLayer::~PhysicalModelLayer() {}

void PhysicalModelLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  PrerollChildren(context, matrix);

  // Add some margin to the paint bounds to leave space for the shadow.
  // The margin is hardcoded to an arbitrary maximum for now because Skia
  // doesn't provide a way to calculate it.
  SkRect bounds(rrect_.getBounds());
  bounds.outset(20.0, 20.0);
  set_paint_bounds(bounds);

  context->child_paint_bounds = bounds;
}

#if defined(OS_FUCHSIA)

void PhysicalModelLayer::UpdateScene(SceneUpdateContext& context,
                                     mozart::Node* container) {
  context.AddLayerToCurrentPaintTask(this);
  auto node = mozart::Node::New();
  node->content_clip = mozart::RectF::From(rrect_.getBounds());
  UpdateSceneChildrenInsideNode(context, container, std::move(node));
}

#endif  // defined(OS_FUCHSIA)

void PhysicalModelLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "PhysicalModelLayer::Paint");

  SkPath path;
  path.addRRect(rrect_);

  if (elevation_ != 0) {
    DrawShadow(&context.canvas, path, SK_ColorBLACK, elevation_,
               SkColorGetA(color_) != 0xff);
  }

  if (needs_system_composite())
    return;

  SkPaint paint;
  paint.setColor(color_);
  context.canvas.drawPath(path, paint);

  SkAutoCanvasRestore save(&context.canvas, false);
  if (rrect_.isRect()) {
    context.canvas.save();
  } else {
    context.canvas.saveLayer(&rrect_.getBounds(), nullptr);
  }
  context.canvas.clipRRect(rrect_, true);
  PaintChildren(context);
}

void PhysicalModelLayer::DrawShadow(SkCanvas* canvas, const SkPath& path,
                                    SkColor color, int elevation,
                                    bool transparentOccluder) {
    SkShadowFlags flags = transparentOccluder ?
        SkShadowFlags::kTransparentOccluder_ShadowFlag :
        SkShadowFlags::kNone_ShadowFlag;
    const SkRect& bounds = path.getBounds();
    SkScalar shadow_x = (bounds.left() + bounds.right()) / 2;
    SkScalar shadow_y = bounds.top() - 600.0f;
    SkShadowUtils::DrawShadow(canvas, path,
                              elevation,
                              SkPoint3::Make(shadow_x, shadow_y, 600.0f),
                              800.0f,
                              0.039f, 0.25f,
                              color,
                              flags);
}

}  // namespace flow
