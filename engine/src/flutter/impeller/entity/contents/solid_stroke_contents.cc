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
  Vector2 max_radius_xy = entity.GetTransformation().TransformDirection(
      Vector2(max_radius, max_radius) * stroke_size_);

  return Rect(path_coverage.origin - max_radius_xy,
              Size(path_coverage.size.width + max_radius_xy.x * 2,
                   path_coverage.size.height + max_radius_xy.y * 2));
}

static VertexBuffer CreateSolidStrokeVertices(
    const Path& path,
    HostBuffer& buffer,
    const SolidStrokeContents::CapProc& cap_proc,
    const SolidStrokeContents::JoinProc& join_proc,
    Scalar miter_limit,
    const SmoothingApproximation& smoothing) {
  using VS = SolidStrokeVertexShader;

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  auto polyline = path.CreatePolyline();

  if (polyline.points.size() < 2) {
    return {};  // Nothing to render.
  }

  VS::PerVertexData vtx;

  // Normal state.
  Point normal;
  Point previous_normal;  // Used for computing joins.

  auto compute_normal = [&polyline, &normal, &previous_normal](size_t point_i) {
    previous_normal = normal;
    Point direction =
        (polyline.points[point_i] - polyline.points[point_i - 1]).Normalize();
    normal = {-direction.y, direction.x};
  };

  for (size_t contour_i = 0; contour_i < polyline.contours.size();
       contour_i++) {
    size_t contour_start_point_i, contour_end_point_i;
    std::tie(contour_start_point_i, contour_end_point_i) =
        polyline.GetContourPointBounds(contour_i);

    if (contour_end_point_i - contour_start_point_i < 2) {
      continue;  // This contour has no renderable content.
    }

    // The first point's normal is always the same as
    compute_normal(contour_start_point_i + 1);
    const Point contour_first_normal = normal;

    if (contour_i > 0) {
      // This branch only executes when we've just finished drawing a contour
      // and are switching to a new one.
      // We're drawing a triangle strip, so we need to "pick up the pen" by
      // appending transparent vertices between the end of the previous contour
      // and the beginning of the new contour.
      vtx.vertex_position = polyline.points[contour_start_point_i - 1];
      vtx.vertex_normal = {};
      vtx.pen_down = 0.0;
      // Append two transparent vertices when "picking up" the pen so that the
      // triangle drawn when moving to the beginning of the new contour will
      // have zero volume. This is necessary because strokes with a transparent
      // color affect the stencil buffer to prevent overdraw.
      vtx_builder.AppendVertex(vtx);
      vtx_builder.AppendVertex(vtx);

      vtx.vertex_position = polyline.points[contour_start_point_i];
      // Append two vertices at the beginning of the new contour
      // so that the next appended vertex will create a triangle with zero
      // volume.
      vtx_builder.AppendVertex(vtx);
      vtx.pen_down = 1.0;
      vtx_builder.AppendVertex(vtx);
    }

    // Generate start cap.
    if (!polyline.contours[contour_i].is_closed) {
      cap_proc(vtx_builder, polyline.points[contour_start_point_i], -normal,
               smoothing);
    }

    // Generate contour geometry.
    for (size_t point_i = contour_start_point_i; point_i < contour_end_point_i;
         point_i++) {
      if (point_i > contour_start_point_i) {
        // Generate line rect.
        vtx.vertex_position = polyline.points[point_i - 1];
        vtx.pen_down = 1.0;
        vtx.vertex_normal = normal;
        vtx_builder.AppendVertex(vtx);
        vtx.vertex_normal = -normal;
        vtx_builder.AppendVertex(vtx);
        vtx.vertex_position = polyline.points[point_i];
        vtx.vertex_normal = normal;
        vtx_builder.AppendVertex(vtx);
        vtx.vertex_normal = -normal;
        vtx_builder.AppendVertex(vtx);

        if (point_i < contour_end_point_i - 1) {
          compute_normal(point_i + 1);

          // Generate join from the current line to the next line.
          join_proc(vtx_builder, polyline.points[point_i], previous_normal,
                    normal, miter_limit, smoothing);
        }
      }
    }

    // Generate end cap or join.
    if (!polyline.contours[contour_i].is_closed) {
      cap_proc(vtx_builder, polyline.points[contour_end_point_i - 1], normal,
               smoothing);
    } else {
      join_proc(vtx_builder, polyline.points[contour_start_point_i], normal,
                contour_first_normal, miter_limit, smoothing);
    }
  }

  return vtx_builder.CreateVertexBuffer(buffer);
}

