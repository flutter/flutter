// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/round_superellipse_param.h"

namespace impeller {

namespace {

// A factor used to calculate the "gap", defined as the distance from the
// midpoint of the curved corners to the nearest sides of the bounding box.
//
// When the corner radius is symmetrical on both dimensions, the midpoint of the
// corner is where the circular arc intersects its quadrant bisector. When the
// corner radius is asymmetrical, since the corner can be considered "elongated"
// from a symmetrical corner, the midpoint is transformed in the same way.
//
// Experiments indicate that the gap is linear with respect to the corner
// radius on that dimension.
//
// The formula should be kept in sync with a few files, as documented in
// `CalculateGap` in round_superellipse_geometry.cc.
constexpr Scalar kGapFactor = 0.2924066406;

// A look up table with precomputed variables.
//
// The columns represent the following variabls respectively:
//
//  * ratio = size / a
//  * n
//  * d / a
//  * thetaJ
//
// For definition of the variables, see DrawOctantSquareLikeSquircle.
constexpr Scalar kPrecomputedVariables[][4] = {
    {2.000, 2.00000, 0.00000, 0.24040},  //
    {2.020, 2.03340, 0.01447, 0.24040},  //
    {2.040, 2.06540, 0.02575, 0.21167},  //
    {2.060, 2.09800, 0.03668, 0.20118},  //
    {2.080, 2.13160, 0.04719, 0.19367},  //
    {2.100, 2.17840, 0.05603, 0.16233},  //
    {2.120, 2.19310, 0.06816, 0.20020},  //
    {2.140, 2.22990, 0.07746, 0.19131},  //
    {2.160, 2.26360, 0.08693, 0.19008},  //
    {2.180, 2.30540, 0.09536, 0.17935},  //
    {2.200, 2.32900, 0.10541, 0.19136},  //
    {2.220, 2.38330, 0.11237, 0.17130},  //
    {2.240, 2.39770, 0.12271, 0.18956},  //
    {2.260, 2.41770, 0.13251, 0.20254},  //
    {2.280, 2.47180, 0.13879, 0.18454},  //
    {2.300, 2.50910, 0.14658, 0.18261}   //
};

constexpr size_t kNumRecords =
    sizeof(kPrecomputedVariables) / sizeof(kPrecomputedVariables[0]);
constexpr Scalar kMinRatio = kPrecomputedVariables[0][0];
constexpr Scalar kMaxRatio = kPrecomputedVariables[kNumRecords - 1][0];
constexpr Scalar kRatioStep =
    kPrecomputedVariables[1][0] - kPrecomputedVariables[0][0];

// Linear interpolation for `kPrecomputedVariables`.
//
// The `column` is a 0-based index that decides the target variable, where 1
// corresponds to the 2nd element of each row, etc.
//
// The `ratio` corresponds to column 0, on which the lerp is calculated.
Scalar LerpPrecomputedVariable(size_t column, Scalar ratio) {
  Scalar steps =
      std::clamp<Scalar>((ratio - kMinRatio) / kRatioStep, 0, kNumRecords - 1);
  size_t left = std::clamp<size_t>(static_cast<size_t>(std::floor(steps)), 0,
                                   kNumRecords - 2);
  Scalar frac = steps - left;

  return (1 - frac) * kPrecomputedVariables[left][column] +
         frac * kPrecomputedVariables[left + 1][column];
}

// Return the value that splits the range from `left` to `right` into two
// portions whose ratio equals to `ratio_left` : `ratio_right`.
Scalar Split(Scalar left, Scalar right, Scalar ratio_left, Scalar ratio_right) {
  return (left * ratio_right + right * ratio_left) / (ratio_left + ratio_right);
}

// Find the center of the circle that passes the given two points and have the
// given radius.
Point FindCircleCenter(Point a, Point b, Scalar r) {
  /* Denote the middle point of A and B as M. The key is to find the center of
   * the circle.
   *         A --__
   *          /  ⟍ `、
   *         /   M  ⟍\
   *        /       ⟋  B
   *       /     ⟋   ↗
   *      /   ⟋
   *     / ⟋    r
   *  C ᜱ  ↙
   */

  Point a_to_b = b - a;
  Point m = (a + b) / 2;
  Point c_to_m = Point(-a_to_b.y, a_to_b.x);
  Scalar distance_am = a_to_b.GetLength() / 2;
  Scalar distance_cm = sqrt(r * r - distance_am * distance_am);
  return m - distance_cm * c_to_m.Normalize();
}

// Compute parameters for the first quadrant of a square-like rounded
// superellipse with a symmetrical radius.
RoundSuperellipseParam::Octant ComputeOctant(Point center,
                                             Scalar size,
                                             Scalar radius) {
  Scalar ratio = {std::min(size / radius, kMaxRatio)};
  Scalar a = ratio * radius / 2;
  Scalar s = size / 2 - a;
  Scalar g = kGapFactor * radius;

  Scalar n = LerpPrecomputedVariable(1, ratio);
  Scalar d = LerpPrecomputedVariable(2, ratio) * a;
  Scalar thetaJ = LerpPrecomputedVariable(3, ratio);

  Scalar R = (a - d - g) * sqrt(2);

  Point pointA{0, size / 2};
  Point pointM{size / 2 - g, size / 2 - g};
  Point pointS{s, s};
  Point pointJ =
      Point{pow(abs(sinf(thetaJ)), 2 / n), pow(abs(cosf(thetaJ)), 2 / n)} * a +
      pointS;
  Point circle_center = FindCircleCenter(pointA, pointM, R);

  return RoundSuperellipseParam::Octant{
      .start = pointA,

      .se_center = pointS,
      .se_a = a,
      .se_n = n,
      .se_max_theta = thetaJ,

      .circle_start = pointJ,
      .circle_center = circle_center,
      .circle_max_angle =
          (pointJ - circle_center).AngleTo(pointM - circle_center),
  };
}

// Compute parameters for a quadrant of a rounded superellipse with asymmetrical
// radii.
//
// The target quadrant is specified by the direction of `corner` relative to
// `center`.
RoundSuperellipseParam::Quadrant ComputeQuadrant(Point center,
                                                 Point corner,
                                                 Size radii) {
  Point full_half_size = corner - center;
  if (radii.width == 0 || radii.height == 0) {
    Point abs_full_half_size = full_half_size.Abs();
    RoundSuperellipseParam::Octant empty{
        .start = abs_full_half_size,

        .se_center = abs_full_half_size,
        .se_a = 0,
        .se_n = 2,
        .se_max_theta = 0,

        .circle_start = abs_full_half_size,
        .circle_center = abs_full_half_size,
        .circle_max_angle = Radians(0),
    };
    return RoundSuperellipseParam::Quadrant{
        .center = center,
        .signed_scale = full_half_size / abs_full_half_size,
        .norm_radius = 0,
        .top = empty,
        .right = empty,
    };
  }
  // Normalize sizes and radii into symmetrical radius by scaling the longer of
  // `radii` to the shorter. For example, to draw a RSE with size (200, 300)
  // and radii (20, 10), this function draws one with size (100, 300) and radii
  // (10, 10) and then scales it by (2x, 1x).
  Scalar norm_radius = radii.MinDimension();
  Size radius_scale = radii / norm_radius;
  Point signed_size = full_half_size * 2;
  Point norm_size = signed_size.Abs() / radius_scale;
  Point signed_scale = signed_size / norm_size;

  // Each quadrant curve is composed of two octant curves, each of which belongs
  // to a square-like rounded rectangle. The centers these two square-like
  // rounded rectangle are offset from the origin by the same distance in
  // different directions. The distance is denoted as `eccentric`.
  Scalar eccentric = (norm_size.x - norm_size.y) / 2;

  return RoundSuperellipseParam::Quadrant{
      .center = center,
      .signed_scale = signed_scale,
      .norm_radius = norm_radius,
      .top = ComputeOctant(Point{0, -eccentric}, norm_size.x, norm_radius),
      .right = ComputeOctant(Point{eccentric, 0}, norm_size.y, norm_radius),
  };
}

}  // namespace

RoundSuperellipseParam RoundSuperellipseParam::MakeBoundsRadii(
    const Rect& bounds_,
    const RoundingRadii& radii_) {
  Scalar top_split = Split(bounds_.GetLeft(), bounds_.GetRight(),
                           radii_.top_left.width, radii_.top_right.width);
  Scalar right_split =
      Split(bounds_.GetTop(), bounds_.GetBottom(), radii_.top_right.height,
            radii_.bottom_right.height);
  Scalar bottom_split =
      Split(bounds_.GetLeft(), bounds_.GetRight(), radii_.bottom_left.width,
            radii_.bottom_right.width);
  Scalar left_split = Split(bounds_.GetTop(), bounds_.GetBottom(),
                            radii_.top_left.height, radii_.bottom_left.height);

  return RoundSuperellipseParam{
      .top_left = ComputeQuadrant(Point{top_split, left_split},
                                  bounds_.GetLeftTop(), radii_.top_left),
      .top_right = ComputeQuadrant(Point{top_split, right_split},
                                   bounds_.GetRightTop(), radii_.top_right),
      .bottom_left =
          ComputeQuadrant(Point{bottom_split, left_split},
                          bounds_.GetLeftBottom(), radii_.bottom_left),
      .bottom_right =
          ComputeQuadrant(Point{bottom_split, right_split},
                          bounds_.GetRightBottom(), radii_.bottom_right),

  };
}

}  // namespace impeller
