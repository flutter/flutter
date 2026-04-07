// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_

#include <memory>

#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

class UberSDFGeometry final : public Geometry {
 public:
  explicit UberSDFGeometry(UberSDFParameters params);

  ~UberSDFGeometry() override;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

  // |Geometry|
  bool IsAxisAlignedRect() const override;

 private:
  std::unique_ptr<Geometry> CreateUnderlyingGeometry() const;

  UberSDFParameters params_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_
