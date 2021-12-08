// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/formats.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A utility that generates triangles of the specified fill type
///             given a polyline. This happens on the CPU.
///
/// @bug        This should just be called a triangulator.
///
class Tessellator {
 public:
  explicit Tessellator(FillType type);

  ~Tessellator();

  WindingOrder GetFrontFaceWinding() const;

  using VertexCallback = std::function<void(Point)>;
  //----------------------------------------------------------------------------
  /// @brief      Generates triangles from the polyline. A callback is invoked
  ///             for each vertex of the triangle.
  ///
  /// @param[in]  polyline  The polyline
  /// @param[in]  callback  The callback
  ///
  /// @return If tessellation was successful.
  ///
  bool Tessellate(const std::vector<Point>& polyline,
                  VertexCallback callback) const;

 private:
  const FillType fill_type_ = FillType::kNonZero;

  FML_DISALLOW_COPY_AND_ASSIGN(Tessellator);
};

}  // namespace impeller
