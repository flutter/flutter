// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/stroke_path_geometry.h"

#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/path_component.h"

namespace impeller {
using VS = SolidFillVertexShader;

namespace {

template <typename VertexWriter>
using CapProc = std::function<void(VertexWriter& vtx_builder,
                                   const Point& position,
                                   const Point& offset,
                                   Scalar scale,
                                   bool reverse)>;

template <typename VertexWriter>
using JoinProc = std::function<void(VertexWriter& vtx_builder,
                                    const Point& position,
                                    const Point& start_offset,
                                    const Point& end_offset,
                                    Scalar miter_limit,
                                    Scalar scale)>;

class PositionWriter {
 public:
  void AppendVertex(const Point& point) {
    data_.emplace_back(SolidFillVertexShader::PerVertexData{.position = point});
  }

  const std::vector<SolidFillVertexShader::PerVertexData>& GetData() const {
    return data_;
  }

 private:
  std::vector<SolidFillVertexShader::PerVertexData> data_ = {};
};

class PositionUVWriter {
 public:
  PositionUVWriter(const Point& texture_origin,
                   const Size& texture_size,
                   const Matrix& effect_transform)
      : texture_origin_(texture_origin),
        texture_size_(texture_size),
        effect_transform_(effect_transform) {}

  const std::vector<TextureFillVertexShader::PerVertexData>& GetData() {
    if (effect_transform_.IsIdentity()) {
      auto origin = texture_origin_;
      auto scale = 1.0 / texture_size_;

      for (auto& pvd : data_) {
        pvd.texture_coords = (pvd.position - origin) * scale;
      }
    } else {
      auto texture_rect = Rect::MakeOriginSize(texture_origin_, texture_size_);
      Matrix uv_transform =
          texture_rect.GetNormalizingTransform() * effect_transform_;

      for (auto& pvd : data_) {
        pvd.texture_coords = uv_transform * pvd.position;
      }
    }
    return data_;
  }

  void AppendVertex(const Point& point) {
    data_.emplace_back(TextureFillVertexShader::PerVertexData{
        .position = point,
        // .texture_coords = default, will be filled in during |GetData()|
    });
  }

 private:
  std::vector<TextureFillVertexShader::PerVertexData> data_ = {};
  const Point texture_origin_;
  const Size texture_size_;
  const Matrix effect_transform_;
};

template <typename VertexWriter>
class StrokeGenerator {
 public:
  StrokeGenerator(const Path::Polyline& p_polyline,
                  const Scalar p_stroke_width,
                  const Scalar p_scaled_miter_limit,
                  const JoinProc<VertexWriter>& p_join_proc,
                  const CapProc<VertexWriter>& p_cap_proc,
                  const Scalar p_scale)
      : polyline(p_polyline),
        stroke_width(p_stroke_width),
        scaled_miter_limit(p_scaled_miter_limit),
        join_proc(p_join_proc),
        cap_proc(p_cap_proc),
        scale(p_scale) {}

