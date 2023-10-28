// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/rect.h"

namespace impeller {
namespace testing {

TEST(RectTest, RectOriginSizeGetters) {
  {
    Rect r{{10, 20}, {50, 40}};
    ASSERT_EQ(r.GetOrigin(), Point(10, 20));
    ASSERT_EQ(r.GetSize(), Size(50, 40));
  }

  {
    Rect r = Rect::MakeLTRB(10, 20, 50, 40);
    ASSERT_EQ(r.GetOrigin(), Point(10, 20));
    ASSERT_EQ(r.GetSize(), Size(40, 20));
  }
}

}  // namespace testing
}  // namespace impeller
