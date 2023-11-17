// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

/// @brief A geometry that implements "drawPaint" like behavior by covering
///        the entire render pass area.
class CoverGeometry final : public Geometry {
 public:
  CoverGeometry();

  ~CoverGeometry() = default;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) const override;

  CoverGeometry(const CoverGeometry&) = delete;

  CoverGeometry& operator=(const CoverGeometry&) = delete;
};

static_assert(std::is_trivially_destructible<CoverGeometry>::value);

}  // namespace impeller
