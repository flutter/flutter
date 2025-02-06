// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/round_superellipse.h"

#include <cmath>

namespace impeller {

RoundSuperellipse RoundSuperellipse::MakeRectRadii(
    const Rect& in_bounds,
    const RoundingRadii& in_radii) {
  if (!in_bounds.IsFinite()) {
    return {};
  }
  Rect bounds = in_bounds.GetPositive();
  // RoundingRadii::Scaled might return an empty radii if bounds or in_radii is
  // empty, which is expected. Pass along the bounds even if the radii is empty
  // as it would still have a valid location and/or 1-dimensional size which
  // might appear when stroked
  return RoundSuperellipse(bounds, in_radii.Scaled(bounds));
}

}  // namespace impeller
