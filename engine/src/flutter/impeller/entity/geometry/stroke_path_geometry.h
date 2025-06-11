// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/dashed_line_path_source.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path_source.h"
#include "impeller/geometry/stroke_parameters.h"
#include "impeller/tessellator/path_tessellator.h"

namespace impeller {

/// @brief  A |SegmentReceiver| that also accepts Arc segments for optimal
///         handling. A path or |PathSource| will typically represent such
///         curves using Conic segments which are harder to iterate.
class PathAndArcSegmentReceiver : public PathTessellator::SegmentReceiver {
 public:
  virtual void RecordArc(const Arc& arc,
                         const Point center,
                         const Size radii) = 0;
};

/// @brief An abstract Geometry base class that produces fillable vertices
///        representing the stroked outline of the segments provided by
///        the subclass in the virtual |Dispatch| method.
///
/// Most subclasses will be based on an instance of |PathSource| and use the
/// |StrokePathSourceGeometry| subclass to feed the segments from that path
/// source object, but some subclasses may be able to operate more optimally
/// by talking directly to the |StrokePathSegmentReceiver| (mainly arcs).
class StrokeSegmentsGeometry : public Geometry {
 public:
  ~StrokeSegmentsGeometry() override;

  Scalar GetStrokeWidth() const;

  Scalar GetMiterLimit() const;

  Cap GetStrokeCap() const;

  Join GetStrokeJoin() const;

  Scalar ComputeAlphaCoverage(const Matrix& transform) const override;

 protected:
  explicit StrokeSegmentsGeometry(const StrokeParameters& parameters);

  /// Dispatch the path segments to the StrokePathSegmentReceiver for
  /// the provided transform scale.
  virtual void Dispatch(PathAndArcSegmentReceiver& receiver,
                        Tessellator& tessellator,
                        Scalar scale) const = 0;

  /// Provide the stroke-padded bounds for the provided bounds of the
  /// segments themselves.
  std::optional<Rect> GetStrokeCoverage(const Matrix& transform,
                                        const Rect& segment_bounds) const;

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  GeometryResult::Mode GetResultMode() const override;

  // Private for benchmarking and debugging
  static std::vector<Point> GenerateSolidStrokeVertices(
      Tessellator& tessellator,
      const PathSource& source,
      const StrokeParameters& stroke,
      Scalar scale);

  friend class ImpellerBenchmarkAccessor;
  friend class ImpellerEntityUnitTestAccessor;

  bool SkipRendering() const;

  const StrokeParameters stroke_;

  StrokeSegmentsGeometry(const StrokeSegmentsGeometry&) = delete;

  StrokeSegmentsGeometry& operator=(const StrokeSegmentsGeometry&) = delete;
};

/// @brief An abstract Geometry base class that produces fillable vertices
///        representing the stroked outline from any |PathSource| provided
///        by the subclass.
class StrokePathSourceGeometry : public StrokeSegmentsGeometry {
 protected:
  explicit StrokePathSourceGeometry(const StrokeParameters& parameters);

  /// The PathSource object that will be iterated to produce the raw
  /// vertices to be stroked.
  virtual const PathSource& GetSource() const = 0;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |StrokeSegmentsGeometry|
  void Dispatch(PathAndArcSegmentReceiver& receiver,
                Tessellator& tessellator,
                Scalar scale) const override;
};

/// @brief A Geometry that produces fillable vertices representing the
///        stroked outline of a |DlPath| object using the
///        |StrokePathSourceGeometry| base class and a |DlPath| object
///        to perform path iteration.
class StrokePathGeometry final : public StrokePathSourceGeometry {
 public:
  StrokePathGeometry(const flutter::DlPath& path,
                     const StrokeParameters& parameters);

 protected:
  // |StrokePathSourceGeometry|
  const PathSource& GetSource() const override;

 private:
  const flutter::DlPath path_;
};

/// @brief A Geometry that produces fillable vertices representing the
///        stroked outline of an |Arc| object using the base class
///        |StrokeSegmentsGeometry| and utilizing the special |RecordArc|
///        extension method provided by the |PathAndArcSegmentReceiver|.
class ArcStrokeGeometry final : public StrokeSegmentsGeometry {
 public:
  ArcStrokeGeometry(const Arc& arc, const StrokeParameters& parameters);

 protected:
  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |StrokeSegmentsGeometry|
  void Dispatch(PathAndArcSegmentReceiver& receiver,
                Tessellator& tessellator,
                Scalar scale) const override;

 private:
  const Arc arc_;
};

/// @brief A Geometry that produces fillable vertices representing the
///        stroked outline of a pair of nested |RoundRect| objects using
///        the |StrokePathSourceGeometry| base class.
class StrokeDiffRoundRectGeometry final : public StrokePathSourceGeometry {
 public:
  explicit StrokeDiffRoundRectGeometry(const RoundRect& outer,
                                       const RoundRect& inner,
                                       const StrokeParameters& parameters);

 protected:
  // |StrokePathSourceGeometry|
  const PathSource& GetSource() const override;

 private:
  const DiffRoundRectPathSource source_;
};

/// @brief A Geometry that produces fillable vertices representing the
///        stroked outline of a |DlPath| object using the
///        |StrokePathSourceGeometry| base class and a |DlPath| object
///        to perform path iteration.
class StrokeDashedLineGeometry final : public StrokePathSourceGeometry {
 public:
  StrokeDashedLineGeometry(Point p0,
                           Point p1,
                           Scalar on_length,
                           Scalar off_length,
                           const StrokeParameters& parameters);

 protected:
  const PathSource& GetSource() const override;

 private:
  const DashedLinePathSource source_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_STROKE_PATH_GEOMETRY_H_
