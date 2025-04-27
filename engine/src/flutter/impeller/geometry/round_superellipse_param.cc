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

// A look up table with precomputed variables.
//
// The columns represent the following variabls respectively:
//
//  * n
//  * k_xJ, which is defined as 1 / (1 - xJ / a)
//
// For definition of the variables, see ComputeOctant.
constexpr Scalar kPrecomputedVariables[][2] = {
    /*ratio=2.00*/ {2.00000000, 1.13276676},
    /*ratio=2.10*/ {2.18349805, 1.20311921},
    /*ratio=2.20*/ {2.33888662, 1.28698796},
    /*ratio=2.30*/ {2.48660575, 1.36351941},
    /*ratio=2.40*/ {2.62226596, 1.44717976},
    /*ratio=2.50*/ {2.75148990, 1.53385819},
    /*ratio=3.00*/ {3.36298265, 1.98288283},
    /*ratio=3.50*/ {4.08649929, 2.23811846},
    /*ratio=4.00*/ {4.85481134, 2.47563463},
    /*ratio=4.50*/ {5.62945551, 2.72948597},
    /*ratio=5.00*/ {6.43023796, 2.98020421}};

constexpr Scalar kMinRatio = 2.00;

// The curve is split into 3 parts:
// * The first part uses a denser look up table.
// * The second part uses a sparser look up table.
// * The third part uses a straight line.
constexpr Scalar kFirstStepInverse = 10;  // = 1 / 0.10
constexpr Scalar kFirstMaxRatio = 2.50;
constexpr Scalar kFirstNumRecords = 6;

constexpr Scalar kSecondStepInverse = 2;  // = 1 / 0.50
constexpr Scalar kSecondMaxRatio = 5.00;

constexpr Scalar kThirdNSlope = 1.559599389;
constexpr Scalar kThirdKxjSlope = 0.522807185;

constexpr size_t kNumRecords =
    sizeof(kPrecomputedVariables) / sizeof(kPrecomputedVariables[0]);

