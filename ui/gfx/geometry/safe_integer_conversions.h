// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_SAFE_INTEGER_CONVERSIONS_H_
#define UI_GFX_GEOMETRY_SAFE_INTEGER_CONVERSIONS_H_

#include <cmath>
#include <limits>

#include "ui/gfx/gfx_export.h"

namespace gfx {

inline int ClampToInt(float value) {
  if (value != value)
    return 0; // no int NaN.
  if (value >= std::numeric_limits<int>::max())
    return std::numeric_limits<int>::max();
  if (value <= std::numeric_limits<int>::min())
    return std::numeric_limits<int>::min();
  return static_cast<int>(value);
}

inline int ToFlooredInt(float value) {
  return ClampToInt(std::floor(value));
}

inline int ToCeiledInt(float value) {
  return ClampToInt(std::ceil(value));
}

inline int ToFlooredInt(double value) {
  return ClampToInt(std::floor(value));
}

inline int ToCeiledInt(double value) {
  return ClampToInt(std::ceil(value));
}

inline int ToRoundedInt(float value) {
  float rounded;
  if (value >= 0.0f)
    rounded = std::floor(value + 0.5f);
  else
    rounded = std::ceil(value - 0.5f);
  return ClampToInt(rounded);
}

inline bool IsExpressibleAsInt(float value) {
  if (value != value)
    return false; // no int NaN.
  if (value > std::numeric_limits<int>::max())
    return false;
  if (value < std::numeric_limits<int>::min())
    return false;
  return true;
}

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_SAFE_INTEGER_CONVERSIONS_H_
