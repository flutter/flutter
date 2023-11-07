// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/size.h"

namespace impeller {
namespace testing {

TEST(SizeTest, SizeIsEmpty) {
  auto nan = std::numeric_limits<Scalar>::quiet_NaN();

  // Non-empty
  EXPECT_FALSE(Size(10.5, 7.2).IsEmpty());

  // Empty both width and height both 0 or negative, in all combinations
  EXPECT_TRUE(Size(0.0, 0.0).IsEmpty());
  EXPECT_TRUE(Size(-1.0, -1.0).IsEmpty());
  EXPECT_TRUE(Size(-1.0, 0.0).IsEmpty());
  EXPECT_TRUE(Size(0.0, -1.0).IsEmpty());

  // Empty for 0 or negative width or height (but not both at the same time)
  EXPECT_TRUE(Size(10.5, 0.0).IsEmpty());
  EXPECT_TRUE(Size(10.5, -1.0).IsEmpty());
  EXPECT_TRUE(Size(0.0, 7.2).IsEmpty());
  EXPECT_TRUE(Size(-1.0, 7.2).IsEmpty());

  // Empty for NaN in width or height or both
  EXPECT_TRUE(Size(10.5, nan).IsEmpty());
  EXPECT_TRUE(Size(nan, 7.2).IsEmpty());
  EXPECT_TRUE(Size(nan, nan).IsEmpty());
}

TEST(SizeTest, ISizeIsEmpty) {
  // Non-empty
  EXPECT_FALSE(ISize(10, 7).IsEmpty());

  // Empty both width and height both 0 or negative, in all combinations
  EXPECT_TRUE(ISize(0, 0).IsEmpty());
  EXPECT_TRUE(ISize(-1, -1).IsEmpty());
  EXPECT_TRUE(ISize(-1, 0).IsEmpty());
  EXPECT_TRUE(ISize(0, -1).IsEmpty());

  // Empty for 0 or negative width or height (but not both at the same time)
  EXPECT_TRUE(ISize(10, 0).IsEmpty());
  EXPECT_TRUE(ISize(10, -1).IsEmpty());
  EXPECT_TRUE(ISize(0, 7).IsEmpty());
  EXPECT_TRUE(ISize(-1, 7).IsEmpty());
}

}  // namespace testing
}  // namespace impeller
