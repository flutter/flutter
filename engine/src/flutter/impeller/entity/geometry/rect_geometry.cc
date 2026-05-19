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
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = data_host_buffer.Emplace(
                  rect_.GetPoints().data(), 8 * sizeof(float), alignof(float)),
              .vertex_count = 4,
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
      .mode = GeometryResult::Mode::kNormal,
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
  Scalar stroke_width = std::max(stroke_width_, min_size);
  Scalar half_stroke_width = stroke_width * 0.5f;

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  const Rect& rect = rect_;
  bool interior_filled = (stroke_width >= rect.GetSize().MinDimension());

  switch (stroke_join_) {
    case Join::kRound: {
      Tessellator::Trigs trigs =
          renderer.GetTessellator().GetTrigsForDeviceRadius(half_stroke_width *
                                                            max_basis);

      FML_DCHECK(trigs.size() >= 2u);

      auto vertex_count = trigs.size() * 4;
      if (!interior_filled) {
        // If there is a hole in the interior (as with most stroked rects
        // unless the stroke width is really really wide) then we need
        // to perform some surgery to generate the hollowed-out interior.
        vertex_count += 12;
      }

      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = data_host_buffer.Emplace(
                      vertex_count * sizeof(Point), alignof(Point),
                      [hsw = half_stroke_width, &rect, vertex_count, &trigs,
                       interior_filled](uint8_t* buffer) {
                        Scalar left = rect.GetLeft();
                        Scalar top = rect.GetTop();
                        Scalar right = rect.GetRight();
                        Scalar bottom = rect.GetBottom();

                        auto vertices = reinterpret_cast<Point*>(buffer);
                        [[maybe_unused]]
                        auto vertices_end = vertices + vertex_count;

                        // Traverse top down, left to right across slices.

                        // Slice 1: Draw across between top pair of round joins.
                        for (auto trig : trigs) {
                          // trig.sin goes from 0 to 1
                          // trig.cos goes from 1 to 0
                          *vertices++ = Point(left - trig.sin * hsw,
                                              top - trig.cos * hsw);
                          *vertices++ = Point(right + trig.sin * hsw,
                                              top - trig.cos * hsw);
                        }
                        // Ends up with vertices that draw across the bottom
                        // of the top curved section (left - hsw, top) to
                        // (right + hsw, top). This is the starting pair of
                        // vertices for the following square section.

                        if (interior_filled) {
                          // If interior is filled, we can just let the bottom
                          // pair of vertices of the top edge connect to the
                          // top pair of vertices of the bottom edge generated
                          // in slice 5 below. They both go left-right so they
                          // will create a proper zig-zag box to connect the
                          // 2 sections.
                        } else {
                          // Slice 2: Draw the inner part of the top stroke.
                          // Simply extend down from the last horizontal pair
                          // of vertices to (top + hsw).
                          *vertices++ = Point(left - hsw, top + hsw);
                          *vertices++ = Point(right + hsw, top + hsw);

                          // Slice 3: Draw the left and right edges.

                          // Slice 3a: Draw the right edge first.
                          // Since we are already at the right edge from the
                          // previous slice, we just have to add 2 vertices
                          // to get to the bottom of that right edge, but we
                          // have to start with an additional vertex that
                          // connects to (right - hsw) instead of the left
                          // side of the rectangle to avoid a big triangle
                          // through the hollow interior section.
                          *vertices++ = Point(right - hsw, top + hsw);
                          *vertices++ = Point(right + hsw, bottom - hsw);
                          *vertices++ = Point(right - hsw, bottom - hsw);

                          // Now we need to jump up for the left edge, but we
                          // need to dupliate the last point and the next point
                          // to avoid drawing anything connecting them. These
                          // 2 vertices end up generating 2 empty triangles.
                          *vertices++ = Point(right - hsw, bottom - hsw);
                          *vertices++ = Point(left + hsw, top + hsw);

                          // Slice 3b: Now draw the left edge.
                          // We draw this in a specific zig zag order so that
                          // we end up at (left - hsw, bottom - hsw) to connect
                          // properly to the next section.
                          *vertices++ = Point(left + hsw, top + hsw);
                          *vertices++ = Point(left - hsw, top + hsw);
                          *vertices++ = Point(left + hsw, bottom - hsw);
                          *vertices++ = Point(left - hsw, bottom - hsw);

                          // Slice 4: Draw the inner part of the bottom stroke.
                          // Since the next section starts by drawing across
                          // the width of the rect at Y=bottom, we simple have
                          // to make sure that we presently have a pair of
                          // vertices that span the top of that section. The
                          // last point was (left - hsw, bottom - hsw), so we
                          // just have to add its right side partner which
                          // is not the same as the vertex before that. This
                          // extra vertex ends up defining an empty triangle,
                          // but sets us up for the final slice to complete
                          // this interior part of the bottom stroke.
                          *vertices++ = Point(right + hsw, bottom - hsw);
                          // Now the first pair of vertices below will
                          // "complete the zig-zag box" for the inner part
                          // of the bottom stroke.
                        }

                        // Slice 5: Draw between bottom pair of round joins.
                        for (auto trig : trigs) {
                          // trig.sin goes from 0 to 1
                          // trig.cos goes from 1 to 0
                          *vertices++ = Point(left - trig.cos * hsw,
                                              bottom + trig.sin * hsw);
                          *vertices++ = Point(right + trig.cos * hsw,
                                              bottom + trig.sin * hsw);
                        }

                        // Make sure our estimate is always up to date.
                        FML_DCHECK(vertices == vertices_end);
                      }),
                  .vertex_count = vertex_count,
                  .index_type = IndexType::kNone,
              },
          .transform = entity.GetShaderTransform(pass),
          .mode = GeometryResult::Mode::kNormal,
      };
    }

    case Join::kBevel: {
      if (interior_filled) {
        return GeometryResult{
            .type = PrimitiveType::kTriangleStrip,
            .vertex_buffer =
                {
                    .vertex_buffer = data_host_buffer.Emplace(
                        8 * sizeof(Point), alignof(Point),
                        [hsw = half_stroke_width, &rect](uint8_t* buffer) {
                          Scalar left = rect.GetLeft();
                          Scalar top = rect.GetTop();
                          Scalar right = rect.GetRight();
                          Scalar bottom = rect.GetBottom();
                          auto vertices = reinterpret_cast<Point*>(buffer);
                          vertices[0] = Point(left, top - hsw);
                          vertices[1] = Point(right, top - hsw);
                          vertices[2] = Point(left - hsw, top);
                          vertices[3] = Point(right + hsw, top);
                          vertices[4] = Point(left - hsw, bottom);
                          vertices[5] = Point(right + hsw, bottom);
                          vertices[6] = Point(left, bottom + hsw);
                          vertices[7] = Point(right, bottom + hsw);
                        }),
                    .vertex_count = 8u,
                    .index_type = IndexType::kNone,
                },
            .transform = entity.GetShaderTransform(pass),
            .mode = GeometryResult::Mode::kNormal,
        };
      }
      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = data_host_buffer.Emplace(
                      17 * sizeof(Point), alignof(Point),
                      [hsw = half_stroke_width, &rect](uint8_t* buffer) {
                        Scalar left = rect.GetLeft();
                        Scalar top = rect.GetTop();
                        Scalar right = rect.GetRight();
                        Scalar bottom = rect.GetBottom();
                        auto vertices = reinterpret_cast<Point*>(buffer);
                        vertices[0] = Point(left - hsw, top);
                        vertices[1] = Point(left + hsw, top + hsw);
                        vertices[2] = Point(left, top - hsw);
                        vertices[3] = Point(right - hsw, top + hsw);
                        vertices[4] = Point(right, top - hsw);
                        vertices[5] = Point(right - hsw, top + hsw);
                        vertices[6] = Point(right + hsw, top);
                        vertices[7] = Point(right - hsw, bottom - hsw);
                        vertices[8] = Point(right + hsw, bottom);
                        vertices[9] = Point(right - hsw, bottom - hsw);
                        vertices[10] = Point(right, bottom + hsw);
                        vertices[11] = Point(left + hsw, bottom - hsw);
                        vertices[12] = Point(left, bottom + hsw);
                        vertices[13] = Point(left + hsw, bottom - hsw);
                        vertices[14] = Point(left - hsw, bottom);
                        vertices[15] = Point(left + hsw, top + hsw);
                        vertices[16] = Point(left - hsw, top);
                      }),
                  .vertex_count = 17u,
                  .index_type = IndexType::kNone,
              },
          .transform = entity.GetShaderTransform(pass),
          .mode = GeometryResult::Mode::kNormal,
      };
    }

    case Join::kMiter: {
      if (interior_filled) {
        return GeometryResult{
            .type = PrimitiveType::kTriangleStrip,
            .vertex_buffer =
                {
                    .vertex_buffer = data_host_buffer.Emplace(
                        4 * sizeof(Point), alignof(Point),
                        [hsw = half_stroke_width, &rect](uint8_t* buffer) {
                          Scalar left = rect.GetLeft();
                          Scalar top = rect.GetTop();
                          Scalar right = rect.GetRight();
                          Scalar bottom = rect.GetBottom();
                          auto vertices = reinterpret_cast<Point*>(buffer);

                          vertices[0] = Point(left - hsw, top - hsw);
                          vertices[1] = Point(right + hsw, top - hsw);
                          vertices[2] = Point(left - hsw, bottom + hsw);
                          vertices[3] = Point(right + hsw, bottom + hsw);
                        }),
                    .vertex_count = 4u,
                    .index_type = IndexType::kNone,
                },
            .transform = entity.GetShaderTransform(pass),
            .mode = GeometryResult::Mode::kNormal,
        };
      }
      return GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = data_host_buffer.Emplace(
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
          .mode = GeometryResult::Mode::kNormal,
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

}  // namespace impeller
