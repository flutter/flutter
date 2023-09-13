// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <type_traits>
#include <variant>
#include <vector>

#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

// The default tolerance value for QuadraticCurveComponent::CreatePolyline and
// CubicCurveComponent::CreatePolyline. It also impacts the number of quadratics
// created when flattening a cubic curve to a polyline.
//
// Smaller numbers mean more points. This number seems suitable for particularly
// curvy curves at scales close to 1.0. As the scale increases, this number
// should be divided by Matrix::GetMaxBasisLength to avoid generating too few
// points for the given scale.
static constexpr Scalar kDefaultCurveTolerance = .1f;

struct LinearPathComponent {
  Point p1;
  Point p2;

  LinearPathComponent() {}

  LinearPathComponent(Point ap1, Point ap2) : p1(ap1), p2(ap2) {}

  Point Solve(Scalar time) const;

  std::vector<Point> CreatePolyline() const;

  std::vector<Point> Extrema() const;

  bool operator==(const LinearPathComponent& other) const {
    return p1 == other.p1 && p2 == other.p2;
  }

  std::optional<Vector2> GetStartDirection() const;

  std::optional<Vector2> GetEndDirection() const;
};

// A component that represets a Quadratic Bézier curve.
struct QuadraticPathComponent {
  // Start point.
  Point p1;
  // Control point.
  Point cp;
  // End point.
  Point p2;

  QuadraticPathComponent() {}

  QuadraticPathComponent(Point ap1, Point acp, Point ap2)
      : p1(ap1), cp(acp), p2(ap2) {}

  Point Solve(Scalar time) const;

  Point SolveDerivative(Scalar time) const;

  // Uses the algorithm described by Raph Levien in
  // https://raphlinus.github.io/graphics/curves/2019/12/23/flatten-quadbez.html.
  //
  // The algorithm has several benefits:
  // - It does not require elevation to cubics for processing.
  // - It generates fewer and more accurate points than recursive subdivision.
  // - Each turn of the core iteration loop has no dependencies on other turns,
  //   making it trivially parallelizable.
  //
  // See also the implementation in kurbo: https://github.com/linebender/kurbo.
  std::vector<Point> CreatePolyline(Scalar scale) const;

  void FillPointsForPolyline(std::vector<Point>& points,
                             Scalar scale_factor) const;

  std::vector<Point> Extrema() const;

  bool operator==(const QuadraticPathComponent& other) const {
    return p1 == other.p1 && cp == other.cp && p2 == other.p2;
  }

  std::optional<Vector2> GetStartDirection() const;

  std::optional<Vector2> GetEndDirection() const;
};

// A component that represets a Cubic Bézier curve.
struct CubicPathComponent {
  // Start point.
  Point p1;
  // The first control point.
  Point cp1;
  // The second control point.
  Point cp2;
  // End point.
  Point p2;

  CubicPathComponent() {}

  CubicPathComponent(const QuadraticPathComponent& q)
      : p1(q.p1),
        cp1(q.p1 + (q.cp - q.p1) * (2.0 / 3.0)),
        cp2(q.p2 + (q.cp - q.p2) * (2.0 / 3.0)),
        p2(q.p2) {}

  CubicPathComponent(Point ap1, Point acp1, Point acp2, Point ap2)
      : p1(ap1), cp1(acp1), cp2(acp2), p2(ap2) {}

  Point Solve(Scalar time) const;

  Point SolveDerivative(Scalar time) const;

  // This method approximates the cubic component with quadratics, and then
  // generates a polyline from those quadratics.
  //
  // See the note on QuadraticPathComponent::CreatePolyline for references.
  std::vector<Point> CreatePolyline(Scalar scale) const;

  std::vector<Point> Extrema() const;

  std::vector<QuadraticPathComponent> ToQuadraticPathComponents(
      Scalar accuracy) const;

  CubicPathComponent Subsegment(Scalar t0, Scalar t1) const;

  bool operator==(const CubicPathComponent& other) const {
    return p1 == other.p1 && cp1 == other.cp1 && cp2 == other.cp2 &&
           p2 == other.p2;
  }

  std::optional<Vector2> GetStartDirection() const;

  std::optional<Vector2> GetEndDirection() const;

 private:
  QuadraticPathComponent Lower() const;
};

struct ContourComponent {
  Point destination;
  bool is_closed = false;

  ContourComponent() {}

  ContourComponent(Point p, bool is_closed = false)
      : destination(p), is_closed(is_closed) {}

  bool operator==(const ContourComponent& other) const {
    return destination == other.destination && is_closed == other.is_closed;
  }
};

using PathComponentVariant = std::variant<std::monostate,
                                          const LinearPathComponent*,
                                          const QuadraticPathComponent*,
                                          const CubicPathComponent*>;

struct PathComponentStartDirectionVisitor {
  std::optional<Vector2> operator()(const LinearPathComponent* component);
  std::optional<Vector2> operator()(const QuadraticPathComponent* component);
  std::optional<Vector2> operator()(const CubicPathComponent* component);
  std::optional<Vector2> operator()(std::monostate monostate) {
    return std::nullopt;
  }
};

struct PathComponentEndDirectionVisitor {
  std::optional<Vector2> operator()(const LinearPathComponent* component);
  std::optional<Vector2> operator()(const QuadraticPathComponent* component);
  std::optional<Vector2> operator()(const CubicPathComponent* component);
  std::optional<Vector2> operator()(std::monostate monostate) {
    return std::nullopt;
  }
};

static_assert(!std::is_polymorphic<LinearPathComponent>::value);
static_assert(!std::is_polymorphic<QuadraticPathComponent>::value);
static_assert(!std::is_polymorphic<CubicPathComponent>::value);

}  // namespace impeller
