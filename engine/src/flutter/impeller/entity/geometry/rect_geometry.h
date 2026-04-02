// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/sdf_compatible_geometry.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

class FillRectGeometry final : public SDFCompatibleGeometry {
 public:
  explicit FillRectGeometry(Rect rect);

  ~FillRectGeometry() override;

  // |SDFCompatibleGeometry|
  Rect GetBaseShapeBounds() const override;

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

class StrokeRectGeometry final : public SDFCompatibleGeometry {
 public:
  explicit StrokeRectGeometry(const Rect& rect, const StrokeParameters& stroke);

  ~StrokeRectGeometry() override;

  // |SDFCompatibleGeometry|
  Rect GetBaseShapeBounds() const override;

  // |SDFCompatibleGeometry|
  std::optional<StrokeParameters> GetStrokeParameters() const override;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

 private:
  const Rect rect_;
  const StrokeParameters stroke_parameters_;

  static StrokeParameters AdjustStrokeJoin(const StrokeParameters& stroke);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_
