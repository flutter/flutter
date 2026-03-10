// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_ARC_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_ARC_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"

#include "impeller/geometry/arc.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

// Geometry class that can generate vertices (with or without texture
// coordinates) for either filled or stroked circles
class ArcGeometry final : public Geometry {
 public:
  explicit ArcGeometry(const Arc& arc);

  explicit ArcGeometry(const Arc& arc, const StrokeParameters& stroke);

  ~ArcGeometry() override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

  // |Geometry|
  bool IsAxisAlignedRect() const override;

  // |Geometry|
  Scalar ComputeAlphaCoverage(const Matrix& transform) const override;

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // Whether the arc has overlapping stroke caps
  bool CapsOverlap() const;

  Arc arc_;
  Scalar stroke_width_;
  Cap cap_;

  ArcGeometry(const ArcGeometry&) = delete;

  ArcGeometry& operator=(const ArcGeometry&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_ARC_GEOMETRY_H_
