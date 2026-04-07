// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

UberSDFGeometry::UberSDFGeometry(UberSDFParameters params) : params_(params) {}

UberSDFGeometry::~UberSDFGeometry() = default;

std::unique_ptr<Geometry> UberSDFGeometry::CreateUnderlyingGeometry() const {
  auto stroke = params_.stroke;
  auto stroke_padding = stroke ? stroke->width * 0.5f : 0.0f;

  switch (params_.type) {
    case UberSDFParameters::Type::kRect: {
      Point center = params_.center;
      Point size = params_.size;
      Rect rect = Rect::MakeXYWH(center.x - size.x, center.y - size.y,
                                 size.x * 2, size.y * 2);
      auto geometry =
          std::make_unique<FillRectGeometry>(rect.Expand(stroke_padding));
      geometry->SetAntialiasPadding(UberSDFParameters::kAntialiasPadding);
      return geometry;
    }
    case UberSDFParameters::Type::kCircle: {
      Point center = params_.center;
      Scalar radius = params_.size.x;
      std::unique_ptr<FillRectGeometry> geometry =
          std::make_unique<FillRectGeometry>(
              Rect::MakeXYWH(center.x, center.y, 0.0f, 0.0f)
                  .Expand(radius + stroke_padding));
      geometry->SetAntialiasPadding(UberSDFParameters::kAntialiasPadding);
      return geometry;
    }
  }
}

GeometryResult UberSDFGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  return CreateUnderlyingGeometry()->GetPositionBuffer(renderer, entity, pass);
}

std::optional<Rect> UberSDFGeometry::GetCoverage(
    const Matrix& transform) const {
  return CreateUnderlyingGeometry()->GetCoverage(transform);
}

bool UberSDFGeometry::CoversArea(const Matrix& transform,
                                 const Rect& rect) const {
  return CreateUnderlyingGeometry()->CoversArea(transform, rect);
}

bool UberSDFGeometry::IsAxisAlignedRect() const {
  return CreateUnderlyingGeometry()->IsAxisAlignedRect();
}

}  // namespace impeller
