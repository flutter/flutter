// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "flutter/flow/paint_utils.h"
#include "include/core/SkColor.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

constexpr SkScalar kLightHeight = 600;
constexpr SkScalar kLightRadius = 800;
constexpr bool kRenderPhysicalShapeUsingSystemCompositor = false;

PhysicalShapeLayer::PhysicalShapeLayer(SkColor color,
                                       SkColor shadow_color,
                                       float elevation,
                                       const SkPath& path,
                                       Clip clip_behavior)
    : color_(color),
      shadow_color_(shadow_color),
      path_(path),
      clip_behavior_(clip_behavior) {
#if !defined(OS_FUCHSIA)
  static_assert(!kRenderPhysicalShapeUsingSystemCompositor,
                "Delegation of PhysicalShapeLayer to the system compositor is "
                "only allowed on Fuchsia");
#endif  // !defined(OS_FUCHSIA)

  // If rendering as a separate frame using the system compositor, then make
  // sure to set up the properties needed to do so.
  if (kRenderPhysicalShapeUsingSystemCompositor) {
    SkRect rect;
    SkRRect frame_rrect;
    if (path.isRect(&rect)) {
      frame_rrect = SkRRect::MakeRect(rect);
    } else if (path.isRRect(&frame_rrect)) {
      // Nothing needed here, as isRRect will fill in frameRRect_ already.
    } else if (path.isOval(&rect)) {
      // isRRect returns false for ovals, so we need to explicitly check isOval
      // as well.
      frame_rrect = SkRRect::MakeOval(rect);
    } else {
      // Scenic currently doesn't provide an easy way to create shapes from
      // arbitrary paths.
      // For shapes that cannot be represented as a rounded rectangle we
      // default to use the bounding rectangle.
      // TODO(amirh): fix this once we have a way to create a Scenic shape from
      // an SkPath.
      frame_rrect = SkRRect::MakeRect(path.getBounds());
    }

    set_frame_properties(frame_rrect, color_, /* opacity */ 1.0f);
  }
  set_elevation(elevation);
}

void PhysicalShapeLayer::Preroll(PrerollContext* context,
                                 const SkMatrix& matrix) {
  ContainerLayer::Preroll(context, matrix);

  // Compute paint bounds based on the layer's elevation.
  set_paint_bounds(path_.getBounds());
  if (elevation() == 0) {
    return;
  }

  // If elevation is non-zero, compute the proper paint_bounds to allow drawing
  // a shadow.
  if (kRenderPhysicalShapeUsingSystemCompositor) {
    // Let the system compositor draw all shadows for us, by popping us out as
    // a new frame.
    set_needs_system_composite(true);

    // If the frame behind us is opaque, don't punch a hole in it for group
    // opacity.
    if (context->is_opaque) {
      set_paint_bounds(SkRect());
    }
  } else {
    // Add some margin to the paint bounds to leave space for the shadow.
    // We fill this whole region and clip children to it so we don't need to
    // join the child paint bounds.
    // The offset is calculated as follows:

    //                   .---                           (kLightRadius)
    //                -------/                          (light)
    //                   |  /
    //                   | /
    //                   |/
    //                   |O
    //                  /|                              (kLightHeight)
    //                 / |
    //                /  |
    //               /   |
    //              /    |
    //             -------------                        (layer)
    //            /|     |
    //           / |     |                              (elevation)
    //        A /  |     |B
    // ------------------------------------------------ (canvas)
    //          ---                                     (extent of shadow)
    //
    // E = lt        }           t = (r + w/2)/h
    //                } =>
    // r + w/2 = ht  }           E = (l/h)(r + w/2)
    //
    // Where: E = extent of shadow
    //        l = elevation of layer
    //        r = radius of the light source
    //        w = width of the layer
    //        h = light height
    //        t = tangent of AOB, i.e., multiplier for elevation to extent
    SkRect bounds(path_.getBounds());
    // tangent for x
    double tx = (kLightRadius * context->frame_device_pixel_ratio +
                 bounds.width() * 0.5) /
                kLightHeight;
    // tangent for y
    double ty = (kLightRadius * context->frame_device_pixel_ratio +
                 bounds.height() * 0.5) /
                kLightHeight;
    bounds.outset(elevation() * tx, elevation() * ty);
    set_paint_bounds(bounds);
  }
}

void PhysicalShapeLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "PhysicalShapeLayer::Paint");
  FML_DCHECK(needs_painting());

  // The compositor will paint this layer (which is a solid color) via the
  // color on |SceneUpdateContext::Frame|.
  //
  // The child layers will be painted into the texture used by the Frame, so
  // painting them here would actually cause them to be painted on the display
  // twice -- once into the current canvas (which may be inside of another
  // Frame) and once into the Frame's texture (which is then drawn on top of the
  // current canvas).
  if (kRenderPhysicalShapeUsingSystemCompositor) {
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

  if (elevation() != 0) {
    DrawShadow(context.leaf_nodes_canvas, path_, shadow_color_, elevation(),
               SkColorGetA(color_) != 0xff, context.frame_device_pixel_ratio);
  }

  // Call drawPath without clip if possible for better performance.
  SkPaint paint;
  paint.setColor(color_);
  paint.setAntiAlias(true);
  if (clip_behavior_ != Clip::antiAliasWithSaveLayer) {
    context.leaf_nodes_canvas->drawPath(path_, paint);
  }

  int saveCount = context.internal_nodes_canvas->save();
  switch (clip_behavior_) {
    case Clip::hardEdge:
      context.internal_nodes_canvas->clipPath(path_, false);
      break;
    case Clip::antiAlias:
      context.internal_nodes_canvas->clipPath(path_, true);
      break;
    case Clip::antiAliasWithSaveLayer:
      context.internal_nodes_canvas->clipPath(path_, true);
      context.internal_nodes_canvas->saveLayer(paint_bounds(), nullptr);
      break;
    case Clip::none:
      break;
  }

  if (clip_behavior_ == Clip::antiAliasWithSaveLayer) {
    // If we want to avoid the bleeding edge artifact
    // (https://github.com/flutter/flutter/issues/18057#issue-328003931)
    // using saveLayer, we have to call drawPaint instead of drawPath as
    // anti-aliased drawPath will always have such artifacts.
    context.leaf_nodes_canvas->drawPaint(paint);
  }

  ContainerLayer::Paint(context);

  context.internal_nodes_canvas->restoreToCount(saveCount);
}

void PhysicalShapeLayer::DrawShadow(SkCanvas* canvas,
                                    const SkPath& path,
                                    SkColor color,
                                    float elevation,
                                    bool transparentOccluder,
                                    SkScalar dpr) {
  const SkScalar kAmbientAlpha = 0.039f;
  const SkScalar kSpotAlpha = 0.25f;

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

}  // namespace flutter
