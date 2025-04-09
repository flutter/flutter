// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TESSELLATOR_PATH_TESSELLATOR_H_
#define FLUTTER_IMPELLER_TESSELLATOR_PATH_TESSELLATOR_H_

#include <memory>
#include <tuple>

#include "flutter/impeller/geometry/path_source.h"
#include "flutter/impeller/geometry/scalar.h"

namespace impeller {

class PathTessellator {
 public:
  /// @brief An interface for generating a multi contour polyline as a triangle
  ///        strip.
  class VertexWriter {
   public:
    virtual void Write(Point point) = 0;
    virtual void EndContour() = 0;
  };

  /// An interface for receiving pruned path segments.
  class SegmentReceiver {
   public:
    /// Every set of path segments will be surrounded by a Begin/EndContour
    /// pair with the same origin point.
    virtual void BeginContour(Point origin) = 0;

    /// Guaranteed to be non-degenerate except in the single case of stroking
    /// where we have a MoveTo followed by any number of degenerate (single
    /// point, going nowhere) path segments.
    /// p1 will always be the last recorded point.
    virtual void RecordLine(Point p1, Point p2) = 0;

    /// Guaranteed to be non-degenerate (not a line).
    /// p1 will always be the last recorded point.
    virtual void RecordQuad(Point p1, Point cp, Point p2) = 0;

    /// Guaranteed to be non-degenerate (not a quad or line)
    /// p1 will always be the last recorded point.
    virtual void RecordConic(Point p1, Point cp, Point p2, Scalar weight) = 0;

    /// Guaranteed to be trivially non-degenerate (not all 4 points the same).
    /// p1 will always be the last recorded point.
    virtual void RecordCubic(Point p1, Point cp1, Point cp2, Point p2) = 0;

    /// Every set of path segments will be surrounded by a Begin/EndContour
    /// pair with the same origin point.
    /// The boolean indicates if the path was closed as the result of an
    /// explicit PathReceiver::Close invocation which tells a stroking
    /// sub-class whether to use end caps or a "join to first segment".
    /// Contours which are closed by a MoveTo will supply "false".
    virtual void EndContour(Point origin, bool with_close) = 0;
  };

  struct Quad {
    Point p1;
    Point cp;
    Point p2;

    Point Solve(Scalar t) {
      Scalar u = 1.0f - t;
      return p1 * u * u + 2 * cp * u * t + p2 * t * t;
    }
  };

  struct Conic {
    Point p1;
    Point cp;
    Point p2;
    Scalar weight;

    Point Solve(Scalar t) {
      Scalar u = 1.0f - t;
      Scalar coeff_1 = u * u;
      Scalar coeff_c = 2 * u * t * weight;
      Scalar coeff_2 = t * t;

      return (p1 * coeff_1 + cp * coeff_c + p2 * coeff_2) /
             (coeff_1 + coeff_c + coeff_2);
    }
  };

  struct Cubic {
    Point p1;
    Point cp1;
    Point cp2;
    Point p2;

    Point Solve(Scalar t) {
      Scalar u = 1.0f - t;
      return p1 * u * u * u +       //
             3 * cp1 * u * u * t +  //
             3 * cp2 * u * t * t +  //
             p2 * t * t * t;
    }
  };

  static void PathToFilledSegments(const PathSource& path,
                                   SegmentReceiver& receiver);

  static std::pair<size_t, size_t> CountFillStorage(const PathSource& path,
                                                    Scalar scale);

  static void PathToFilledVertices(const PathSource& path,
                                   VertexWriter& writer,
                                   Scalar scale);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TESSELLATOR_PATH_TESSELLATOR_H_
