// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

class RectGeometry : public Geometry {
 public:
  explicit RectGeometry(Rect rect);

  ~RectGeometry();

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) override;

  Rect rect_;

  FML_DISALLOW_COPY_AND_ASSIGN(RectGeometry);
};

}  // namespace impeller
