// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/path_builder.h"

namespace impeller {
namespace testing {

TEST(EntityGeometryTest, RectGeometryCoversArea) {
  auto geometry = Geometry::MakeRect(Rect::MakeLTRB(0, 0, 100, 100));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillPathGeometryCoversArea) {
  auto path = PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath();
  auto geometry = Geometry::MakeFillPath(
      path, /* inner rect */ Rect::MakeLTRB(0, 0, 100, 100));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillPathGeometryCoversAreaNoInnerRect) {
  auto path = PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath();
  auto geometry = Geometry::MakeFillPath(path);
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, LineGeometryCoverage) {
  {
    auto geometry = Geometry::MakeLine({10, 10}, {20, 10}, 2, Cap::kButt);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(10, 9, 20, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(10, 9, 20, 11)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {20, 10}, 2, Cap::kSquare);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 9, 21, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 9, 21, 11)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {10, 20}, 2, Cap::kButt);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 10, 11, 20));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 10, 11, 20)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {10, 20}, 2, Cap::kSquare);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 9, 11, 21));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 9, 11, 21)));
  }
}

}  // namespace testing
}  // namespace impeller
