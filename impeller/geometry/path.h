// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <optional>
#include <set>
#include <vector>

#include "impeller/geometry/path_component.h"

namespace impeller {

enum class FillType {
  kNonZero,  // The default winding order.
  kOdd,
  kPositive,
  kNegative,
  kAbsGeqTwo,
};

//------------------------------------------------------------------------------
/// @brief      Paths are lightweight objects that describe a collection of
///             linear, quadratic, or cubic segments. These segments may be
///             be broken up by move commands, which are effectively linear
///             commands that pick up the pen rather than continuing to draw.
///
///             All shapes supported by Impeller are paths either directly or
///             via approximation (in the case of circles).
///
///             Creating paths that describe complex shapes is usually done by a
///             path builder.
///
class Path {
 public:
  enum class ComponentType {
    kLinear,
    kQuadratic,
    kCubic,
    kMove,
  };

  /// One or more contours represented as a series of points and indices in
  /// the point vector representing the start of a new contour.
  struct Polyline {
    /// Points in the polyline, which may represent multiple contours specified
    /// by indices in |breaks|.
    std::vector<Point> points;
    /// Indices of points that end a subcontour.
    std::set<size_t> breaks;
  };

  Path();

  ~Path();

  size_t GetComponentCount() const;

  void SetFillType(FillType fill);

  FillType GetFillType() const;

  Path& AddLinearComponent(Point p1, Point p2);

  Path& AddQuadraticComponent(Point p1, Point cp, Point p2);

  Path& AddCubicComponent(Point p1, Point cp1, Point cp2, Point p2);

  Path& AddMoveComponent(Point destination);

  template <class T>
  using Applier = std::function<void(size_t index, const T& component)>;
  void EnumerateComponents(Applier<LinearPathComponent> linearApplier,
                           Applier<QuadraticPathComponent> quadApplier,
                           Applier<CubicPathComponent> cubicApplier,
                           Applier<MovePathComponent> moveApplier) const;

  bool GetLinearComponentAtIndex(size_t index,
                                 LinearPathComponent& linear) const;

  bool GetQuadraticComponentAtIndex(size_t index,
                                    QuadraticPathComponent& quadratic) const;

  bool GetCubicComponentAtIndex(size_t index, CubicPathComponent& cubic) const;

  bool GetMoveComponentAtIndex(size_t index, MovePathComponent& move) const;

  bool UpdateLinearComponentAtIndex(size_t index,
                                    const LinearPathComponent& linear);

  bool UpdateQuadraticComponentAtIndex(size_t index,
                                       const QuadraticPathComponent& quadratic);

  bool UpdateCubicComponentAtIndex(size_t index, CubicPathComponent& cubic);

  bool UpdateMoveComponentAtIndex(size_t index, const MovePathComponent& move);

  Polyline CreatePolyline(
      const SmoothingApproximation& approximation = {}) const;

  std::optional<Rect> GetBoundingBox() const;

  std::optional<std::pair<Point, Point>> GetMinMaxCoveragePoints() const;

 private:
  struct ComponentIndexPair {
    ComponentType type = ComponentType::kLinear;
    size_t index = 0;

    ComponentIndexPair() {}

    ComponentIndexPair(ComponentType aType, size_t aIndex)
        : type(aType), index(aIndex) {}
  };

  FillType fill_ = FillType::kNonZero;
  std::vector<ComponentIndexPair> components_;
  std::vector<LinearPathComponent> linears_;
  std::vector<QuadraticPathComponent> quads_;
  std::vector<CubicPathComponent> cubics_;
  std::vector<MovePathComponent> moves_;
};

}  // namespace impeller
