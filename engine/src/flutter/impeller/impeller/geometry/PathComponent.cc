// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "PathComponent.h"
#include <cmath>

namespace impeller {

static const size_t kRecursionLimit = 32;
static const double kCurveCollinearityEpsilon = 1e-30;
static const double kCurveAngleToleranceEpsilon = 0.01;

/*
 *  Based on: https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Specific_cases
 */

static inline double LinearSolve(double t, double p0, double p1) {
  return p0 + t * (p1 - p0);
}

static inline double QuadraticSolve(double t, double p0, double p1, double p2) {
  return (1 - t) * (1 - t) * p0 +  //
         2 * (1 - t) * t * p1 +    //
         t * t * p2;
}

static inline double QuadraticSolveDerivative(double t,
                                              double p0,
                                              double p1,
                                              double p2) {
  return 2 * (1 - t) * (p1 - p0) +  //
         2 * t * (p2 - p1);
}

static inline double CubicSolve(double t,
                                double p0,
                                double p1,
                                double p2,
                                double p3) {
  return (1 - t) * (1 - t) * (1 - t) * p0 +  //
         3 * (1 - t) * (1 - t) * t * p1 +    //
         3 * (1 - t) * t * t * p2 +          //
         t * t * t * p3;
}

static inline double CubicSolveDerivative(double t,
                                          double p0,
                                          double p1,
                                          double p2,
                                          double p3) {
  return -3 * p0 * (1 - t) * (1 - t) +  //
         p1 * (3 * (1 - t) * (1 - t) - 6 * (1 - t) * t) +
         p2 * (6 * (1 - t) * t - 3 * t * t) +  //
         3 * p3 * t * t;
}

Point LinearPathComponent::Solve(double time) const {
  return {
      LinearSolve(time, p1.x, p2.x),  // x
      LinearSolve(time, p1.y, p2.y),  // y
  };
}

std::vector<Point> LinearPathComponent::SmoothPoints() const {
  return {p1, p2};
}

std::vector<Point> LinearPathComponent::Extrema() const {
  return {p1, p2};
}

Point QuadraticPathComponent::Solve(double time) const {
  return {
      QuadraticSolve(time, p1.x, cp.x, p2.x),  // x
      QuadraticSolve(time, p1.y, cp.y, p2.y),  // y
  };
}

Point QuadraticPathComponent::SolveDerivative(double time) const {
  return {
      QuadraticSolveDerivative(time, p1.x, cp.x, p2.x),  // x
      QuadraticSolveDerivative(time, p1.y, cp.y, p2.y),  // y
  };
}

std::vector<Point> QuadraticPathComponent::SmoothPoints(
    const SmoothingApproximation& approximation) const {
  CubicPathComponent elevated(*this);
  return elevated.SmoothPoints(approximation);
}

std::vector<Point> QuadraticPathComponent::Sxtrema() const {
  CubicPathComponent elevated(*this);
  return elevated.Extrema();
}

Point CubicPathComponent::Solve(double time) const {
  return {
      CubicSolve(time, p1.x, cp1.x, cp2.x, p2.x),  // x
      CubicSolve(time, p1.y, cp1.y, cp2.y, p2.y),  // y
  };
}

Point CubicPathComponent::SolveDerivative(double time) const {
  return {
      CubicSolveDerivative(time, p1.x, cp1.x, cp2.x, p2.x),  // x
      CubicSolveDerivative(time, p1.y, cp1.y, cp2.y, p2.y),  // y
  };
}

/*
 *  Paul de Casteljau's subdivision with modifications as described in
 *  http://www.antigrain.com/research/adaptive_bezier/index.html.
 *  Refer to the diagram on that page for a description of the points.
 */
static void CubicPathSmoothenRecursive(const SmoothingApproximation& approx,
                                       std::vector<Point>& points,
                                       Point p1,
                                       Point p2,
                                       Point p3,
                                       Point p4,
                                       size_t level) {
  if (level >= kRecursionLimit) {
    return;
  }

  /*
   *  Find all midpoints.
   */
  auto p12 = (p1 + p2) / 2.0;
  auto p23 = (p2 + p3) / 2.0;
  auto p34 = (p3 + p4) / 2.0;

  auto p123 = (p12 + p23) / 2.0;
  auto p234 = (p23 + p34) / 2.0;

  auto p1234 = (p123 + p234) / 2.0;

  /*
   *  Attempt approximation using single straight line.
   */
  auto d = p4 - p1;
  double d2 = fabs(((p2.x - p4.x) * d.y - (p2.y - p4.y) * d.x));
  double d3 = fabs(((p3.x - p4.x) * d.y - (p3.y - p4.y) * d.x));

  double da1 = 0;
  double da2 = 0;
  double k = 0;

  switch ((static_cast<int>(d2 > kCurveCollinearityEpsilon) << 1) +
          static_cast<int>(d3 > kCurveCollinearityEpsilon)) {
    case 0:
      /*
       *  All collinear OR p1 == p4.
       */
      k = d.x * d.x + d.y * d.y;
      if (k == 0) {
        d2 = p1.GetDistanceSquared(p2);
        d3 = p4.GetDistanceSquared(p3);
      } else {
        k = 1.0 / k;
        da1 = p2.x - p1.x;
        da2 = p2.y - p1.y;
        d2 = k * (da1 * d.x + da2 * d.y);
        da1 = p3.x - p1.x;
        da2 = p3.y - p1.y;
        d3 = k * (da1 * d.x + da2 * d.y);

        if (d2 > 0 && d2 < 1 && d3 > 0 && d3 < 1) {
          /*
           *  Simple collinear case, 1---2---3---4. Leave just two endpoints.
           */
          return;
        }

        if (d2 <= 0) {
          d2 = p2.GetDistanceSquared(p1);
        } else if (d2 >= 1) {
          d2 = p2.GetDistanceSquared(p4);
        } else {
          d2 = p2.GetDistanceSquared({p1.x + d2 * d.x, p1.y + d2 * d.y});
        }

        if (d3 <= 0) {
          d3 = p3.GetDistanceSquared(p1);
        } else if (d3 >= 1) {
          d3 = p3.GetDistanceSquared(p4);
        } else {
          d3 = p3.GetDistanceSquared({p1.x + d3 * d.x, p1.y + d3 * d.y});
        }
      }

      if (d2 > d3) {
        if (d2 < approx.distanceToleranceSquare) {
          points.emplace_back(p2);
          return;
        }
      } else {
        if (d3 < approx.distanceToleranceSquare) {
          points.emplace_back(p3);
          return;
        }
      }
      break;
    case 1:
      /*
       *  p1, p2, p4 are collinear, p3 is significant.
       */
      if (d3 * d3 <= approx.distanceToleranceSquare * (d.x * d.x + d.y * d.y)) {
        if (approx.angleTolerance < kCurveAngleToleranceEpsilon) {
          points.emplace_back(p23);
          return;
        }

        /*
         *  Angle Condition.
         */
        da1 = ::fabs(::atan2(p4.y - p3.y, p4.x - p3.x) -
                     ::atan2(p3.y - p2.y, p3.x - p2.x));

        if (da1 >= M_PI) {
          da1 = 2.0 * M_PI - da1;
        }

        if (da1 < approx.angleTolerance) {
          points.emplace_back(p2);
          points.emplace_back(p3);
          return;
        }

        if (approx.cuspLimit != 0.0) {
          if (da1 > approx.cuspLimit) {
            points.emplace_back(p3);
            return;
          }
        }
      }
      break;

    case 2:
      /*
       *  p1,p3,p4 are collinear, p2 is significant.
       */
      if (d2 * d2 <= approx.distanceToleranceSquare * (d.x * d.x + d.y * d.y)) {
        if (approx.angleTolerance < kCurveAngleToleranceEpsilon) {
          points.emplace_back(p23);
          return;
        }

        /*
         *  Angle Condition.
         */
        da1 = ::fabs(::atan2(p3.y - p2.y, p3.x - p2.x) -
                     ::atan2(p2.y - p1.y, p2.x - p1.x));

        if (da1 >= M_PI) {
          da1 = 2.0 * M_PI - da1;
        }

        if (da1 < approx.angleTolerance) {
          points.emplace_back(p2);
          points.emplace_back(p3);
          return;
        }

        if (approx.cuspLimit != 0.0) {
          if (da1 > approx.cuspLimit) {
            points.emplace_back(p2);
            return;
          }
        }
      }
      break;

    case 3:
      /*
       *  Regular case.
       */
      if ((d2 + d3) * (d2 + d3) <=
          approx.distanceToleranceSquare * (d.x * d.x + d.y * d.y)) {
        /*
         *  If the curvature doesn't exceed the distance_tolerance value
         *  we tend to finish subdivisions.
         */
        if (approx.angleTolerance < kCurveAngleToleranceEpsilon) {
          points.emplace_back(p23);
          return;
        }

        /*
         *  Angle & Cusp Condition.
         */
        k = ::atan2(p3.y - p2.y, p3.x - p2.x);
        da1 = ::fabs(k - ::atan2(p2.y - p1.y, p2.x - p1.x));
        da2 = ::fabs(::atan2(p4.y - p3.y, p4.x - p3.x) - k);

        if (da1 >= M_PI) {
          da1 = 2.0 * M_PI - da1;
        }

        if (da2 >= M_PI) {
          da2 = 2.0 * M_PI - da2;
        }

        if (da1 + da2 < approx.angleTolerance) {
          /*
           *  Finally we can stop the recursion.
           */
          points.emplace_back(p23);
          return;
        }

        if (approx.cuspLimit != 0.0) {
          if (da1 > approx.cuspLimit) {
            points.emplace_back(p2);
            return;
          }

          if (da2 > approx.cuspLimit) {
            points.emplace_back(p3);
            return;
          }
        }
      }
      break;
  }

  /*
   *  Continue subdivision.
   */
  CubicPathSmoothenRecursive(approx, points, p1, p12, p123, p1234, level + 1);
  CubicPathSmoothenRecursive(approx, points, p1234, p234, p34, p4, level + 1);
}

std::vector<Point> CubicPathComponent::SmoothPoints(
    const SmoothingApproximation& approximation) const {
  std::vector<Point> points;
  points.emplace_back(p1);
  CubicPathSmoothenRecursive(approximation, points, p1, cp1, cp2, p2, 0);
  points.emplace_back(p2);
  return points;
}

static inline bool NearEqual(double a, double b, double epsilon) {
  return (a > (b - epsilon)) && (a < (b + epsilon));
}

static inline bool NearZero(double a) {
  return NearEqual(a, 0.0, 1e-12);
}

static void CubicPathBoundingPopulateValues(std::vector<double>& values,
                                            double p1,
                                            double p2,
                                            double p3,
                                            double p4) {
  const double a = 3.0 * (-p1 + 3.0 * p2 - 3.0 * p3 + p4);
  const double b = 6.0 * (p1 - 2.0 * p2 + p3);
  const double c = 3.0 * (p2 - p1);

  /*
   *  Boundary conditions.
   */
  if (NearZero(a)) {
    if (NearZero(b)) {
      return;
    }

    double t = -c / b;
    if (t >= 0.0 && t <= 1.0) {
      values.emplace_back(t);
    }
    return;
  }

  double b2Minus4AC = (b * b) - (4.0 * a * c);

  if (b2Minus4AC < 0.0) {
    return;
  }

  double rootB2Minus4AC = ::sqrt(b2Minus4AC);

  {
    double t = (-b + rootB2Minus4AC) / (2.0 * a);
    if (t >= 0.0 && t <= 1.0) {
      values.emplace_back(t);
    }
  }

  {
    double t = (-b - rootB2Minus4AC) / (2.0 * a);
    if (t >= 0.0 && t <= 1.0) {
      values.emplace_back(t);
    }
  }
}

std::vector<Point> CubicPathComponent::Extrema() const {
  /*
   *  As described in: https://pomax.github.io/bezierinfo/#extremities
   */
  std::vector<double> values;

  CubicPathBoundingPopulateValues(values, p1.x, cp1.x, cp2.x, p2.x);
  CubicPathBoundingPopulateValues(values, p1.y, cp1.y, cp2.y, p2.y);

  std::vector<Point> points;

  for (const auto& value : values) {
    points.emplace_back(Solve(value));
  }

  return points;
}

}  // namespace impeller
