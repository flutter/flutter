// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/nullable_string16.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(NullableString16Test, DefaultConstructor) {
  NullableString16 s;
  EXPECT_TRUE(s.is_null());
  EXPECT_EQ(string16(), s.string());
}

TEST(NullableString16Test, Equals) {
  NullableString16 a(ASCIIToUTF16("hello"), false);
  NullableString16 b(ASCIIToUTF16("hello"), false);
  EXPECT_EQ(a, b);
}

TEST(NullableString16Test, NotEquals) {
  NullableString16 a(ASCIIToUTF16("hello"), false);
  NullableString16 b(ASCIIToUTF16("world"), false);
  EXPECT_NE(a, b);
}

TEST(NullableString16Test, NotEqualsNull) {
  NullableString16 a(ASCIIToUTF16("hello"), false);
  NullableString16 b;
  EXPECT_NE(a, b);
}

}  // namespace base
