// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

class Tessellator;

struct GeometryResult {
  PrimitiveType type;
  VertexBuffer vertex_buffer;
  Matrix transform;
  bool prevent_overdraw;
};

enum GeometryVertexType {
  kPosition,
  kColor,
  kUV,
};

/// @brief Compute UV geometry for a VBB that contains only position geometry.
///
/// texture_origin should be set to 0, 0 for stroke and stroke based geometry,
/// like the point field.
VertexBufferBuilder<TextureFillVertexShader::PerVertexData>
ComputeUVGeometryCPU(
    VertexBufferBuilder<SolidFillVertexShader::PerVertexData>& input,
    Point texture_origin,
    Size texture_coverage,
    Matrix effect_transform);

GeometryResult ComputeUVGeometryForRect(Rect source_rect,
                                        Rect texture_coverage,
                                        Matrix effect_transform,
                                        const ContentContext& renderer,
                                        const Entity& entity,
                                        RenderPass& pass);

/// @brief Given a polyline created from a convex filled path, perform a
/// tessellation.
std::pair<std::vector<Point>, std::vector<uint16_t>> TessellateConvex(
    Path::Polyline polyline);

class Geometry {
 public:
  Geometry();

  virtual ~Geometry();

  static std::unique_ptr<Geometry> MakeFillPath(const Path& path);

  static std::unique_ptr<Geometry> MakeStrokePath(
      const Path& path,
      Scalar stroke_width = 0.0,
      Scalar miter_limit = 4.0,
      Cap stroke_cap = Cap::kButt,
      Join stroke_join = Join::kMiter);

  static std::unique_ptr<Geometry> MakeCover();

  static std::unique_ptr<Geometry> MakeRect(Rect rect);

  static std::unique_ptr<Geometry> MakePointField(std::vector<Point> points,
                                                  Scalar radius,
                                                  bool round);

  virtual GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                           const Entity& entity,
                                           RenderPass& pass) = 0;

  virtual GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                             Matrix effect_transform,
                                             const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass);

  virtual GeometryVertexType GetVertexType() const = 0;

  virtual std::optional<Rect> GetCoverage(const Matrix& transform) const = 0;
};

}  // namespace impeller
