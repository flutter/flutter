// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/insets.h"

#include "testing/gtest/include/gtest/gtest.h"

TEST(InsetsTest, InsetsDefault) {
  gfx::Insets insets;
  EXPECT_EQ(0, insets.top());
  EXPECT_EQ(0, insets.left());
  EXPECT_EQ(0, insets.bottom());
  EXPECT_EQ(0, insets.right());
  EXPECT_EQ(0, insets.width());
  EXPECT_EQ(0, insets.height());
  EXPECT_TRUE(insets.empty());
}

TEST(InsetsTest, Insets) {
  gfx::Insets insets(1, 2, 3, 4);
  EXPECT_EQ(1, insets.top());
  EXPECT_EQ(2, insets.left());
  EXPECT_EQ(3, insets.bottom());
  EXPECT_EQ(4, insets.right());
  EXPECT_EQ(6, insets.width());  // Left + right.
  EXPECT_EQ(4, insets.height());  // Top + bottom.
  EXPECT_FALSE(insets.empty());
}

TEST(InsetsTest, Set) {
  gfx::Insets insets;
  insets.Set(1, 2, 3, 4);
  EXPECT_EQ(1, insets.top());
  EXPECT_EQ(2, insets.left());
  EXPECT_EQ(3, insets.bottom());
  EXPECT_EQ(4, insets.right());
}

TEST(InsetsTest, Add) {
  gfx::Insets insets;
  insets.Set(1, 2, 3, 4);
  insets += gfx::Insets(5, 6, 7, 8);
  EXPECT_EQ(6, insets.top());
  EXPECT_EQ(8, insets.left());
  EXPECT_EQ(10, insets.bottom());
  EXPECT_EQ(12, insets.right());
}

TEST(InsetsTest, Equality) {
  gfx::Insets insets1;
  insets1.Set(1, 2, 3, 4);
  gfx::Insets insets2;
  // Test operator== and operator!=.
  EXPECT_FALSE(insets1 == insets2);
  EXPECT_TRUE(insets1 != insets2);

  insets2.Set(1, 2, 3, 4);
  EXPECT_TRUE(insets1 == insets2);
  EXPECT_FALSE(insets1 != insets2);
}

TEST(InsetsTest, ToString) {
  gfx::Insets insets(1, 2, 3, 4);
  EXPECT_EQ("1,2,3,4", insets.ToString());
}
