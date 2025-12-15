// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/arc_geometry.h"

#include "flutter/impeller/entity/geometry/line_geometry.h"
#include "fml/logging.h"

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

    auto result = ComputePositionGeometry(renderer, generator, entity, pass);
    if (CapsOverlap()) {
      result.mode = GeometryResult::Mode::kPreventOverdraw;
    }
    return result;
  }
}

std::optional<Rect> ArcGeometry::GetCoverage(const Matrix& transform) const {
  Scalar padding =  //
      stroke_width_ < 0
          ? 0.0
          : LineGeometry::ComputePixelHalfWidth(transform, stroke_width_);

  if (arc_.IsFullCircle()) {
    // Simpler calculation than below and we don't pad by the extra distance
    // that square caps take up because we aren't going to use caps.
    return arc_.GetOvalBounds().Expand(padding).TransformAndClipBounds(
        transform);
  }

  if (cap_ == Cap::kSquare) {
    padding = padding * kSqrt2;
  }

  return arc_.GetTightArcBounds().Expand(padding).TransformAndClipBounds(
      transform);
}

bool ArcGeometry::CoversArea(const Matrix& transform, const Rect& rect) const {
  return false;
}

bool ArcGeometry::IsAxisAlignedRect() const {
  return false;
}

bool ArcGeometry::CapsOverlap() const {
  FML_DCHECK(arc_.GetSweep().degrees >= 0.0f);
  FML_DCHECK(arc_.GetSweep().degrees <= 360.0f);

  if (stroke_width_ < 0 || cap_ == Cap::kButt ||
      arc_.GetSweep().degrees <= 180) {
    return false;
  }

  switch (cap_) {
    case Cap::kSquare: {
      // Square caps overlap if the inner corner of the ending cap extends
      // inside the inner edge of the start cap. For a visualization of when
      // this occurs, see
      // https://github.com/flutter/flutter/issues/178746#issuecomment-3554526727
      // Note that testing for overlap is completely independent of the arc's
      // start angle. To simplify the overlap test, we treat the arc as if its
      // start angle is 0. This allows the test to only require checking the x
      // coordinate of the ending cap, rather than needing to calculate overlap
      // based on both x and y positions of both caps.
      auto radius = arc_.GetOvalSize().width * 0.5f;
      auto half_width = stroke_width_ * 0.5f;
      auto inner_radius = radius - half_width;
      auto inner_arc_end_x =
          cos(Radians(arc_.GetSweep()).radians) * inner_radius;
      auto inner_square_cap_end_x =
          inner_arc_end_x +
          cos(Radians(arc_.GetSweep() + Degrees(90)).radians) * half_width;
      return inner_square_cap_end_x > inner_radius;
    }
    case Cap::kRound: {
      // Round caps overlap if the distance between the arc's start and end
      // points is less than the stroke width.
      // https://github.com/flutter/flutter/issues/178746#issuecomment-3554526727
      // Note that testing for overlap is completely independent of the arc's
      // start angle. To simplify the overlap test, we treat the arc as if its
      // start angle is 0.
      auto radius = arc_.GetOvalSize().width / 2.0f;
      auto start_point = Point(radius, 0);
      auto sweep_radians = Radians(arc_.GetSweep()).radians;
      auto end_point = Point(cos(sweep_radians), sin(sweep_radians)) * radius;
      return start_point.GetDistanceSquared(end_point) <
             stroke_width_ * stroke_width_;
    }
    case Cap::kButt:
      FML_UNREACHABLE()
  }
}

}  // namespace impeller
