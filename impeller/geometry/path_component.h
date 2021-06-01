// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "rect.h"

namespace impeller {

struct SmoothingApproximation {
  const double scale;
  const double angleTolerance;
  const double cuspLimit;
  const double distanceToleranceSquare;

  SmoothingApproximation(/* default */)
      : SmoothingApproximation(1.0 /* scale */,
                               0.0 /* angle tolerance */,
                               0.0 /* cusp limit */) {}

  SmoothingApproximation(double pScale,
                         double pAngleTolerance,
                         double pCuspLimit)
      : scale(pScale),
        angleTolerance(pAngleTolerance),
        cuspLimit(pCuspLimit),
        distanceToleranceSquare(0.5 * pScale * 0.5 * pScale) {}
};

struct LinearPathComponent {
  Point p1;
  Point p2;

  LinearPathComponent() {}

  LinearPathComponent(Point ap1, Point ap2) : p1(ap1), p2(ap2) {}

  Point Solve(double time) const;

  std::vector<Point> SmoothPoints() const;

  std::vector<Point> Extrema() const;

  bool operator==(const LinearPathComponent& other) const {
    return p1 == other.p1 && p2 == other.p2;
  }
};

struct QuadraticPathComponent {
  Point p1;
  Point cp;
  Point p2;

  QuadraticPathComponent() {}

  QuadraticPathComponent(Point ap1, Point acp, Point ap2)
      : p1(ap1), cp(acp), p2(ap2) {}

  Point Solve(double time) const;

  Point SolveDerivative(double time) const;

  std::vector<Point> SmoothPoints(
      const SmoothingApproximation& approximation) const;

  std::vector<Point> Sxtrema() const;

  bool operator==(const QuadraticPathComponent& other) const {
    return p1 == other.p1 && cp == other.cp && p2 == other.p2;
  }
};

struct CubicPathComponent {
  Point p1;
  Point cp1;
  Point cp2;
  Point p2;

  CubicPathComponent() {}

  CubicPathComponent(const QuadraticPathComponent& q)
      : p1(q.p1),
        cp1(q.p1 + (q.cp - q.p1) * (2.0 / 3.0)),
        cp2(q.p2 + (q.cp - q.p2) * (2.0 / 3.0)),
        p2(q.p2) {}

  CubicPathComponent(Point ap1, Point acp1, Point acp2, Point ap2)
      : p1(ap1), cp1(acp1), cp2(acp2), p2(ap2) {}

  Point Solve(double time) const;

  Point SolveDerivative(double time) const;

  std::vector<Point> SmoothPoints(
      const SmoothingApproximation& approximation) const;

  std::vector<Point> Extrema() const;

  bool operator==(const CubicPathComponent& other) const {
    return p1 == other.p1 && cp1 == other.cp1 && cp2 == other.cp2 &&
           p2 == other.p2;
  }
};

}  // namespace impeller