  void Generate(VertexWriter& vtx_builder) {
    for (size_t contour_i = 0; contour_i < polyline.contours.size();
         contour_i++) {
      const Path::PolylineContour& contour = polyline.contours[contour_i];
      size_t contour_start_point_i, contour_end_point_i;
      std::tie(contour_start_point_i, contour_end_point_i) =
          polyline.GetContourPointBounds(contour_i);

      auto contour_delta = contour_end_point_i - contour_start_point_i;
      if (contour_delta == 1) {
        Point p = polyline.GetPoint(contour_start_point_i);
        cap_proc(vtx_builder, p, {-stroke_width * 0.5f, 0}, scale,
                 /*reverse=*/false);
        cap_proc(vtx_builder, p, {stroke_width * 0.5f, 0}, scale,
                 /*reverse=*/false);
        continue;
      } else if (contour_delta == 0) {
        continue;  // This contour has no renderable content.
      }

      previous_offset = offset;
      offset = ComputeOffset(contour_start_point_i, contour_start_point_i,
                             contour_end_point_i, contour);
      const Point contour_first_offset = offset;

      if (contour_i > 0) {
        // This branch only executes when we've just finished drawing a contour
        // and are switching to a new one.
        // We're drawing a triangle strip, so we need to "pick up the pen" by
        // appending two vertices at the end of the previous contour and two
        // vertices at the start of the new contour (thus connecting the two
        // contours with two zero volume triangles, which will be discarded by
        // the rasterizer).
        vtx.position = polyline.GetPoint(contour_start_point_i - 1);
        // Append two vertices when "picking up" the pen so that the triangle
        // drawn when moving to the beginning of the new contour will have zero
        // volume.
        vtx_builder.AppendVertex(vtx.position);
        vtx_builder.AppendVertex(vtx.position);

        vtx.position = polyline.GetPoint(contour_start_point_i);
        // Append two vertices at the beginning of the new contour, which
        // appends  two triangles of zero area.
        vtx_builder.AppendVertex(vtx.position);
        vtx_builder.AppendVertex(vtx.position);
      }

      // Generate start cap.
      if (!polyline.contours[contour_i].is_closed) {
        Point cap_offset =
            Vector2(-contour.start_direction.y, contour.start_direction.x) *
            stroke_width * 0.5f;  // Counterclockwise normal
        cap_proc(vtx_builder, polyline.GetPoint(contour_start_point_i),
                 cap_offset, scale, /*reverse=*/true);
      }

      for (size_t contour_component_i = 0;
           contour_component_i < contour.components.size();
           contour_component_i++) {
        const Path::PolylineContour::Component& component =
            contour.components[contour_component_i];
        bool is_last_component =
            contour_component_i == contour.components.size() - 1;

        size_t component_start_index = component.component_start_index;
        size_t component_end_index =
            is_last_component ? contour_end_point_i - 1
                              : contour.components[contour_component_i + 1]
                                    .component_start_index;
        if (component.is_curve) {
          AddVerticesForCurveComponent(
              vtx_builder, component_start_index, component_end_index,
              contour_start_point_i, contour_end_point_i, contour);
        } else {
          AddVerticesForLinearComponent(
              vtx_builder, component_start_index, component_end_index,
              contour_start_point_i, contour_end_point_i, contour);
        }
      }

      // Generate end cap or join.
      if (!contour.is_closed) {
        auto cap_offset =
            Vector2(-contour.end_direction.y, contour.end_direction.x) *
            stroke_width * 0.5f;  // Clockwise normal
        cap_proc(vtx_builder, polyline.GetPoint(contour_end_point_i - 1),
                 cap_offset, scale, /*reverse=*/false);
      } else {
        join_proc(vtx_builder, polyline.GetPoint(contour_start_point_i), offset,
                  contour_first_offset, scaled_miter_limit, scale);
      }
    }
  }

  /// Computes offset by calculating the direction from point_i - 1 to point_i
  /// if point_i is within `contour_start_point_i` and `contour_end_point_i`;
  /// Otherwise, it uses direction from contour.
  Point ComputeOffset(const size_t point_i,
                      const size_t contour_start_point_i,
                      const size_t contour_end_point_i,
                      const Path::PolylineContour& contour) const {
    Point direction;
    if (point_i >= contour_end_point_i) {
      direction = contour.end_direction;
    } else if (point_i <= contour_start_point_i) {
      direction = -contour.start_direction;
    } else {
      direction = (polyline.GetPoint(point_i) - polyline.GetPoint(point_i - 1))
                      .Normalize();
    }
    return Vector2{-direction.y, direction.x} * stroke_width * 0.5f;
  }

  void AddVerticesForLinearComponent(VertexWriter& vtx_builder,
                                     const size_t component_start_index,
                                     const size_t component_end_index,
                                     const size_t contour_start_point_i,
                                     const size_t contour_end_point_i,
                                     const Path::PolylineContour& contour) {
    bool is_last_component = component_start_index ==
                             contour.components.back().component_start_index;

    for (size_t point_i = component_start_index; point_i < component_end_index;
         point_i++) {
      bool is_end_of_component = point_i == component_end_index - 1;
      vtx.position = polyline.GetPoint(point_i) + offset;
      vtx_builder.AppendVertex(vtx.position);
      vtx.position = polyline.GetPoint(point_i) - offset;
      vtx_builder.AppendVertex(vtx.position);

      // For line components, two additional points need to be appended
      // prior to appending a join connecting the next component.
      vtx.position = polyline.GetPoint(point_i + 1) + offset;
      vtx_builder.AppendVertex(vtx.position);
      vtx.position = polyline.GetPoint(point_i + 1) - offset;
      vtx_builder.AppendVertex(vtx.position);

      previous_offset = offset;
      offset = ComputeOffset(point_i + 2, contour_start_point_i,
                             contour_end_point_i, contour);
      if (!is_last_component && is_end_of_component) {
        // Generate join from the current line to the next line.
        join_proc(vtx_builder, polyline.GetPoint(point_i + 1), previous_offset,
                  offset, scaled_miter_limit, scale);
      }
    }
  }

