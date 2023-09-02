// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/dl_vertices_geometry.h"

#include "display_list/dl_vertices.h"
#include "impeller/display_list/skia_conversions.h"
#include "impeller/entity/geometry/vertices_geometry.h"
#include "impeller/geometry/point.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"

namespace impeller {

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

static VerticesGeometry::VertexMode ToVertexMode(flutter::DlVertexMode mode) {
  switch (mode) {
    case flutter::DlVertexMode::kTriangles:
      return VerticesGeometry::VertexMode::kTriangles;
    case flutter::DlVertexMode::kTriangleStrip:
      return VerticesGeometry::VertexMode::kTriangleStrip;
    case flutter::DlVertexMode::kTriangleFan:
      return VerticesGeometry::VertexMode::kTriangleFan;
  };
}

std::shared_ptr<impeller::VerticesGeometry> MakeVertices(
    const flutter::DlVertices* vertices) {
  auto bounds = ToRect(vertices->bounds());
  auto mode = ToVertexMode(vertices->mode());
  std::vector<Point> positions(vertices->vertex_count());
  for (auto i = 0; i < vertices->vertex_count(); i++) {
    positions[i] = skia_conversions::ToPoint(vertices->vertices()[i]);
  }

  std::vector<uint16_t> indices(vertices->index_count());
  for (auto i = 0; i < vertices->index_count(); i++) {
    indices[i] = vertices->indices()[i];
  }

  std::vector<Color> colors;
  if (vertices->colors()) {
    colors.reserve(vertices->vertex_count());
    for (auto i = 0; i < vertices->vertex_count(); i++) {
      colors.push_back(
          skia_conversions::ToColor(vertices->colors()[i]).Premultiply());
    }
  }
  std::vector<Point> texture_coordinates;
  if (vertices->texture_coordinates()) {
    texture_coordinates.reserve(vertices->vertex_count());
    for (auto i = 0; i < vertices->vertex_count(); i++) {
      texture_coordinates.push_back(
          skia_conversions::ToPoint(vertices->texture_coordinates()[i]));
    }
  }
  return std::make_shared<VerticesGeometry>(
      positions, indices, texture_coordinates, colors, bounds, mode);
}

}  // namespace impeller
