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

/**
 * @brief Populate a vector with the interpolated colors for the linear gradient
 * described colors and stops.
 *
 * @param colors
 * @param stops
 * @return std::vector<u_int8_t>
 */
std::vector<uint8_t> CreateGradientBuffer(const std::vector<Color>& colors,
                                          const std::vector<Scalar>& stops,
                                          uint32_t* out_texture_size);

}  // namespace impeller
