// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_WANGS_FORMULA_H_
#define FLUTTER_IMPELLER_GEOMETRY_WANGS_FORMULA_H_

#include "impeller/geometry/constants.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"

// Skia GPU Ports

// Wang's formula gives the minimum number of evenly spaced (in the parametric
// sense) line segments that a bezier curve must be chopped into in order to
// guarantee all lines stay within a distance of "1/precision" pixels from the
// true curve. Its definition for a bezier curve of degree "n" is as follows:
//
//     maxLength = max([length(p[i+2] - 2p[i+1] + p[i]) for (0 <= i <= n-2)])
//     numParametricSegments = sqrt(maxLength * precision * n*(n - 1)/8)
//
// (Goldman, Ron. (2003). 5.6.3 Wang's Formula. "Pyramid Algorithms: A Dynamic
// Programming Approach to Curves and Surfaces for Geometric Modeling". Morgan
// Kaufmann Publishers.)
namespace impeller {

/// The maximum number of line segments that any one curve will be subdivided
/// into by the functions below.
///
/// Without a limit, a curve with very large (or non-finite) coordinates
/// relative to the scale factor produces an enormous or infinite count, and
/// the tessellators that loop over that count never finish. Very large
/// coordinates are legitimate, for example geometry drawn in "world" units
/// and positioned with a transform, so this clamps the count instead of
/// rejecting the curve.
///
/// The limit matches the one used for circles and ovals, because ovals and
/// round rect corners reach these functions as one conic per quarter turn.
/// See |kMaxSegmentsPerQuarterTurn|.
///
/// All of the functions below return a value in the range
/// [0, kMaxCurveSubdivisions]. A non-finite count is returned as
/// kMaxCurveSubdivisions rather than 0 or 1, because an infinite or NaN
/// count usually comes from float overflow on huge but finite coordinates
/// (for example inf * 0 in the conic formula), and too few segments would
/// render such a curve as a straight line.
constexpr Scalar kMaxCurveSubdivisions =
    static_cast<Scalar>(kMaxSegmentsPerQuarterTurn);

/// Returns the minimum number of evenly spaced (in the parametric sense) line
/// segments that the cubic must be chopped into in order to guarantee all lines
/// stay within a distance of "1/intolerance" pixels from the true curve.
///
/// The scale_factor should be the max basis XY of the current transform.
Scalar ComputeCubicSubdivisions(Scalar scale_factor,
                                Point p0,
                                Point p1,
                                Point p2,
                                Point p3);

/// Returns the minimum number of evenly spaced (in the parametric sense) line
/// segments that the quadratic must be chopped into in order to guarantee all
/// lines stay within a distance of "1/intolerance" pixels from the true curve.
///
/// The scale_factor should be the max basis XY of the current transform.
Scalar ComputeQuadradicSubdivisions(Scalar scale_factor,
                                    Point p0,
                                    Point p1,
                                    Point p2);

/// Returns the minimum number of evenly spaced (in the parametric sense) line
/// segments that the conic must be chopped into in order to guarantee all
/// lines stay within a distance of "1/intolerance" pixels from the true curve.
///
/// The scale_factor should be the max basis XY of the current transform.
Scalar ComputeConicSubdivisions(Scalar scale_factor,
                                Point p0,
                                Point p1,
                                Point p2,
                                Scalar w);
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GEOMETRY_WANGS_FORMULA_H_
