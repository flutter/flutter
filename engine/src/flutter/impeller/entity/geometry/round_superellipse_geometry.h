// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_ROUND_SUPERELLIPSE_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_ROUND_SUPERELLIPSE_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/stroke_path_geometry.h"
#include "impeller/geometry/round_superellipse.h"
#include "impeller/geometry/rounding_radii.h"

namespace impeller {
/// @brief A Geometry class that generates fillable vertices (with or without
///        texture coordinates) directly from a round superellipse object
///        regardless of radii uniformity.
///
/// A rounded superellipse is a shape similar to a typical rounded rectangle
/// (`RoundSuperellipse`), but with smoother transitions between the straight
/// sides and the rounded corners. It resembles the `RoundedRectangle` shape in
/// SwiftUI with the `.continuous` corner style. Technically, it is created by
/// replacing the four corners of a superellipse (also known as a Lamé curve)
/// with circular arcs.
///
/// The `bounds` defines the position and size of the shape. The `corner_radius`
/// corresponds to SwiftUI's `cornerRadius` parameter, which is close to, but
/// not exactly equals to, the radius of the corner circles.
///
/// @see |StrokeRoundSuperellipseGeometry|
class RoundSuperellipseGeometry final : public Geometry {
 public:
  RoundSuperellipseGeometry(const Rect& bounds, const RoundingRadii& radii);
  RoundSuperellipseGeometry(const Rect& bounds, float corner_radius);

  ~RoundSuperellipseGeometry() override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

  // |Geometry|
  bool IsAxisAlignedRect() const override;

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  const Rect bounds_;
  const RoundingRadii radii_;

  RoundSuperellipseGeometry(const RoundSuperellipseGeometry&) = delete;

  RoundSuperellipseGeometry& operator=(const RoundSuperellipseGeometry&) =
      delete;
};

/// @brief A Geometry class that produces fillable vertices representing
///        the stroked outline of any |RoundSuperellipse| object regardless of
///        radii uniformity.
///
/// This class uses the |StrokePathSourceGeometry| base class to do the work
/// by providing a |RoundSuperellipsePathSoure| iterator.
///
/// @see |RoundSuperellipseGeometry|
class StrokeRoundSuperellipseGeometry final : public StrokePathSourceGeometry {
 public:
  StrokeRoundSuperellipseGeometry(const RoundSuperellipse& round_superellipse,
                                  const StrokeParameters& parameters);

 protected:
  // |StrokePathSourceGeometry|
  const PathSource& GetSource() const override;

 private:
  const RoundSuperellipsePathSource round_superellipse_source_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_ROUND_SUPERELLIPSE_GEOMETRY_H_
