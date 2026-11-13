// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_GRADIENT_H_
#define FLUTTER_IMPELLER_GEOMETRY_GRADIENT_H_

#include <cstdint>
#include <vector>

#include "impeller/geometry/color.h"

namespace impeller {

// If colors is empty then the gradient is invalid.
struct GradientData {
  std::vector<Color> colors;
};

/**
 * @brief Populate GradientData with the interpolated colors for the linear
 * gradient described by colors and stops.
 *
 * @param colors
 * @param stops
 * @return GradientData
 */
GradientData CreateGradientBuffer(const std::vector<Color>& colors,
                                  const std::vector<Scalar>& stops);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GEOMETRY_GRADIENT_H_
