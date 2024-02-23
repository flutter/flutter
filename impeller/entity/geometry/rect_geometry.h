// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

class RectGeometry final : public Geometry {
 public:
  explicit RectGeometry(Rect rect);

  ~RectGeometry() = default;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

  // |Geometry|
  bool IsAxisAlignedRect() const override;

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

 private:
  Rect rect_;

  RectGeometry(const RectGeometry&) = delete;

  RectGeometry& operator=(const RectGeometry&) = delete;
};

static_assert(std::is_trivially_destructible<RectGeometry>::value);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_RECT_GEOMETRY_H_
