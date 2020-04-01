// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "flutter/flow/paint_utils.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

const SkScalar kLightHeight = 600;
const SkScalar kLightRadius = 800;

PhysicalShapeLayer::PhysicalShapeLayer(SkColor color,
                                       SkColor shadow_color,
                                       float elevation,
                                       const SkPath& path,
                                       Clip clip_behavior)
    : color_(color),
      shadow_color_(shadow_color),
      elevation_(elevation),
      path_(path),
      isRect_(false),
      clip_behavior_(clip_behavior) {
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
  TRACE_EVENT0("flutter", "PhysicalShapeLayer::Preroll");
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context, UsesSaveLayer());

  context->total_elevation += elevation_;
  total_elevation_ = context->total_elevation;
#if defined(OS_FUCHSIA)
  child_layer_exists_below_ = context->child_scene_layer_exists_below;
  context->child_scene_layer_exists_below = false;
#endif

  SkRect child_paint_bounds;
  PrerollChildren(context, matrix, &child_paint_bounds);

#if defined(OS_FUCHSIA)
  if (child_layer_exists_below_) {
    set_needs_system_composite(true);
  }
  context->child_scene_layer_exists_below =
      context->child_scene_layer_exists_below || child_layer_exists_below_;
#endif
  context->total_elevation -= elevation_;

  if (elevation_ == 0) {
    set_paint_bounds(path_.getBounds());
  } else {
    // We will draw the shadow in Paint(), so add some margin to the paint
    // bounds to leave space for the shadow. We fill this whole region and clip
    // children to it so we don't need to join the child paint bounds.
    set_paint_bounds(ComputeShadowBounds(path_.getBounds(), elevation_,
                                         context->frame_device_pixel_ratio));
  }
}

#if defined(OS_FUCHSIA)

void PhysicalShapeLayer::UpdateScene(SceneUpdateContext& context) {
  FML_DCHECK(needs_system_composite());
  TRACE_EVENT0("flutter", "PhysicalShapeLayer::UpdateScene");

  // If there is embedded Fuchsia content in the scene (a ChildSceneLayer),
  // PhysicalShapeLayers that appear above the embedded content will be turned
  // into their own Scenic layers.
  if (child_layer_exists_below_) {
    float global_scenic_elevation =
        context.GetGlobalElevationForNextScenicLayer();
    float local_scenic_elevation =
        global_scenic_elevation - context.scenic_elevation();
    float z_translation = -local_scenic_elevation;

    // Retained rendering: speedup by reusing a retained entity node if
    // possible. When an entity node is reused, no paint layer is added to the
    // frame so we won't call PhysicalShapeLayer::Paint.
    LayerRasterCacheKey key(unique_id(), context.Matrix());
    if (context.HasRetainedNode(key)) {
      TRACE_EVENT_INSTANT0("flutter", "retained layer cache hit");
      scenic::EntityNode* retained_node = context.GetRetainedNode(key);
      FML_DCHECK(context.top_entity());
      FML_DCHECK(retained_node->session() == context.session());

      // Re-adjust the elevation.
      retained_node->SetTranslation(0.f, 0.f, z_translation);

      context.top_entity()->entity_node().AddChild(*retained_node);
      return;
    }

    TRACE_EVENT_INSTANT0("flutter", "cache miss, creating");
    // If we can't find an existing retained surface, create one.
    SceneUpdateContext::Frame frame(context, frameRRect_, SK_ColorTRANSPARENT,
                                    SkScalarRoundToInt(context.alphaf() * 255),
                                    "flutter::PhysicalShapeLayer",
                                    z_translation, this);

    frame.AddPaintLayer(this);

    // Node: UpdateSceneChildren needs to be called here so that |frame| is
    // still in scope (and therefore alive) while UpdateSceneChildren is being
    // called.
    float scenic_elevation = context.scenic_elevation();
    context.set_scenic_elevation(scenic_elevation + local_scenic_elevation);
    ContainerLayer::UpdateSceneChildren(context);
    context.set_scenic_elevation(scenic_elevation);
  } else {
    ContainerLayer::UpdateSceneChildren(context);
  }
}

#endif  // defined(OS_FUCHSIA)

void PhysicalShapeLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "PhysicalShapeLayer::Paint");
  FML_DCHECK(needs_painting());

  if (elevation_ != 0) {
    DrawShadow(context.leaf_nodes_canvas, path_, shadow_color_, elevation_,
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

  if (UsesSaveLayer()) {
    // If we want to avoid the bleeding edge artifact
    // (https://github.com/flutter/flutter/issues/18057#issue-328003931)
    // using saveLayer, we have to call drawPaint instead of drawPath as
    // anti-aliased drawPath will always have such artifacts.
    context.leaf_nodes_canvas->drawPaint(paint);
  }

  PaintChildren(context);

  context.internal_nodes_canvas->restoreToCount(saveCount);
}

SkRect PhysicalShapeLayer::ComputeShadowBounds(const SkRect& bounds,
                                               float elevation,
                                               float pixel_ratio) {
  // The shadow offset is calculated as follows:
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
  // tangent for x
  double tx =
      (kLightRadius * pixel_ratio + bounds.width() * 0.5) / kLightHeight;
  // tangent for y
  double ty =
      (kLightRadius * pixel_ratio + bounds.height() * 0.5) / kLightHeight;
  SkRect shadow_bounds(bounds);
  shadow_bounds.outset(elevation * tx, elevation * ty);

  return shadow_bounds;
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
