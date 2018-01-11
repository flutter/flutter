// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "flutter/flow/paint_utils.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flow {

PhysicalShapeLayer::PhysicalShapeLayer() : isRect_(false) {}

PhysicalShapeLayer::~PhysicalShapeLayer() = default;

void PhysicalShapeLayer::Preroll(PrerollContext* context,
                                 const SkMatrix& matrix) {
  SkRect child_paint_bounds;
  PrerollChildren(context, matrix, &child_paint_bounds);

  if (elevation_ == 0) {
    set_paint_bounds(path_.getBounds());
  } else {
#if defined(OS_FUCHSIA)
    // Let the system compositor draw all shadows for us.
    set_needs_system_composite(true);
#else
    // Add some margin to the paint bounds to leave space for the shadow.
    // The margin is hardcoded to an arbitrary maximum for now because Skia
    // doesn't provide a way to calculate it.  We fill this whole region
    // and clip children to it so we don't need to join the child paint bounds.
    SkRect bounds(path_.getBounds());
    bounds.outset(20.0, 20.0);
    set_paint_bounds(bounds);
#endif  // defined(OS_FUCHSIA)
  }
}

#if defined(OS_FUCHSIA)

void PhysicalShapeLayer::UpdateScene(SceneUpdateContext& context) {
  FXL_DCHECK(needs_system_composite());

  SceneUpdateContext::Frame frame(context, frameRRect_, color_, elevation_);
  for (auto& layer : layers()) {
    if (layer->needs_painting()) {
      frame.AddPaintedLayer(layer.get());
    }
  }

  UpdateSceneChildren(context);
}

#endif  // defined(OS_FUCHSIA)

void PhysicalShapeLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "PhysicalShapeLayer::Paint");
  FXL_DCHECK(needs_painting());

  if (elevation_ != 0) {
    DrawShadow(&context.canvas, path_, SK_ColorBLACK, elevation_,
               SkColorGetA(color_) != 0xff, device_pixel_ratio_);
  }

  SkPaint paint;
  paint.setColor(color_);
  context.canvas.drawPath(path_, paint);

  SkAutoCanvasRestore save(&context.canvas, false);
  if (isRect_) {
    context.canvas.save();
  } else {
    context.canvas.saveLayer(path_.getBounds(), nullptr);
  }
  context.canvas.clipPath(path_, true);
  PaintChildren(context);
  if (context.checkerboard_offscreen_layers && !isRect_)
    DrawCheckerboard(&context.canvas, path_.getBounds());
}

void PhysicalShapeLayer::DrawShadow(SkCanvas* canvas,
                                    const SkPath& path,
                                    SkColor color,
                                    float elevation,
                                    bool transparentOccluder,
                                    SkScalar dpr) {
  SkShadowFlags flags = transparentOccluder
                            ? SkShadowFlags::kTransparentOccluder_ShadowFlag
                            : SkShadowFlags::kNone_ShadowFlag;
  const SkRect& bounds = path.getBounds();
  SkScalar shadow_x = (bounds.left() + bounds.right()) / 2;
  SkScalar shadow_y = bounds.top() - 600.0f;
  SkShadowUtils::DrawShadow(canvas, path, dpr * elevation,
                            SkPoint3::Make(shadow_x, shadow_y, dpr * 600.0f),
                            dpr * 800.0f, 0.039f, 0.25f, color, flags);
}

}  // namespace flow
