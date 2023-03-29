// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry.h"

#include "impeller/core/device_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

Geometry::Geometry() = default;

Geometry::~Geometry() = default;

GeometryResult Geometry::GetPositionUVBuffer(Rect texture_coverage,
                                             Matrix effect_transform,
                                             const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass) {
  return {};
}

// static
std::unique_ptr<Geometry> Geometry::MakeFillPath(const Path& path) {
  return std::make_unique<FillPathGeometry>(path);
}

// static
std::unique_ptr<Geometry> Geometry::MakeRRect(Rect rect, Scalar corner_radius) {
  return std::make_unique<RRectGeometry>(rect, corner_radius);
}

std::unique_ptr<Geometry> Geometry::MakeStrokePath(const Path& path,
                                                   Scalar stroke_width,
                                                   Scalar miter_limit,
                                                   Cap stroke_cap,
                                                   Join stroke_join) {
  // Skia behaves like this.
  if (miter_limit < 0) {
    miter_limit = 4.0;
  }
  return std::make_unique<StrokePathGeometry>(path, stroke_width, miter_limit,
                                              stroke_cap, stroke_join);
}

std::unique_ptr<Geometry> Geometry::MakeCover() {
  return std::make_unique<CoverGeometry>();
}

std::unique_ptr<Geometry> Geometry::MakeRect(Rect rect) {
  return std::make_unique<RectGeometry>(rect);
}

