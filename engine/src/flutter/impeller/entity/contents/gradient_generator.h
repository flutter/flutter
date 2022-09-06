// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/impeller/renderer/texture.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"

namespace impeller {

class Context;

/**
 * @brief Create a host visible texture that contains the gradient defined
 * by the provided colors and stops.
 */
std::shared_ptr<Texture> CreateGradientTexture(
    const std::vector<Color>& colors,
    const std::vector<Scalar>& stops,
    std::shared_ptr<impeller::Context> context);

}  // namespace impeller
