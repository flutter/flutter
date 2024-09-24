// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_component.h"

#include <cmath>

#include "impeller/geometry/wangs_formula.h"

namespace impeller {

VertexWriter::VertexWriter(std::vector<Point>& points,
                           std::vector<uint16_t>& indices)
    : points_(points), indices_(indices) {}

void VertexWriter::EndContour() {
  if (points_.size() == 0u || contour_start_ == points_.size() - 1) {
    // Empty or first contour.
    return;
  }

  auto start = contour_start_;
  auto end = points_.size() - 1;
  // All filled paths are drawn as if they are closed, but if
  // there is an explicit close then a lineTo to the origin
  // is inserted. This point isn't strictly necesary to
  // correctly render the shape and can be dropped.
  if (points_[end] == points_[start]) {
    end--;
  }

  // Triangle strip break for subsequent contours
  if (contour_start_ != 0) {
    auto back = indices_.back();
    indices_.push_back(back);
    indices_.push_back(start);
    indices_.push_back(start);

    // If the contour has an odd number of points, insert an extra point when
    // bridging to the next contour to preserve the correct triangle winding
    // order.
    if (previous_contour_odd_points_) {
      indices_.push_back(start);
    }
  } else {
    indices_.push_back(start);
  }

  size_t a = start + 1;
  size_t b = end;
  while (a < b) {
    indices_.push_back(a);
    indices_.push_back(b);
    a++;
    b--;
  }
  if (a == b) {
    indices_.push_back(a);
    previous_contour_odd_points_ = false;
  } else {
    previous_contour_odd_points_ = true;
  }
  contour_start_ = points_.size();
}

void VertexWriter::Write(Point point) {
  points_.push_back(point);
}

/*
 *  Based on: https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Specific_cases
 */

static inline Scalar LinearSolve(Scalar t, Scalar p0, Scalar p1) {
  return p0 + t * (p1 - p0);
}

static inline Scalar QuadraticSolve(Scalar t, Scalar p0, Scalar p1, Scalar p2) {
  return (1 - t) * (1 - t) * p0 +  //
         2 * (1 - t) * t * p1 +    //
         t * t * p2;
}

static inline Scalar QuadraticSolveDerivative(Scalar t,
                                              Scalar p0,
                                              Scalar p1,
                                              Scalar p2) {
  return 2 * (1 - t) * (p1 - p0) +  //
         2 * t * (p2 - p1);
}

static inline Scalar CubicSolve(Scalar t,
                                Scalar p0,
                                Scalar p1,
                                Scalar p2,
                                Scalar p3) {
  return (1 - t) * (1 - t) * (1 - t) * p0 +  //
         3 * (1 - t) * (1 - t) * t * p1 +    //
         3 * (1 - t) * t * t * p2 +          //
         t * t * t * p3;
}

static inline Scalar CubicSolveDerivative(Scalar t,
                                          Scalar p0,
                                          Scalar p1,
                                          Scalar p2,
                                          Scalar p3) {
  return -3 * p0 * (1 - t) * (1 - t) +  //
         p1 * (3 * (1 - t) * (1 - t) - 6 * (1 - t) * t) +
         p2 * (6 * (1 - t) * t - 3 * t * t) +  //
         3 * p3 * t * t;
}

Point LinearPathComponent::Solve(Scalar time) const {
  return {
      LinearSolve(time, p1.x, p2.x),  // x
      LinearSolve(time, p1.y, p2.y),  // y
  };
}

void LinearPathComponent::AppendPolylinePoints(
    std::vector<Point>& points) const {
  if (points.size() == 0 || points.back() != p2) {
    points.push_back(p2);
  }
}

std::vector<Point> LinearPathComponent::Extrema() const {
  return {p1, p2};
}

std::optional<Vector2> LinearPathComponent::GetStartDirection() const {
  if (p1 == p2) {
    return std::nullopt;
  }
  return (p1 - p2).Normalize();
}

std::optional<Vector2> LinearPathComponent::GetEndDirection() const {
  if (p1 == p2) {
    return std::nullopt;
  }
  return (p2 - p1).Normalize();
}

Point QuadraticPathComponent::Solve(Scalar time) const {
  return {
      QuadraticSolve(time, p1.x, cp.x, p2.x),  // x
      QuadraticSolve(time, p1.y, cp.y, p2.y),  // y
  };
}

Point QuadraticPathComponent::SolveDerivative(Scalar time) const {
  return {
      QuadraticSolveDerivative(time, p1.x, cp.x, p2.x),  // x
      QuadraticSolveDerivative(time, p1.y, cp.y, p2.y),  // y
  };
}

void QuadraticPathComponent::ToLinearPathComponents(
    Scalar scale,
    VertexWriter& writer) const {
  Scalar line_count = std::ceilf(ComputeQuadradicSubdivisions(scale, *this));
  for (size_t i = 1; i < line_count; i += 1) {
    writer.Write(Solve(i / line_count));
  }
  writer.Write(p2);
}

void QuadraticPathComponent::AppendPolylinePoints(
    Scalar scale_factor,
    std::vector<Point>& points) const {
  ToLinearPathComponents(scale_factor, [&points](const Point& point) {
    points.emplace_back(point);
  });
}

void QuadraticPathComponent::ToLinearPathComponents(
    Scalar scale_factor,
    const PointProc& proc) const {
  Scalar line_count =
      std::ceilf(ComputeQuadradicSubdivisions(scale_factor, *this));
  for (size_t i = 1; i < line_count; i += 1) {
    proc(Solve(i / line_count));
  }
  proc(p2);
}

std::vector<Point> QuadraticPathComponent::Extrema() const {
  CubicPathComponent elevated(*this);
  return elevated.Extrema();
}

std::optional<Vector2> QuadraticPathComponent::GetStartDirection() const {
  if (p1 != cp) {
    return (p1 - cp).Normalize();
  }
  if (p1 != p2) {
    return (p1 - p2).Normalize();
  }
  return std::nullopt;
}

std::optional<Vector2> QuadraticPathComponent::GetEndDirection() const {
  if (p2 != cp) {
    return (p2 - cp).Normalize();
  }
  if (p2 != p1) {
    return (p2 - p1).Normalize();
  }
  return std::nullopt;
}

Point CubicPathComponent::Solve(Scalar time) const {
  return {
      CubicSolve(time, p1.x, cp1.x, cp2.x, p2.x),  // x
      CubicSolve(time, p1.y, cp1.y, cp2.y, p2.y),  // y
  };
}

Point CubicPathComponent::SolveDerivative(Scalar time) const {
  return {
      CubicSolveDerivative(time, p1.x, cp1.x, cp2.x, p2.x),  // x
      CubicSolveDerivative(time, p1.y, cp1.y, cp2.y, p2.y),  // y
  };
}

void CubicPathComponent::AppendPolylinePoints(
    Scalar scale,
    std::vector<Point>& points) const {
  ToLinearPathComponents(
      scale, [&points](const Point& point) { points.emplace_back(point); });
}

void CubicPathComponent::ToLinearPathComponents(Scalar scale,
                                                VertexWriter& writer) const {
  Scalar line_count = std::ceilf(ComputeCubicSubdivisions(scale, *this));
  for (size_t i = 1; i < line_count; i++) {
    writer.Write(Solve(i / line_count));
  }
  writer.Write(p2);
}

inline QuadraticPathComponent CubicPathComponent::Lower() const {
  return QuadraticPathComponent(3.0 * (cp1 - p1), 3.0 * (cp2 - cp1),
                                3.0 * (p2 - cp2));
}

CubicPathComponent CubicPathComponent::Subsegment(Scalar t0, Scalar t1) const {
  auto p0 = Solve(t0);
  auto p3 = Solve(t1);
  auto d = Lower();
  auto scale = (t1 - t0) * (1.0 / 3.0);
  auto p1 = p0 + scale * d.Solve(t0);
  auto p2 = p3 - scale * d.Solve(t1);
  return CubicPathComponent(p0, p1, p2, p3);
}

void CubicPathComponent::ToLinearPathComponents(Scalar scale,
                                                const PointProc& proc) const {
  Scalar line_count = std::ceilf(ComputeCubicSubdivisions(scale, *this));
  for (size_t i = 1; i < line_count; i++) {
    proc(Solve(i / line_count));
  }
  proc(p2);
}

static inline bool NearEqual(Scalar a, Scalar b, Scalar epsilon) {
  return (a > (b - epsilon)) && (a < (b + epsilon));
}

static inline bool NearZero(Scalar a) {
  return NearEqual(a, 0.0, 1e-12);
}

static void CubicPathBoundingPopulateValues(std::vector<Scalar>& values,
                                            Scalar p1,
                                            Scalar p2,
                                            Scalar p3,
                                            Scalar p4) {
  const Scalar a = 3.0 * (-p1 + 3.0 * p2 - 3.0 * p3 + p4);
  const Scalar b = 6.0 * (p1 - 2.0 * p2 + p3);
  const Scalar c = 3.0 * (p2 - p1);

  /*
   *  Boundary conditions.
   */
  if (NearZero(a)) {
    if (NearZero(b)) {
      return;
    }

    Scalar t = -c / b;
    if (t >= 0.0 && t <= 1.0) {
      values.emplace_back(t);
    }
    return;
  }

  Scalar b2Minus4AC = (b * b) - (4.0 * a * c);

  if (b2Minus4AC < 0.0) {
    return;
  }

  Scalar rootB2Minus4AC = ::sqrt(b2Minus4AC);

  /* From Numerical Recipes in C.
   *
   * q = -1/2 (b + sign(b) sqrt[b^2 - 4ac])
   * x1 = q / a
   * x2 = c / q
   */
  Scalar q = (b < 0) ? -(b - rootB2Minus4AC) / 2 : -(b + rootB2Minus4AC) / 2;

  {
    Scalar t = q / a;
    if (t >= 0.0 && t <= 1.0) {
      values.emplace_back(t);
    }
  }

  {
    Scalar t = c / q;
    if (t >= 0.0 && t <= 1.0) {
      values.emplace_back(t);
    }
  }
}

std::vector<Point> CubicPathComponent::Extrema() const {
  /*
   *  As described in: https://pomax.github.io/bezierinfo/#extremities
   */
  std::vector<Scalar> values;

  CubicPathBoundingPopulateValues(values, p1.x, cp1.x, cp2.x, p2.x);
  CubicPathBoundingPopulateValues(values, p1.y, cp1.y, cp2.y, p2.y);

  std::vector<Point> points = {p1, p2};

  for (const auto& value : values) {
    points.emplace_back(Solve(value));
  }

  return points;
}

std::optional<Vector2> CubicPathComponent::GetStartDirection() const {
  if (p1 != cp1) {
    return (p1 - cp1).Normalize();
  }
  if (p1 != cp2) {
    return (p1 - cp2).Normalize();
  }
  if (p1 != p2) {
    return (p1 - p2).Normalize();
  }
  return std::nullopt;
}

std::optional<Vector2> CubicPathComponent::GetEndDirection() const {
  if (p2 != cp2) {
    return (p2 - cp2).Normalize();
  }
  if (p2 != cp1) {
    return (p2 - cp1).Normalize();
  }
  if (p2 != p1) {
    return (p2 - p1).Normalize();
  }
  return std::nullopt;
}

}  // namespace impeller
