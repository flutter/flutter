// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/geometry/wangs_formula.h"

namespace impeller {

namespace {

// Don't allow linearized segments to be off by more than 1/4th of a pixel from
// the true curve. This value should be scaled by the max basis of the
// X and Y directions.
constexpr static Scalar kPrecision = 4;

inline Scalar length(Point n) {
  Point nn = n * n;
  return std::sqrt(nn.x + nn.y);
}

}  // namespace

Scalar ComputeCubicSubdivisions(Scalar scale_factor,
                                Point p0,
                                Point p1,
                                Point p2,
                                Point p3) {
  Scalar k = scale_factor * .75f * kPrecision;
  Point a = (p0 - p1 * 2 + p2).Abs();
  Point b = (p1 - p2 * 2 + p3).Abs();
  return std::sqrt(k * length(a.Max(b)));
}

Scalar ComputeQuadradicSubdivisions(Scalar scale_factor,
                                    Point p0,
                                    Point p1,
                                    Point p2) {
  Scalar k = scale_factor * .25f * kPrecision;
  return std::sqrt(k * length(p0 - p1 * 2 + p2));
}

// Returns Wang's formula specialized for a conic curve.
//
// This is not actually due to Wang, but is an analogue from:
//   (Theorem 3, corollary 1):
//   J. Zheng, T. Sederberg. "Estimating Tessellation Parameter Intervals for
//   Rational Curves and Surfaces." ACM Transactions on Graphics 19(1). 2000.
Scalar ComputeConicSubdivisions(Scalar scale_factor,
                                Point p0,
                                Point p1,
                                Point p2,
                                Scalar w) {
  // Compute center of bounding box in projected space
  const Point C = 0.5f * (p0.Min(p1).Min(p2) + p0.Max(p1).Max(p2));

  // Translate by -C. This improves translation-invariance of the formula,
  // see Sec. 3.3 of cited paper
  p0 -= C;
  p1 -= C;
  p2 -= C;

  // Compute max length
  const Scalar max_len =
      std::sqrt(std::max(p0.Dot(p0), std::max(p1.Dot(p1), p2.Dot(p2))));

  // Compute forward differences
  const Point dp = -2 * w * p1 + p0 + p2;
  const Scalar dw = std::abs(-2 * w + 2);

  // Compute numerator and denominator for parametric step size of
  // linearization. Here, the epsilon referenced from the cited paper
  // is 1/precision.
  Scalar k = scale_factor * kPrecision;
  const Scalar rp_minus_1 = std::max(0.0f, max_len * k - 1);
  const Scalar numer = std::sqrt(dp.Dot(dp)) * k + rp_minus_1 * dw;
  const Scalar denom = 4 * std::min(w, 1.0f);

  // Number of segments = sqrt(numer / denom).
  // This assumes parametric interval of curve being linearized is
  //   [t0,t1] = [0, 1].
  // If not, the number of segments is (tmax - tmin) / sqrt(denom / numer).
  return std::sqrt(numer / denom);
}

}  // namespace impeller
