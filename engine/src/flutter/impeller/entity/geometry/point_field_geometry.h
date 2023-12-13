// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_POINT_FIELD_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_POINT_FIELD_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

class PointFieldGeometry final : public Geometry {
 public:
  PointFieldGeometry(std::vector<Point> points, Scalar radius, bool round);

  ~PointFieldGeometry() = default;

  static size_t ComputeCircleDivisions(Scalar scaled_radius, bool round);

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) const override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  GeometryResult GetPositionBufferGPU(
      const ContentContext& renderer,
      const Entity& entity,
      RenderPass& pass,
      std::optional<Rect> texture_coverage = std::nullopt,
      std::optional<Matrix> effect_transform = std::nullopt) const;

  std::optional<VertexBufferBuilder<SolidFillVertexShader::PerVertexData>>
  GetPositionBufferCPU(const ContentContext& renderer,
                       const Entity& entity,
                       RenderPass& pass) const;

  std::vector<Point> points_;
  Scalar radius_;
  bool round_;

  PointFieldGeometry(const PointFieldGeometry&) = delete;

  PointFieldGeometry& operator=(const PointFieldGeometry&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_POINT_FIELD_GEOMETRY_H_
