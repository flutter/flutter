// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "solid_stroke_contents.h"

#include <optional>

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

SolidStrokeContents::SolidStrokeContents() {
  SetStrokeCap(Cap::kButt);
  SetStrokeJoin(Join::kMiter);
}

SolidStrokeContents::~SolidStrokeContents() = default;

void SolidStrokeContents::SetColor(Color color) {
  color_ = color;
}

const Color& SolidStrokeContents::GetColor() const {
  return color_;
}

void SolidStrokeContents::SetPath(Path path) {
  path_ = std::move(path);
}

std::optional<Rect> SolidStrokeContents::GetCoverage(
    const Entity& entity) const {
  if (color_.IsTransparent()) {
    return std::nullopt;
  }

  auto path_bounds = path_.GetBoundingBox();
  if (!path_bounds.has_value()) {
    return std::nullopt;
  }
  auto path_coverage = path_bounds->TransformBounds(entity.GetTransformation());

  Scalar max_radius = 0.5;
  if (cap_ == Cap::kSquare) {
    max_radius = max_radius * kSqrt2;
  }
  if (join_ == Join::kMiter) {
    max_radius = std::max(max_radius, miter_limit_ * 0.5f);
  }
  Scalar determinant = entity.GetTransformation().GetDeterminant();
  if (determinant == 0) {
    return std::nullopt;
  }
  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Vector2 max_radius_xy = entity.GetTransformation().TransformDirection(
      Vector2(max_radius, max_radius) * std::max(stroke_size_, min_size));

  return Rect(path_coverage.origin - max_radius_xy,
              Size(path_coverage.size.width + max_radius_xy.x * 2,
                   path_coverage.size.height + max_radius_xy.y * 2));
}

static VertexBuffer CreateSolidStrokeVertices(
    const Path& path,
    HostBuffer& buffer,
    Scalar stroke_width,
    const SolidStrokeContents::CapProc& cap_proc,
    const SolidStrokeContents::JoinProc& join_proc,
    Scalar miter_limit,
    Scalar tolerance) {
  using VS = SolidFillVertexShader;

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  auto polyline = path.CreatePolyline();

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
    size_t contour_start_point_i, contour_end_point_i;
    std::tie(contour_start_point_i, contour_end_point_i) =
        polyline.GetContourPointBounds(contour_i);

    switch (contour_end_point_i - contour_start_point_i) {
      case 1: {
        Point p = polyline.points[contour_start_point_i];
        cap_proc(vtx_builder, p, {-stroke_width * 0.5f, 0}, tolerance);
        cap_proc(vtx_builder, p, {stroke_width * 0.5f, 0}, tolerance);
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
      // contours with two zero volume triangles, which will be discarded by the
      // rasterizer).
      vtx.position = polyline.points[contour_start_point_i - 1];
      // Append two vertices when "picking up" the pen so that the triangle
      // drawn when moving to the beginning of the new contour will have zero
      // volume.
      vtx_builder.AppendVertex(vtx);
      vtx_builder.AppendVertex(vtx);

      vtx.position = polyline.points[contour_start_point_i];
      // Append two vertices at the beginning of the new contour, which appends
      // two triangles of zero area.
      vtx_builder.AppendVertex(vtx);
      vtx_builder.AppendVertex(vtx);
    }

    // Generate start cap.
    if (!polyline.contours[contour_i].is_closed) {
      cap_proc(vtx_builder, polyline.points[contour_start_point_i], -offset,
               tolerance);
    }

    // Generate contour geometry.
    for (size_t point_i = contour_start_point_i; point_i < contour_end_point_i;
         point_i++) {
      if (point_i > contour_start_point_i) {
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
                    offset, miter_limit, tolerance);
        }
      }
    }

    // Generate end cap or join.
    if (!polyline.contours[contour_i].is_closed) {
      cap_proc(vtx_builder, polyline.points[contour_end_point_i - 1], offset,
               tolerance);
    } else {
      join_proc(vtx_builder, polyline.points[contour_start_point_i], offset,
                contour_first_offset, miter_limit, tolerance);
    }
  }

  return vtx_builder.CreateVertexBuffer(buffer);
}

