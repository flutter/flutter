// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/test/gfx_util.h"

#include <iomanip>
#include <sstream>
#include <string>

#include "ui/gfx/geometry/box_f.h"
#include "ui/gfx/geometry/point.h"
#include "ui/gfx/geometry/point3_f.h"
#include "ui/gfx/geometry/point_f.h"
#include "ui/gfx/geometry/quad_f.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/geometry/rect_f.h"
#include "ui/gfx/geometry/scroll_offset.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/geometry/size_f.h"
#include "ui/gfx/geometry/vector2d.h"
#include "ui/gfx/geometry/vector2d_f.h"
#include "ui/gfx/geometry/vector3d_f.h"
#include "ui/gfx/transform.h"

namespace gfx {

namespace {

std::string ColorAsString(SkColor color) {
  std::ostringstream stream;
  stream << std::hex << std::uppercase << "#" << std::setfill('0')
         << std::setw(2) << SkColorGetA(color)
         << std::setw(2) << SkColorGetR(color)
         << std::setw(2) << SkColorGetG(color)
         << std::setw(2) << SkColorGetB(color);
  return stream.str();
}

bool FloatAlmostEqual(float a, float b) {
  // FloatLE is the gtest predicate for less than or almost equal to.
  return ::testing::FloatLE("a", "b", a, b) &&
         ::testing::FloatLE("b", "a", b, a);
}

}  // namespace

::testing::AssertionResult AssertBoxFloatEqual(const char* lhs_expr,
                                               const char* rhs_expr,
                                               const BoxF& lhs,
                                               const BoxF& rhs) {
  if (FloatAlmostEqual(lhs.x(), rhs.x()) &&
      FloatAlmostEqual(lhs.y(), rhs.y()) &&
      FloatAlmostEqual(lhs.z(), rhs.z()) &&
      FloatAlmostEqual(lhs.width(), rhs.width()) &&
      FloatAlmostEqual(lhs.height(), rhs.height()) &&
      FloatAlmostEqual(lhs.depth(), rhs.depth())) {
    return ::testing::AssertionSuccess();
  }
  return ::testing::AssertionFailure() << "Value of: " << rhs_expr
                                       << "\n  Actual: " << rhs.ToString()
                                       << "\nExpected: " << lhs_expr
                                       << "\nWhich is: " << lhs.ToString();
}

::testing::AssertionResult AssertRectFloatEqual(const char* lhs_expr,
                                                const char* rhs_expr,
                                                const RectF& lhs,
                                                const RectF& rhs) {
  if (FloatAlmostEqual(lhs.x(), rhs.x()) &&
      FloatAlmostEqual(lhs.y(), rhs.y()) &&
      FloatAlmostEqual(lhs.width(), rhs.width()) &&
      FloatAlmostEqual(lhs.height(), rhs.height())) {
    return ::testing::AssertionSuccess();
  }
  return ::testing::AssertionFailure()
         << "Value of: " << rhs_expr << "\n  Actual: " << rhs.ToString()
         << "\nExpected: " << lhs_expr << "\nWhich is: " << lhs.ToString();
}

::testing::AssertionResult AssertSkColorsEqual(const char* lhs_expr,
                                               const char* rhs_expr,
                                               SkColor lhs,
                                               SkColor rhs) {
  if (lhs == rhs) {
    return ::testing::AssertionSuccess();
  }
  return ::testing::AssertionFailure() << "Value of: " << rhs_expr
                                       << "\n  Actual: " << ColorAsString(rhs)
                                       << "\nExpected: " << lhs_expr
                                       << "\nWhich is: " << ColorAsString(lhs);
}

void PrintTo(const BoxF& box, ::std::ostream* os) {
  *os << box.ToString();
}

void PrintTo(const Point& point, ::std::ostream* os) {
  *os << point.ToString();
}

void PrintTo(const Point3F& point, ::std::ostream* os) {
  *os << point.ToString();
}

void PrintTo(const PointF& point, ::std::ostream* os) {
  *os << point.ToString();
}

void PrintTo(const QuadF& quad, ::std::ostream* os) {
  *os << quad.ToString();
}

void PrintTo(const Rect& rect, ::std::ostream* os) {
  *os << rect.ToString();
}

void PrintTo(const RectF& rect, ::std::ostream* os) {
  *os << rect.ToString();
}

void PrintTo(const ScrollOffset& offset, ::std::ostream* os) {
  *os << offset.ToString();
}

void PrintTo(const Size& size, ::std::ostream* os) {
  *os << size.ToString();
}

void PrintTo(const SizeF& size, ::std::ostream* os) {
  *os << size.ToString();
}

void PrintTo(const Transform& transform, ::std::ostream* os) {
  *os << transform.ToString();
}

void PrintTo(const Vector2d& vector, ::std::ostream* os) {
  *os << vector.ToString();
}

void PrintTo(const Vector2dF& vector, ::std::ostream* os) {
  *os << vector.ToString();
}

void PrintTo(const Vector3dF& vector, ::std::ostream* os) {
  *os << vector.ToString();
}

}  // namespace gfx
