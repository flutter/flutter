// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_CIRCLE_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_CIRCLE_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

// Geometry class that can generate vertices (with or without texture
// coordinates) for either filled or stroked circles
class CircleGeometry final : public Geometry {
 public:
  explicit CircleGeometry(const Point& center, Scalar radius);

  explicit CircleGeometry(const Point& center,
                          Scalar radius,
                          Scalar stroke_width);

  ~CircleGeometry() override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

  // |Geometry|
  bool IsAxisAlignedRect() const override;

  // |Geometry|
  Scalar ComputeAlphaCoverage(const Matrix& transform) const override;

  Scalar GetRadius() const;
  Scalar GetStrokeWidth() const;
  Point GetCenter() const;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // Set the number of pixels to add to the edge(s) of the circle for
  // SDF-based antialiasing
  void SetAntialiasPadding(Scalar extra_pixels);

  Scalar GetAntialiasPadding() const;

 private:
  Point center_;
  Scalar radius_;
  Scalar stroke_width_;
  Scalar padding_pixels_;

  CircleGeometry(const CircleGeometry&) = delete;

  CircleGeometry& operator=(const CircleGeometry&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_CIRCLE_GEOMETRY_H_
