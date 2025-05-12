// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path_source.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

/// @brief An abstract Geometry base class that produces fillable vertices
///        representing the stroked outline from any |PathSource| provided
///        by the type-specific subclass.
class StrokePathSourceGeometry : public Geometry {
 public:
  ~StrokePathSourceGeometry() override;

  Scalar GetStrokeWidth() const;

  Scalar GetMiterLimit() const;

  Cap GetStrokeCap() const;

  Join GetStrokeJoin() const;

  Scalar ComputeAlphaCoverage(const Matrix& transform) const override;

 protected:
  explicit StrokePathSourceGeometry(const StrokeParameters& parameters);

  /// The PathSource object that will be iterated to produce the stroked
  /// outline vertices.
  virtual const PathSource& GetSource() const = 0;

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
      const StrokeParameters& stroke,
      Scalar scale);

  friend class ImpellerBenchmarkAccessor;
  friend class ImpellerEntityUnitTestAccessor;

  bool SkipRendering() const;

  const StrokeParameters stroke_;

  StrokePathSourceGeometry(const StrokePathSourceGeometry&) = delete;

  StrokePathSourceGeometry& operator=(const StrokePathSourceGeometry&) = delete;
};

/// @brief A Geometry that produces fillable vertices representing the
///        stroked outline of a |DlPath| or |impeller::Path| object using
///        the |StrokePathSourceGeometry| base class and a |DlPath| object
///        to perform path iteration.
class StrokePathGeometry final : public StrokePathSourceGeometry {
 public:
  StrokePathGeometry(const Path& path, const StrokeParameters& parameters);

  StrokePathGeometry(const flutter::DlPath& path,
                     const StrokeParameters& parameters);

 protected:
  const PathSource& GetSource() const override;

 private:
  const flutter::DlPath path_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_
