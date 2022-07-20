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
    : positions_(std::move(points)),
      indices_(std::move(indices)),
      colors_(std::move(colors)),
      vertex_mode_(vertex_mode),
      bounds_(bounds) {
  NormalizeIndices();
}

Vertices::~Vertices() = default;

bool Vertices::IsValid() const {
  size_t points_size = positions_.size();
  size_t colors_size = colors_.size();

  if (colors_size > 0 && colors_size != points_size) {
    return false;
  }

  return true;
}

std::optional<Rect> Vertices::GetBoundingBox() const {
  return bounds_;
};

std::optional<Rect> Vertices::GetTransformedBoundingBox(
    const Matrix& transform) const {
  auto bounds = GetBoundingBox();
  if (!bounds.has_value()) {
    return std::nullopt;
  }
  return bounds->TransformBounds(transform);
};

const std::vector<Point>& Vertices::GetPositions() const {
  return positions_;
}

const std::vector<uint16_t>& Vertices::GetIndices() const {
  return indices_;
}

const std::vector<Color>& Vertices::GetColors() const {
  return colors_;
}

VertexMode Vertices::GetMode() const {
  return vertex_mode_;
}

void Vertices::NormalizeIndices() {
  if (indices_.size() != 0 || positions_.size() == 0) {
    return;
  }
  for (size_t i = 0; i < positions_.size(); i++) {
    indices_.push_back(i);
  }
}

}  // namespace impeller