bool SolidStrokeContents::Render(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  if (stroke_size_ <= 0.0) {
    return true;
  }

  using VS = SolidStrokeVertexShader;

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.color = color_.Premultiply();
  frame_info.size = stroke_size_;

  Command cmd;
  cmd.primitive_type = PrimitiveType::kTriangleStrip;
  cmd.label = "Solid Stroke";
  auto options = OptionsFromPassAndEntity(pass, entity);
  if (!color_.IsOpaque()) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  cmd.pipeline = renderer.GetSolidStrokePipeline(options);
  cmd.stencil_reference = entity.GetStencilDepth();

  auto smoothing = SmoothingApproximation(
      5.0 / (stroke_size_ * entity.GetTransformation().GetMaxBasisLength()),
      0.0, 0.0);
  cmd.BindVertices(CreateSolidStrokeVertices(path_, pass.GetTransientsBuffer(),
                                             cap_proc_, join_proc_,
                                             miter_limit_, smoothing));
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

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

  using VS = SolidStrokeVertexShader;
  switch (cap) {
    case Cap::kButt:
      cap_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& normal,
                     const SmoothingApproximation& smoothing) {};
      break;
    case Cap::kRound:
      cap_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& normal,
                     const SmoothingApproximation& smoothing) {
        SolidStrokeVertexShader::PerVertexData vtx;
        vtx.vertex_position = position;
        vtx.pen_down = 1.0;

        Point forward(normal.y, -normal.x);

        auto arc_points =
            CubicPathComponent(
                normal, normal + forward * PathBuilder::kArcApproximationMagic,
                forward + normal * PathBuilder::kArcApproximationMagic, forward)
                .CreatePolyline(smoothing);

        vtx.vertex_normal = normal;
        vtx_builder.AppendVertex(vtx);
        vtx.vertex_normal = -normal;
        vtx_builder.AppendVertex(vtx);
        for (const auto& point : arc_points) {
          vtx.vertex_normal = point;
          vtx_builder.AppendVertex(vtx);
          vtx.vertex_normal = (-point).Reflect(forward);
          vtx_builder.AppendVertex(vtx);
        }
      };
      break;
    case Cap::kSquare:
      cap_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                     const Point& position, const Point& normal,
                     const SmoothingApproximation& smoothing) {
        SolidStrokeVertexShader::PerVertexData vtx;
        vtx.vertex_position = position;
        vtx.pen_down = 1.0;

        Point forward(normal.y, -normal.x);

        vtx.vertex_normal = normal;
        vtx_builder.AppendVertex(vtx);
        vtx.vertex_normal = -normal;
        vtx_builder.AppendVertex(vtx);
        vtx.vertex_normal = normal + forward;
        vtx_builder.AppendVertex(vtx);
        vtx.vertex_normal = -normal + forward;
        vtx_builder.AppendVertex(vtx);
      };
      break;
  }
}

SolidStrokeContents::Cap SolidStrokeContents::GetStrokeCap() {
  return cap_;
}

static Scalar CreateBevelAndGetDirection(
    VertexBufferBuilder<SolidStrokeVertexShader::PerVertexData>& vtx_builder,
    const Point& position,
    const Point& start_normal,
    const Point& end_normal) {
  SolidStrokeVertexShader::PerVertexData vtx;
  vtx.vertex_position = position;
  vtx.pen_down = 1.0;
  vtx.vertex_normal = {};
  vtx_builder.AppendVertex(vtx);

  Scalar dir = start_normal.Cross(end_normal) > 0 ? -1 : 1;
  vtx.vertex_normal = start_normal * dir;
  vtx_builder.AppendVertex(vtx);
  vtx.vertex_normal = end_normal * dir;
  vtx_builder.AppendVertex(vtx);

  return dir;
}

void SolidStrokeContents::SetStrokeJoin(Join join) {
  join_ = join;

  using VS = SolidStrokeVertexShader;
  switch (join) {
    case Join::kBevel:
      join_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                      const Point& position, const Point& start_normal,
                      const Point& end_normal, Scalar miter_limit,
                      const SmoothingApproximation& smoothing) {
        CreateBevelAndGetDirection(vtx_builder, position, start_normal,
                                   end_normal);
      };
      break;
    case Join::kMiter:
      join_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                      const Point& position, const Point& start_normal,
                      const Point& end_normal, Scalar miter_limit,
                      const SmoothingApproximation& smoothing) {
        // 1 for no joint (straight line), 0 for max joint (180 degrees).
        Scalar alignment = (start_normal.Dot(end_normal) + 1) / 2;
        if (ScalarNearlyEqual(alignment, 1)) {
          return;
        }

        Scalar dir = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_normal, end_normal);

        Point miter_point = (start_normal + end_normal) / 2 / alignment;
        if (miter_point.GetDistanceSquared({0, 0}) >
            miter_limit * miter_limit) {
          return;  // Convert to bevel when we exceed the miter limit.
        }

        // Outer miter point.
        SolidStrokeVertexShader::PerVertexData vtx;
        vtx.vertex_position = position;
        vtx.pen_down = 1.0;
        vtx.vertex_normal = miter_point * dir;
        vtx_builder.AppendVertex(vtx);
      };
      break;
    case Join::kRound:
      join_proc_ = [](VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                      const Point& position, const Point& start_normal,
                      const Point& end_normal, Scalar miter_limit,
                      const SmoothingApproximation& smoothing) {
        // 0 for no joint (straight line), 1 for max joint (180 degrees).
        Scalar alignment = 1 - (start_normal.Dot(end_normal) + 1) / 2;
        if (ScalarNearlyEqual(alignment, 0)) {
          return;
        }

        Scalar dir = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_normal, end_normal);

        Point middle = (start_normal + end_normal).Normalize();
        Point middle_handle = middle + Point(-middle.y, middle.x) *
                                           PathBuilder::kArcApproximationMagic *
                                           alignment * dir;
        Point start_handle =
            start_normal + Point(start_normal.y, -start_normal.x) *
                               PathBuilder::kArcApproximationMagic * alignment *
                               dir;

        auto arc_points = CubicPathComponent(start_normal, start_handle,
                                             middle_handle, middle)
                              .CreatePolyline(smoothing);

        SolidStrokeVertexShader::PerVertexData vtx;
        vtx.vertex_position = position;
        vtx.pen_down = 1.0;
        for (const auto& point : arc_points) {
          vtx.vertex_normal = point * dir;
          vtx_builder.AppendVertex(vtx);
          vtx.vertex_normal = (-point * dir).Reflect(middle);
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
