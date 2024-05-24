// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_GRADIENT_GENERATOR_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_GRADIENT_GENERATOR_H_

#include <memory>
#include <vector>

#include "flutter/impeller/core/texture.h"
#include "impeller/core/shader_types.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/gradient.h"

namespace impeller {

class Context;

/**
 * @brief Create a host visible texture that contains the gradient defined
 * by the provided gradient data.
 */
std::shared_ptr<Texture> CreateGradientTexture(
    const GradientData& gradient_data,
    const std::shared_ptr<impeller::Context>& context);

struct StopData {
  Color color;
  Scalar stop;
  Scalar inverse_delta;
  Padding<8> _padding_;
};

static_assert(sizeof(StopData) == 32);

/**
 * @brief Populate a vector with the color and stop data for a gradient
 *
 * @param colors
 * @param stops
 * @return StopData
 */
std::vector<StopData> CreateGradientColors(const std::vector<Color>& colors,
                                           const std::vector<Scalar>& stops);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_GRADIENT_GENERATOR_H_
