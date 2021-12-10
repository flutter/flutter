// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "string_utils.h"

#include <cerrno>
#include <cstddef>

#include "base/logging.h"
#include "gtest/gtest.h"

namespace base {

TEST(StringUtilsTest, StringPrintfEmpty) {
  EXPECT_EQ("", base::StringPrintf("%s", ""));
}

TEST(StringUtilsTest, StringPrintfMisc) {
  EXPECT_EQ("123hello w", StringPrintf("%3d%2s %1c", 123, "hello", 'w'));
}
// Test that StringPrintf and StringAppendV do not change errno.
TEST(StringUtilsTest, StringPrintfErrno) {
  errno = 1;
  EXPECT_EQ("", StringPrintf("%s", ""));
  EXPECT_EQ(1, errno);
}

TEST(StringUtilsTest, canASCIIToUTF16) {
  std::string ascii = "abcdefg";
  EXPECT_EQ(ASCIIToUTF16(ascii).compare(u"abcdefg"), 0);
}

TEST(StringUtilsTest, canUTF8ToUTF16) {
  std::string utf8 = "äåè";
  EXPECT_EQ(UTF8ToUTF16(utf8).compare(u"äåè"), 0);
}

TEST(StringUtilsTest, canUTF16ToUTF8) {
  std::u16string utf16 = u"äåè";
  EXPECT_EQ(UTF16ToUTF8(utf16).compare("äåè"), 0);
}

TEST(StringUtilsTest, canNumberToString16) {
  float number = 1.123;
  EXPECT_EQ(NumberToString16(number).compare(u"1.123000"), 0);
}

TEST(StringUtilsTest, canNumberToString) {
  float f = 1.123;
  EXPECT_EQ(NumberToString(f).compare("1.123000"), 0);
  unsigned int s = 11;
  EXPECT_EQ(NumberToString(s).compare("11"), 0);
  int32_t i = -23;
  EXPECT_EQ(NumberToString(i).compare("-23"), 0);
}

}  // namespace base
