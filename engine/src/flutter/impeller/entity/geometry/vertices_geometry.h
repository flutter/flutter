// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_VERTICES_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_VERTICES_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

/// @brief A geometry that is created from a vertices object.
class VerticesGeometry final : public Geometry {
 public:
  enum class VertexMode {
    kTriangles,
    kTriangleStrip,
    kTriangleFan,
  };

  VerticesGeometry(std::vector<Point> vertices,
                   std::vector<uint16_t> indices,
                   std::vector<Point> texture_coordinates,
                   std::vector<Color> colors,
                   Rect bounds,
                   VerticesGeometry::VertexMode vertex_mode);

  ~VerticesGeometry() = default;

  GeometryResult GetPositionColorBuffer(const ContentContext& renderer,
                                        const Entity& entity,
                                        RenderPass& pass);

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) const override;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  bool HasVertexColors() const;

  bool HasTextureCoordinates() const;

  std::optional<Rect> GetTextureCoordinateCoverge() const;

 private:
  void NormalizeIndices();

  PrimitiveType GetPrimitiveType() const;

  std::vector<Point> vertices_;
  std::vector<Color> colors_;
  std::vector<Point> texture_coordinates_;
  std::vector<uint16_t> indices_;
  Rect bounds_;
  VerticesGeometry::VertexMode vertex_mode_ =
      VerticesGeometry::VertexMode::kTriangles;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_VERTICES_GEOMETRY_H_
