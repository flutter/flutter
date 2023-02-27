// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/device_buffer.h"
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
                    const Point& position, const Point& offset, Scalar scale) {
        VS::PerVertexData vtx;
        vtx.position = position + offset;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - offset;
        vtx_builder.AppendVertex(vtx);
      };
      break;
    case Cap::kRound:
      cap_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                    const Point& position, const Point& offset, Scalar scale) {
        VS::PerVertexData vtx;

        Point forward(offset.y, -offset.x);
        Point forward_normal = forward.Normalize();

        auto arc_points =
            CubicPathComponent(
                offset, offset + forward * PathBuilder::kArcApproximationMagic,
                forward + offset * PathBuilder::kArcApproximationMagic, forward)
                .CreatePolyline(scale);

        vtx.position = position + offset;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - offset;
        vtx_builder.AppendVertex(vtx);
        for (const auto& point : arc_points) {
          vtx.position = position + point;
          vtx_builder.AppendVertex(vtx);
          vtx.position = position + (-point).Reflect(forward_normal);
          vtx_builder.AppendVertex(vtx);
        }
      };
      break;
    case Cap::kSquare:
      cap_proc = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                    const Point& position, const Point& offset, Scalar scale) {
        VS::PerVertexData vtx;

        Point forward(offset.y, -offset.x);

        vtx.position = position + offset;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - offset;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position + offset + forward;
        vtx_builder.AppendVertex(vtx);
        vtx.position = position - offset + forward;
        vtx_builder.AppendVertex(vtx);
      };
      break;
  }
  return cap_proc;
}

// static
VertexBuffer StrokePathGeometry::CreateSolidStrokeVertices(
    const Path& path,
    HostBuffer& buffer,
    Scalar stroke_width,
    Scalar scaled_miter_limit,
    Cap cap,
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
        cap_proc(vtx_builder, p, {-stroke_width * 0.5f, 0}, scale);
        cap_proc(vtx_builder, p, {stroke_width * 0.5f, 0}, scale);
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
      Vector2 direction;
      if (cap == Cap::kButt) {
        direction =
            Vector2(contour.start_direction.y, -contour.start_direction.x);
      } else {
        direction =
            Vector2(-contour.start_direction.y, contour.start_direction.x);
      }
      auto cap_offset = direction * stroke_width * 0.5;
      cap_proc(vtx_builder, polyline.points[contour_start_point_i], cap_offset,
               scale);
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
          stroke_width * 0.5;
      cap_proc(vtx_builder, polyline.points[contour_end_point_i - 1],
               cap_offset, scale);
    } else {
      join_proc(vtx_builder, polyline.points[contour_start_point_i], offset,
                contour_first_offset, scaled_miter_limit, scale);
    }
  }

  return vtx_builder.CreateVertexBuffer(buffer);
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
  auto vertex_buffer = CreateSolidStrokeVertices(
      path_, host_buffer, stroke_width, miter_limit_ * stroke_width_ * 0.5,
      stroke_cap_, GetJoinProc(stroke_join_), GetCapProc(stroke_cap_),
      entity.GetTransformation().GetMaxBasisLength());

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer = vertex_buffer,
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

GeometryVertexType RectGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> RectGeometry::GetCoverage(const Matrix& transform) const {
  return rect_.TransformBounds(transform);
}

}  // namespace impeller
