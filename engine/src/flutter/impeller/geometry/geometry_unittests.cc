// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/size.h"

namespace impeller {
namespace testing {

TEST(GeometryTest, CanGenerateMipCounts) {
  ASSERT_EQ((Size{128, 128}.MipCount()), 7u);
  ASSERT_EQ((Size{128, 256}.MipCount()), 8u);
  ASSERT_EQ((Size{128, 130}.MipCount()), 8u);
  ASSERT_EQ((Size{128, 257}.MipCount()), 9u);
  ASSERT_EQ((Size{257, 128}.MipCount()), 9u);
  ASSERT_EQ((Size{128, 0}.MipCount()), 1u);
  ASSERT_EQ((Size{128, -25}.MipCount()), 1u);
  ASSERT_EQ((Size{-128, 25}.MipCount()), 1u);
}

TEST(GeometryTest, CanConvertTTypesExplicitly) {
  {
    Point p1(1.0, 2.0);
    IPoint p2 = static_cast<IPoint>(p1);
    ASSERT_EQ(p2.x, 1u);
    ASSERT_EQ(p2.y, 2u);
  }

  {
    Size s1(1.0, 2.0);
    ISize s2 = static_cast<ISize>(s1);
    ASSERT_EQ(s2.width, 1u);
    ASSERT_EQ(s2.height, 2u);
  }

  {
    Rect r1(1.0, 2.0, 3.0, 4.0);
    IRect r2 = static_cast<IRect>(r1);
    ASSERT_EQ(r2.origin.x, 1u);
    ASSERT_EQ(r2.origin.y, 2u);
    ASSERT_EQ(r2.size.width, 3u);
    ASSERT_EQ(r2.size.height, 4u);
  }
}

}  // namespace testing
}  // namespace impeller
