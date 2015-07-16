// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/char_iterator.h"

#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace i18n {

TEST(CharIteratorsTest, TestUTF8) {
  std::string empty;
  UTF8CharIterator empty_iter(&empty);
  ASSERT_TRUE(empty_iter.end());
  ASSERT_EQ(0, empty_iter.array_pos());
  ASSERT_EQ(0, empty_iter.char_pos());
  ASSERT_FALSE(empty_iter.Advance());

  std::string str("s\303\273r");  // [u with circumflex]
  UTF8CharIterator iter(&str);
  ASSERT_FALSE(iter.end());
  ASSERT_EQ(0, iter.array_pos());
  ASSERT_EQ(0, iter.char_pos());
  ASSERT_EQ('s', iter.get());
  ASSERT_TRUE(iter.Advance());

  ASSERT_FALSE(iter.end());
  ASSERT_EQ(1, iter.array_pos());
  ASSERT_EQ(1, iter.char_pos());
  ASSERT_EQ(251, iter.get());
  ASSERT_TRUE(iter.Advance());

  ASSERT_FALSE(iter.end());
  ASSERT_EQ(3, iter.array_pos());
  ASSERT_EQ(2, iter.char_pos());
  ASSERT_EQ('r', iter.get());
  ASSERT_TRUE(iter.Advance());

  ASSERT_TRUE(iter.end());
  ASSERT_EQ(4, iter.array_pos());
  ASSERT_EQ(3, iter.char_pos());

  // Don't care what it returns, but this shouldn't crash
  iter.get();

  ASSERT_FALSE(iter.Advance());
}

TEST(CharIteratorsTest, TestUTF16) {
  string16 empty = UTF8ToUTF16("");
  UTF16CharIterator empty_iter(&empty);
  ASSERT_TRUE(empty_iter.end());
  ASSERT_EQ(0, empty_iter.array_pos());
  ASSERT_EQ(0, empty_iter.char_pos());
  ASSERT_FALSE(empty_iter.Advance());

  // This test string contains 4 characters:
  //   x
  //   u with circumflex - 2 bytes in UTF8, 1 codeword in UTF16
  //   math double-struck A - 4 bytes in UTF8, 2 codewords in UTF16
  //   z
  string16 str = UTF8ToUTF16("x\303\273\360\235\224\270z");
  UTF16CharIterator iter(&str);
  ASSERT_FALSE(iter.end());
  ASSERT_EQ(0, iter.array_pos());
  ASSERT_EQ(0, iter.char_pos());
  ASSERT_EQ('x', iter.get());
  ASSERT_TRUE(iter.Advance());

  ASSERT_FALSE(iter.end());
  ASSERT_EQ(1, iter.array_pos());
  ASSERT_EQ(1, iter.char_pos());
  ASSERT_EQ(251, iter.get());
  ASSERT_TRUE(iter.Advance());

  ASSERT_FALSE(iter.end());
  ASSERT_EQ(2, iter.array_pos());
  ASSERT_EQ(2, iter.char_pos());
  ASSERT_EQ(120120, iter.get());
  ASSERT_TRUE(iter.Advance());

  ASSERT_FALSE(iter.end());
  ASSERT_EQ(4, iter.array_pos());
  ASSERT_EQ(3, iter.char_pos());
  ASSERT_EQ('z', iter.get());
  ASSERT_TRUE(iter.Advance());

  ASSERT_TRUE(iter.end());
  ASSERT_EQ(5, iter.array_pos());
  ASSERT_EQ(4, iter.char_pos());

  // Don't care what it returns, but this shouldn't crash
  iter.get();

  ASSERT_FALSE(iter.Advance());
}

}  // namespace i18n
}  // namespace base