// Compute the `n` and `xJ / a` for the given ratio.
std::array<Scalar, 2> ComputeNAndXj(Scalar ratio) {
  if (ratio > kSecondMaxRatio) {
    Scalar n = kThirdNSlope * (ratio - kSecondMaxRatio) +
               kPrecomputedVariables[kNumRecords - 1][0];
    Scalar k_xJ = kThirdKxjSlope * (ratio - kSecondMaxRatio) +
                  kPrecomputedVariables[kNumRecords - 1][1];
    return {n, 1 - 1 / k_xJ};
  }
  ratio = std::clamp(ratio, kMinRatio, kSecondMaxRatio);
  Scalar steps;
  if (ratio < kFirstMaxRatio) {
    steps = (ratio - kMinRatio) * kFirstStepInverse;
  } else {
    steps =
        (ratio - kFirstMaxRatio) * kSecondStepInverse + kFirstNumRecords - 1;
  }

  size_t left = std::clamp<size_t>(static_cast<size_t>(std::floor(steps)), 0,
                                   kNumRecords - 2);
  Scalar frac = steps - left;

  Scalar n = (1 - frac) * kPrecomputedVariables[left][0] +
             frac * kPrecomputedVariables[left + 1][0];
  Scalar k_xJ = (1 - frac) * kPrecomputedVariables[left][1] +
                frac * kPrecomputedVariables[left + 1][1];
  return {n, 1 - 1 / k_xJ};
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
                                             Scalar a,
                                             Scalar radius) {
  /* The following figure shows the first quadrant of a square-like rounded
   * superellipse.
   *
   *              superelipse
   *        A     ↓            circular arc
   *        ---------...._J   ↙
   *        |           /   `⟍ M (where x=y)
   *        |          /     ⟋ ⟍
   *        |         /   ⟋     \
   *        |        / ⟋         |
   *        |       ᜱD           |
   *        |     ⟋              |
   *        |  ⟋                 |
   *        |⟋                   |
   *        +--------------------| A'
   *       O
   *        ←-------- a ---------→
   */

  if (radius <= 0) {
    return RoundSuperellipseParam::Octant{
        .offset = center,

        .se_a = a,
        .se_n = 0,
    };
  }

  Scalar ratio = a * 2 / radius;
  Scalar g = RoundSuperellipseParam::kGapFactor * radius;

  auto precomputed_vars = ComputeNAndXj(ratio);
  Scalar n = precomputed_vars[0];
  Scalar xJ = precomputed_vars[1] * a;
  Scalar yJ = pow(1 - pow(precomputed_vars[1], n), 1 / n) * a;
  Scalar max_theta = asinf(pow(precomputed_vars[1], n / 2));

  Scalar tan_phiJ = pow(xJ / yJ, n - 1);
  Scalar d = (xJ - tan_phiJ * yJ) / (1 - tan_phiJ);
  Scalar R = (a - d - g) * sqrt(2);

  Point pointM{a - g, a - g};
  Point pointJ = Point{xJ, yJ};
  Point circle_center =
      radius == 0 ? pointM : FindCircleCenter(pointJ, pointM, R);
  Radians circle_max_angle =
      radius == 0 ? Radians(0)
                  : (pointM - circle_center).AngleTo(pointJ - circle_center);

  return RoundSuperellipseParam::Octant{
      .offset = center,

      .se_a = a,
      .se_n = n,
      .se_max_theta = max_theta,

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
  // Check if the point is within the superellipsoid segment.
  if (p.x <= param.circle_start.x) {
    Point p_se = p / param.se_a;
    return powf(p_se.x, param.se_n) + powf(p_se.y, param.se_n) <= 1;
  }
  Scalar circle_radius =
      param.circle_start.GetDistanceSquared(param.circle_center);
  Point p_circle = p - param.circle_center;
  return p_circle.GetDistanceSquared(Point()) < circle_radius;
}

// Determine if p is inside the corner curve defined by the indicated corner
// param.
//
// The coordinates of p should be within the same coordinate space with
// `param.offset`.
//
// If `check_quadrant` is true, then this function first checks if the point is
// within the quadrant of given corner. If not, this function returns true,
// otherwise this method continues to check whether the point is contained in
// the rounded superellipse.
//
// If `check_quadrant` is false, then the first step above is skipped, and the
// function checks whether the absolute (relative to the center) coordinate of p
// is contained in the rounded superellipse.
bool CornerContains(const RoundSuperellipseParam::Quadrant& param,
                    const Point& p,
                    bool check_quadrant = true) {
  Point norm_point = (p - param.offset) / param.signed_scale;
  if (check_quadrant) {
    if (norm_point.x < 0 || norm_point.y < 0) {
      return true;
    }
  } else {
    norm_point = norm_point.Abs();
  }
  if (param.top.se_n < 2 || param.right.se_n < 2) {
    // A rectangular corner. The top and left sides contain the borders
    // while the bottom and right sides don't (see `Rect.contains`).
    Scalar x_delta = param.right.offset.x + param.right.se_a - norm_point.x;
    Scalar y_delta = param.top.offset.y + param.top.se_a - norm_point.y;
    bool x_within = x_delta > 0 || (x_delta == 0 && param.signed_scale.x < 0);
    bool y_within = y_delta > 0 || (y_delta == 0 && param.signed_scale.y < 0);
    return x_within && y_within;
  }
  return OctantContains(param.top, norm_point - param.top.offset) &&
         OctantContains(param.right, Flip(norm_point - param.right.offset));
}

class RoundSuperellipseBuilder {
 public:
  explicit RoundSuperellipseBuilder(PathBuilder& builder) : builder_(builder) {}

  // Draws an arc representing 1/4 of a rounded superellipse.
  //
  // If `reverse` is false, the resulting arc spans from 0 to pi/2, moving
  // clockwise starting from the positive Y-axis. Otherwise it moves from pi/2
  // to 0.
  void AddQuadrant(const RoundSuperellipseParam::Quadrant& param,
                   bool reverse,
                   Point scale_sign = Point(1, 1)) {
    auto transform = Matrix::MakeTranslateScale(param.signed_scale * scale_sign,
                                                param.offset);
    if (param.top.se_n < 2 || param.right.se_n < 2) {
      builder_.LineTo(transform * (param.top.offset +
                                   Point(param.top.se_a, param.top.se_a)));
      if (!reverse) {
        builder_.LineTo(transform *
                        (param.top.offset + Point(param.top.se_a, 0)));
      } else {
        builder_.LineTo(transform *
                        (param.top.offset + Point(0, param.top.se_a)));
      }
      return;
    }
    if (!reverse) {
      AddOctant(param.top, /*reverse=*/false, /*flip=*/false, transform);
      AddOctant(param.right, /*reverse=*/true, /*flip=*/true, transform);
    } else {
      AddOctant(param.right, /*reverse=*/false, /*flip=*/true, transform);
      AddOctant(param.top, /*reverse=*/true, /*flip=*/false, transform);
    }
  }

 private:
  std::array<Point, 4> SuperellipseArcPoints(
      const RoundSuperellipseParam::Octant& param) {
    Point start = {0, param.se_a};
    const Point& end = param.circle_start;
    constexpr Point start_tangent = {1, 0};
    Point circle_start_vector = param.circle_start - param.circle_center;
    Point end_tangent =
        Point{-circle_start_vector.y, circle_start_vector.x}.Normalize();

    std::array<Scalar, 2> factors = SuperellipseBezierFactors(param.se_n);

    return std::array<Point, 4>{
        start, start + start_tangent * factors[0] * param.se_a,
        end + end_tangent * factors[1] * param.se_a, end};
  };

  std::array<Point, 4> CircularArcPoints(
      const RoundSuperellipseParam::Octant& param) {
    Point start_vector = param.circle_start - param.circle_center;
    Point end_vector =
        start_vector.Rotate(Radians(-param.circle_max_angle.radians));
    Point circle_end = param.circle_center + end_vector;
    Point start_tangent = Point{start_vector.y, -start_vector.x}.Normalize();
    Point end_tangent = Point{-end_vector.y, end_vector.x}.Normalize();
    Scalar bezier_factor = std::tan(param.circle_max_angle.radians / 4) * 4 / 3;
    Scalar radius = start_vector.GetLength();

    return std::array<Point, 4>{
        param.circle_start,
        param.circle_start + start_tangent * bezier_factor * radius,
        circle_end + end_tangent * bezier_factor * radius, circle_end};
  };

  // Draws an arc representing 1/8 of a rounded superellipse.
  //
  // If `reverse` is false, the resulting arc spans from 0 to pi/4, moving
  // clockwise starting from the positive Y-axis. Otherwise it moves from pi/4
  // to 0.
  //
  // If `flip` is true, all points have their X and Y coordinates swapped,
  // effectively mirrowing each point by the y=x line.
  //
  // All points are transformed by `external_transform` after the optional
  // flipping before being used as control points for the cubic curves.
  void AddOctant(const RoundSuperellipseParam::Octant& param,
                 bool reverse,
                 bool flip,
                 const Matrix& external_transform) {
    Matrix transform =
        external_transform * Matrix::MakeTranslation(param.offset);
    if (flip) {
      transform = transform * kFlip;
    }

    auto circle_points = CircularArcPoints(param);
    auto se_points = SuperellipseArcPoints(param);

    if (!reverse) {
      builder_.CubicCurveTo(transform * se_points[1], transform * se_points[2],
                            transform * se_points[3]);
      builder_.CubicCurveTo(transform * circle_points[1],
                            transform * circle_points[2],
                            transform * circle_points[3]);
    } else {
      builder_.CubicCurveTo(transform * circle_points[2],
                            transform * circle_points[1],
                            transform * circle_points[0]);
      builder_.CubicCurveTo(transform * se_points[2], transform * se_points[1],
                            transform * se_points[0]);
    }
  };

  // Get the Bezier factor for the superellipse arc in a rounded superellipse.
  //
  // The result will be assigned to output, where [0] will be the factor for the
  // starting tangent and [1] for the ending tangent.
  //
  // These values are computed by brute-force searching for the minimal distance
  // on a rounded superellipse and are not for general purpose superellipses.
  std::array<Scalar, 2> SuperellipseBezierFactors(Scalar n) {
    constexpr Scalar kPrecomputedVariables[][2] = {
        /*n=2.0*/ {0.01339448, 0.05994973},
        /*n=3.0*/ {0.13664115, 0.13592082},
        /*n=4.0*/ {0.24545546, 0.14099516},
        /*n=5.0*/ {0.32353151, 0.12808021},
        /*n=6.0*/ {0.39093068, 0.11726264},
        /*n=7.0*/ {0.44847800, 0.10808278},
        /*n=8.0*/ {0.49817452, 0.10026175},
        /*n=9.0*/ {0.54105583, 0.09344429},
        /*n=10.0*/ {0.57812578, 0.08748984},
        /*n=11.0*/ {0.61050961, 0.08224722},
        /*n=12.0*/ {0.63903989, 0.07759639},
        /*n=13.0*/ {0.66416338, 0.07346530},
        /*n=14.0*/ {0.68675338, 0.06974996},
        /*n=15.0*/ {0.70678034, 0.06529512}};
    constexpr size_t kNumRecords =
        sizeof(kPrecomputedVariables) / sizeof(kPrecomputedVariables[0]);
    constexpr Scalar kStep = 1.00f;
    constexpr Scalar kMinN = 2.00f;
    constexpr Scalar kMaxN = kMinN + (kNumRecords - 1) * kStep;

    if (n >= kMaxN) {
      // Heuristic formula derived from fitting.
      return {1.07f - expf(1.307649835) * powf(n, -0.8568516731),
              -0.01f + expf(-0.9287690322) * powf(n, -0.6120901398)};
    }

    Scalar steps = std::clamp<Scalar>((n - kMinN) / kStep, 0, kNumRecords - 1);
    size_t left = std::clamp<size_t>(static_cast<size_t>(std::floor(steps)), 0,
                                     kNumRecords - 2);
    Scalar frac = steps - left;

    return std::array<Scalar, 2>{(1 - frac) * kPrecomputedVariables[left][0] +
                                     frac * kPrecomputedVariables[left + 1][0],
                                 (1 - frac) * kPrecomputedVariables[left][1] +
                                     frac * kPrecomputedVariables[left + 1][1]};
  }

  PathBuilder& builder_;

  // A matrix that swaps the coordinates of a point.
  // clang-format off
  static constexpr Matrix kFlip = Matrix(
    0.0f, 1.0f, 0.0f, 0.0f,
    1.0f, 0.0f, 0.0f, 0.0f,
    0.0f, 0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f);
  // clang-format on
};

}  // namespace