static GeometryResult ComputeUVGeometryForRect(Rect source_rect,
                                               Rect texture_coverage,
                                               Matrix effect_transform,
                                               const ContentContext& renderer,
                                               const Entity& entity,
                                               RenderPass& pass) {
  constexpr uint16_t kRectIndicies[4] = {0, 1, 2, 3};
  auto& host_buffer = pass.GetTransientsBuffer();

  std::vector<Point> data(8);
  auto points = source_rect.GetPoints();
  for (auto i = 0u, j = 0u; i < 8; i += 2, j++) {
    data[i] = points[j];
    data[i + 1] = effect_transform * ((points[j] - texture_coverage.origin) /
                                      texture_coverage.size);
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(
                  data.data(), 16 * sizeof(float), alignof(float)),
              .index_buffer = host_buffer.Emplace(
                  kRectIndicies, 4 * sizeof(uint16_t), alignof(uint16_t)),
              .index_count = 4,
              .index_type = IndexType::k16bit,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

/////// Path Geometry ///////

FillPathGeometry::FillPathGeometry(const Path& path) : path_(path) {}

FillPathGeometry::~FillPathGeometry() = default;

GeometryResult FillPathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  VertexBuffer vertex_buffer;
  auto& host_buffer = pass.GetTransientsBuffer();
  auto tesselation_result = renderer.GetTessellator()->Tessellate(
      path_.GetFillType(),
      path_.CreatePolyline(entity.GetTransformation().GetMaxBasisLength()),
      [&vertex_buffer, &host_buffer](
          const float* vertices, size_t vertices_count, const uint16_t* indices,
          size_t indices_count) {
        vertex_buffer.vertex_buffer = host_buffer.Emplace(
            vertices, vertices_count * sizeof(float), alignof(float));
        vertex_buffer.index_buffer = host_buffer.Emplace(
            indices, indices_count * sizeof(uint16_t), alignof(uint16_t));
        vertex_buffer.index_count = indices_count;
        vertex_buffer.index_type = IndexType::k16bit;
        return true;
      });
  if (tesselation_result != Tessellator::Result::kSuccess) {
    return {};
  }
  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer = vertex_buffer,
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

// |Geometry|
GeometryResult FillPathGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  using VS = TextureFillVertexShader;

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  auto tesselation_result = renderer.GetTessellator()->Tessellate(
      path_.GetFillType(),
      path_.CreatePolyline(entity.GetTransformation().GetMaxBasisLength()),
      [&vertex_builder, &texture_coverage, &effect_transform](
          const float* vertices, size_t vertices_count, const uint16_t* indices,
          size_t indices_count) {
        for (auto i = 0u; i < vertices_count; i += 2) {
          VS::PerVertexData data;
          Point vtx = {vertices[i], vertices[i + 1]};
          data.position = vtx;
          auto coverage_coords =
              ((vtx - texture_coverage.origin) / texture_coverage.size) /
              texture_coverage.size;
          data.texture_coords = effect_transform * coverage_coords;
          vertex_builder.AppendVertex(data);
        }
        FML_DCHECK(vertex_builder.GetVertexCount() == vertices_count / 2);
        for (auto i = 0u; i < indices_count; i++) {
          vertex_builder.AppendIndex(indices[i]);
        }
        return true;
      });
  if (tesselation_result != Tessellator::Result::kSuccess) {
    return {};
  }
  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer =
          vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer()),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryVertexType FillPathGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> FillPathGeometry::GetCoverage(
    const Matrix& transform) const {
  return path_.GetTransformedBoundingBox(transform);
}

///// Stroke Geometry //////

StrokePathGeometry::StrokePathGeometry(const Path& path,
                                       Scalar stroke_width,
                                       Scalar miter_limit,
                                       Cap stroke_cap,
                                       Join stroke_join)
    : path_(path),
      stroke_width_(stroke_width),
      miter_limit_(miter_limit),
      stroke_cap_(stroke_cap),
      stroke_join_(stroke_join) {}

StrokePathGeometry::~StrokePathGeometry() = default;

Scalar StrokePathGeometry::GetStrokeWidth() const {
  return stroke_width_;
}

Scalar StrokePathGeometry::GetMiterLimit() const {
  return miter_limit_;
}

Cap StrokePathGeometry::GetStrokeCap() const {
  return stroke_cap_;
}

Join StrokePathGeometry::GetStrokeJoin() const {
  return stroke_join_;
}

// static
Scalar StrokePathGeometry::CreateBevelAndGetDirection(
    VertexBufferBuilder<SolidFillVertexShader::PerVertexData>& vtx_builder,
    const Point& position,
    const Point& start_offset,
    const Point& end_offset) {
  SolidFillVertexShader::PerVertexData vtx;
  vtx.position = position;
  vtx_builder.AppendVertex(vtx);

  Scalar dir = start_offset.Cross(end_offset) > 0 ? -1 : 1;
  vtx.position = position + start_offset * dir;
  vtx_builder.AppendVertex(vtx);
  vtx.position = position + end_offset * dir;
  vtx_builder.AppendVertex(vtx);

  return dir;
}

// static
StrokePathGeometry::JoinProc StrokePathGeometry::GetJoinProc(Join stroke_join) {
  using VS = SolidFillVertexShader;
  StrokePathGeometry::JoinProc join_proc;
  switch (stroke_join) {
    case Join::kBevel:
      join_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& start_offset,
                     const Point& end_offset, Scalar miter_limit,
                     Scalar scale) {
        CreateBevelAndGetDirection(vtx_builder, position, start_offset,
                                   end_offset);
      };
      break;
    case Join::kMiter:
      join_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& start_offset,
                     const Point& end_offset, Scalar miter_limit,
                     Scalar scale) {
        Point start_normal = start_offset.Normalize();
        Point end_normal = end_offset.Normalize();

        // 1 for no joint (straight line), 0 for max joint (180 degrees).
        Scalar alignment = (start_normal.Dot(end_normal) + 1) / 2;
        if (ScalarNearlyEqual(alignment, 1)) {
          return;
        }

        Scalar dir = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_offset, end_offset);

        Point miter_point = (start_offset + end_offset) / 2 / alignment;
        if (miter_point.GetDistanceSquared({0, 0}) >
            miter_limit * miter_limit) {
          return;  // Convert to bevel when we exceed the miter limit.
        }

        // Outer miter point.
        VS::PerVertexData vtx;
        vtx.position = position + miter_point * dir;
        vtx_builder.AppendVertex(vtx);
      };
      break;
    case Join::kRound:
      join_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& start_offset,
                     const Point& end_offset, Scalar miter_limit,
                     Scalar scale) {
        Point start_normal = start_offset.Normalize();
        Point end_normal = end_offset.Normalize();

        // 0 for no joint (straight line), 1 for max joint (180 degrees).
        Scalar alignment = 1 - (start_normal.Dot(end_normal) + 1) / 2;
        if (ScalarNearlyEqual(alignment, 0)) {
          return;
        }

        Scalar dir = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_offset, end_offset);

        Point middle =
            (start_offset + end_offset).Normalize() * start_offset.GetLength();
        Point middle_normal = middle.Normalize();

        Point middle_handle = middle + Point(-middle.y, middle.x) *
                                           PathBuilder::kArcApproximationMagic *
                                           alignment * dir;
        Point start_handle =
            start_offset + Point(start_offset.y, -start_offset.x) *
                               PathBuilder::kArcApproximationMagic * alignment *
                               dir;

        auto arc_points = CubicPathComponent(start_offset, start_handle,
                                             middle_handle, middle)
                              .CreatePolyline(scale);

        VS::PerVertexData vtx;
        for (const auto& point : arc_points) {
          vtx.position = position + point * dir;
          vtx_builder.AppendVertex(vtx);
          vtx.position = position + (-point * dir).Reflect(middle_normal);
          vtx_builder.AppendVertex(vtx);
        }
      };
      break;
  }
  return join_proc;
}

