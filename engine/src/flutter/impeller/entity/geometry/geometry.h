// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_GEOMETRY_H_

#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

class Tessellator;

struct GeometryResult {
  PrimitiveType type;
  VertexBuffer vertex_buffer;
  Matrix transform;
  bool prevent_overdraw;
};

static const GeometryResult kEmptyResult = {
    .vertex_buffer =
        {
            .index_type = IndexType::kNone,
        },
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

class Geometry {
 public:
  static std::shared_ptr<Geometry> MakeFillPath(
      Path path,
      std::optional<Rect> inner_rect = std::nullopt);

  static std::shared_ptr<Geometry> MakeStrokePath(
      Path path,
      Scalar stroke_width = 0.0,
      Scalar miter_limit = 4.0,
      Cap stroke_cap = Cap::kButt,
      Join stroke_join = Join::kMiter);

  static std::shared_ptr<Geometry> MakeCover();

  static std::shared_ptr<Geometry> MakeRect(const Rect& rect);

  static std::shared_ptr<Geometry> MakeOval(const Rect& rect);

  static std::shared_ptr<Geometry> MakeLine(const Point& p0,
                                            const Point& p1,
                                            Scalar width,
                                            Cap cap);

  static std::shared_ptr<Geometry> MakeCircle(const Point& center,
                                              Scalar radius);

  static std::shared_ptr<Geometry> MakeStrokedCircle(const Point& center,
                                                     Scalar radius,
                                                     Scalar stroke_width);

  static std::shared_ptr<Geometry> MakeRoundRect(const Rect& rect,
                                                 const Size& radii);

  static std::shared_ptr<Geometry> MakePointField(std::vector<Point> points,
                                                  Scalar radius,
                                                  bool round);

  virtual GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                           const Entity& entity,
                                           RenderPass& pass) const = 0;

  virtual GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                             Matrix effect_transform,
                                             const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass) const = 0;

  virtual GeometryVertexType GetVertexType() const = 0;

  virtual std::optional<Rect> GetCoverage(const Matrix& transform) const = 0;

  /// @brief    Determines if this geometry, transformed by the given
  ///           `transform`, will completely cover all surface area of the given
  ///           `rect`.
  ///
  ///           This is a conservative estimate useful for certain
  ///           optimizations.
  ///
  /// @returns  `true` if the transformed geometry is guaranteed to cover the
  ///           given `rect`. May return `false` in many undetected cases where
  ///           the transformed geometry does in fact cover the `rect`.
  virtual bool CoversArea(const Matrix& transform, const Rect& rect) const;

  virtual bool IsAxisAlignedRect() const;

 protected:
  static GeometryResult ComputePositionGeometry(
      const ContentContext& renderer,
      const Tessellator::VertexGenerator& generator,
      const Entity& entity,
      RenderPass& pass);

  static GeometryResult ComputePositionUVGeometry(
      const ContentContext& renderer,
      const Tessellator::VertexGenerator& generator,
      const Matrix& uv_transform,
      const Entity& entity,
      RenderPass& pass);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_GEOMETRY_H_
