// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "flutter/flow/paint_utils.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flow {

PhysicalShapeLayer::PhysicalShapeLayer(Clip clip_behavior)
    : isRect_(false), clip_behavior_(clip_behavior) {}

PhysicalShapeLayer::~PhysicalShapeLayer() = default;

void PhysicalShapeLayer::set_path(const SkPath& path) {
  path_ = path;
  isRect_ = false;
  SkRect rect;
  if (path.isRect(&rect)) {
    isRect_ = true;
    frameRRect_ = SkRRect::MakeRect(rect);
  } else if (path.isRRect(&frameRRect_)) {
    isRect_ = frameRRect_.isRect();
  } else if (path.isOval(&rect)) {
    // isRRect returns false for ovals, so we need to explicitly check isOval
    // as well.
    frameRRect_ = SkRRect::MakeOval(rect);
  } else {
    // Scenic currently doesn't provide an easy way to create shapes from
    // arbitrary paths.
    // For shapes that cannot be represented as a rounded rectangle we
    // default to use the bounding rectangle.
    // TODO(amirh): fix this once we have a way to create a Scenic shape from
    // an SkPath.
    frameRRect_ = SkRRect::MakeRect(path.getBounds());
  }
}

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
  FML_DCHECK(needs_system_composite());

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
  FML_DCHECK(needs_painting());

  if (elevation_ != 0) {
    DrawShadow(context.canvas, path_, shadow_color_, elevation_,
               SkColorGetA(color_) != 0xff, device_pixel_ratio_);
  }

  // Call drawPath without clip if possible for better performance.
  SkPaint paint;
  paint.setColor(color_);
  if (clip_behavior_ != Clip::antiAliasWithSaveLayer) {
    context.canvas->drawPath(path_, paint);
  }

  int saveCount = context.canvas->save();
  switch (clip_behavior_) {
    case Clip::hardEdge:
      context.canvas->clipPath(path_, false);
      break;
    case Clip::antiAlias:
      context.canvas->clipPath(path_, true);
      break;
    case Clip::antiAliasWithSaveLayer:
      context.canvas->clipPath(path_, true);
      context.canvas->saveLayer(paint_bounds(), nullptr);
      break;
    case Clip::none:
      break;
  }

  if (clip_behavior_ == Clip::antiAliasWithSaveLayer) {
    // If we want to avoid the bleeding edge artifact
    // (https://github.com/flutter/flutter/issues/18057#issue-328003931)
    // using saveLayer, we have to call drawPaint instead of drawPath as
    // anti-aliased drawPath will always have such artifacts.
    context.canvas->drawPaint(paint);
  }

  PaintChildren(context);

  context.canvas->restoreToCount(saveCount);
}

void PhysicalShapeLayer::DrawShadow(SkCanvas* canvas,
                                    const SkPath& path,
                                    SkColor color,
                                    float elevation,
                                    bool transparentOccluder,
                                    SkScalar dpr) {
  const SkScalar kAmbientAlpha = 0.039f;
  const SkScalar kSpotAlpha = 0.25f;
  const SkScalar kLightHeight = 600;
  const SkScalar kLightRadius = 800;

  SkShadowFlags flags = transparentOccluder
                            ? SkShadowFlags::kTransparentOccluder_ShadowFlag
                            : SkShadowFlags::kNone_ShadowFlag;
  const SkRect& bounds = path.getBounds();
  SkScalar shadow_x = (bounds.left() + bounds.right()) / 2;
  SkScalar shadow_y = bounds.top() - 600.0f;
  SkColor inAmbient = SkColorSetA(color, kAmbientAlpha * SkColorGetA(color));
  SkColor inSpot = SkColorSetA(color, kSpotAlpha * SkColorGetA(color));
  SkColor ambientColor, spotColor;
  SkShadowUtils::ComputeTonalColors(inAmbient, inSpot, &ambientColor,
                                    &spotColor);
  SkShadowUtils::DrawShadow(
      canvas, path, SkPoint3::Make(0, 0, dpr * elevation),
      SkPoint3::Make(shadow_x, shadow_y, dpr * kLightHeight),
      dpr * kLightRadius, ambientColor, spotColor, flags);
}

}  // namespace flow
