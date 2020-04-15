// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/string_conversion.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(StringConversion, Utf16FromUtf8Empty) {
  EXPECT_EQ(Utf16FromUtf8(""), L"");
}

TEST(StringConversion, Utf16FromUtf8Ascii) {
  EXPECT_EQ(Utf16FromUtf8("abc123"), L"abc123");
}

TEST(StringConversion, Utf16FromUtf8Unicode) {
  EXPECT_EQ(Utf16FromUtf8("\xe2\x98\x83"), L"\x2603");
}

TEST(StringConversion, Utf8FromUtf16Empty) {
  EXPECT_EQ(Utf8FromUtf16(L""), "");
}

TEST(StringConversion, Utf8FromUtf16Ascii) {
  EXPECT_EQ(Utf8FromUtf16(L"abc123"), "abc123");
}

TEST(StringConversion, Utf8FromUtf16Unicode) {
  EXPECT_EQ(Utf8FromUtf16(L"\x2603"), "\xe2\x98\x83");
}

}  // namespace testing
}  // namespace flutter