  void AddVerticesForCurveComponent(VertexWriter& vtx_builder,
                                    const size_t component_start_index,
                                    const size_t component_end_index,
                                    const size_t contour_start_point_i,
                                    const size_t contour_end_point_i,
                                    const Path::PolylineContour& contour) {
    bool is_last_component = component_start_index ==
                             contour.components.back().component_start_index;

    for (size_t point_i = component_start_index; point_i < component_end_index;
         point_i++) {
      bool is_end_of_component = point_i == component_end_index - 1;

      vtx.position = polyline.GetPoint(point_i) + offset;
      vtx_builder.AppendVertex(vtx.position);
      vtx.position = polyline.GetPoint(point_i) - offset;
      vtx_builder.AppendVertex(vtx.position);

      previous_offset = offset;
      offset = ComputeOffset(point_i + 2, contour_start_point_i,
                             contour_end_point_i, contour);
      // For curve components, the polyline is detailed enough such that
      // it can avoid worrying about joins altogether.
      if (is_end_of_component) {
        vtx.position = polyline.GetPoint(point_i + 1) + offset;
        vtx_builder.AppendVertex(vtx.position);
        vtx.position = polyline.GetPoint(point_i + 1) - offset;
        vtx_builder.AppendVertex(vtx.position);
        // Generate join from the current line to the next line.
        if (!is_last_component) {
          join_proc(vtx_builder, polyline.GetPoint(point_i + 1),
                    previous_offset, offset, scaled_miter_limit, scale);
        }
      }
    }
  }

  const Path::Polyline& polyline;
  const Scalar stroke_width;
  const Scalar scaled_miter_limit;
  const JoinProc<VertexWriter>& join_proc;
  const CapProc<VertexWriter>& cap_proc;
  const Scalar scale;

  Point previous_offset;
  Point offset;
  SolidFillVertexShader::PerVertexData vtx;
};

template <typename VertexWriter>
void CreateButtCap(VertexWriter& vtx_builder,
                   const Point& position,
                   const Point& offset,
                   Scalar scale,
                   bool reverse) {
  Point orientation = offset * (reverse ? -1 : 1);
  VS::PerVertexData vtx;
  vtx.position = position + orientation;
  vtx_builder.AppendVertex(vtx.position);
  vtx.position = position - orientation;
  vtx_builder.AppendVertex(vtx.position);
}

template <typename VertexWriter>
void CreateRoundCap(VertexWriter& vtx_builder,
                    const Point& position,
                    const Point& offset,
                    Scalar scale,
                    bool reverse) {
  Point orientation = offset * (reverse ? -1 : 1);
  Point forward(offset.y, -offset.x);
  Point forward_normal = forward.Normalize();

  CubicPathComponent arc;
  if (reverse) {
    arc = CubicPathComponent(
        forward, forward + orientation * PathBuilder::kArcApproximationMagic,
        orientation + forward * PathBuilder::kArcApproximationMagic,
        orientation);
  } else {
    arc = CubicPathComponent(
        orientation,
        orientation + forward * PathBuilder::kArcApproximationMagic,
        forward + orientation * PathBuilder::kArcApproximationMagic, forward);
  }

  Point vtx = position + orientation;
  vtx_builder.AppendVertex(vtx);
  vtx = position - orientation;
  vtx_builder.AppendVertex(vtx);

  arc.ToLinearPathComponents(scale, [&vtx_builder, &vtx, forward_normal,
                                     position](const Point& point) {
    vtx = position + point;
    vtx_builder.AppendVertex(vtx);
    vtx = position + (-point).Reflect(forward_normal);
    vtx_builder.AppendVertex(vtx);
  });
}

template <typename VertexWriter>
void CreateSquareCap(VertexWriter& vtx_builder,
                     const Point& position,
                     const Point& offset,
                     Scalar scale,
                     bool reverse) {
  Point orientation = offset * (reverse ? -1 : 1);
  Point forward(offset.y, -offset.x);

  Point vtx = position + orientation;
  vtx_builder.AppendVertex(vtx);
  vtx = position - orientation;
  vtx_builder.AppendVertex(vtx);
  vtx = position + orientation + forward;
  vtx_builder.AppendVertex(vtx);
  vtx = position - orientation + forward;
  vtx_builder.AppendVertex(vtx);
}

template <typename VertexWriter>
Scalar CreateBevelAndGetDirection(VertexWriter& vtx_builder,
                                  const Point& position,
                                  const Point& start_offset,
                                  const Point& end_offset) {
  Point vtx = position;
  vtx_builder.AppendVertex(vtx);

  Scalar dir = start_offset.Cross(end_offset) > 0 ? -1 : 1;
  vtx = position + start_offset * dir;
  vtx_builder.AppendVertex(vtx);
  vtx = position + end_offset * dir;
  vtx_builder.AppendVertex(vtx);

  return dir;
}

template <typename VertexWriter>
void CreateMiterJoin(VertexWriter& vtx_builder,
                     const Point& position,
                     const Point& start_offset,
                     const Point& end_offset,
                     Scalar miter_limit,
                     Scalar scale) {
  Point start_normal = start_offset.Normalize();
  Point end_normal = end_offset.Normalize();

  // 1 for no joint (straight line), 0 for max joint (180 degrees).
  Scalar alignment = (start_normal.Dot(end_normal) + 1) / 2;
  if (ScalarNearlyEqual(alignment, 1)) {
    return;
  }

  Scalar direction = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_offset, end_offset);