// static
StrokePathGeometry::CapProc StrokePathGeometry::GetCapProc(Cap stroke_cap) {
  using VS = SolidFillVertexShader;
  StrokePathGeometry::CapProc cap_proc;
  switch (stroke_cap) {
    case Cap::kButt:
      cap_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                    const Point& position, const Point& offset, Scalar scale,
                    bool reverse) {
        Point orientation = offset * (reverse ? -1 : 1);
        VS::PerVertexData vtx;
        vtx.position = position + orientation;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - orientation;
        vtx_builder.AppendVertex(vtx);
      };
      break;
    case Cap::kRound:
      cap_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                    const Point& position, const Point& offset, Scalar scale,
                    bool reverse) {
        Point orientation = offset * (reverse ? -1 : 1);

        VS::PerVertexData vtx;

        Point forward(offset.y, -offset.x);
        Point forward_normal = forward.Normalize();

        CubicPathComponent arc;
        if (reverse) {
          arc = CubicPathComponent(
              forward,
              forward + orientation * PathBuilder::kArcApproximationMagic,
              orientation + forward * PathBuilder::kArcApproximationMagic,
              orientation);
        } else {
          arc = CubicPathComponent(
              orientation,
              orientation + forward * PathBuilder::kArcApproximationMagic,
              forward + orientation * PathBuilder::kArcApproximationMagic,
              forward);
        }

        vtx.position = position + orientation;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - orientation;
        vtx_builder.AppendVertex(vtx);
        for (const auto& point : arc.CreatePolyline(scale)) {
          vtx.position = position + point;
          vtx_builder.AppendVertex(vtx);
          vtx.position = position + (-point).Reflect(forward_normal);
          vtx_builder.AppendVertex(vtx);
        }
      };
      break;
    case Cap::kSquare:
      cap_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                    const Point& position, const Point& offset, Scalar scale,
                    bool reverse) {
        Point orientation = offset * (reverse ? -1 : 1);

        VS::PerVertexData vtx;

        Point forward(offset.y, -offset.x);

        vtx.position = position + orientation;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - orientation;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position + orientation + forward;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - orientation + forward;
        vtx_builder.AppendVertex(vtx);
      };
      break;
  }
  return cap_proc;
}

