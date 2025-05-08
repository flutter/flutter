// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

FillRectGeometry::FillRectGeometry(Rect rect) : rect_(rect) {}

FillRectGeometry::~FillRectGeometry() = default;

GeometryResult FillRectGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto& host_buffer = renderer.GetTransientsBuffer();
  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(
                  rect_.GetPoints().data(), 8 * sizeof(float), alignof(float)),
              .vertex_count = 4,
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
  };
}

std::optional<Rect> FillRectGeometry::GetCoverage(
    const Matrix& transform) const {
  return rect_.TransformBounds(transform);
}

bool FillRectGeometry::CoversArea(const Matrix& transform,
                                  const Rect& rect) const {
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }
  Rect coverage = rect_.TransformBounds(transform);
  return coverage.Contains(rect);
}

bool FillRectGeometry::IsAxisAlignedRect() const {
  return true;
}

StrokeRectGeometry::StrokeRectGeometry(const Rect& rect,
                                       const StrokeParameters& stroke)
    : rect_(rect),
      stroke_width_(stroke.width),
      stroke_join_(AdjustStrokeJoin(stroke)) {}

StrokeRectGeometry::~StrokeRectGeometry() = default;

GeometryResult StrokeRectGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (stroke_width_ < 0.0) {
    return {};
  }
  Scalar max_basis = entity.GetTransform().GetMaxBasisLengthXY();
  if (max_basis == 0) {
    return {};
  }

  Scalar min_size = kMinStrokeSize / max_basis;
  Scalar half_stroke_width = std::max(stroke_width_, min_size) * 0.5f;

  auto& host_buffer = renderer.GetTransientsBuffer();
  const Rect& rect = rect_;

  switch (stroke_join_) {
    case Join::kRound: {
      Tessellator::Trigs trigs =
          renderer.GetTessellator().GetTrigsForDeviceRadius(half_stroke_width *
                                                            max_basis);

      FML_DCHECK(trigs.size() >= 2u);

      // We use all but the first entry in trigs for each corner.
      auto vertex_count = trigs.size() - 1;
      // Every other point has a center vertex added.
      vertex_count = vertex_count + (vertex_count >> 1);
      // The loop also adds 3 points of its own.
      vertex_count += 3;
      // We do that for each of the 4 corners.
      vertex_count = vertex_count * 4;
      // We then add 2 more points at the end to close the last edge.
      vertex_count += 2;

      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = host_buffer.Emplace(
                      vertex_count * sizeof(Point), alignof(Point),
                      [hsw = half_stroke_width, &rect, vertex_count,
                       &trigs](uint8_t* buffer) {
                        auto vertices = reinterpret_cast<Point*>(buffer);
                        [[maybe_unused]]
                        auto vertices_end = vertices + vertex_count;

                        vertices =
                            AppendRoundCornerJoin(vertices, rect.GetLeftTop(),
                                                  Vector2(-hsw, 0), trigs);
                        vertices =
                            AppendRoundCornerJoin(vertices, rect.GetRightTop(),
                                                  Vector2(0, -hsw), trigs);
                        vertices = AppendRoundCornerJoin(
                            vertices, rect.GetRightBottom(), Vector2(hsw, 0),
                            trigs);
                        vertices = AppendRoundCornerJoin(
                            vertices, rect.GetLeftBottom(), Vector2(0, hsw),
                            trigs);

                        // Repeat the first 2 points from the first corner to
                        // close the last edge.
                        *vertices++ = rect.GetLeftTop() - Vector2(hsw, 0);
                        *vertices++ = rect.GetLeftTop() + Vector2(hsw, 0);

                        // Make sure our estimate is always up to date.
                        FML_DCHECK(vertices == vertices_end);
                      }),
                  .vertex_count = vertex_count,
                  .index_type = IndexType::kNone,
              },
          .transform = entity.GetShaderTransform(pass),
      };
    }

    case Join::kBevel: {
      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = host_buffer.Emplace(
                      17 * sizeof(Point), alignof(Point),
                      [hsw = half_stroke_width, &rect](uint8_t* buffer) {
                        Scalar left = rect.GetLeft();
                        Scalar top = rect.GetTop();
                        Scalar right = rect.GetRight();
                        Scalar bottom = rect.GetBottom();
                        auto vertices = reinterpret_cast<Point*>(buffer);
                        vertices[0] = Point(left, top - hsw);
                        vertices[1] = Point(left, top + hsw);
                        vertices[2] = Point(right, top - hsw);
                        vertices[3] = Point(right, top + hsw);
                        vertices[4] = Point(right + hsw, top);
                        vertices[5] = Point(right - hsw, top);
                        vertices[6] = Point(right + hsw, bottom);
                        vertices[7] = Point(right - hsw, bottom);
                        vertices[8] = Point(right, bottom + hsw);
                        vertices[9] = Point(right, bottom - hsw);
                        vertices[10] = Point(left, bottom + hsw);
                        vertices[11] = Point(left, bottom - hsw);
                        vertices[12] = Point(left - hsw, bottom);
                        vertices[13] = Point(left + hsw, bottom);
                        vertices[14] = Point(left - hsw, top);
                        vertices[15] = Point(left + hsw, top);
                        vertices[16] = Point(left, top - hsw);
                      }),
                  .vertex_count = 17u,
                  .index_type = IndexType::kNone,
              },
          .transform = entity.GetShaderTransform(pass),
      };
    }

    case Join::kMiter: {
      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = host_buffer.Emplace(
                      10 * sizeof(Point), alignof(Point),
                      [hsw = half_stroke_width, &rect](uint8_t* buffer) {
                        Scalar left = rect.GetLeft();
                        Scalar top = rect.GetTop();
                        Scalar right = rect.GetRight();
                        Scalar bottom = rect.GetBottom();
                        auto vertices = reinterpret_cast<Point*>(buffer);
                        vertices[0] = Point(left - hsw, top - hsw);
                        vertices[1] = Point(left + hsw, top + hsw);
                        vertices[2] = Point(right + hsw, top - hsw);
                        vertices[3] = Point(right - hsw, top + hsw);
                        vertices[4] = Point(right + hsw, bottom + hsw);
                        vertices[5] = Point(right - hsw, bottom - hsw);
                        vertices[6] = Point(left - hsw, bottom + hsw);
                        vertices[7] = Point(left + hsw, bottom - hsw);
                        vertices[8] = Point(left - hsw, top - hsw);
                        vertices[9] = Point(left + hsw, top + hsw);
                      }),
                  .vertex_count = 10u,
                  .index_type = IndexType::kNone,
              },
          .transform = entity.GetShaderTransform(pass),
      };
    }
  }
}

std::optional<Rect> StrokeRectGeometry::GetCoverage(
    const Matrix& transform) const {
  return rect_.TransformBounds(transform);
}

Join StrokeRectGeometry::AdjustStrokeJoin(const StrokeParameters& stroke) {
  return (stroke.join == Join::kMiter && stroke.miter_limit < kSqrt2)
             ? Join::kBevel
             : stroke.join;
}

Point* StrokeRectGeometry::AppendRoundCornerJoin(
    Point* buffer,
    Point corner,
    Vector2 offset,
    const Tessellator::Trigs& trigs) {
  // Close the edge box set up by the end of the last corner and
  // set up the first wedge of this corner.
  *buffer++ = corner + offset;
  *buffer++ = corner - offset;
  bool do_center = false;
  auto trig = trigs.begin();
  auto end = trigs.end();
  while (++trig < end) {
    if (do_center) {
      *buffer++ = corner;
    }
    do_center = !do_center;
    *buffer++ = corner + *trig * offset;
  }
  // Together with the last point pushed by the loop we set up to
  // initiate the edge box connecting to the next corner.
  *buffer++ = corner - end[-1] * offset;
  return buffer;
}

}  // namespace impeller
