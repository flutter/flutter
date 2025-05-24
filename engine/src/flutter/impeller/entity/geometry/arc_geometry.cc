// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/arc_geometry.h"

#include "flutter/impeller/entity/geometry/line_geometry.h"

namespace impeller {

ArcGeometry::ArcGeometry(const Rect& oval_bounds,
                         Degrees start,
                         Degrees sweep,
                         bool include_center)
    : oval_bounds_(oval_bounds),
      start_(start),
      sweep_(sweep),
      include_center_(include_center),
      stroke_width_(-1.0f),
      cap_(Cap::kButt) {}

ArcGeometry::ArcGeometry(const Rect& oval_bounds,
                         Degrees start,
                         Degrees sweep,
                         const StrokeParameters& stroke)
    : oval_bounds_(oval_bounds),
      start_(start),
      sweep_(sweep),
      include_center_(false),
      stroke_width_(stroke.width),
      cap_(stroke.cap) {
  FML_DCHECK(oval_bounds_.IsSquare());
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
        transform, oval_bounds_, start_, sweep_, include_center_,
        renderer.GetDeviceCapabilities().SupportsTriangleFan());

    return ComputePositionGeometry(renderer, generator, entity, pass);
  } else {
    FML_DCHECK(oval_bounds_.IsSquare());
    Scalar half_width =
        LineGeometry::ComputePixelHalfWidth(transform, stroke_width_);

    auto generator = renderer.GetTessellator().StrokedArc(
        transform, oval_bounds_, start_, sweep_, cap_, half_width);

    return ComputePositionGeometry(renderer, generator, entity, pass);
  }
}

std::optional<Rect> ArcGeometry::GetCoverage(const Matrix& transform) const {
  Scalar half_width =  //
      stroke_width_ < 0
          ? 0.0
          : LineGeometry::ComputePixelHalfWidth(transform, stroke_width_);

  if (sweep_.degrees <= -360 || sweep_.degrees >= 360) {
    return oval_bounds_.Expand(half_width).TransformAndClipBounds(transform);
  }

  Point center = oval_bounds_.GetCenter();
  Size size = oval_bounds_.GetSize();

  Degrees start = start_.GetPositive();
  Degrees end = start + sweep_;

  // 1. start vector
  // 2. end vector
  // 3. optional center
  // 4-7. optional quadrant extrema
  Point extrema[7];
  int count = 0;

  extrema[count++] = Matrix::CosSin(start);
  extrema[count++] = Matrix::CosSin(end);

  if (include_center_) {
    extrema[count++] = {0, 0};
  }

  if (start.degrees <= 90 && end.degrees >= 90) {
    extrema[count++] = {0, 1};
  }
  if (start.degrees <= 180 && end.degrees >= 180) {
    extrema[count++] = {-1, 0};
  }
  if (start.degrees <= 270 && end.degrees >= 270) {
    extrema[count++] = {0, -1};
  }
  if (start.degrees <= 360 && end.degrees >= 360) {
    extrema[count++] = {1, 0};
  }

  FML_DCHECK(count <= 7);

  for (int i = 0; i < count; i++) {
    extrema[i] = transform * (center + extrema[i] * size);
  }
  auto opt_rect = Rect::MakePointBounds(extrema, extrema + count);
  if (opt_rect.has_value()) {
    // Pretty much guaranteed because count >= 2...
    opt_rect = opt_rect  //
                   .value()
                   .Expand(half_width)
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
