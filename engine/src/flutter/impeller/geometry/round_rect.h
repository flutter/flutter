// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_ROUND_RECT_H_
#define FLUTTER_IMPELLER_GEOMETRY_ROUND_RECT_H_

#include "flutter/impeller/geometry/point.h"
#include "flutter/impeller/geometry/rect.h"
#include "flutter/impeller/geometry/rounding_radii.h"
#include "flutter/impeller/geometry/size.h"

namespace impeller {

struct RoundRect {
  RoundRect() = default;

  constexpr static RoundRect MakeRect(const Rect& rect) {
    return MakeRectRadii(rect, RoundingRadii());
  }

  constexpr static RoundRect MakeOval(const Rect& rect) {
    return MakeRectRadii(rect, RoundingRadii::MakeRadii(rect.GetSize() * 0.5f));
  }

  constexpr static RoundRect MakeRectRadius(const Rect& rect, Scalar radius) {
    return MakeRectRadii(rect, RoundingRadii::MakeRadius(radius));
  }

  constexpr static RoundRect MakeRectXY(const Rect& rect,
                                        Scalar x_radius,
                                        Scalar y_radius) {
    return MakeRectRadii(rect,
                         RoundingRadii::MakeRadii(Size(x_radius, y_radius)));
  }

  constexpr static RoundRect MakeRectXY(const Rect& rect, Size corner_radii) {
    return MakeRectRadii(rect, RoundingRadii::MakeRadii(corner_radii));
  }

  constexpr static RoundRect MakeNinePatch(const Rect& rect,
                                           Scalar left,
                                           Scalar top,
                                           Scalar right,
                                           Scalar bottom) {
    return MakeRectRadii(
        rect, RoundingRadii::MakeNinePatch(left, top, right, bottom));
  }

  static RoundRect MakeRectRadii(const Rect& rect, const RoundingRadii& radii);

  constexpr const Rect& GetBounds() const { return bounds_; }
  constexpr const RoundingRadii& GetRadii() const { return radii_; }

  [[nodiscard]] constexpr bool IsFinite() const {
    return bounds_.IsFinite() &&             //
           radii_.top_left.IsFinite() &&     //
           radii_.top_right.IsFinite() &&    //
           radii_.bottom_left.IsFinite() &&  //
           radii_.bottom_right.IsFinite();
  }

  [[nodiscard]] constexpr bool IsEmpty() const { return bounds_.IsEmpty(); }

  [[nodiscard]] constexpr bool IsRect() const {
    return !bounds_.IsEmpty() && radii_.AreAllCornersEmpty();
  }

  [[nodiscard]] constexpr bool IsOval() const {
    return !bounds_.IsEmpty() && radii_.AreAllCornersSame() &&
           ScalarNearlyEqual(radii_.top_left.width,
                             bounds_.GetWidth() * 0.5f) &&
           ScalarNearlyEqual(radii_.top_left.height,
                             bounds_.GetHeight() * 0.5f);
  }

  /// @brief  Returns true iff the provided point |p| is inside the
  ///         half-open interior of this rectangle.
  ///
  ///         For purposes of containment, a rectangle contains points
  ///         along the top and left edges but not points along the
  ///         right and bottom edges so that a point is only ever
  ///         considered inside one of two abutting rectangles.
  [[nodiscard]] bool Contains(const Point& p) const;

  /// @brief  Returns a new round rectangle translated by the given offset.
  [[nodiscard]] constexpr RoundRect Shift(Scalar dx, Scalar dy) const {
    // Just in case, use the factory rather than the internal constructor
    // as shifting the rectangle may increase/decrease its bit precision
    // so we should re-validate the radii to the newly located rectangle.
    return MakeRectRadii(bounds_.Shift(dx, dy), radii_);
  }

  /// @brief  Returns a round rectangle with expanded edges. Negative expansion
  ///         results in shrinking.
  [[nodiscard]] constexpr RoundRect Expand(Scalar left,
                                           Scalar top,
                                           Scalar right,
                                           Scalar bottom) const {
    // Use the factory rather than the internal constructor as the changing
    // size of the rectangle requires that we re-validate the radii to the
    // newly sized rectangle.
    return MakeRectRadii(bounds_.Expand(left, top, right, bottom), radii_);
  }

  /// @brief  Returns a round rectangle with expanded edges. Negative expansion
  ///         results in shrinking.
  [[nodiscard]] constexpr RoundRect Expand(Scalar horizontal,
                                           Scalar vertical) const {
    // Use the factory rather than the internal constructor as the changing
    // size of the rectangle requires that we re-validate the radii to the
    // newly sized rectangle.
    return MakeRectRadii(bounds_.Expand(horizontal, vertical), radii_);
  }

  /// @brief  Returns a round rectangle with expanded edges. Negative expansion
  ///         results in shrinking.
  [[nodiscard]] constexpr RoundRect Expand(Scalar amount) const {
    // Use the factory rather than the internal constructor as the changing
    // size of the rectangle requires that we re-validate the radii to the
    // newly sized rectangle.
    return MakeRectRadii(bounds_.Expand(amount), radii_);
  }

  [[nodiscard]] constexpr bool operator==(const RoundRect& rr) const {
    return bounds_ == rr.bounds_ && radii_ == rr.radii_;
  }

  [[nodiscard]] constexpr bool operator!=(const RoundRect& r) const {
    return !(*this == r);
  }

 private:
  constexpr RoundRect(const Rect& bounds, const RoundingRadii& radii)
      : bounds_(bounds), radii_(radii) {}

  Rect bounds_;
  RoundingRadii radii_;
};

}  // namespace impeller

namespace std {

inline std::ostream& operator<<(std::ostream& out,
                                const impeller::RoundRect& rr) {
  out << "("                                 //
      << "rect: " << rr.GetBounds() << ", "  //
      << "radii: " << rr.GetRadii()          //
      << ")";
  return out;
}

}  // namespace std

#endif  // FLUTTER_IMPELLER_GEOMETRY_ROUND_RECT_H_