// static
VertexBufferBuilder<SolidFillVertexShader::PerVertexData>
StrokePathGeometry::CreateSolidStrokeVertices(
    const Path& path,
    Scalar stroke_width,
    Scalar scaled_miter_limit,
    const StrokePathGeometry::JoinProc& join_proc,
    const StrokePathGeometry::CapProc& cap_proc,
    Scalar scale) {
  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  auto polyline = path.CreatePolyline(scale);

  VS::PerVertexData vtx;

  // Offset state.
  Point offset;
  Point previous_offset;  // Used for computing joins.

  auto compute_offset = [&polyline, &offset, &previous_offset,
                         &stroke_width](size_t point_i) {
    previous_offset = offset;
    Point direction =
        (polyline.points[point_i] - polyline.points[point_i - 1]).Normalize();
    offset = Vector2{-direction.y, direction.x} * stroke_width * 0.5;
  };

  for (size_t contour_i = 0; contour_i < polyline.contours.size();
       contour_i++) {
    auto contour = polyline.contours[contour_i];
    size_t contour_start_point_i, contour_end_point_i;
    std::tie(contour_start_point_i, contour_end_point_i) =
        polyline.GetContourPointBounds(contour_i);

    switch (contour_end_point_i - contour_start_point_i) {
      case 1: {
        Point p = polyline.points[contour_start_point_i];
        cap_proc(vtx_builder, p, {-stroke_width * 0.5f, 0}, scale, false);
        cap_proc(vtx_builder, p, {stroke_width * 0.5f, 0}, scale, false);
        continue;
      }
      case 0:
        continue;  // This contour has no renderable content.
      default:
        break;
    }

    // The first point's offset is always the same as the second point.
    compute_offset(contour_start_point_i + 1);
    const Point contour_first_offset = offset;

    if (contour_i > 0) {
      // This branch only executes when we've just finished drawing a contour
      // and are switching to a new one.
      // We're drawing a triangle strip, so we need to "pick up the pen" by
      // appending two vertices at the end of the previous contour and two
      // vertices at the start of the new contour (thus connecting the two
      // contours with two zero volume triangles, which will be discarded by
      // the rasterizer).
      vtx.position = polyline.points[contour_start_point_i - 1];
      // Append two vertices when "picking up" the pen so that the triangle
      // drawn when moving to the beginning of the new contour will have zero
      // volume.
      vtx_builder.AppendVertex(vtx);
      vtx_builder.AppendVertex(vtx);

      vtx.position = polyline.points[contour_start_point_i];
      // Append two vertices at the beginning of the new contour, which
      // appends  two triangles of zero area.
      vtx_builder.AppendVertex(vtx);
      vtx_builder.AppendVertex(vtx);
    }

    // Generate start cap.
    if (!polyline.contours[contour_i].is_closed) {
      auto cap_offset =
          Vector2(-contour.start_direction.y, contour.start_direction.x) *
          stroke_width * 0.5;  // Counterclockwise normal
      cap_proc(vtx_builder, polyline.points[contour_start_point_i], cap_offset,
               scale, true);
    }

    // Generate contour geometry.
    for (size_t point_i = contour_start_point_i + 1;
         point_i < contour_end_point_i; point_i++) {
      // Generate line rect.
      vtx.position = polyline.points[point_i - 1] + offset;
      vtx_builder.AppendVertex(vtx);
      vtx.position = polyline.points[point_i - 1] - offset;
      vtx_builder.AppendVertex(vtx);
      vtx.position = polyline.points[point_i] + offset;
      vtx_builder.AppendVertex(vtx);
      vtx.position = polyline.points[point_i] - offset;
      vtx_builder.AppendVertex(vtx);

      if (point_i < contour_end_point_i - 1) {
        compute_offset(point_i + 1);

        // Generate join from the current line to the next line.
        join_proc(vtx_builder, polyline.points[point_i], previous_offset,
                  offset, scaled_miter_limit, scale);
      }
    }

    // Generate end cap or join.
    if (!polyline.contours[contour_i].is_closed) {
      auto cap_offset =
          Vector2(-contour.end_direction.y, contour.end_direction.x) *
          stroke_width * 0.5;  // Clockwise normal
      cap_proc(vtx_builder, polyline.points[contour_end_point_i - 1],
               cap_offset, scale, false);
    } else {
      join_proc(vtx_builder, polyline.points[contour_start_point_i], offset,
                contour_first_offset, scaled_miter_limit, scale);
    }
  }

  return vtx_builder;
}

GeometryResult StrokePathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  if (stroke_width_ < 0.0) {
    return {};
  }
  auto determinant = entity.GetTransformation().GetDeterminant();
  if (determinant == 0) {
    return {};
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar stroke_width = std::max(stroke_width_, min_size);

  auto& host_buffer = pass.GetTransientsBuffer();
  auto vertex_builder = CreateSolidStrokeVertices(
      path_, stroke_width, miter_limit_ * stroke_width_ * 0.5,
      GetJoinProc(stroke_join_), GetCapProc(stroke_cap_),
      entity.GetTransformation().GetMaxBasisLength());

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer = vertex_builder.CreateVertexBuffer(host_buffer),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = true,
  };
}

GeometryResult StrokePathGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  if (stroke_width_ < 0.0) {
    return {};
  }
  auto determinant = entity.GetTransformation().GetDeterminant();
  if (determinant == 0) {
    return {};
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar stroke_width = std::max(stroke_width_, min_size);

  auto& host_buffer = pass.GetTransientsBuffer();
  auto stroke_builder = CreateSolidStrokeVertices(
      path_, stroke_width, miter_limit_ * stroke_width_ * 0.5,
      GetJoinProc(stroke_join_), GetCapProc(stroke_cap_),
      entity.GetTransformation().GetMaxBasisLength());

  VertexBufferBuilder<TextureFillVertexShader::PerVertexData> vertex_builder;
  stroke_builder.IterateVertices(
      [&vertex_builder, &texture_coverage,
       &effect_transform](SolidFillVertexShader::PerVertexData old_vtx) {
        TextureFillVertexShader::PerVertexData data;
        data.position = old_vtx.position;
        auto coverage_coords = (old_vtx.position - texture_coverage.origin) /
                               texture_coverage.size;
        data.texture_coords = effect_transform * coverage_coords;
        vertex_builder.AppendVertex(data);
      });

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer = vertex_builder.CreateVertexBuffer(host_buffer),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = true,
  };
}

