// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_PATH_SOURCE_H_
#define FLUTTER_IMPELLER_GEOMETRY_PATH_SOURCE_H_

#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"

namespace impeller {

/// @brief   Collection of functions to receive path segments from the
///          underlying path representation via the DlPath::Dispatch method.
///
/// The conic_to function is optional. If the receiver understands rational
/// quadratic Bezier curve forms then it should accept the curve parameters
/// and return true, otherwise it can return false and the dispatcher will
/// provide the path segment in a different form via the other methods.
///
/// The dispatcher might not call the recommend_size or recommend_bounds
/// functions if the original path does not contain such information. If
/// it does call these functions then they should be called before any
/// path segments are dispatched.
///
/// The dispatcher will always call the path_info function, though the
/// is_convex parameter may be conservatively reported as false if the
/// original path does not contain such info.
///
/// Finally the dispatcher will always call the PathEnd function as the
/// last action before returning control to the method that called it.
class PathReceiver {
 public:
  virtual ~PathReceiver() = default;
  virtual void MoveTo(const Point& p2, bool will_be_closed) = 0;
  virtual void LineTo(const Point& p2) = 0;
  virtual void QuadTo(const Point& cp, const Point& p2) = 0;
  virtual bool ConicTo(const Point& cp, const Point& p2, Scalar weight) {
    return false;
  }
  virtual void CubicTo(const Point& cp1, const Point& cp2, const Point& p2) = 0;
  virtual void Close() = 0;
  virtual void PathEnd() {}
};

class PathSource {
 public:
  virtual ~PathSource() = default;
  virtual FillType GetFillType() const = 0;
  virtual Rect GetBounds() const = 0;
  virtual bool IsConvex() const = 0;
  virtual void Dispatch(PathReceiver& receiver) const = 0;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GEOMETRY_PATH_SOURCE_H_
