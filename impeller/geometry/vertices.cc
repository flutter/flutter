// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices.h"

namespace impeller {

Vertices::Vertices(std::vector<Point> points,
                   std::vector<uint16_t> indices,
                   std::vector<Color> colors,
                   VertexMode vertex_mode,
                   Rect bounds)
    : points_(std::move(points)),
      indices_(std::move(indices)),
      colors_(std::move(colors)),
      vertex_mode_(vertex_mode),
      bounds_(bounds){};

Vertices::~Vertices() = default;

std::optional<Rect> Vertices::GetTransformedBoundingBox(
    const Matrix& transform) const {
  auto bounds = GetBoundingBox();
  if (!bounds.has_value()) {
    return std::nullopt;
  }
  return bounds->TransformBounds(transform);
};

}  // namespace impeller
