// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/arc_geometry.h"

#include "flutter/impeller/entity/geometry/line_geometry.h"

namespace impeller {

ArcGeometry::ArcGeometry(const Arc& arc)
    : arc_(arc), stroke_width_(-1.0f), cap_(Cap::kButt) {}

ArcGeometry::ArcGeometry(const Arc& arc, const StrokeParameters& stroke)
    : arc_(arc), stroke_width_(stroke.width), cap_(stroke.cap) {
  FML_DCHECK(arc.IsPerfectCircle());
  FML_DCHECK(!arc.IncludeCenter());
}

ArcGeometry::~ArcGeometry() = default;

// |Geometry|
Scalar ArcGeometry::ComputeAlphaCoverage(const Matrix& transform) const {
  if (stroke_width_ < 0) {
    return 1;
  }
  return Geometry::ComputeStrokeAlphaCoverage(transform, stroke_width_);
}

GeometryResult ArcGeometry::GetPositionBuffer(const ContentContext& renderer,
                                              const Entity& entity,
                                              RenderPass& pass) const {
  auto& transform = entity.GetTransform();

  if (stroke_width_ < 0) {
    auto generator = renderer.GetTessellator().FilledArc(
        transform, arc_,
        renderer.GetDeviceCapabilities().SupportsTriangleFan());

    return ComputePositionGeometry(renderer, generator, entity, pass);
  } else {
    FML_DCHECK(arc_.IsPerfectCircle());
    FML_DCHECK(!arc_.IncludeCenter());
    Scalar half_width =
        LineGeometry::ComputePixelHalfWidth(transform, stroke_width_);

    auto generator =
        renderer.GetTessellator().StrokedArc(transform, arc_, cap_, half_width);

    return ComputePositionGeometry(renderer, generator, entity, pass);
  }
}

std::optional<Rect> ArcGeometry::GetCoverage(const Matrix& transform) const {
  Scalar padding =  //
      stroke_width_ < 0
          ? 0.0
          : LineGeometry::ComputePixelHalfWidth(transform, stroke_width_);

  if (arc_.IsFullCircle()) {
    return arc_.GetBounds().Expand(padding).TransformAndClipBounds(transform);
  }

  if (cap_ == Cap::kSquare) {
    padding = padding * kSqrt2;
  }

  Degrees start_angle = arc_.GetStart().GetPositive();
  Degrees end_angle = start_angle + arc_.GetSweep();
  FML_DCHECK(start_angle.degrees >= 0 && start_angle.degrees < 360);
  FML_DCHECK(end_angle > start_angle && end_angle.degrees < 720);

  // 1. start vector
  // 2. end vector
  // 3. optional center
  // 4-7. optional quadrant extrema
  Point extrema[7];
  int count = 0;

  extrema[count++] = Matrix::CosSin(start_angle);
  extrema[count++] = Matrix::CosSin(end_angle);

  if (arc_.IncludeCenter()) {
    // We don't handle strokes with include_center so the stroking
    // parameters should be the default.
    FML_DCHECK(stroke_width_ < 0 && cap_ == Cap::kButt && padding == 0.0f);
    extrema[count++] = {0, 0};
  }

  // cur_axis will be pre-incremented before recording the following axis
  int cur_axis = std::floor(start_angle.degrees / 90.0f);
  // end_axis is a non-inclusive end of the range
  int end_axis = std::ceil(end_angle.degrees / 90.0f);
  while (++cur_axis < end_axis) {
    extrema[count++] = kQuadrantAxes[cur_axis & 3];
  }

  FML_DCHECK(count <= 7);

  Point center = arc_.GetBounds().GetCenter();
  Size radii = arc_.GetBounds().GetSize() * 0.5f;

  for (int i = 0; i < count; i++) {
    extrema[i] = center + extrema[i] * radii;
  }
  auto opt_rect = Rect::MakePointBounds(extrema, extrema + count);
  if (opt_rect.has_value()) {
    // Pretty much guaranteed because count >= 2...
    opt_rect = opt_rect  //
                   .value()
                   .Expand(padding)
                   .TransformAndClipBounds(transform);
  }
  return opt_rect;
}

bool ArcGeometry::CoversArea(const Matrix& transform, const Rect& rect) const {
  return false;
}

bool ArcGeometry::IsAxisAlignedRect() const {
  return false;
}

}  // namespace impeller