  Point miter_point = (((start_offset + end_offset) / 2) / alignment);
  if (miter_point.GetDistanceSquared({0, 0}) > miter_limit * miter_limit) {
    return;  // Convert to bevel when we exceed the miter limit.
  }

  // Outer miter point.
  VS::PerVertexData vtx;
  vtx.position = position + miter_point * direction;
  vtx_builder.AppendVertex(vtx.position);
}

template <typename VertexWriter>
void CreateRoundJoin(VertexWriter& vtx_builder,
                     const Point& position,
                     const Point& start_offset,
                     const Point& end_offset,
                     Scalar miter_limit,
                     Scalar scale) {
  Point start_normal = start_offset.Normalize();
  Point end_normal = end_offset.Normalize();

  // 0 for no joint (straight line), 1 for max joint (180 degrees).
  Scalar alignment = 1 - (start_normal.Dot(end_normal) + 1) / 2;
  if (ScalarNearlyEqual(alignment, 0)) {
    return;
  }

  Scalar direction = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_offset, end_offset);

  Point middle =
      (start_offset + end_offset).Normalize() * start_offset.GetLength();
  Point middle_normal = middle.Normalize();

  Point middle_handle = middle + Point(-middle.y, middle.x) *
                                     PathBuilder::kArcApproximationMagic *
                                     alignment * direction;
  Point start_handle = start_offset + Point(start_offset.y, -start_offset.x) *
                                          PathBuilder::kArcApproximationMagic *
                                          alignment * direction;

  VS::PerVertexData vtx;
  CubicPathComponent(start_offset, start_handle, middle_handle, middle)
      .ToLinearPathComponents(scale, [&vtx_builder, direction, &vtx, position,
                                      middle_normal](const Point& point) {
        vtx.position = position + point * direction;
        vtx_builder.AppendVertex(vtx.position);
        vtx.position = position + (-point * direction).Reflect(middle_normal);
        vtx_builder.AppendVertex(vtx.position);
      });
}

template <typename VertexWriter>
void CreateBevelJoin(VertexWriter& vtx_builder,
                     const Point& position,
                     const Point& start_offset,
                     const Point& end_offset,
                     Scalar miter_limit,
                     Scalar scale) {
  CreateBevelAndGetDirection(vtx_builder, position, start_offset, end_offset);
}

template <typename VertexWriter>
void CreateSolidStrokeVertices(VertexWriter& vtx_builder,
                               const Path::Polyline& polyline,
                               Scalar stroke_width,
                               Scalar scaled_miter_limit,
                               const JoinProc<VertexWriter>& join_proc,
                               const CapProc<VertexWriter>& cap_proc,
                               Scalar scale) {
  StrokeGenerator stroke_generator(polyline, stroke_width, scaled_miter_limit,
                                   join_proc, cap_proc, scale);
  stroke_generator.Generate(vtx_builder);
}

// static
template <typename VertexWriter>
JoinProc<VertexWriter> GetJoinProc(Join stroke_join) {
  switch (stroke_join) {
    case Join::kBevel:
      return &CreateBevelJoin<VertexWriter>;
    case Join::kMiter:
      return &CreateMiterJoin<VertexWriter>;
    case Join::kRound:
      return &CreateRoundJoin<VertexWriter>;
  }
}

template <typename VertexWriter>
CapProc<VertexWriter> GetCapProc(Cap stroke_cap) {
  switch (stroke_cap) {
    case Cap::kButt:
      return &CreateButtCap<VertexWriter>;
    case Cap::kRound:
      return &CreateRoundCap<VertexWriter>;
    case Cap::kSquare:
      return &CreateSquareCap<VertexWriter>;
  }
}
}  // namespace

