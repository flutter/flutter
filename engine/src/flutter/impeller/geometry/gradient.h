// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <vector>

#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"

namespace impeller {

// If texture_size is 0 then the gradient is invalid.
struct GradientData {
  std::vector<uint8_t> color_bytes;
  uint32_t texture_size;
};

/**
 * @brief Populate a vector with the interpolated color bytes for the linear
 * gradient described by colors and stops.
 *
 * @param colors
 * @param stops
 * @return GradientData
 */
GradientData CreateGradientBuffer(const std::vector<Color>& colors,
                                  const std::vector<Scalar>& stops);

/**
 * @brief Populate a vector with the interpolated colors for the linear gradient
 * described  by colors and stops.
 *
 * If the returned result is std::nullopt, the original color buffer can be used
 * instead.
 *
 * @param colors
 * @param stops
 * @return GradientData
 */
std::optional<std::vector<Color>> CreateGradientColors(
    const std::vector<Color>& colors,
    const std::vector<Scalar>& stops);

}  // namespace impeller
