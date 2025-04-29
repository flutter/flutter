// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_

#include "impeller/entity/geometry/path_geometry_base.h"
#include "impeller/geometry/matrix.h"

namespace impeller {

/// @brief A geometry that is created from a stroked path object.
class StrokePathGeometry final : public PathGeometryBase {
 public:
  template <typename T>
  explicit StrokePathGeometry(const T& t,
                              Scalar stroke_width,
                              Scalar miter_limit,
                              Cap stroke_cap,
                              Join stroke_join)
      : PathGeometryBase(t),
        stroke_width_(stroke_width),
        miter_limit_(miter_limit),
        stroke_cap_(stroke_cap),
        stroke_join_(stroke_join) {}

  ~StrokePathGeometry() override;

  Scalar GetStrokeWidth() const;

  Scalar GetMiterLimit() const;

  Cap GetStrokeCap() const;

  Join GetStrokeJoin() const;

  Scalar ComputeAlphaCoverage(const Matrix& transform) const override;

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  GeometryResult::Mode GetResultMode() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // Private for benchmarking and debugging
  static std::vector<Point> GenerateSolidStrokeVertices(
      const PathSource& source,
      Scalar stroke_width,
      Scalar miter_limit,
      Join stroke_join,
      Cap stroke_cap,
      Scalar scale);

  friend class ImpellerBenchmarkAccessor;
  friend class ImpellerEntityUnitTestAccessor;

  bool SkipRendering() const;

  const Scalar stroke_width_;
  const Scalar miter_limit_;
  const Cap stroke_cap_;
  const Join stroke_join_;

  StrokePathGeometry(const StrokePathGeometry&) = delete;

  StrokePathGeometry& operator=(const StrokePathGeometry&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_
