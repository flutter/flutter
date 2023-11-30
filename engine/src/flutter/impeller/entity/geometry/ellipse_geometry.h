// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

class EllipseGeometry final : public Geometry {
 public:
  explicit EllipseGeometry(Point center, Scalar radius);

  ~EllipseGeometry() = default;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

  // |Geometry|
  bool IsAxisAlignedRect() const override;

 private:
  // Computes the 4 corners of a rectangle that defines the line and
  // possibly extended endpoints which will be rendered under the given
  // transform, and returns true if such a rectangle is defined.
  //
  // The coordinates will be generated in the original coordinate system
  // of the line end points and the transform will only be used to determine
  // the minimum line width.
  //
  // For kButt and kSquare end caps the ends should always be exteded as
  // per that decoration, but for kRound caps the ends might be extended
  // if the goal is to get a conservative bounds and might not be extended
  // if the calling code is planning to draw the round caps on the ends.
  //
  // @return true if the transform and width were not degenerate
  bool ComputeCorners(Point corners[4],
                      const Matrix& transform,
                      bool extend_endpoints) const;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) const override;

  Point center_;
  Scalar radius_;

  EllipseGeometry(const EllipseGeometry&) = delete;

  EllipseGeometry& operator=(const EllipseGeometry&) = delete;
};

}  // namespace impeller
