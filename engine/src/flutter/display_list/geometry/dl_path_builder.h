// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_GEOMETRY_DL_PATH_BUILDER_H_
#define FLUTTER_DISPLAY_LIST_GEOMETRY_DL_PATH_BUILDER_H_

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/third_party/skia/include/core/SkPathBuilder.h"

namespace flutter {

class DlPathBuilder {
 public:
  /// Used for approximating quarter circle arcs with cubic curves. This is
  /// the control point distance which results in the smallest possible unit
  /// circle integration for a right angle arc. It can be used to approximate
  /// arcs less than 90 degrees to great effect by simply reducing it
  /// proportionally to the angle. However, accuracy rapidly diminishes if
  /// magnified for obtuse angle arcs, and so multiple cubic curves should
  /// be used when approximating arcs greater than 90 degrees.
  constexpr static const DlScalar kArcApproximationMagic = 0.551915024494f;

  /// @brief  Set the fill type that should be used to determine the interior
  ///         of this path to the indicated |fill_type|.
  ///
  /// @see |DlPathFillType|
  DlPathBuilder& SetFillType(DlPathFillType fill_type);

  /// @brief  Start a new contour that will originate at the indicated
  ///         point p2.
  DlPathBuilder& MoveTo(DlPoint p2);

  /// @brief  Draw a line from the current point to the indicated point p2.
  ///
  /// If the path is empty, a new contour will automatically be started from
  /// the point (0, 0) as if |MoveTo| had been called.
  DlPathBuilder& LineTo(DlPoint p2);

  /// @brief  Draw a quadratic bezier curve from the current point to the
  ///         indicated point p2, using the indicated point cp as a control
  ///         point.
  ///
  /// If the path is empty, a new contour will automatically be started from
  /// the point (0, 0) as if |MoveTo| had been called.
  DlPathBuilder& QuadraticCurveTo(DlPoint cp, DlPoint p2);

  /// @brief  Draw a conic curve (a rational quadratic bezier curve) from
  ///         the current point to the indicated point p2, using the
  ///         indicated point cp as a control point and the indicated
  ///         weight to control the contribution of the control point.
  ///
  /// A weight of less than 0, or NaN, is treated is if it were 0 which
  /// produces a curve that is identical to a line segment and will be
  /// inserted as a line segment in lieu of the conic.
  ///
  /// A weight of (sqrt(2)/2) will produce a quarter section of an
  /// elliptical path.
  ///
  /// A weight of 1.0 is identical to a quadratic bezier curve and will be
  /// inserted as a quadratic curve in lieu of the conic.
  ///
  /// If the path is empty, a new contour will automatically be started from
  /// the point (0, 0) as if |MoveTo| had been called.
  DlPathBuilder& ConicCurveTo(DlPoint cp, DlPoint p2, DlScalar weight);

  /// @brief  Draw a cubic bezier curve from the current point to the
  ///         indicated point p2, using the indicated points cp1 and cp2
  ///         as control points.
  ///
  /// If the path is empty, a new contour will automatically be started from
  /// the point (0, 0) as if |MoveTo| had been called.
  DlPathBuilder& CubicCurveTo(DlPoint cp1, DlPoint cp2, DlPoint p2);

  /// @brief  The path is closed back to the location of the most recent
  ///         MoveTo call. Contours that are filled are always implicitly
  ///         assumed to be closed, but contours that are stroked will
  ///         either:
  ///           - If closed, draw the stroke back to the contour origin and
  ///             insert a join decoration back to the leading vertex of the
  ///             contour's first segment.
  ///           - If not closed, draw cap decorations at the first and last
  ///             vertices in the contour.
  DlPathBuilder& Close();

  /// @brief  Append a closed rectangular contour to the path.
  DlPathBuilder& AddRect(const DlRect& rect);

  /// @brief  Append a closed elliptical contour to the path inscribed in
  ///         the provided bounds.
  DlPathBuilder& AddOval(const DlRect& bounds);

  /// @brief  Append a closed circular contour to the path centered on the
  ///         provided point at the provided radius.
  DlPathBuilder& AddCircle(DlPoint center, DlScalar radius);

  /// @brief  Append a closed rounded rect contour to the path.
  DlPathBuilder& AddRoundRect(const DlRoundRect& round_rect);

  /// @brief  Append a closed rounded super-ellipse contour to the path.
  DlPathBuilder& AddRoundSuperellipse(const DlRoundSuperellipse& rse);

  /// @brief  Append an arc contour to the path which:
  ///           - is a portion of an ellipse inscribed in the provided
  ///             bounds starting at the indicated angle and sweeping
  ///             by the indicated sweep, clockwise for positive sweeps
  ///             or counter-clockwise for negative sweeps.
  ///           - if use_center is false, starts and ends on the ellipse
  ///             at the specified angles forming a portion of the ellipse
  ///             sliced at the indicated angles.
  ///           - if use_center is false, starts and ends at the center of
  ///             the ellipse forming a pie or pacman shape depending on
  ///             how large the sweep is.
  DlPathBuilder& AddArc(const DlRect& bounds,
                        DlDegrees start,
                        DlDegrees sweep,
                        bool use_center = false);

  /// @brief  Append the provided path to this path as if the commands
  ///         used to construct it were repeated on this path. The fill
  ///         type of the current path will continue to be used, ignoring
  ///         the fill type of the indicated path.
  DlPathBuilder& AddPath(const DlPath& path);

  /// @brief  Returns the path constructed by this path builder so far and
  ///         retains all current geometry to continue building the path.
  const DlPath CopyPath();

  /// @brief  Returns the path constructed by this path builder and resets
  ///         its internal state to the default state when it was constructed.
  const DlPath TakePath();

 private:
  SkPathBuilder path_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_GEOMETRY_DL_PATH_BUILDER_H_
