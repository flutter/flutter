// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/text_range.h"

#include "gtest/gtest.h"

namespace flutter {

TEST(TextRange, TextRangeFromPositionZero) {
  TextRange range(0);
  EXPECT_EQ(range.base(), size_t(0));
  EXPECT_EQ(range.extent(), size_t(0));
  EXPECT_EQ(range.start(), size_t(0));
  EXPECT_EQ(range.end(), size_t(0));
  EXPECT_EQ(range.length(), size_t(0));
  EXPECT_EQ(range.position(), size_t(0));
  EXPECT_TRUE(range.collapsed());
}

TEST(TextRange, TextRangeFromPositionNonZero) {
  TextRange range(3);
  EXPECT_EQ(range.base(), size_t(3));
  EXPECT_EQ(range.extent(), size_t(3));
  EXPECT_EQ(range.start(), size_t(3));
  EXPECT_EQ(range.end(), size_t(3));
  EXPECT_EQ(range.length(), size_t(0));
  EXPECT_EQ(range.position(), size_t(3));
  EXPECT_TRUE(range.collapsed());
}

TEST(TextRange, TextRangeFromRange) {
  TextRange range(3, 7);
  EXPECT_EQ(range.base(), size_t(3));
  EXPECT_EQ(range.extent(), size_t(7));
  EXPECT_EQ(range.start(), size_t(3));
  EXPECT_EQ(range.end(), size_t(7));
  EXPECT_EQ(range.length(), size_t(4));
  EXPECT_FALSE(range.collapsed());
}

TEST(TextRange, TextRangeFromReversedRange) {
  TextRange range(7, 3);
  EXPECT_EQ(range.base(), size_t(7));
  EXPECT_EQ(range.extent(), size_t(3));
  EXPECT_EQ(range.start(), size_t(3));
  EXPECT_EQ(range.end(), size_t(7));
  EXPECT_EQ(range.length(), size_t(4));
  EXPECT_FALSE(range.collapsed());
}

}  // namespace flutter