bool SolidStrokeContents::Render(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  if (stroke_size_ < 0.0) {
    return true;
  }

  VS::VertInfo vert_info;
  vert_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                  entity.GetTransformation();
  Scalar determinant = entity.GetTransformation().GetDeterminant();
  if (determinant == 0) {
    return true;
  }

  FS::FragInfo frag_info;
  frag_info.color = color_.Premultiply();

  Command cmd;
  cmd.primitive_type = PrimitiveType::kTriangleStrip;
  cmd.label = "Solid Stroke";
  auto options = OptionsFromPassAndEntity(pass, entity);
  if (!color_.IsOpaque()) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  cmd.pipeline = renderer.GetSolidFillPipeline(options);
  cmd.stencil_reference = entity.GetStencilDepth();

  auto tolerance =
      kDefaultCurveTolerance /
      (stroke_size_ * entity.GetTransformation().GetMaxBasisLength());

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar stroke_width = std::max(stroke_size_, min_size);
  cmd.BindVertices(CreateSolidStrokeVertices(
      path_, pass.GetTransientsBuffer(), stroke_width, cap_proc_, join_proc_,
      miter_limit_ * stroke_width * 0.5, tolerance));
  VS::BindVertInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(vert_info));
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  pass.AddCommand(cmd);

  if (!color_.IsOpaque()) {
    return ClipRestoreContents().Render(renderer, entity, pass);
  }

  return true;
}

void SolidStrokeContents::SetStrokeSize(Scalar size) {
  stroke_size_ = size;
}

Scalar SolidStrokeContents::GetStrokeSize() const {
  return stroke_size_;
}

void SolidStrokeContents::SetStrokeMiter(Scalar miter_limit) {
  if (miter_limit < 0) {
    return;  // Skia behaves like this.
  }
  miter_limit_ = miter_limit;
}

Scalar SolidStrokeContents::GetStrokeMiter() {
  return miter_limit_;
}

void SolidStrokeContents::SetStrokeCap(Cap cap) {
  cap_ = cap;

  switch (cap) {
    case Cap::kButt:
      cap_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& offset,
                     Scalar tolerance) {};
      break;
    case Cap::kRound:
      cap_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& offset,
                     Scalar tolerance) {
        VS::PerVertexData vtx;

        Point forward(offset.y, -offset.x);
        Point forward_normal = forward.Normalize();

        auto arc_points =
            CubicPathComponent(
                offset, offset + forward * PathBuilder::kArcApproximationMagic,
                forward + offset * PathBuilder::kArcApproximationMagic, forward)
                .CreatePolyline(tolerance);

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
      cap_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& offset,
                     Scalar tolerance) {
        VS::PerVertexData vtx;
        vtx.position = position;

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
}

SolidStrokeContents::Cap SolidStrokeContents::GetStrokeCap() {
  return cap_;
}

static Scalar CreateBevelAndGetDirection(
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

void SolidStrokeContents::SetStrokeJoin(Join join) {
  join_ = join;

  switch (join) {
    case Join::kBevel:
      join_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                      const Point& position, const Point& start_offset,
                      const Point& end_offset, Scalar miter_limit,
                      Scalar tolerance) {
        CreateBevelAndGetDirection(vtx_builder, position, start_offset,
                                   end_offset);
      };
      break;
    case Join::kMiter:
      join_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                      const Point& position, const Point& start_offset,
                      const Point& end_offset, Scalar miter_limit,
                      Scalar tolerance) {
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
      join_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                      const Point& position, const Point& start_offset,
                      const Point& end_offset, Scalar miter_limit,
                      Scalar tolerance) {
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
                              .CreatePolyline(tolerance);

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
}

SolidStrokeContents::Join SolidStrokeContents::GetStrokeJoin() {
  return join_;
}

}  // namespace impeller
