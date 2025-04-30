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

StrokeRectGeometry::StrokeRectGeometry(Rect rect,
                                       Scalar stroke_width,
                                       Join stroke_join,
                                       Scalar miter_limit)
    : rect_(rect),
      stroke_width_(stroke_width),
      stroke_join_(AdjustStrokeJoin(stroke_join, miter_limit)) {}

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
  Scalar left = rect_.GetLeft();
  Scalar top = rect_.GetTop();
  Scalar right = rect_.GetRight();
  Scalar bottom = rect_.GetBottom();

  switch (stroke_join_) {
    case Join::kRound: {
      Scalar radius = half_stroke_width;
      Tessellator::Trigs trigs =
          renderer.GetTessellator().GetTrigsForDeviceRadius(radius * max_basis);

      FML_DCHECK(trigs.size() >= 2u);

      // We use all but the first entry in trigs for each corner.
      auto needed = trigs.size() - 1;
      // Every other point has a center vertex added.
      needed = needed + (needed >> 1);
      // The loop also adds 3 points of its own.
      needed += 3;
      // We do that for each of the 4 corners.
      needed = needed * 4;
      // We then add 2 more points at the end to close the last edge.
      needed += 2;
      std::vector<Point> points;
      points.reserve(needed);

      auto draw_corner = [&points, &trigs](Point corner, Vector2 offset) {
        // Close the edge box set up by the end of the last corner and
        // set up the first wedge of this corner.
        points.push_back(corner + offset);
        points.push_back(corner - offset);
        bool do_center = false;
        auto trig = trigs.begin();
        auto end = trigs.end();
        while (++trig < end) {
          if (do_center) {
            points.push_back(corner);
          }
          do_center = !do_center;
          points.push_back(corner + *trig * offset);
        }
        // Together with the last point pushed by the loop we set up to
        // initiate the edge box connecting to the next corner.
        points.push_back(corner - end[-1] * offset);
      };

      draw_corner(Point(left, top), Vector2(-radius, 0));
      draw_corner(Point(right, top), Vector2(0, -radius));
      draw_corner(Point(right, bottom), Vector2(radius, 0));
      draw_corner(Point(left, bottom), Vector2(0, radius));

      // Repeat the first 2 points from the first corner to close the
      // last edge.
      points.push_back(Point(left - radius, top));
      points.push_back(Point(left + radius, top));
      FML_DCHECK(points.size() == needed);

      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = host_buffer.Emplace(
                      points.data(), points.size() * sizeof(Point),
                      alignof(float)),
                  .vertex_count = points.size(),
                  .index_type = IndexType::kNone,
              },
          .transform = entity.GetShaderTransform(pass),
      };
    }

    case Join::kBevel: {
      std::array<Point, 17> points{
          Point(left, top - half_stroke_width),
          Point(left, top + half_stroke_width),
          Point(right, top - half_stroke_width),
          Point(right, top + half_stroke_width),
          Point(right + half_stroke_width, top),
          Point(right - half_stroke_width, top),
          Point(right + half_stroke_width, bottom),
          Point(right - half_stroke_width, bottom),
          Point(right, bottom + half_stroke_width),
          Point(right, bottom - half_stroke_width),
          Point(left, bottom + half_stroke_width),
          Point(left, bottom - half_stroke_width),
          Point(left - half_stroke_width, bottom),
          Point(left + half_stroke_width, bottom),
          Point(left - half_stroke_width, top),
          Point(left + half_stroke_width, top),
          Point(left, top - half_stroke_width),
      };
      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = host_buffer.Emplace(
                      points.data(), points.size() * sizeof(Point),
                      alignof(float)),
                  .vertex_count = points.size(),
                  .index_type = IndexType::kNone,
              },
          .transform = entity.GetShaderTransform(pass),
      };
    }

    case Join::kMiter: {
      std::array<Point, 10> points{
          Point(left - half_stroke_width, top - half_stroke_width),
          Point(left + half_stroke_width, top + half_stroke_width),
          Point(right + half_stroke_width, top - half_stroke_width),
          Point(right - half_stroke_width, top + half_stroke_width),
          Point(right + half_stroke_width, bottom + half_stroke_width),
          Point(right - half_stroke_width, bottom - half_stroke_width),
          Point(left - half_stroke_width, bottom + half_stroke_width),
          Point(left + half_stroke_width, bottom - half_stroke_width),
          Point(left - half_stroke_width, top - half_stroke_width),
          Point(left + half_stroke_width, top + half_stroke_width),
      };
      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = host_buffer.Emplace(
                      points.data(), points.size() * sizeof(Point),
                      alignof(float)),
                  .vertex_count = points.size(),
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

Join StrokeRectGeometry::AdjustStrokeJoin(Join join, Scalar miter_limit) {
  return (join == Join::kMiter && miter_limit < kSqrt2) ? Join::kBevel : join;
}

}  // namespace impeller
