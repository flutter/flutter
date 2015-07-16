// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/basictypes.h"
#include "base/strings/string_piece.h"
#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "base/test/scoped_locale.h"
#include "testing/gtest/include/gtest/gtest.h"

#ifdef WCHAR_T_IS_UTF32
static const std::wstring kSysWideOldItalicLetterA = L"\x10300";
#else
static const std::wstring kSysWideOldItalicLetterA = L"\xd800\xdf00";
#endif

namespace base {

TEST(SysStrings, SysWideToUTF8) {
  EXPECT_EQ("Hello, world", SysWideToUTF8(L"Hello, world"));
  EXPECT_EQ("\xe4\xbd\xa0\xe5\xa5\xbd", SysWideToUTF8(L"\x4f60\x597d"));

  // >16 bits
  EXPECT_EQ("\xF0\x90\x8C\x80", SysWideToUTF8(kSysWideOldItalicLetterA));

  // Error case. When Windows finds a UTF-16 character going off the end of
  // a string, it just converts that literal value to UTF-8, even though this
  // is invalid.
  //
  // This is what XP does, but Vista has different behavior, so we don't bother
  // verifying it:
  // EXPECT_EQ("\xE4\xBD\xA0\xED\xA0\x80zyxw",
  //           SysWideToUTF8(L"\x4f60\xd800zyxw"));

  // Test embedded NULLs.
  std::wstring wide_null(L"a");
  wide_null.push_back(0);
  wide_null.push_back('b');

  std::string expected_null("a");
  expected_null.push_back(0);
  expected_null.push_back('b');

  EXPECT_EQ(expected_null, SysWideToUTF8(wide_null));
}

TEST(SysStrings, SysUTF8ToWide) {
  EXPECT_EQ(L"Hello, world", SysUTF8ToWide("Hello, world"));
  EXPECT_EQ(L"\x4f60\x597d", SysUTF8ToWide("\xe4\xbd\xa0\xe5\xa5\xbd"));
  // >16 bits
  EXPECT_EQ(kSysWideOldItalicLetterA, SysUTF8ToWide("\xF0\x90\x8C\x80"));

  // Error case. When Windows finds an invalid UTF-8 character, it just skips
  // it. This seems weird because it's inconsistent with the reverse conversion.
  //
  // This is what XP does, but Vista has different behavior, so we don't bother
  // verifying it:
  // EXPECT_EQ(L"\x4f60zyxw", SysUTF8ToWide("\xe4\xbd\xa0\xe5\xa5zyxw"));

  // Test embedded NULLs.
  std::string utf8_null("a");
  utf8_null.push_back(0);
  utf8_null.push_back('b');

  std::wstring expected_null(L"a");
  expected_null.push_back(0);
  expected_null.push_back('b');

  EXPECT_EQ(expected_null, SysUTF8ToWide(utf8_null));
}

#if defined(OS_LINUX)  // Tests depend on setting a specific Linux locale.

TEST(SysStrings, SysWideToNativeMB) {
#if !defined(SYSTEM_NATIVE_UTF8)
  ScopedLocale locale("en_US.utf-8");
#endif
  EXPECT_EQ("Hello, world", SysWideToNativeMB(L"Hello, world"));
  EXPECT_EQ("\xe4\xbd\xa0\xe5\xa5\xbd", SysWideToNativeMB(L"\x4f60\x597d"));

  // >16 bits
  EXPECT_EQ("\xF0\x90\x8C\x80", SysWideToNativeMB(kSysWideOldItalicLetterA));

  // Error case. When Windows finds a UTF-16 character going off the end of
  // a string, it just converts that literal value to UTF-8, even though this
  // is invalid.
  //
  // This is what XP does, but Vista has different behavior, so we don't bother
  // verifying it:
  // EXPECT_EQ("\xE4\xBD\xA0\xED\xA0\x80zyxw",
  //           SysWideToNativeMB(L"\x4f60\xd800zyxw"));

  // Test embedded NULLs.
  std::wstring wide_null(L"a");
  wide_null.push_back(0);
  wide_null.push_back('b');

  std::string expected_null("a");
  expected_null.push_back(0);
  expected_null.push_back('b');

  EXPECT_EQ(expected_null, SysWideToNativeMB(wide_null));
}

// We assume the test is running in a UTF8 locale.
TEST(SysStrings, SysNativeMBToWide) {
#if !defined(SYSTEM_NATIVE_UTF8)
  ScopedLocale locale("en_US.utf-8");
#endif
  EXPECT_EQ(L"Hello, world", SysNativeMBToWide("Hello, world"));
  EXPECT_EQ(L"\x4f60\x597d", SysNativeMBToWide("\xe4\xbd\xa0\xe5\xa5\xbd"));
  // >16 bits
  EXPECT_EQ(kSysWideOldItalicLetterA, SysNativeMBToWide("\xF0\x90\x8C\x80"));

  // Error case. When Windows finds an invalid UTF-8 character, it just skips
  // it. This seems weird because it's inconsistent with the reverse conversion.
  //
  // This is what XP does, but Vista has different behavior, so we don't bother
  // verifying it:
  // EXPECT_EQ(L"\x4f60zyxw", SysNativeMBToWide("\xe4\xbd\xa0\xe5\xa5zyxw"));

  // Test embedded NULLs.
  std::string utf8_null("a");
  utf8_null.push_back(0);
  utf8_null.push_back('b');

  std::wstring expected_null(L"a");
  expected_null.push_back(0);
  expected_null.push_back('b');

  EXPECT_EQ(expected_null, SysNativeMBToWide(utf8_null));
}

static const wchar_t* const kConvertRoundtripCases[] = {
  L"Google Video",
  // "网页 图片 资讯更多 »"
  L"\x7f51\x9875\x0020\x56fe\x7247\x0020\x8d44\x8baf\x66f4\x591a\x0020\x00bb",
  //  "Παγκόσμιος Ιστός"
  L"\x03a0\x03b1\x03b3\x03ba\x03cc\x03c3\x03bc\x03b9"
  L"\x03bf\x03c2\x0020\x0399\x03c3\x03c4\x03cc\x03c2",
  // "Поиск страниц на русском"
  L"\x041f\x043e\x0438\x0441\x043a\x0020\x0441\x0442"
  L"\x0440\x0430\x043d\x0438\x0446\x0020\x043d\x0430"
  L"\x0020\x0440\x0443\x0441\x0441\x043a\x043e\x043c",
  // "전체서비스"
  L"\xc804\xccb4\xc11c\xbe44\xc2a4",

  // Test characters that take more than 16 bits. This will depend on whether
  // wchar_t is 16 or 32 bits.
#if defined(WCHAR_T_IS_UTF16)
  L"\xd800\xdf00",
  // ?????  (Mathematical Alphanumeric Symbols (U+011d40 - U+011d44 : A,B,C,D,E)
  L"\xd807\xdd40\xd807\xdd41\xd807\xdd42\xd807\xdd43\xd807\xdd44",
#elif defined(WCHAR_T_IS_UTF32)
  L"\x10300",
  // ?????  (Mathematical Alphanumeric Symbols (U+011d40 - U+011d44 : A,B,C,D,E)
  L"\x11d40\x11d41\x11d42\x11d43\x11d44",
#endif
};


TEST(SysStrings, SysNativeMBAndWide) {
#if !defined(SYSTEM_NATIVE_UTF8)
  ScopedLocale locale("en_US.utf-8");
#endif
  for (size_t i = 0; i < arraysize(kConvertRoundtripCases); ++i) {
    std::wstring wide = kConvertRoundtripCases[i];
    std::wstring trip = SysNativeMBToWide(SysWideToNativeMB(wide));
    EXPECT_EQ(wide.size(), trip.size());
    EXPECT_EQ(wide, trip);
  }

  // We assume our test is running in UTF-8, so double check through ICU.
  for (size_t i = 0; i < arraysize(kConvertRoundtripCases); ++i) {
    std::wstring wide = kConvertRoundtripCases[i];
    std::wstring trip = SysNativeMBToWide(WideToUTF8(wide));
    EXPECT_EQ(wide.size(), trip.size());
    EXPECT_EQ(wide, trip);
  }

  for (size_t i = 0; i < arraysize(kConvertRoundtripCases); ++i) {
    std::wstring wide = kConvertRoundtripCases[i];
    std::wstring trip = UTF8ToWide(SysWideToNativeMB(wide));
    EXPECT_EQ(wide.size(), trip.size());
    EXPECT_EQ(wide, trip);
  }
}
#endif  // OS_LINUX

}  // namespace base
