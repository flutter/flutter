// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>
#include <vector>

#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"

namespace impeller {

enum class VertexMode {
  kTriangle,
  kTriangleStrip,
};

class Vertices {
 public:
  Vertices(std::vector<Point> positions,
           std::vector<uint16_t> indices,
           std::vector<Color> colors,
           VertexMode vertex_mode,
           Rect bounds);

  ~Vertices();

  bool IsValid() const;

  std::optional<Rect> GetBoundingBox() const;

  std::optional<Rect> GetTransformedBoundingBox(const Matrix& transform) const;

  const std::vector<Point>& GetPositions() const;

  const std::vector<uint16_t>& GetIndices() const;

  const std::vector<Color>& GetColors() const;

  VertexMode GetMode() const;

 private:
  std::vector<Point> positions_;
  std::vector<uint16_t> indices_;
  std::vector<Color> colors_;
  VertexMode vertex_mode_;
  Rect bounds_;

  void NormalizeIndices();
};

}  // namespace impeller
