// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_ROUND_RECT_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_ROUND_RECT_GEOMETRY_H_

#include "impeller/entity/geometry/fill_path_geometry.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/stroke_path_geometry.h"
#include "impeller/geometry/round_rect.h"

namespace impeller {

/// @brief A Geometry class that generates fillable vertices (with or without
///        texture coordinates) directly from a round rect object with uniform
///        radii at every corner.
///
/// Generating vertices for a stroked ellipse would require a lot more work
/// since the line width must be applied perpendicular to the distorted
/// ellipse shape.
///
/// @see |FillRoundRectGeometry|
/// @see |StrokeRoundRectGeometry|
class RoundRectGeometry final : public Geometry {
 public:
  explicit RoundRectGeometry(const Rect& bounds, const Size& radii);

  ~RoundRectGeometry() override;

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
  const Size radii_;

  RoundRectGeometry(const RoundRectGeometry&) = delete;

  RoundRectGeometry& operator=(const RoundRectGeometry&) = delete;
};

/// @brief A Geometry class that produces fillable vertices from any
///        |RoundRect| object regardless of radii uniformity.
///
/// This class uses the |FillPathSourceGeometry| base class to do the work
/// by providing a |RoundRectPathSoure| iterator.
class FillRoundRectGeometry final : public FillPathSourceGeometry {
 public:
  explicit FillRoundRectGeometry(const RoundRect& round_rect);

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

 protected:
  // |FillPathSourceGeometry|
  const PathSource& GetSource() const override;

 private:
  const RoundRectPathSource round_rect_source_;
};

/// @brief A Geometry class that produces fillable vertices representing
///        the stroked outline of any |Roundrect| object regardless of
///        radii uniformity.
///
/// This class uses the |StrokePathSourceGeometry| base class to do the work
/// by providing a |RoundRectPathSoure| iterator.
class StrokeRoundRectGeometry final : public StrokePathSourceGeometry {
 public:
  StrokeRoundRectGeometry(const RoundRect& rect,
                          const StrokeParameters& parameters);

 protected:
  // |StrokePathSourceGeometry|
  const PathSource& GetSource() const override;

 private:
  const RoundRectPathSource round_rect_source_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_ROUND_RECT_GEOMETRY_H_