RoundSuperellipseParam RoundSuperellipseParam::MakeBoundsRadii(
    const Rect& bounds,
    const RoundingRadii& radii) {
  if (radii.AreAllCornersSame() && !radii.top_left.IsEmpty()) {
    // Having four empty corners indicate a rectangle, which needs special
    // treatment on border containment and therefore is not `all_corners_same`.
    return RoundSuperellipseParam{
        .top_right = ComputeQuadrant(bounds.GetCenter(), bounds.GetRightTop(),
                                     radii.top_right),
        .all_corners_same = true,
    };
  }
  Scalar top_split = Split(bounds.GetLeft(), bounds.GetRight(),
                           radii.top_left.width, radii.top_right.width);
  Scalar right_split = Split(bounds.GetTop(), bounds.GetBottom(),
                             radii.top_right.height, radii.bottom_right.height);
  Scalar bottom_split =
      Split(bounds.GetLeft(), bounds.GetRight(), radii.bottom_left.width,
            radii.bottom_right.width);
  Scalar left_split = Split(bounds.GetTop(), bounds.GetBottom(),
                            radii.top_left.height, radii.bottom_left.height);

  return RoundSuperellipseParam{
      .top_right = ComputeQuadrant(Point{top_split, right_split},
                                   bounds.GetRightTop(), radii.top_right),
      .bottom_right =
          ComputeQuadrant(Point{bottom_split, right_split},
                          bounds.GetRightBottom(), radii.bottom_right),
      .bottom_left = ComputeQuadrant(Point{bottom_split, left_split},
                                     bounds.GetLeftBottom(), radii.bottom_left),
      .top_left = ComputeQuadrant(Point{top_split, left_split},
                                  bounds.GetLeftTop(), radii.top_left),
      .all_corners_same = false,
  };
}

