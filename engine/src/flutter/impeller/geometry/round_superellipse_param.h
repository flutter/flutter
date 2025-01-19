// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_ROUND_SUPERELLIPSE_PARAM_H_
#define FLUTTER_IMPELLER_GEOMETRY_ROUND_SUPERELLIPSE_PARAM_H_

#include "flutter/impeller/geometry/point.h"
#include "flutter/impeller/geometry/rect.h"
#include "flutter/impeller/geometry/rounding_radii.h"
#include "flutter/impeller/geometry/size.h"

namespace impeller {

struct RoundSuperellipseParam {
  struct Octant {
    //
    Point start;

    Point se_center;
    // Semi-axis of the superellipse.
    Scalar se_a;
    // Degree of the superellipse.
    Scalar se_n;
    Scalar se_max_theta;

    // Start point of the circular_arc.
    Point circle_start;
    // Center of the circle.
    Point circle_center;
    Radians circle_max_angle;
  };

  struct Quadrant {
    // The center of the quadrant.
    Point center;

    // All parameters below describe the shape centered at the origin.

    // The scale in order to transform into the original shape (with
    // asymmetrical radius size and in the correct quadrant) from the normalized
    // shape with a symmetrical corner in the first quadrant.
    //
    // Normalize: If the radius size of this corner is asymmetrical, then the
    // quadrant shape is normalized by shortening the longer radius to the
    // shorter one, so that problem is simplified into drawing symmetrical
    // corners.
    //
    // Sign: During the normalization, the shape is also flipped to the first
    // quadrant (top right).
    Point signed_scale;

    // All parameters below describe the shape after normalization.

    // The symmetrical radius after normalization.
    Scalar norm_radius;

    // Half of height and width.
    //
    // Effectively the top right corner of the bounds.
    // Point half_size;

    // The width and the height of the straight segments.
    Point stretch;

    // The offset of the center of the octants from the `stretch` point.
    Scalar octant_eccentric;

    Octant top;
    Octant right;
  };

  Quadrant top_left;
  Quadrant top_right;
  Quadrant bottom_left;
  Quadrant bottom_right;

  [[nodiscard]] static RoundSuperellipseParam MakeBoundsRadii(
      const Rect& bounds,
      const RoundingRadii& radii);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GEOMETRY_ROUND_SUPERELLIPSE_PARAM_H_