GeometryVertexType StrokePathGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> StrokePathGeometry::GetCoverage(
    const Matrix& transform) const {
  auto path_bounds = path_.GetBoundingBox();
  if (!path_bounds.has_value()) {
    return std::nullopt;
  }
  auto path_coverage = path_bounds->TransformBounds(transform);

  Scalar max_radius = 0.5;
  if (stroke_cap_ == Cap::kSquare) {
    max_radius = max_radius * kSqrt2;
  }
  if (stroke_join_ == Join::kMiter) {
    max_radius = std::max(max_radius, miter_limit_ * 0.5f);
  }
  Scalar determinant = transform.GetDeterminant();
  if (determinant == 0) {
    return std::nullopt;
  }
  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Vector2 max_radius_xy = transform.TransformDirection(
      Vector2(max_radius, max_radius) * std::max(stroke_width_, min_size));

  return Rect(path_coverage.origin - max_radius_xy,
              Size(path_coverage.size.width + max_radius_xy.x * 2,
                   path_coverage.size.height + max_radius_xy.y * 2));
}

/////// Cover Geometry ///////

CoverGeometry::CoverGeometry() = default;

CoverGeometry::~CoverGeometry() = default;

GeometryResult CoverGeometry::GetPositionBuffer(const ContentContext& renderer,
                                                const Entity& entity,
                                                RenderPass& pass) {
  auto rect = Rect(Size(pass.GetRenderTargetSize()));
  constexpr uint16_t kRectIndicies[4] = {0, 1, 2, 3};
  auto& host_buffer = pass.GetTransientsBuffer();
  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(
                  rect.GetPoints().data(), 8 * sizeof(float), alignof(float)),
              .index_buffer = host_buffer.Emplace(
                  kRectIndicies, 4 * sizeof(uint16_t), alignof(uint16_t)),
              .index_count = 4,
              .index_type = IndexType::k16bit,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()),
      .prevent_overdraw = false,
  };
}

// |Geometry|
GeometryResult CoverGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  auto rect = Rect(Size(pass.GetRenderTargetSize()));
  return ComputeUVGeometryForRect(rect, texture_coverage, effect_transform,
                                  renderer, entity, pass);
}

GeometryVertexType CoverGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> CoverGeometry::GetCoverage(const Matrix& transform) const {
  return Rect::MakeMaximum();
}

/////// Rect Geometry ///////

RectGeometry::RectGeometry(Rect rect) : rect_(rect) {}

RectGeometry::~RectGeometry() = default;

