// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/arc.h"

namespace impeller {

Arc::Arc(const Rect& bounds, Degrees start, Degrees sweep, bool include_center)
    : bounds_(bounds), include_center_(include_center) {
  if (bounds.IsFinite() && start.IsFinite() && sweep.IsFinite()) {
    if (sweep.degrees < 0) {
      start = start + sweep;
      sweep = -sweep;
    }
    if (sweep.degrees > 360) {
      // We need to represent over-sweeping a full circle for the case where
      // we will be stroking the circle with the center incuded where we
      // stroke the entire perimeter, but the two segments that connect to
      // the center are at the proper angles.
      // Normalize to less than 720.
      sweep.degrees = 360.0f + std::fmodf(sweep.degrees, 360.0f);
    }
  } else {
    // Don't bother sweeping any distance if anything is non-finite.
    sweep = Degrees(0);
    if (!start.IsFinite() || !bounds.IsFinite()) {
      // We can maintain start if both it and bounds are finite.
      start = Degrees(0);
    }
  }
  start_ = start;
  sweep_ = sweep;
}

size_t Arc::Iteration::GetPointCount() const {
  size_t count = 2;
  for (size_t i = 0; i < quadrant_count; i++) {
    count += quadrants[i].GetPointCount();
  }
  return count;
}

const Arc::Iteration Arc::ComputeCircleArcIterations(size_t step_count) {
  return {
      {1.0f, 0.0f},
      {1.0f, 0.0f},
      4u,
      {
          {kQuadrantAxes[0], 1u, step_count},
          {kQuadrantAxes[1], 0u, step_count},
          {kQuadrantAxes[2], 0u, step_count},
          {kQuadrantAxes[3], 0u, step_count},
          {{}, 0u, 0u},
      },
  };
}

Rect Arc::GetTightArcBounds() const {
  if (IsFullCircle()) {
    return bounds_;
  }

  Degrees start_angle = start_.GetPositive();
  Degrees end_angle = start_angle + sweep_;
  FML_DCHECK(start_angle.degrees >= 0 && start_angle.degrees < 360);
  FML_DCHECK(end_angle > start_angle && end_angle.degrees < 720);

  // 1. start vector
  // 2. end vector
  // 3. optional center
  // 4-7. optional quadrant extrema
  Point extrema[7];
  int count = 0;

  extrema[count++] = Matrix::CosSin(start_angle);
  extrema[count++] = Matrix::CosSin(end_angle);

  if (include_center_) {
    extrema[count++] = {0, 0};
  }

  // cur_axis will be pre-incremented before recording the following axis
  int cur_axis = std::floor(start_angle.degrees / 90.0f);
  // end_axis is a non-inclusive end of the range
  int end_axis = std::ceil(end_angle.degrees / 90.0f);
  while (++cur_axis < end_axis) {
    extrema[count++] = kQuadrantAxes[cur_axis & 3];
  }

  FML_DCHECK(count <= 7);

  Point center = bounds_.GetCenter();
  Size radii = bounds_.GetSize() * 0.5f;

  for (int i = 0; i < count; i++) {
    extrema[i] = center + extrema[i] * radii;
  }
  return Rect::MakePointBounds(extrema, extrema + count).value_or(Rect());
}

Arc::Iteration Arc::ComputeIterations(size_t step_count,
                                      bool simplify_360) const {
  if (sweep_.degrees == 0) {
    return {};
  }

  FML_DCHECK(sweep_.degrees >= 0);

  if (simplify_360 && sweep_.degrees >= 360) {
    return ComputeCircleArcIterations(step_count);
  }
  FML_DCHECK(sweep_.degrees < 720);

  Degrees start = start_.GetPositive();
  Degrees end = start + sweep_;
  FML_DCHECK(start.degrees >= 0.0f && start.degrees < 360.0f);
  FML_DCHECK(end >= start);
  FML_DCHECK(end.degrees < start.degrees + (simplify_360 ? 360.0f : 720.0f));

  Iteration iterations;
  iterations.start = impeller::Matrix::CosSin(start);
  iterations.end = impeller::Matrix::CosSin(end);

  // We nudge the start and stop by 1/10th of a step so we don't end
  // up with degenerately small steps at the start and end of the
  // arc.
  Degrees nudge = Degrees((90.0f / step_count) * 0.1f);

  if ((start + nudge) >= (end - nudge)) {
    iterations.quadrant_count = 0u;
    return iterations;
  }

  int cur_quadrant =
      static_cast<int>(std::floor((start + nudge).degrees / 90.0f));
  int end_quadrant =
      static_cast<int>(std::floor((end - nudge).degrees / 90.0f));
  FML_DCHECK(cur_quadrant >= 0 &&  //
             cur_quadrant <= 4);
  FML_DCHECK(end_quadrant >= cur_quadrant &&  //
             end_quadrant <= cur_quadrant + 8);
  FML_DCHECK(cur_quadrant * 90 <= (start + nudge).degrees);
  FML_DCHECK(end_quadrant * 90 + 90 >= (end - nudge).degrees);

  auto next_step = [step_count](Degrees angle, int quadrant) -> size_t {
    Scalar quadrant_fract = angle.degrees / 90.0f - quadrant;
    return static_cast<size_t>(std::ceil(quadrant_fract * step_count));
  };

  int i = 0;
  iterations.quadrants[i] = {
      kQuadrantAxes[cur_quadrant & 3],
      next_step(start + nudge, cur_quadrant),
      step_count,
  };
  if (iterations.quadrants[0].end_index > iterations.quadrants[0].start_index) {
    i++;
  }
  while (cur_quadrant < end_quadrant) {
    iterations.quadrants[i++] = {
        kQuadrantAxes[(++cur_quadrant) % 4],
        0u,
        step_count,
    };
  }
  FML_DCHECK(i <= 9);
  if (i > 0) {
    iterations.quadrants[i - 1].end_index =
        next_step(end - nudge, cur_quadrant);
    if (iterations.quadrants[i - 1].end_index <=
        iterations.quadrants[i - 1].start_index) {
      i--;
    }
  }
  iterations.quadrant_count = i;
  return iterations;
}

}  // namespace impeller
