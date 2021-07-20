// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cfloat>

#include "impeller/geometry/constants.h"

namespace impeller {

using Scalar = float;

struct Degrees;

struct Radians {
  Scalar radians = 0.0;

  constexpr Radians() = default;

  explicit constexpr Radians(Scalar p_radians) : radians(p_radians) {}
};

struct Degrees {
  Scalar degrees = 0.0;

  constexpr Degrees() = default;

  explicit constexpr Degrees(Scalar p_degrees) : degrees(p_degrees) {}

  constexpr operator Radians() const {
    return Radians{degrees * kPi / 180.0f};
  };
};

}  // namespace impeller
