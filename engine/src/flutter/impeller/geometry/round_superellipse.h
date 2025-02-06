// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_ROUND_SUPERELLIPSE_H_
#define FLUTTER_IMPELLER_GEOMETRY_ROUND_SUPERELLIPSE_H_

#include "flutter/impeller/geometry/point.h"
#include "flutter/impeller/geometry/rect.h"
#include "flutter/impeller/geometry/rounding_radii.h"
#include "flutter/impeller/geometry/size.h"

namespace impeller {

struct RoundSuperellipse {
  RoundSuperellipse() = default;

  constexpr static RoundSuperellipse MakeRectRadius(const Rect& rect,
                                                    Scalar radius) {
    return MakeRectRadii(rect, RoundingRadii::MakeRadius(radius));
  }

  static RoundSuperellipse MakeRectRadii(const Rect& rect,
                                         const RoundingRadii& radii);

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

  /// @brief  Returns a new round rectangle translated by the given offset.
  [[nodiscard]] constexpr RoundSuperellipse Shift(Scalar dx, Scalar dy) const {
    // Just in case, use the factory rather than the internal constructor
    // as shifting the rectangle may increase/decrease its bit precision
    // so we should re-validate the radii to the newly located rectangle.
    return MakeRectRadii(bounds_.Shift(dx, dy), radii_);
  }

  [[nodiscard]] constexpr bool operator==(const RoundSuperellipse& rr) const {
    return bounds_ == rr.bounds_ && radii_ == rr.radii_;
  }

  [[nodiscard]] constexpr bool operator!=(const RoundSuperellipse& r) const {
    return !(*this == r);
  }

 private:
  constexpr RoundSuperellipse(const Rect& bounds, const RoundingRadii& radii)
      : bounds_(bounds), radii_(radii) {}

  Rect bounds_;
  RoundingRadii radii_;
};

}  // namespace impeller

namespace std {

inline std::ostream& operator<<(std::ostream& out,
                                const impeller::RoundSuperellipse& rr) {
  out << "("                                 //
      << "rect: " << rr.GetBounds() << ", "  //
      << "radii: " << rr.GetRadii()          //
      << ")";
  return out;
}

}  // namespace std

#endif  // FLUTTER_IMPELLER_GEOMETRY_ROUND_SUPERELLIPSE_H_
