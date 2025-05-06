// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/round_rect.h"

namespace impeller {

RoundRect RoundRect::MakeRectRadii(const Rect& in_bounds,
                                   const RoundingRadii& in_radii) {
  if (!in_bounds.IsFinite()) {
    return {};
  }
  Rect bounds = in_bounds.GetPositive();
  // RoundingRadii::Scaled might return an empty radii if bounds or in_radii is
  // empty, which is expected. Pass along the bounds even if the radii is empty
  // as it would still have a valid location and/or 1-dimensional size which
  // might appear when stroked
  return RoundRect(bounds, in_radii.Scaled(bounds));
}

// Determine if p is inside the elliptical corner curve defined by the
// indicated corner point and the indicated radii.
// p - is the test point in absolute coordinates
// corner - is the location of the associated corner in absolute coordinates
// direction - is the sign of (corner - center), or the sign of coordinates
//             as they move in the direction of the corner from inside the
//             rect ((-1,-1) for the upper left corner for instance)
// radii - the non-negative X and Y size of the corner's radii.
static bool CornerContains(const Point& p,
                           const Point& corner,
                           const Point& direction,
                           const Size& radii) {
  FML_DCHECK(radii.width >= 0.0f && radii.height >= 0.0f);
  if (radii.IsEmpty()) {
    // This corner is not curved, therefore the containment is the same as
    // the previously checked bounds containment.
    return true;
  }

  // The positive X,Y distance between the corner and the point.
  Point corner_relative = (corner - p) * direction;

  // The distance from the "center" of the corner's elliptical curve.
  // If both numbers are positive then we need to do an elliptical distance
  // check to determine if it is inside the curve.
  // If either number is negative, then the point is outside this quadrant
  // and is governed by inclusion in the bounds and inclusion within other
  // corners of this round rect. In that case, we return true here to allow
  // further evaluation within other quadrants.
  Point quadrant_relative = radii - corner_relative;
  if (quadrant_relative.x <= 0.0f || quadrant_relative.y <= 0.0f) {
    // Not within the curved quadrant of this corner, therefore "inside"
    // relative to this one corner.
    return true;
  }

  // Dividing the quadrant_relative point by the radii gives a corresponding
  // location within a unit circle which can be more easily tested for
  // containment. We can use x^2 + y^2 and compare it against the radius
  // squared (1.0) to avoid the sqrt.
  Point quadrant_unit_circle_point = quadrant_relative / radii;
  return quadrant_unit_circle_point.GetLengthSquared() <= 1.0;
}

// The sign of the direction that points move as they approach the indicated
// corner from within the rectangle.
static constexpr Point kUpperLeftDirection(-1.0f, -1.0f);
static constexpr Point kUpperRightDirection(1.0f, -1.0f);
static constexpr Point kLowerLeftDirection(-1.0f, 1.0f);
static constexpr Point kLowerRightDirection(1.0f, 1.0f);

[[nodiscard]] bool RoundRect::Contains(const Point& p) const {
  if (!bounds_.Contains(p)) {
    return false;
  }
  if (!CornerContains(p, bounds_.GetLeftTop(), kUpperLeftDirection,
                      radii_.top_left) ||
      !CornerContains(p, bounds_.GetRightTop(), kUpperRightDirection,
                      radii_.top_right) ||
      !CornerContains(p, bounds_.GetLeftBottom(), kLowerLeftDirection,
                      radii_.bottom_left) ||
      !CornerContains(p, bounds_.GetRightBottom(), kLowerRightDirection,
                      radii_.bottom_right)) {
    return false;
  }
  return true;
}

RoundRectPathSource::RoundRectPathSource(const RoundRect& round_rect)
    : round_rect_(round_rect) {}

RoundRectPathSource::~RoundRectPathSource() = default;

FillType RoundRectPathSource::GetFillType() const {
  return FillType::kNonZero;
}

Rect RoundRectPathSource::GetBounds() const {
  return round_rect_.GetBounds();
}

bool RoundRectPathSource::IsConvex() const {
  return true;
}

void RoundRectPathSource::Dispatch(PathReceiver& receiver) const {
  Scalar left = round_rect_.GetBounds().GetLeft();
  Scalar top = round_rect_.GetBounds().GetTop();
  Scalar right = round_rect_.GetBounds().GetRight();
  Scalar bottom = round_rect_.GetBounds().GetBottom();
  const RoundingRadii& radii = round_rect_.GetRadii();

  receiver.MoveTo(Point(left + radii.top_left.width, top), true);
  receiver.LineTo(Point(right - radii.top_right.width, top));

  receiver.ConicTo(Point(right, top),
                   Point(right, top + radii.top_right.height),  //
                   kSqrt2Over2);

  receiver.LineTo(Point(right, bottom - radii.bottom_right.height));

  receiver.ConicTo(Point(right, bottom),
                   Point(right - radii.bottom_right.width, bottom),  //
                   kSqrt2Over2);

  receiver.LineTo(Point(left + radii.bottom_left.width, bottom));

  receiver.ConicTo(Point(left, bottom),
                   Point(left, bottom - radii.bottom_left.height),  //
                   kSqrt2Over2);

  receiver.LineTo(Point(left, top + radii.top_left.height));

  receiver.ConicTo(Point(left, top),
                   Point(left + radii.top_left.width, top),  //
                   kSqrt2Over2);

  receiver.Close();
  receiver.PathEnd();
}

}  // namespace impeller
