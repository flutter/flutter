// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_

#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

/// Geometry for rendering shapes using the UberSDF shader.
class UberSDFGeometry final : public Geometry {
 public:
  explicit UberSDFGeometry(const UberSDFParameters& params);

  ~UberSDFGeometry() override;

  // |Geometry|
  // Returns the mesh that the SDF is drawn onto. This is a superset of the
  // drawn SDF shape, and is not necessarily "tight" around the drawn shape. In
  // other words, this is a bounding container mesh onto which the smaller SDF
  // shape is drawn.
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
  UberSDFParameters params_;

  // Returns the bounds rectangle of the SDF, expanded to account for stroke
  // width and AA.
  //
  // The `transform` argument is used to determine the exact stroke width and AA
  // padding to apply. But the returned rectangle is in local space;
  // `transform` is not applied to the returned bounds rectangle.
  Rect GetExpandedBounds(const Matrix& transform) const;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_
