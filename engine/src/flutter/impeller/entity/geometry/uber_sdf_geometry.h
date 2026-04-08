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
  explicit UberSDFGeometry(const UberSDFParameters& params);

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
  // Compute the local bounds of the primitive based on the center and size
  // and optionally taking into account the expansion due to the stroke width
  // if the primitive is being stroked.
  Rect GetExpandedBaseBounds() const;

  // Compute the device bounds of the primitive based on the center and size
  // and taking into account the expansion due to the stroke width as
  // well as either expanding (inset == false) or reducing (inset == true)
  // the bounds by the AA pixel fringe. Some operations need to work on
  // the full coverage center of the operation, the part that is entirely
  // inside the edge pixels that may have been reduced by the AA coverage
  // calculations.
  Rect GetExpandedDeviceBounds(const Matrix& transform,
                               bool inset = false) const;

  // Compute the local bounds of the primitive based on the center and size
  // and taking into account the expansion due to the stroke width. This
  // version of the bounds will always be outside by the AA pixel padding.
  Rect GetExpandedLocalBounds(const Matrix& transform) const;

  UberSDFParameters params_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_
