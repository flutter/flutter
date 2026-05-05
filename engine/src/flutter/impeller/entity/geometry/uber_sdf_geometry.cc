// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

UberSDFGeometry::UberSDFGeometry(const UberSDFParameters& params)
    : params_(params) {}

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
  return GetExpandedBounds(transform).TransformAndClipBounds(transform);
}

bool UberSDFGeometry::CoversArea(const Matrix& transform,
                                 const Rect& rect) const {
  if (params_.type == UberSDFParameters::Type::kRect && !params_.stroke &&
      transform.IsTranslationScaleOnly()) {
    // The SDF is a filled axis-aligned rectangle. It "covers" the input rect if
    // the SDF shader fully replaces the pixels contained in the rect parameter.
    // The SDF shader is computed by the GPU at the center of the pixels it
    // intersects and it computes a coverage for the pixels that reaches full
    // coverage (1.0) at (aa_pixels / 2.0) inside the geometry. That coverage
    // value will be applied for every MSAA sample intersected by the geometry.
    //
    // Since the input rect is an integer rect we already know that it encloses
    // at least half a pixel on each side of the pixel centers inside it and
    // that it encloses every MSAA sample location within those pixels. This
    // means that the integer rect already meets all of the above criteria (as
    // long as kAntialiasPixels is <= 1.0), so if the transformed geometry
    // contains the integer input rect, all pixels will be fully rendered.
    static_assert(UberSDFParameters::kAntialiasPixels <= 1.0);
    return Rect::MakeEllipseBounds(params_.center, params_.size)
        .TransformBounds(transform)
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

  // Padding for antialiasing.
  Size aa_padding = UberSDFParameters::kAntialiasPixels * device_pixel_size;

  return Rect::MakeEllipseBounds(params_.center, params_.size)
      .Expand(stroke_padding + aa_padding);
}

}  // namespace impeller
