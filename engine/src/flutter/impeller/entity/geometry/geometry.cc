// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/geometry.h"

#include <memory>
#include <optional>

#include "fml/status.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/entity/geometry/cover_geometry.h"
#include "impeller/entity/geometry/ellipse_geometry.h"
#include "impeller/entity/geometry/fill_path_geometry.h"
#include "impeller/entity/geometry/line_geometry.h"
#include "impeller/entity/geometry/point_field_geometry.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/entity/geometry/round_rect_geometry.h"
#include "impeller/entity/geometry/stroke_path_geometry.h"
#include "impeller/geometry/rect.h"

namespace impeller {

GeometryResult Geometry::ComputePositionGeometry(
    const ContentContext& renderer,
    const Tessellator::VertexGenerator& generator,
    const Entity& entity,
    RenderPass& pass) {
  using VT = SolidFillVertexShader::PerVertexData;

  size_t count = generator.GetVertexCount();

  return GeometryResult{
      .type = generator.GetTriangleType(),
      .vertex_buffer =
          {
              .vertex_buffer = renderer.GetTransientsBuffer().Emplace(
                  count * sizeof(VT), alignof(VT),
                  [&generator](uint8_t* buffer) {
                    auto vertices = reinterpret_cast<VT*>(buffer);
                    generator.GenerateVertices([&vertices](const Point& p) {
                      *vertices++ = {
                          .position = p,
                      };
                    });
                    FML_DCHECK(vertices == reinterpret_cast<VT*>(buffer) +
                                               generator.GetVertexCount());
                  }),
              .vertex_count = count,
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
  };
}

GeometryResult Geometry::ComputePositionUVGeometry(
    const ContentContext& renderer,
    const Tessellator::VertexGenerator& generator,
    const Matrix& uv_transform,
    const Entity& entity,
    RenderPass& pass) {
  using VT = TextureFillVertexShader::PerVertexData;

  size_t count = generator.GetVertexCount();

  return GeometryResult{
      .type = generator.GetTriangleType(),
      .vertex_buffer =
          {
              .vertex_buffer = renderer.GetTransientsBuffer().Emplace(
                  count * sizeof(VT), alignof(VT),
                  [&generator, &uv_transform](uint8_t* buffer) {
                    auto vertices = reinterpret_cast<VT*>(buffer);
                    generator.GenerateVertices(
                        [&vertices, &uv_transform](const Point& p) {  //
                          *vertices++ = {
                              .position = p,
                              .texture_coords = uv_transform * p,
                          };
                        });
                    FML_DCHECK(vertices == reinterpret_cast<VT*>(buffer) +
                                               generator.GetVertexCount());
                  }),
              .vertex_count = count,
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
  };
}

VertexBufferBuilder<TextureFillVertexShader::PerVertexData>
ComputeUVGeometryCPU(
    VertexBufferBuilder<SolidFillVertexShader::PerVertexData>& input,
    Point texture_origin,
    Size texture_coverage,
    Matrix effect_transform) {
  VertexBufferBuilder<TextureFillVertexShader::PerVertexData> vertex_builder;
  vertex_builder.Reserve(input.GetVertexCount());
  input.IterateVertices(
      [&vertex_builder, &texture_coverage, &effect_transform,
       &texture_origin](SolidFillVertexShader::PerVertexData old_vtx) {
        TextureFillVertexShader::PerVertexData data;
        data.position = old_vtx.position;
        data.texture_coords = effect_transform *
                              (old_vtx.position - texture_origin) /
                              texture_coverage;
        vertex_builder.AppendVertex(data);
      });
  return vertex_builder;
}

GeometryResult ComputeUVGeometryForRect(Rect source_rect,
                                        Rect texture_bounds,
                                        Matrix effect_transform,
                                        const ContentContext& renderer,
                                        const Entity& entity,
                                        RenderPass& pass) {
  auto& host_buffer = renderer.GetTransientsBuffer();

  // Calculate UV-specific transform based on texture coverage and effect.
  // For example, if the texture is 100x100 and the effect transform is
  // scaling by 2.0, texture_bounds.GetNormalizingTransform() will result in a
  // Matrix that scales by 0.01, and then if the effect_transform is
  // Matrix::MakeScale(Vector2{2, 2}), the resulting uv_transform will have x
  // and y basis vectors with scale 0.02.
  auto uv_transform = texture_bounds.GetNormalizingTransform() *  //
                      effect_transform;

  // Allocate space for vertex and UV data (4 vertices)
  // 0: position
  // 1: UV
  // 2: position
  // 3: UV
  // etc.
  Point data[8];

  // Get the raw points from the rect and transform them into UV space.
  auto points = source_rect.GetPoints();
  for (auto i = 0u, j = 0u; i < 8; i += 2, j++) {
    // Store original coordinates.
    data[i] = points[j];

    // Store transformed UV coordinates.
    data[i + 1] = uv_transform * points[j];
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(
                  /*buffer=*/data,
                  /*length=*/16 * sizeof(float),
                  /*align=*/alignof(float)),
              .vertex_count = 4,
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
  };
}

GeometryResult Geometry::GetPositionUVBuffer(Rect texture_coverage,
                                             Matrix effect_transform,
                                             const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass) const {
  return {};
}

GeometryResult::Mode Geometry::GetResultMode() const {
  return GeometryResult::Mode::kNormal;
}

std::shared_ptr<Geometry> Geometry::MakeFillPath(
    const Path& path,
    std::optional<Rect> inner_rect) {
  return std::make_shared<FillPathGeometry>(path, inner_rect);
}

std::shared_ptr<Geometry> Geometry::MakePointField(std::vector<Point> points,
                                                   Scalar radius,
                                                   bool round) {
  return std::make_shared<PointFieldGeometry>(std::move(points), radius, round);
}

std::shared_ptr<Geometry> Geometry::MakeStrokePath(const Path& path,
                                                   Scalar stroke_width,
                                                   Scalar miter_limit,
                                                   Cap stroke_cap,
                                                   Join stroke_join) {
  // Skia behaves like this.
  if (miter_limit < 0) {
    miter_limit = 4.0;
  }
  return std::make_shared<StrokePathGeometry>(path, stroke_width, miter_limit,
                                              stroke_cap, stroke_join);
}

std::shared_ptr<Geometry> Geometry::MakeCover() {
  return std::make_shared<CoverGeometry>();
}

std::shared_ptr<Geometry> Geometry::MakeRect(const Rect& rect) {
  return std::make_shared<RectGeometry>(rect);
}

std::shared_ptr<Geometry> Geometry::MakeOval(const Rect& rect) {
  return std::make_shared<EllipseGeometry>(rect);
}

std::shared_ptr<Geometry> Geometry::MakeLine(const Point& p0,
                                             const Point& p1,
                                             Scalar width,
                                             Cap cap) {
  return std::make_shared<LineGeometry>(p0, p1, width, cap);
}

std::shared_ptr<Geometry> Geometry::MakeCircle(const Point& center,
                                               Scalar radius) {
  return std::make_shared<CircleGeometry>(center, radius);
}

std::shared_ptr<Geometry> Geometry::MakeStrokedCircle(const Point& center,
                                                      Scalar radius,
                                                      Scalar stroke_width) {
  return std::make_shared<CircleGeometry>(center, radius, stroke_width);
}

std::shared_ptr<Geometry> Geometry::MakeRoundRect(const Rect& rect,
                                                  const Size& radii) {
  return std::make_shared<RoundRectGeometry>(rect, radii);
}

bool Geometry::CoversArea(const Matrix& transform, const Rect& rect) const {
  return false;
}

bool Geometry::IsAxisAlignedRect() const {
  return false;
}

bool Geometry::CanApplyMaskFilter() const {
  return true;
}

}  // namespace impeller
