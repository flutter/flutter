// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

class FillRectGeometry final : public Geometry {
 public:
  explicit FillRectGeometry(Rect rect);

  ~FillRectGeometry() override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

  // |Geometry|
  bool IsAxisAlignedRect() const override;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

 private:
  Rect rect_;
};

class StrokeRectGeometry final : public Geometry {
 public:
  explicit StrokeRectGeometry(const Rect& rect, const StrokeParameters& stroke);

  ~StrokeRectGeometry() override;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

 private:
  const Rect rect_;
  const Scalar stroke_width_;
  const Join stroke_join_;

  static Join AdjustStrokeJoin(const StrokeParameters& stroke);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_
