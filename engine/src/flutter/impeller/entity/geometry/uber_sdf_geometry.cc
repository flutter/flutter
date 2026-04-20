// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

UberSDFGeometry::UberSDFGeometry(const UberSDFParameters& params)
    : params_(params) {
  base_bounds_ = Rect::MakeEllipseBounds(params_.center, params_.size);
  if (params_.stroke) {
    base_bounds_ = base_bounds_.Expand(params_.stroke->width * 0.5);
  }
}

UberSDFGeometry::~UberSDFGeometry() = default;

GeometryResult UberSDFGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  // Return a quad (FillRectGeometry) that covers the base shape expanded by
  // padding for stroke width and AA.
  //
  // For future performance enhancements (if the fill rate is a limiting factor)
  // this can be optimized to use a tighter geometry for specific shapes. E.g.
  // Using a tighter polygon, or cutting out the interior for stroked shapes.
  FillRectGeometry frg(GetExpandedBounds(entity.GetTransform()));
  return frg.GetPositionBuffer(renderer, entity, pass);
}

std::optional<Rect> UberSDFGeometry::GetCoverage(
    const Matrix& transform) const {
  Rect local_space_bounds = GetExpandedBounds(transform);
  return local_space_bounds.TransformAndClipBounds(transform);
}

bool UberSDFGeometry::CoversArea(const Matrix& transform,
                                 const Rect& rect) const {
  if (params_.type == UberSDFParameters::Type::kRect && !params_.stroke &&
      transform.IsTranslationScaleOnly()) {
    // The SDF is a filled axis-aligned rectangle. It covers the input rect if
    // the SDF's rect covers the input rect, subtracting the AA padding from the
    // SDF rect.
    Rect transformed_bounds =
        GetExpandedBounds(transform).TransformAndClipBounds(transform);
    return transformed_bounds.Expand(-UberSDFParameters::kAntialiasPixels)
        .Contains(rect);
  }

  // Conservatively return false. We can optimize to handle more cases in the
  // future if needed for performance reasons.
  return false;
}

bool UberSDFGeometry::IsAxisAlignedRect() const {
  return (params_.type == UberSDFParameters::Type::kRect && !params_.stroke);
}

Rect UberSDFGeometry::GetExpandedBounds(const Matrix& transform) const {
  // Get the scaling factor of the transform in the X and Y directions.
  Vector2 transform_scaling = transform.GetBasisScaleXY();

  // Get the device pixel size in local space units. This is the inverse of the
  // transform scaling. E.g. if the transform performs a scale of 4 in the X
  // direction and 0.5 in the Y direction, then 1 device pixel is size
  // {0.25, 2.0} in local space units.
  Size device_pixel_size = {
      transform_scaling.x != 0 ? 1.0f / transform_scaling.x : 0,
      transform_scaling.y != 0 ? 1.0f / transform_scaling.y : 0};

  // The stroke padding is half the stroke width, if the shape is stroked.
  Size stroke_padding;
  if (params_.stroke) {
    // For the purposes of stroke padding, clamp stroke width to a minimum of 1
    // device pixel. Note that this means the stroke width padding in the X
    // direction may differ from the stroke width padding in the Y direction.
    Size effective_stroke_width =
        Size(params_.stroke->width).Max(device_pixel_size);
    stroke_padding = effective_stroke_width * 0.5f;
  }

  // The AA padding is half of the AA pixel amount multiplied by the device
  // pixel size. The padding is multiplied by 0.5 because AA fades the SDF
  // alpha across |kAntialiasPixels| pixels at the shape's edge, so half of the
  // fade occurs inside the shape and half of the fade occurs outside the shape.
  // This padding covers the half of the fade that occurs outside of the shape.
  Size aa_padding =
      UberSDFParameters::kAntialiasPixels * device_pixel_size * 0.5f;

  return base_bounds_.Expand(stroke_padding + aa_padding);
}

}  // namespace impeller
