// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_ELLIPSE_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_ELLIPSE_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/stroke_path_geometry.h"

namespace impeller {

/// @brief A Geometry class that can directly generate vertices (with or
///        without texture coordinates) for filled ellipses.
///
/// Generating vertices for a stroked ellipse would require a lot more work
/// since the line width must be applied perpendicular to the distorted
/// ellipse shape.
///
/// @see |StrokeEllipseGeometry|
class EllipseGeometry final : public Geometry {
 public:
  explicit EllipseGeometry(Rect bounds);

  ~EllipseGeometry() override = default;

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

  Rect bounds_;

  EllipseGeometry(const EllipseGeometry&) = delete;

  EllipseGeometry& operator=(const EllipseGeometry&) = delete;
};

/// @brief A Geometry class that produces fillable vertices representing
///        the stroked outline of an ellipse with the given bounds.
///
/// This class uses the |StrokePathSourceGeometry| base class to do the work
/// by providing an |EllipsePathSoure| iterator.
class StrokeEllipseGeometry final : public StrokePathSourceGeometry {
 public:
  StrokeEllipseGeometry(const Rect& rect, const StrokeParameters& parameters);

 protected:
  // |StrokePathSourceGeometry|
  const PathSource& GetSource() const override;

 private:
  const EllipsePathSource ellipse_source_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_ELLIPSE_GEOMETRY_H_
