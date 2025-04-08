// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TESSELLATOR_PATH_TESSELLATOR_H_
#define FLUTTER_IMPELLER_TESSELLATOR_PATH_TESSELLATOR_H_

#include <memory>
#include <tuple>

#include "flutter/impeller/geometry/path_source.h"
#include "flutter/impeller/geometry/scalar.h"

namespace impeller {

/// @brief An interface for generating a multi contour polyline as a triangle
///        strip.
class PathVertexWriter {
 public:
  virtual void Write(Point point) = 0;

  virtual void EndContour() = 0;
};

class PathTessellator {
 public:
  static std::pair<size_t, size_t> CountFillStorage(const PathSource& path,
                                                    Scalar scale);

  static void PathToFilledVertices(const PathSource& path,
                                   PathVertexWriter& writer,
                                   Scalar scale);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TESSELLATOR_PATH_TESSELLATOR_H_