std::vector<SolidFillVertexShader::PerVertexData>
StrokePathGeometry::GenerateSolidStrokeVertices(const Path::Polyline& polyline,
                                                Scalar stroke_width,
                                                Scalar miter_limit,
                                                Join stroke_join,
                                                Cap stroke_cap,
                                                Scalar scale) {
  auto scaled_miter_limit = stroke_width * miter_limit * 0.5f;
  auto join_proc = GetJoinProc<PositionWriter>(stroke_join);
  auto cap_proc = GetCapProc<PositionWriter>(stroke_cap);
  StrokeGenerator stroke_generator(polyline, stroke_width, scaled_miter_limit,
                                   join_proc, cap_proc, scale);
  PositionWriter vtx_builder;
  stroke_generator.Generate(vtx_builder);
  return vtx_builder.GetData();
}

std::vector<TextureFillVertexShader::PerVertexData>
StrokePathGeometry::GenerateSolidStrokeVerticesUV(
    const Path::Polyline& polyline,
    Scalar stroke_width,
    Scalar miter_limit,
    Join stroke_join,
    Cap stroke_cap,
    Scalar scale,
    Point texture_origin,
    Size texture_size,
    const Matrix& effect_transform) {
  auto scaled_miter_limit = stroke_width * miter_limit * 0.5f;
  auto join_proc = GetJoinProc<PositionUVWriter>(stroke_join);
  auto cap_proc = GetCapProc<PositionUVWriter>(stroke_cap);
  StrokeGenerator stroke_generator(polyline, stroke_width, scaled_miter_limit,
                                   join_proc, cap_proc, scale);
  PositionUVWriter vtx_builder(texture_origin, texture_size, effect_transform);
  stroke_generator.Generate(vtx_builder);
  return vtx_builder.GetData();
}

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

GeometryResult StrokePathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (stroke_width_ < 0.0) {
    return {};
  }
  auto determinant = entity.GetTransform().GetDeterminant();
  if (determinant == 0) {
    return {};
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar stroke_width = std::max(stroke_width_, min_size);

  auto& host_buffer = renderer.GetTransientsBuffer();
  auto scale = entity.GetTransform().GetMaxBasisLength();

  PositionWriter position_writer;
  auto polyline = renderer.GetTessellator()->CreateTempPolyline(path_, scale);
  CreateSolidStrokeVertices(position_writer, polyline, stroke_width,
                            miter_limit_ * stroke_width_ * 0.5f,
                            GetJoinProc<PositionWriter>(stroke_join_),
                            GetCapProc<PositionWriter>(stroke_cap_), scale);

  BufferView buffer_view =
      host_buffer.Emplace(position_writer.GetData().data(),
                          position_writer.GetData().size() *
                              sizeof(SolidFillVertexShader::PerVertexData),
                          alignof(SolidFillVertexShader::PerVertexData));

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = buffer_view,
              .vertex_count = position_writer.GetData().size(),
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
      .mode = GeometryResult::Mode::kPreventOverdraw,
  };
}

GeometryResult StrokePathGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (stroke_width_ < 0.0) {
    return {};
  }
  auto determinant = entity.GetTransform().GetDeterminant();
  if (determinant == 0) {
    return {};
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar stroke_width = std::max(stroke_width_, min_size);

  auto& host_buffer = renderer.GetTransientsBuffer();
  auto scale = entity.GetTransform().GetMaxBasisLength();
  auto polyline = renderer.GetTessellator()->CreateTempPolyline(path_, scale);

  PositionUVWriter writer(Point{0, 0}, texture_coverage.GetSize(),
                          effect_transform);
  CreateSolidStrokeVertices(writer, polyline, stroke_width,
                            miter_limit_ * stroke_width_ * 0.5f,
                            GetJoinProc<PositionUVWriter>(stroke_join_),
                            GetCapProc<PositionUVWriter>(stroke_cap_), scale);

  BufferView buffer_view = host_buffer.Emplace(
      writer.GetData().data(),
      writer.GetData().size() * sizeof(TextureFillVertexShader::PerVertexData),
      alignof(TextureFillVertexShader::PerVertexData));

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = buffer_view,
              .vertex_count = writer.GetData().size(),
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
      .mode = GeometryResult::Mode::kPreventOverdraw,
  };
}

GeometryResult::Mode StrokePathGeometry::GetResultMode() const {
  return GeometryResult::Mode::kPreventOverdraw;
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
  max_radius *= std::max(stroke_width_, min_size);
  return path_bounds->Expand(max_radius).TransformBounds(transform);
}

}  // namespace impeller