GeometryResult RectGeometry::GetPositionBuffer(const ContentContext& renderer,
                                               const Entity& entity,
                                               RenderPass& pass) {
  constexpr uint16_t kRectIndicies[4] = {0, 1, 2, 3};
  auto& host_buffer = pass.GetTransientsBuffer();
  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(
                  rect_.GetPoints().data(), 8 * sizeof(float), alignof(float)),
              .index_buffer = host_buffer.Emplace(
                  kRectIndicies, 4 * sizeof(uint16_t), alignof(uint16_t)),
              .index_count = 4,
              .index_type = IndexType::k16bit,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

// |Geometry|
GeometryResult RectGeometry::GetPositionUVBuffer(Rect texture_coverage,
                                                 Matrix effect_transform,
                                                 const ContentContext& renderer,
                                                 const Entity& entity,
                                                 RenderPass& pass) {
  return ComputeUVGeometryForRect(rect_, texture_coverage, effect_transform,
                                  renderer, entity, pass);
}

GeometryVertexType RectGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> RectGeometry::GetCoverage(const Matrix& transform) const {
  return rect_.TransformBounds(transform);
}

/////// RRect Geometry ///////

RRectGeometry::RRectGeometry(Rect rect, Scalar corner_radius)
    : rect_(rect), corner_radius_(corner_radius) {}

RRectGeometry::~RRectGeometry() = default;

static void AppendRRectCorner(Path::Polyline polyline,
                              Point corner,
                              VertexBufferBuilder<Point>& vtx_builder) {
  for (auto i = 1u; i < polyline.points.size(); i++) {
    vtx_builder.AddVertices({
        polyline.points[i - 1],
        polyline.points[i],
        corner,
    });
  }
}

VertexBufferBuilder<Point> RRectGeometry::CreatePositionBuffer(
    const Entity& entity) const {
  VertexBufferBuilder<Point> vtx_builder;

  // The rounded rectangle is split into parts:
  //  * four corner sections defined by an arc
  //  * An interior shape composed of three rectangles.

  auto left = rect_.GetLeft();
  auto right = rect_.GetRight();
  auto bottom = rect_.GetBottom();
  auto top = rect_.GetTop();
  auto radii = PathBuilder::RoundingRadii(corner_radius_, corner_radius_,
                                          corner_radius_, corner_radius_);

  auto topLeft =
      PathBuilder{}
          .MoveTo({rect_.origin.x, rect_.origin.y + corner_radius_})
          .AddRoundedRectTopLeft(rect_, radii)
          .TakePath()
          .CreatePolyline(entity.GetTransformation().GetMaxBasisLength());
  auto topRight =
      PathBuilder{}
          .MoveTo({right - radii.top_right.x, rect_.origin.y})
          .AddRoundedRectTopRight(rect_, radii)
          .TakePath()
          .CreatePolyline(entity.GetTransformation().GetMaxBasisLength());
  auto bottomLeft =
      PathBuilder{}
          .MoveTo({left + corner_radius_, bottom})
          .AddRoundedRectBottomLeft(rect_, radii)
          .TakePath()
          .CreatePolyline(entity.GetTransformation().GetMaxBasisLength());
  auto bottomRight =
      PathBuilder{}
          .MoveTo({right, bottom - corner_radius_})
          .AddRoundedRectBottomRight(rect_, radii)
          .TakePath()
          .CreatePolyline(entity.GetTransformation().GetMaxBasisLength());

  vtx_builder.Reserve(12 * (topLeft.points.size() - 1) + 18);

  AppendRRectCorner(topLeft, Point(left + corner_radius_, top + corner_radius_),
                    vtx_builder);

  AppendRRectCorner(topRight,
                    Point(right - corner_radius_, top + corner_radius_),
                    vtx_builder);

  AppendRRectCorner(bottomLeft,
                    Point(left + corner_radius_, bottom - corner_radius_),
                    vtx_builder);

  AppendRRectCorner(bottomRight,
                    Point(right - corner_radius_, bottom - corner_radius_),
                    vtx_builder);
  vtx_builder.AddVertices({
      // Top Component.
      Point(left + corner_radius_, top + corner_radius_),
      Point(left + corner_radius_, top),
      Point(right - corner_radius_, top + corner_radius_),

      Point(left + corner_radius_, top),
      Point(right - corner_radius_, top + corner_radius_),
      Point(right - corner_radius_, top),

      // Bottom Component.
      Point(left + corner_radius_, bottom - corner_radius_),
      Point(left + corner_radius_, bottom),
      Point(right - corner_radius_, bottom - corner_radius_),

      Point(left + corner_radius_, bottom),
      Point(right - corner_radius_, bottom - corner_radius_),
      Point(right - corner_radius_, bottom),

      // // Center Component.
      Point(left, top + corner_radius_),
      Point(right, top + corner_radius_),
      Point(right, bottom - corner_radius_),

      Point(left, top + corner_radius_),
      Point(left, bottom - corner_radius_),
      Point(right, bottom - corner_radius_),
  });

  return vtx_builder;
}

GeometryResult RRectGeometry::GetPositionBuffer(const ContentContext& renderer,
                                                const Entity& entity,
                                                RenderPass& pass) {
  auto vtx_builder = CreatePositionBuffer(entity);

  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer =
          vtx_builder.CreateVertexBuffer(pass.GetTransientsBuffer()),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryResult RRectGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  auto vtx_builder = CreatePositionBuffer(entity);

  VertexBufferBuilder<TextureFillVertexShader::PerVertexData> vertex_builder;
  vtx_builder.IterateVertices(
      [&vertex_builder, &texture_coverage, &effect_transform](Point position) {
        TextureFillVertexShader::PerVertexData data;
        data.position = position;
        auto coverage_coords =
            (position - texture_coverage.origin) / texture_coverage.size;
        data.texture_coords = effect_transform * coverage_coords;
        vertex_builder.AppendVertex(data);
      });

  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer =
          vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer()),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = true,
  };
}

GeometryVertexType RRectGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> RRectGeometry::GetCoverage(const Matrix& transform) const {
  return rect_.TransformBounds(transform);
}

}  // namespace impeller
