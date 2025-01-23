// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/round_superellipse_param.h"

namespace impeller {

namespace {

// Return the value that splits the range from `left` to `right` into two
// portions whose ratio equals to `ratio_left` : `ratio_right`.
Scalar Split(Scalar left, Scalar right, Scalar ratio_left, Scalar ratio_right) {
  if (ratio_left == 0 && ratio_right == 0) {
    return (left + right) / 2;
  }
  return (left * ratio_right + right * ratio_left) / (ratio_left + ratio_right);
}

// Return the same Point, but each NaN coordinate is replaced by 1.
inline Point ReplanceNaNWithOne(Point in) {
  return Point{std::isnan(in.x) ? 1 : in.x, std::isnan(in.y) ? 1 : in.y};
}

// Swap the x and y coordinate of a point.
//
// Effectively mirrors the point by the y=x line.
inline Point Flip(Point a) {
  return Point{a.y, a.x};
}

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

// Compute parameters for a square-like rounded superellipse with a symmetrical
// radius.
RoundSuperellipseParam::Octant ComputeOctant(Point center,
                                             Scalar half_size,
                                             Scalar radius) {
  /* The following figure shows the first quadrant of a square-like rounded
   * superellipse. The target arc consists of the "stretch" (AB), a
   * superellipsoid arc (BJ), and a circular arc (JM).
   *
   *     straight   superelipse
   *          ↓     ↓
   *        A    B       J    circular arc
   *        ---------...._   ↙
   *        |    |      /  `⟍ M
   *        |    |     /    ⟋ ⟍
   *        |    |    /  ⟋     \
   *        |    |   / ⟋        |
   *        |    |  ᜱD          |
   *        |    | /             |
   *    ↑   +----+ S             |
   *    s   |    |               |
   *    ↓   +----+---------------| A'
   *       O
   *        ← s →
   *        ←---- half_size -----→
   */

  Scalar ratio =
      radius == 0 ? kMaxRatio : std::min(half_size * 2 / radius, kMaxRatio);
  Scalar a = ratio * radius / 2;
  Scalar s = half_size - a;
  Scalar g = kGapFactor * radius;

  Scalar n = LerpPrecomputedVariable(1, ratio);
  Scalar d = LerpPrecomputedVariable(2, ratio) * a;
  Scalar thetaJ = radius == 0 ? 0 : LerpPrecomputedVariable(3, ratio);

  Scalar R = (a - d - g) * sqrt(2);

  Point pointA{0, half_size};
  Point pointM{half_size - g, half_size - g};
  Point pointS{s, s};
  Point pointJ =
      Point{pow(abs(sinf(thetaJ)), 2 / n), pow(abs(cosf(thetaJ)), 2 / n)} * a +
      pointS;
  Point circle_center =
      radius == 0 ? pointM : FindCircleCenter(pointJ, pointM, R);
  Radians circle_max_angle =
      radius == 0 ? Radians(0)
                  : (pointM - circle_center).AngleTo(pointJ - circle_center);

  return RoundSuperellipseParam::Octant{
      .offset = center,

      .edge_mid = pointA,

      .se_center = pointS,
      .se_a = a,
      .se_n = n,
      .se_max_theta = thetaJ,

      .circle_start = pointJ,
      .circle_center = circle_center,
      .circle_max_angle = circle_max_angle,
  };
}

// Compute parameters for a quadrant of a rounded superellipse with asymmetrical
// radii.
//
// The `corner` is the coordinate of the corner point in the same coordinate
// space as `center`, which specifies both the half size of the bounding box and
// which quadrant the curve should be.
RoundSuperellipseParam::Quadrant ComputeQuadrant(Point center,
                                                 Point corner,
                                                 Size in_radii) {
  Point corner_vector = corner - center;
  Size radii = in_radii.Abs();

  // The prefix "norm" is short for "normalized".
  //
  // Be extra careful to avoid NaNs in cases that some coordinates of `in_radii`
  // or `corner_vector` are zero.
  Scalar norm_radius = radii.MinDimension();
  Size forward_scale = norm_radius == 0 ? Size{1, 1} : radii / norm_radius;
  Point norm_half_size = corner_vector.Abs() / forward_scale;
  Point signed_scale = ReplanceNaNWithOne(corner_vector / norm_half_size);

  // Each quadrant curve is composed of two octant curves, each of which belongs
  // to a square-like rounded rectangle. For the two octants to connect at the
  // circular arc, the centers these two square-like rounded rectangle must be
  // offset from the quadrant center by a same distance in different directions.
  // The distance is denoted as `c`.
  Scalar c = norm_half_size.x - norm_half_size.y;

  return RoundSuperellipseParam::Quadrant{
      .offset = center,
      .signed_scale = signed_scale,
      .top = ComputeOctant(Point{0, -c}, norm_half_size.x, norm_radius),
      .right = ComputeOctant(Point{c, 0}, norm_half_size.y, norm_radius),
  };
}

// Checks whether the given point is contained in the first octant of the given
// square-like rounded superellipse.
//
// The first octant refers to the region that spans from 0 to pi/4 starting from
// positive Y axis clockwise.
//
// If the point is not within this octant at all, then this function always
// returns true.  Otherwise this function returns whether the point is contained
// within the rounded superellipse.
//
// The `param.offset` is ignored. The input point should have been transformed
// to the coordinate space where the rounded superellipse is centered at the
// origin.
bool OctantContains(const RoundSuperellipseParam::Octant& param,
                    const Point& p) {
  // Check whether the point is within the octant.
  if (p.x < 0 || p.y < 0 || p.y < p.x) {
    return true;
  }
  // Check if the point is within the stretch segment.
  if (p.x <= param.se_center.x) {
    return p.y <= param.edge_mid.y;
  }
  // Check if the point is within the superellipsoid segment.
  if (p.x <= param.circle_start.x) {
    Point p_se = (p - param.se_center) / param.se_a;
    return powf(p_se.x, param.se_n) + powf(p_se.y, param.se_n) <= 1;
  }
  Scalar circle_radius =
      param.circle_start.GetDistanceSquared(param.circle_center);
  Point p_circle = p - param.circle_center;
  return p_circle.GetDistanceSquared(Point()) < circle_radius;
}

// Checks whether the given quadrant contains the given point if the point is
// under the quadrant's jurisdiction.
//
// If `check_quadrant` is true, then this function first checks if the point is
// governed by the given quadrant, and returns true if not. Otherwise this
// method returns whether the point is contained in the rounded superellipse.
//
// If `check_quadrant` is false, then the first step above is skipped, and the
// function flips the point to the target quadrant and checks containment.
bool QuadrantContains(const RoundSuperellipseParam::Quadrant& param,
                      const Point& in_point,
                      bool check_quadrant = true) {
  Point norm_point = (in_point - param.offset) / param.signed_scale;
  if (check_quadrant) {
    if (norm_point.x < 0 || norm_point.y < 0) {
      return false;
    }
  } else {
    norm_point = norm_point.Abs();
  }
  return OctantContains(param.top, norm_point - param.top.offset) &&
         OctantContains(param.right, Flip(norm_point - param.right.offset));
}

}  // namespace

RoundSuperellipseParam RoundSuperellipseParam::MakeBoundsRadii(
    const Rect& bounds_,
    const RoundingRadii& radii_) {
  if (radii_.AreAllCornersSame()) {
    return RoundSuperellipseParam{
        .top_right = ComputeQuadrant(bounds_.GetCenter(), bounds_.GetRightTop(),
                                     radii_.top_right),
        .all_corners_same = true,
    };
  }
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
      .top_right = ComputeQuadrant(Point{top_split, right_split},
                                   bounds_.GetRightTop(), radii_.top_right),
      .bottom_right =
          ComputeQuadrant(Point{bottom_split, right_split},
                          bounds_.GetRightBottom(), radii_.bottom_right),
      .bottom_left =
          ComputeQuadrant(Point{bottom_split, left_split},
                          bounds_.GetLeftBottom(), radii_.bottom_left),
      .top_left = ComputeQuadrant(Point{top_split, left_split},
                                  bounds_.GetLeftTop(), radii_.top_left),
      .all_corners_same = false,
  };
}

bool RoundSuperellipseParam::Contains(const Point& point) const {
  if (all_corners_same) {
    return QuadrantContains(top_right, point, /*check_quadrant=*/false);
  }
  return QuadrantContains(top_right, point) &&
         QuadrantContains(bottom_right, point) &&
         QuadrantContains(bottom_left, point) &&
         QuadrantContains(top_left, point);
}

}  // namespace impeller
