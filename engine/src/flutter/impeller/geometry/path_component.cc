// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_component.h"

#include <cmath>

namespace impeller {

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

static Scalar ApproximateParabolaIntegral(Scalar x) {
  constexpr Scalar d = 0.67;
  return x / (1.0 - d + sqrt(sqrt(pow(d, 4) + 0.25 * x * x)));
}

void QuadraticPathComponent::AppendPolylinePoints(
    Scalar scale_factor,
    std::vector<Point>& points) const {
  auto tolerance = kDefaultCurveTolerance / scale_factor;
  auto sqrt_tolerance = sqrt(tolerance);

  auto d01 = cp - p1;
  auto d12 = p2 - cp;
  auto dd = d01 - d12;
  auto cross = (p2 - p1).Cross(dd);
  auto x0 = d01.Dot(dd) * 1 / cross;
  auto x2 = d12.Dot(dd) * 1 / cross;
  auto scale = std::abs(cross / (hypot(dd.x, dd.y) * (x2 - x0)));

  auto a0 = ApproximateParabolaIntegral(x0);
  auto a2 = ApproximateParabolaIntegral(x2);
  Scalar val = 0.f;
  if (std::isfinite(scale)) {
    auto da = std::abs(a2 - a0);
    auto sqrt_scale = sqrt(scale);
    if ((x0 < 0 && x2 < 0) || (x0 >= 0 && x2 >= 0)) {
      val = da * sqrt_scale;
    } else {
      // cusp case
      auto xmin = sqrt_tolerance / sqrt_scale;
      val = sqrt_tolerance * da / ApproximateParabolaIntegral(xmin);
    }
  }
  auto u0 = ApproximateParabolaIntegral(a0);
  auto u2 = ApproximateParabolaIntegral(a2);
  auto uscale = 1 / (u2 - u0);

  auto line_count = std::max(1., ceil(0.5 * val / sqrt_tolerance));
  auto step = 1 / line_count;
  for (size_t i = 1; i < line_count; i += 1) {
    auto u = i * step;
    auto a = a0 + (a2 - a0) * u;
    auto t = (ApproximateParabolaIntegral(a) - u0) * uscale;
    points.emplace_back(Solve(t));
  }
  points.emplace_back(p2);
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
  auto quads = ToQuadraticPathComponents(.1);
  for (const auto& quad : quads) {
    quad.AppendPolylinePoints(scale, points);
  }
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

std::vector<QuadraticPathComponent>
CubicPathComponent::ToQuadraticPathComponents(Scalar accuracy) const {
  std::vector<QuadraticPathComponent> quads;
  // The maximum error, as a vector from the cubic to the best approximating
  // quadratic, is proportional to the third derivative, which is constant
  // across the segment. Thus, the error scales down as the third power of
  // the number of subdivisions. Our strategy then is to subdivide `t` evenly.
  //
  // This is an overestimate of the error because only the component
  // perpendicular to the first derivative is important. But the simplicity is
  // appealing.

  // This magic number is the square of 36 / sqrt(3).
  // See: http://caffeineowl.com/graphics/2d/vectorial/cubic2quad01.html
  auto max_hypot2 = 432.0 * accuracy * accuracy;
  auto p1x2 = 3.0 * cp1 - p1;
  auto p2x2 = 3.0 * cp2 - p2;
  auto p = p2x2 - p1x2;
  auto err = p.Dot(p);
  auto quad_count = std::max(1., ceil(pow(err / max_hypot2, 1. / 6.0)));
  quads.reserve(quad_count);
  for (size_t i = 0; i < quad_count; i++) {
    auto t0 = i / quad_count;
    auto t1 = (i + 1) / quad_count;
    auto seg = Subsegment(t0, t1);
    auto p1x2 = 3.0 * seg.cp1 - seg.p1;
    auto p2x2 = 3.0 * seg.cp2 - seg.p2;
    quads.emplace_back(
        QuadraticPathComponent(seg.p1, ((p1x2 + p2x2) / 4.0), seg.p2));
  }
  return quads;
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

std::optional<Vector2> PathComponentStartDirectionVisitor::operator()(
    const LinearPathComponent* component) {
  if (!component) {
    return std::nullopt;
  }
  return component->GetStartDirection();
}

std::optional<Vector2> PathComponentStartDirectionVisitor::operator()(
    const QuadraticPathComponent* component) {
  if (!component) {
    return std::nullopt;
  }
  return component->GetStartDirection();
}

std::optional<Vector2> PathComponentStartDirectionVisitor::operator()(
    const CubicPathComponent* component) {
  if (!component) {
    return std::nullopt;
  }
  return component->GetStartDirection();
}

std::optional<Vector2> PathComponentEndDirectionVisitor::operator()(
    const LinearPathComponent* component) {
  if (!component) {
    return std::nullopt;
  }
  return component->GetEndDirection();
}

std::optional<Vector2> PathComponentEndDirectionVisitor::operator()(
    const QuadraticPathComponent* component) {
  if (!component) {
    return std::nullopt;
  }
  return component->GetEndDirection();
}

std::optional<Vector2> PathComponentEndDirectionVisitor::operator()(
    const CubicPathComponent* component) {
  if (!component) {
    return std::nullopt;
  }
  return component->GetEndDirection();
}

}  // namespace impeller
