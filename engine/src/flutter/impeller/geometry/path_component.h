// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_PATH_COMPONENT_H_
#define FLUTTER_IMPELLER_GEOMETRY_PATH_COMPONENT_H_

#include <functional>
#include <optional>
#include <type_traits>
#include <variant>
#include <vector>

#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

/// @brief An interface for generating a multi contour polyline as a triangle
///        strip.
class VertexWriter {
 public:
  explicit VertexWriter(std::vector<Point>& points,
                        std::vector<uint16_t>& indices);

  ~VertexWriter() = default;

  void EndContour();

  void Write(Point point);

 private:
  bool previous_contour_odd_points_ = false;
  size_t contour_start_ = 0u;
  std::vector<Point>& points_;
  std::vector<uint16_t>& indices_;
};

struct LinearPathComponent {
  Point p1;
  Point p2;

  LinearPathComponent() {}

  LinearPathComponent(Point ap1, Point ap2) : p1(ap1), p2(ap2) {}

  Point Solve(Scalar time) const;

  void AppendPolylinePoints(std::vector<Point>& points) const;

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

  void AppendPolylinePoints(Scalar scale_factor,
                            std::vector<Point>& points) const;

  using PointProc = std::function<void(const Point& point)>;

  void ToLinearPathComponents(Scalar scale_factor, const PointProc& proc) const;

  void ToLinearPathComponents(Scalar scale, VertexWriter& writer) const;

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

  explicit CubicPathComponent(const QuadraticPathComponent& q)
      : p1(q.p1),
        cp1(q.p1 + (q.cp - q.p1) * (2.0 / 3.0)),
        cp2(q.p2 + (q.cp - q.p2) * (2.0 / 3.0)),
        p2(q.p2) {}

  CubicPathComponent(Point ap1, Point acp1, Point acp2, Point ap2)
      : p1(ap1), cp1(acp1), cp2(acp2), p2(ap2) {}

  Point Solve(Scalar time) const;

  Point SolveDerivative(Scalar time) const;

  void AppendPolylinePoints(Scalar scale, std::vector<Point>& points) const;

  std::vector<Point> Extrema() const;

  using PointProc = std::function<void(const Point& point)>;

  void ToLinearPathComponents(Scalar scale, const PointProc& proc) const;

  void ToLinearPathComponents(Scalar scale, VertexWriter& writer) const;

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

  explicit ContourComponent(Point p, bool is_closed = false)
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

#endif  // FLUTTER_IMPELLER_GEOMETRY_PATH_COMPONENT_H_
