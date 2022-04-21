// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <optional>
#include <set>
#include <tuple>
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
    kContour,
  };

  struct PolylineContour {
    /// Index that denotes the first point of this contour.
    size_t start_index;
    /// Denotes whether the last point of this contour is connected to the first
    /// point of this contour or not.
    bool is_closed;
  };

  /// One or more contours represented as a series of points and indices in
  /// the point vector representing the start of a new contour.
  struct Polyline {
    /// Points in the polyline, which may represent multiple contours specified
    /// by indices in |breaks|.
    std::vector<Point> points;
    std::vector<PolylineContour> contours;

    /// Convenience method to compute the start (inclusive) and end (exclusive)
    /// point of the given contour index.
    ///
    /// The contour_index parameter is clamped to contours.size().
    std::tuple<size_t, size_t> GetContourPointBounds(
        size_t contour_index) const;
  };

  Path();

  ~Path();

  size_t GetComponentCount() const;

  void SetFillType(FillType fill);

  FillType GetFillType() const;

  Path& AddLinearComponent(Point p1, Point p2);

  Path& AddQuadraticComponent(Point p1, Point cp, Point p2);

  Path& AddCubicComponent(Point p1, Point cp1, Point cp2, Point p2);

  Path& AddContourComponent(Point destination, bool is_closed = false);

  void SetContourClosed(bool is_closed);

  template <class T>
  using Applier = std::function<void(size_t index, const T& component)>;
  void EnumerateComponents(Applier<LinearPathComponent> linear_applier,
                           Applier<QuadraticPathComponent> quad_applier,
                           Applier<CubicPathComponent> cubic_applier,
                           Applier<ContourComponent> contour_applier) const;

  bool GetLinearComponentAtIndex(size_t index,
                                 LinearPathComponent& linear) const;

  bool GetQuadraticComponentAtIndex(size_t index,
                                    QuadraticPathComponent& quadratic) const;

  bool GetCubicComponentAtIndex(size_t index, CubicPathComponent& cubic) const;

  bool GetContourComponentAtIndex(size_t index,
                                  ContourComponent& contour) const;

  bool UpdateLinearComponentAtIndex(size_t index,
                                    const LinearPathComponent& linear);

  bool UpdateQuadraticComponentAtIndex(size_t index,
                                       const QuadraticPathComponent& quadratic);

  bool UpdateCubicComponentAtIndex(size_t index, CubicPathComponent& cubic);

  bool UpdateContourComponentAtIndex(size_t index,
                                     const ContourComponent& contour);

  Polyline CreatePolyline(
      const SmoothingApproximation& approximation = {}) const;

  std::optional<Rect> GetBoundingBox() const;

  std::optional<Rect> GetTransformedBoundingBox(const Matrix& transform) const;

  std::optional<std::pair<Point, Point>> GetMinMaxCoveragePoints() const;

 private:
  struct ComponentIndexPair {
    ComponentType type = ComponentType::kLinear;
    size_t index = 0;

    ComponentIndexPair() {}

    ComponentIndexPair(ComponentType a_type, size_t a_index)
        : type(a_type), index(a_index) {}
  };

  FillType fill_ = FillType::kNonZero;
  std::vector<ComponentIndexPair> components_;
  std::vector<LinearPathComponent> linears_;
  std::vector<QuadraticPathComponent> quads_;
  std::vector<CubicPathComponent> cubics_;
  std::vector<ContourComponent> contours_;
};

}  // namespace impeller
