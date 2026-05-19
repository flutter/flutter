// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/tessellator/path_tessellator.h"

#include "flutter/impeller/geometry/path_source.h"
#include "flutter/impeller/geometry/wangs_formula.h"

namespace {

using Point = impeller::Point;
using Scalar = impeller::Scalar;

using SegmentReceiver = impeller::PathTessellator::SegmentReceiver;
using VertexWriter = impeller::PathTessellator::VertexWriter;
using Quad = impeller::PathTessellator::Quad;
using Conic = impeller::PathTessellator::Conic;
using Cubic = impeller::PathTessellator::Cubic;

/// Base class for all utility path receivers in this file. It prunes
/// empty contours and degenerate path segments so that all path
/// tessellator receivers will operate on the same data.
///
/// Some simplifications and guarantees that it implements:
///   - remove duplicate MoveTo operations
///   - ensure Begin/EndContour on every sub-path
///   - ensure a single degenerate line for empty stroked sub-paths
///   - ensure line back to origin for filled sub-paths
///   - trivial Quad to Line
///   - trivial Conic to Quad
///   - trivial Conic to Line
///
/// Some of these simplifications could be implemented in the Path object
/// if we controlled the entire process from end to end.
class PathPruner : public impeller::PathReceiver {
 public:
  explicit PathPruner(SegmentReceiver& receiver, bool is_stroking = false)
      : receiver_(receiver), is_stroking_(is_stroking) {}

  void MoveTo(const Point& p2, bool will_be_closed) override {
    if (is_stroking_) {
      if (contour_has_segments_ && !contour_has_points_) {
        // If we had actual path segments, but none of them went anywhere
        // (i.e. they never generated any points) then we have to record a
        // 0-length line so that stroker can draw "cap boxes"
        receiver_.RecordLine(contour_origin_, contour_origin_);
      }
    } else {  // !is_stroking_
      if (current_point_ != contour_origin_) {
        // We help fill operations out by manually connecting back to the
        // contour origin - basically all fill operations implicitly close
        // their contours. If the current point is not at the contour
        // origin then we must have encountered both segments and points.
        FML_DCHECK(contour_has_segments_);
        FML_DCHECK(contour_has_points_);
        receiver_.RecordLine(current_point_, contour_origin_);
      }
    }
    if (contour_has_segments_) {
      // contour_has_segments_ implies we have called BeginContour at some
      // point in time, so we need to end it as we've "moved on".
      receiver_.EndContour(contour_origin_, false);
    }
    contour_origin_ = current_point_ = p2;
    contour_has_segments_ = contour_has_points_ = false;
    contour_will_be_closed_ = will_be_closed;
    // We will not record a BeginContour for this potential new contour
    // until we get an actual segment within the contour.
    // See SegmentEncountered()
  }

  void LineTo(const Point& p2) override {
    SegmentEncountered();
    if (p2 != current_point_) {
      receiver_.RecordLine(current_point_, p2);
      current_point_ = p2;
      contour_has_points_ = true;
    }
  }

  void QuadTo(const Point& cp, const Point& p2) override {
    if (cp == current_point_ || p2 == cp) {
      // If all 3 are the same, LineTo will handle that for us
      LineTo(p2);
    } else {
      SegmentEncountered();
      receiver_.RecordQuad(current_point_, cp, p2);
      current_point_ = p2;
      contour_has_points_ = true;
    }
  }

  bool ConicTo(const Point& cp, const Point& p2, Scalar weight) override {
    if (weight == 1.0f) {
      QuadTo(cp, p2);
    } else if (cp == current_point_ || p2 == cp || weight == 0.0f) {
      LineTo(p2);
    } else {
      SegmentEncountered();
      receiver_.RecordConic(current_point_, cp, p2, weight);
      current_point_ = p2;
      contour_has_points_ = true;
    }
    return true;
  };

  void CubicTo(const Point& cp1, const Point& cp2, const Point& p2) override {
    SegmentEncountered();
    if (cp1 != current_point_ ||  //
        cp2 != current_point_ ||  //
        p2 != current_point_) {
      // We could check if 3 of the 4 points are equal and simplify to a
      // LineTo, but that quantity of compares is overkill for the unlikely
      // case that it will happen. Checking for simplifying to a QuadTo
      // would involve computing the intersection point of the control
      // polygon edges which is too expensive to be worth the benefit.
      receiver_.RecordCubic(current_point_, cp1, cp2, p2);
      current_point_ = p2;
      contour_has_points_ = true;
    }
  }

  void Close() override {
    // Even a {MoveTo(); Close();} sequence generates a "cap box" at the
    // contour origin location, so we always consider this an "encountered"
    // segment.
    SegmentEncountered();
    if (is_stroking_) {
      if (!contour_has_points_) {
        FML_DCHECK(contour_has_segments_);
        receiver_.RecordLine(current_point_, contour_origin_);
        contour_has_points_ = true;
      }
    } else {  // !is_stroking_
      if (current_point_ != contour_origin_) {
        FML_DCHECK(contour_has_segments_);
        FML_DCHECK(contour_has_points_);
        receiver_.RecordLine(current_point_, contour_origin_);
      }
    }
    receiver_.EndContour(contour_origin_, true);
    // The following mirrors the actions of MoveTo - we remain open to
    // recording a new contour from this origin point as if we had had
    // a MoveTo, but we perform no other processing that a MoveTo implies.
    current_point_ = contour_origin_;
    contour_has_segments_ = contour_has_points_ = false;
    // We will not record a BeginContour for this potential new contour
    // until we get an actual segment within the contour.
    // See SegmentEncountered()
  }

