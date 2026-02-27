// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_PATH_SOURCE_H_
#define FLUTTER_IMPELLER_GEOMETRY_PATH_SOURCE_H_

#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"

namespace impeller {

enum class FillType {
  kNonZero,  // The default winding order.
  kOdd,
};

enum class Convexity {
  kUnknown,
  kConvex,
};

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
};

class PathSource {
 public:
  virtual ~PathSource() = default;
  virtual FillType GetFillType() const = 0;
  virtual Rect GetBounds() const = 0;
  virtual bool IsConvex() const = 0;
  virtual void Dispatch(PathReceiver& receiver) const = 0;
};

/// @brief A PathSource object that provides path iteration for any TRect.
class RectPathSource : public PathSource {
 public:
  template <class T>
  explicit RectPathSource(const TRect<T>& r) : rect_(r) {}

  ~RectPathSource();

  // |PathSource|
  FillType GetFillType() const override;

  // |PathSource|
  Rect GetBounds() const override;

  // |PathSource|
  bool IsConvex() const override;

  // |PathSource|
  void Dispatch(PathReceiver& receiver) const override;

 private:
  const Rect rect_;
};

/// @brief A PathSource object that provides path iteration for any ellipse
///        inscribed within a Rect bounds.
class EllipsePathSource : public PathSource {
 public:
  explicit EllipsePathSource(const Rect& bounds);

  ~EllipsePathSource();

  // |PathSource|
  FillType GetFillType() const override;

  // |PathSource|
  Rect GetBounds() const override;

  // |PathSource|
  bool IsConvex() const override;

  // |PathSource|
  void Dispatch(PathReceiver& receiver) const override;

 private:
  const Rect bounds_;
};

/// A utility class to receive path segments from a source, transform them
/// by a matrix, and pass them along to a subsequent receiver.
class PathTransformer : public impeller::PathReceiver {
 public:
  PathTransformer(PathReceiver& receiver [[clang::lifetimebound]],
                  const impeller::Matrix& matrix [[clang::lifetimebound]])
      : receiver_(receiver), matrix_(matrix) {}

  void MoveTo(const Point& p2, bool will_be_closed) override {
    receiver_.MoveTo(matrix_ * p2, will_be_closed);
  }

  void LineTo(const Point& p2) override { receiver_.LineTo(matrix_ * p2); }

  void QuadTo(const Point& cp, const Point& p2) override {
    receiver_.QuadTo(matrix_ * cp, matrix_ * p2);
  }

  bool ConicTo(const Point& cp, const Point& p2, Scalar weight) override {
    return receiver_.ConicTo(matrix_ * cp, matrix_ * p2, weight);
  }

  void CubicTo(const Point& cp1, const Point& cp2, const Point& p2) override {
    receiver_.CubicTo(matrix_ * cp1, matrix_ * cp2, matrix_ * p2);
  }

  void Close() override { receiver_.Close(); }

 private:
  PathReceiver& receiver_;
  const impeller::Matrix& matrix_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GEOMETRY_PATH_SOURCE_H_
