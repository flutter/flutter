// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/rect.h"

#include "flutter/impeller/geometry/geometry_asserts.h"

namespace impeller {
namespace testing {

TEST(RectTest, RectOriginSizeGetters) {
  {
    Rect r = Rect::MakeOriginSize({10, 20}, {50, 40});
    ASSERT_EQ(r.GetOrigin(), Point(10, 20));
    ASSERT_EQ(r.GetSize(), Size(50, 40));
  }

  {
    Rect r = Rect::MakeLTRB(10, 20, 50, 40);
    ASSERT_EQ(r.GetOrigin(), Point(10, 20));
    ASSERT_EQ(r.GetSize(), Size(40, 20));
  }
}

TEST(RectTest, RectMakeSize) {
  {
    Size s(100, 200);
    Rect r = Rect::MakeSize(s);
    Rect expected = Rect::MakeLTRB(0, 0, 100, 200);
    ASSERT_RECT_NEAR(r, expected);
  }

  {
    ISize s(100, 200);
    Rect r = Rect::MakeSize(s);
    Rect expected = Rect::MakeLTRB(0, 0, 100, 200);
    ASSERT_RECT_NEAR(r, expected);
  }

  {
    Size s(100, 200);
    IRect r = IRect::MakeSize(s);
    IRect expected = IRect::MakeLTRB(0, 0, 100, 200);
    ASSERT_EQ(r, expected);
  }

  {
    ISize s(100, 200);
    IRect r = IRect::MakeSize(s);
    IRect expected = IRect::MakeLTRB(0, 0, 100, 200);
    ASSERT_EQ(r, expected);
  }
}

}  // namespace testing
}  // namespace impeller