  void PathEnd() {
    if (!is_stroking_ && current_point_ != contour_origin_) {
      FML_DCHECK(contour_has_segments_);
      FML_DCHECK(contour_has_points_);
      receiver_.RecordLine(current_point_, contour_origin_);
    }
    if (contour_has_segments_) {
      receiver_.EndContour(contour_origin_, false);
    }
  }

 private:
  SegmentReceiver& receiver_;
  const bool is_stroking_;

  void SegmentEncountered() {
    if (!contour_has_segments_) {
      receiver_.BeginContour(contour_origin_, contour_will_be_closed_);
      contour_has_segments_ = true;
    }
  }

  bool contour_has_segments_ = false;
  bool contour_has_points_ = false;
  bool contour_will_be_closed_ = false;
  Point contour_origin_;
  Point current_point_;
};

class StorageCounter : public SegmentReceiver {
 public:
  explicit StorageCounter(impeller::Scalar scale) : scale_(scale) {}

  void BeginContour(Point origin, bool will_be_closed) override {
    // This is a new contour
    contour_count_++;

    // This contour will have an implicit "from" point that will be
    // be delivered with the corresponding Segment methods below.
    point_count_++;
  }

  void RecordLine(Point p1, Point p2) override { point_count_++; }

  void RecordQuad(Point p1, Point cp, Point p2) override {
    size_t count =  //
        std::ceilf(ComputeQuadradicSubdivisions(scale_, p1, cp, p2));
    point_count_ += std::max<size_t>(count, 1);
  }

  void RecordConic(Point p1, Point cp, Point p2, Scalar weight) override {
    size_t count =  //
        std::ceilf(ComputeConicSubdivisions(scale_, p1, cp, p2, weight));
    point_count_ += std::max<size_t>(count, 1);
  }

  void RecordCubic(Point p1, Point cp1, Point cp2, Point p2) override {
    size_t count =  //
        std::ceilf(ComputeCubicSubdivisions(scale_, p1, cp1, cp2, p2));
    point_count_ += std::max<size_t>(count, 1);
  }

  void EndContour(Point origin, bool with_close) override {
    // If the close operation would have resulted in an additional line
    // segment then the pruner will call RecordLine independently.
    // We count contours in the BeginContour method
  }

  size_t GetPointCount() const { return point_count_; }
  size_t GetContourCount() const { return contour_count_; }

 private:
  size_t point_count_ = 0u;
  size_t contour_count_ = 0u;

  Scalar scale_;
};

class PathFillWriter : public SegmentReceiver {
 public:
  PathFillWriter(VertexWriter& writer, Scalar scale)
      : writer_(writer), scale_(scale) {}

  void BeginContour(Point origin, bool will_be_closed) override {
    writer_.Write(origin);
  }

  void RecordLine(Point p1, Point p2) override { writer_.Write(p2); }

  void RecordQuad(Point p1, Point cp, Point p2) override {
    Quad quad{p1, cp, p2};
    Scalar count = std::ceilf(ComputeQuadradicSubdivisions(scale_, p1, cp, p2));
    for (size_t i = 1; i < count; i++) {
      writer_.Write(quad.Solve(i / count));
    }
    writer_.Write(p2);
  }

  void RecordConic(Point p1, Point cp, Point p2, Scalar weight) override {
    Conic conic{p1, cp, p2, weight};
    Scalar count =
        std::ceilf(ComputeConicSubdivisions(scale_, p1, cp, p2, weight));
    for (size_t i = 1; i < count; i++) {
      writer_.Write(conic.Solve(i / count));
    }
    writer_.Write(p2);
  }

  void RecordCubic(Point p1, Point cp1, Point cp2, Point p2) override {
    Cubic cubic{p1, cp1, cp2, p2};
    Scalar count =
        std::ceilf(ComputeCubicSubdivisions(scale_, p1, cp1, cp2, p2));
    for (size_t i = 1; i < count; i++) {
      writer_.Write(cubic.Solve(i / count));
    }
    writer_.Write(p2);
  }

  void EndContour(Point origin, bool with_close) override {
    writer_.EndContour();
  }

 private:
  VertexWriter& writer_;
  Scalar scale_;
};

}  // namespace

namespace impeller {

void PathTessellator::PathToFilledSegments(const PathSource& source,
                                           SegmentReceiver& receiver) {
  PathPruner pruner(receiver, false);
  source.Dispatch(pruner);
  pruner.PathEnd();
}

void PathTessellator::PathToStrokedSegments(const PathSource& source,
                                            SegmentReceiver& receiver) {
  PathPruner pruner(receiver, true);
  source.Dispatch(pruner);
  pruner.PathEnd();
}

std::pair<size_t, size_t> PathTessellator::CountFillStorage(
    const PathSource& source,
    Scalar scale) {
  StorageCounter counter(scale);
  PathPruner pruner(counter, false);
  source.Dispatch(pruner);
  pruner.PathEnd();
  return {counter.GetPointCount(), counter.GetContourCount()};
}

void PathTessellator::PathToFilledVertices(const PathSource& source,
                                           VertexWriter& writer,
                                           Scalar scale) {
  PathFillWriter path_writer(writer, scale);
  PathPruner pruner(path_writer, false);
  source.Dispatch(pruner);
  pruner.PathEnd();
}

void PathTessellator::PathToTransformedFilledVertices(const PathSource& source,
                                                      VertexWriter& writer,
                                                      const Matrix& matrix) {
  PathFillWriter path_writer(writer, matrix.GetMaxBasisLengthXY());
  PathPruner pruner(path_writer, false);
  PathTransformer transformer(pruner, matrix);
  source.Dispatch(transformer);
  pruner.PathEnd();
}

}  // namespace impeller
