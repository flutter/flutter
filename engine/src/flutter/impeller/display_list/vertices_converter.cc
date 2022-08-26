// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/vertices_converter.h"
#include "flutter/display_list/display_list_vertices.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/point.h"

namespace impeller {

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

static std::vector<Color> fromColors(const flutter::DlVertices* vertices) {
  std::vector<Color> colors;
  auto* dl_colors = vertices->colors();
  if (dl_colors == nullptr) {
    return colors;
  }
  auto color_count = vertices->vertex_count();
  colors.reserve(color_count);
  for (int i = 0; i < color_count; i++) {
    auto dl_color = dl_colors[i];
    colors.push_back({
        dl_color.getRedF(),
        dl_color.getGreenF(),
        dl_color.getBlueF(),
        dl_color.getAlphaF(),
    });
  }
  return colors;
}

static std::vector<Point> fromPoints(const flutter::DlVertices* vertices) {
  std::vector<Point> points;
  auto vertex_count = vertices->vertex_count();
  auto* dl_vertices = vertices->vertices();
  points.reserve(vertex_count);
  for (int i = 0; i < vertex_count; i++) {
    auto point = dl_vertices[i];
    points.push_back(Point(point.x(), point.y()));
  }
  return points;
}

// Fan mode isn't natively supported. Unroll into triangle mode by
// manipulating the index array.
//
// In Triangle fan, the first vertex is shared across all triangles, and then
// each sliding window of two vertices plus that first vertex defines a
// triangle.
static std::vector<uint16_t> fromFanIndices(
    const flutter::DlVertices* vertices) {
  FML_DCHECK(vertices->vertex_count() >= 3);
  FML_DCHECK(vertices->mode() == flutter::DlVertexMode::kTriangleFan);

  std::vector<uint16_t> indices;

  // Un-fan index buffer if provided.
  if (vertices->index_count() > 0) {
    auto* dl_indices = vertices->indices();
    auto center_point = dl_indices[0];
    for (int i = 1; i < vertices->index_count() - 1; i++) {
      indices.push_back(center_point);
      indices.push_back(dl_indices[i]);
      indices.push_back(dl_indices[i + 1]);
    }
  } else {
    // If indices were not provided, create an index buffer that unfans
    // triangles instead of re-writing points, colors, et cetera.
    for (int i = 1; i < vertices->vertex_count() - 1; i++) {
      indices.push_back(0);
      indices.push_back(i);
      indices.push_back(i + 1);
    }
  }
  return indices;
}

static std::vector<uint16_t> fromIndices(const flutter::DlVertices* vertices) {
  if (vertices->mode() == flutter::DlVertexMode::kTriangleFan) {
    return fromFanIndices(vertices);
  }

  std::vector<uint16_t> indices;
  auto index_count = vertices->index_count();
  auto* dl_indices = vertices->indices();
  indices.reserve(index_count);
  for (int i = 0; i < index_count; i++) {
    auto index = dl_indices[i];
    indices.push_back(index);
  }
  return indices;
}

Vertices ToVertices(const flutter::DlVertices* vertices) {
  std::vector<uint16_t> indices = fromIndices(vertices);
  std::vector<Point> points = fromPoints(vertices);
  std::vector<Color> colors = fromColors(vertices);

  VertexMode mode;
  switch (vertices->mode()) {
    case flutter::DlVertexMode::kTriangles:
      mode = VertexMode::kTriangle;
      break;
    case flutter::DlVertexMode::kTriangleStrip:
      mode = VertexMode::kTriangleStrip;
      break;
    case flutter::DlVertexMode::kTriangleFan:
      // Unrolled into triangle mode by fromIndices.
      mode = VertexMode::kTriangle;
      break;
  }

  auto bounds = vertices->bounds();
  return Vertices(std::move(points), std::move(indices), std::move(colors),
                  mode, ToRect(bounds));
}

}  // namespace impeller