void RoundSuperellipseParam::AddToPath(PathBuilder& path_builder) const {
  RoundSuperellipseBuilder builder(path_builder);

  Point start = top_right.offset +
                top_right.signed_scale *
                    (top_right.top.offset + Point(0, top_right.top.se_a));
  path_builder.MoveTo(start);

  if (all_corners_same) {
    builder.AddQuadrant(top_right, /*reverse=*/false, Point(1, 1));
    builder.AddQuadrant(top_right, /*reverse=*/true, Point(1, -1));
    builder.AddQuadrant(top_right, /*reverse=*/false, Point(-1, -1));
    builder.AddQuadrant(top_right, /*reverse=*/true, Point(-1, 1));
  } else {
    builder.AddQuadrant(top_right, /*reverse=*/false);
    builder.AddQuadrant(bottom_right, /*reverse=*/true);
    builder.AddQuadrant(bottom_left, /*reverse=*/false);
    builder.AddQuadrant(top_left, /*reverse=*/true);
  }

  path_builder.LineTo(start);
  path_builder.Close();
}

bool RoundSuperellipseParam::Contains(const Point& point) const {
  if (all_corners_same) {
    return CornerContains(top_right, point, /*check_quadrant=*/false);
  }
  return CornerContains(top_right, point) &&
         CornerContains(bottom_right, point) &&
         CornerContains(bottom_left, point) && CornerContains(top_left, point);
}

}  // namespace impeller
