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

}  // namespace impeller
