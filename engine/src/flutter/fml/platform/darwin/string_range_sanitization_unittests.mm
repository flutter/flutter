// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Foundation/Foundation.h>

#include "flutter/fml/platform/darwin/string_range_sanitization.h"
#include "gtest/gtest.h"

TEST(StringRangeSanitizationTest, CanHandleUnicode) {
  auto result = fml::RangeForCharacterAtIndex(@"😠", 1);
  EXPECT_EQ(result.location, 0UL);
  EXPECT_EQ(result.length, 2UL);
}

TEST(StringRangeSanitizationTest, HandlesInvalidRanges) {
  EXPECT_EQ(fml::RangeForCharacterAtIndex(@"😠", 3).location,  0UL);
  EXPECT_EQ(fml::RangeForCharacterAtIndex(@"😠", -1).location,  0UL);
  EXPECT_EQ(fml::RangeForCharacterAtIndex(nil, 0).location, 0UL);
  EXPECT_EQ(fml::RangeForCharactersInRange(@"😠", NSMakeRange(1, 2)).location,  0UL);
  EXPECT_EQ(fml::RangeForCharactersInRange(@"😠", NSMakeRange(3, 0)).location,  0UL);
  EXPECT_EQ(fml::RangeForCharactersInRange(nil, NSMakeRange(0, 0)).location, 0UL);
}

TEST(StringRangeSanitizationTest, CanHandleUnicodeRange) {
  auto result = fml::RangeForCharactersInRange(@"😠", NSMakeRange(1, 0));
  EXPECT_EQ(result.location, 0UL);
  EXPECT_EQ(result.length, 2UL);
}

TEST(StringRangeSanitizationTest, HandlesEndOfRange) {
  EXPECT_EQ(fml::RangeForCharacterAtIndex(@"1234", 4).location, 4UL);
  EXPECT_EQ(fml::RangeForCharacterAtIndex(@"1234", 4).length, 0UL);
}
