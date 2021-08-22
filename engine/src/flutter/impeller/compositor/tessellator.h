// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/compositor/formats.h"
#include "impeller/geometry/point.h"

namespace impeller {

class Tessellator {
 public:
  enum class FillType {
    kNonZero,  // The default winding order.
    kOdd,
    kPositive,
    kNegative,
    kAbsGeqTwo,
  };

  Tessellator();

  ~Tessellator();

  void SetFillType(FillType winding);

  FillType GetFillType() const;

  WindingOrder GetFrontFaceWinding() const;

  using VertexCallback = std::function<void(Point)>;
  [[nodiscard]] bool Tessellate(const std::vector<Point>& vertices,
                                VertexCallback callback) const;

 private:
  FillType fill_type_ = FillType::kNonZero;

  FML_DISALLOW_COPY_AND_ASSIGN(Tessellator);
};

}  // namespace impeller
