// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/i18n/rtl.h"
#include "base/i18n/string_search.h"
#include "base/strings/string16.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/icu/source/i18n/unicode/usearch.h"

namespace base {
namespace i18n {

// Note on setting default locale for testing: The current default locale on
// the Mac trybot is en_US_POSIX, with which primary-level collation strength
// string search is case-sensitive, when normally it should be
// case-insensitive. In other locales (including en_US which English speakers
// in the U.S. use), this search would be case-insensitive as expected.

TEST(StringSearchTest, ASCII) {
  std::string default_locale(uloc_getDefault());
  bool locale_is_posix = (default_locale == "en_US_POSIX");
  if (locale_is_posix)
    SetICUDefaultLocale("en_US");

  size_t index = 0;
  size_t length = 0;

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      ASCIIToUTF16("hello"), ASCIIToUTF16("hello world"), &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(5U, length);

  EXPECT_FALSE(StringSearchIgnoringCaseAndAccents(
      ASCIIToUTF16("h    e l l o"), ASCIIToUTF16("h   e l l o"),
      &index, &length));

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      ASCIIToUTF16("aabaaa"), ASCIIToUTF16("aaabaabaaa"), &index, &length));
  EXPECT_EQ(4U, index);
  EXPECT_EQ(6U, length);

  EXPECT_FALSE(StringSearchIgnoringCaseAndAccents(
      ASCIIToUTF16("searching within empty string"), string16(),
      &index, &length));

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      string16(), ASCIIToUTF16("searching for empty string"), &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(0U, length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      ASCIIToUTF16("case insensitivity"), ASCIIToUTF16("CaSe InSeNsItIvItY"),
      &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(18U, length);

  if (locale_is_posix)
    SetICUDefaultLocale(default_locale.data());
}

TEST(StringSearchTest, UnicodeLocaleIndependent) {
  // Base characters
  const string16 e_base = WideToUTF16(L"e");
  const string16 E_base = WideToUTF16(L"E");
  const string16 a_base = WideToUTF16(L"a");

  // Composed characters
  const string16 e_with_acute_accent = WideToUTF16(L"\u00e9");
  const string16 E_with_acute_accent = WideToUTF16(L"\u00c9");
  const string16 e_with_grave_accent = WideToUTF16(L"\u00e8");
  const string16 E_with_grave_accent = WideToUTF16(L"\u00c8");
  const string16 a_with_acute_accent = WideToUTF16(L"\u00e1");

  // Decomposed characters
  const string16 e_with_acute_combining_mark = WideToUTF16(L"e\u0301");
  const string16 E_with_acute_combining_mark = WideToUTF16(L"E\u0301");
  const string16 e_with_grave_combining_mark = WideToUTF16(L"e\u0300");
  const string16 E_with_grave_combining_mark = WideToUTF16(L"E\u0300");
  const string16 a_with_acute_combining_mark = WideToUTF16(L"a\u0301");

  std::string default_locale(uloc_getDefault());
  bool locale_is_posix = (default_locale == "en_US_POSIX");
  if (locale_is_posix)
    SetICUDefaultLocale("en_US");

  size_t index = 0;
  size_t length = 0;

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_base, e_with_acute_accent, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_accent.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_acute_accent, e_base, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_base.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_base, e_with_acute_combining_mark, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_combining_mark.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_acute_combining_mark, e_base, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_base.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_acute_combining_mark, e_with_acute_accent,
      &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_accent.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_acute_accent, e_with_acute_combining_mark,
      &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_combining_mark.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_acute_combining_mark, e_with_grave_combining_mark,
      &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_grave_combining_mark.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_grave_combining_mark, e_with_acute_combining_mark,
      &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_combining_mark.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_acute_combining_mark, e_with_grave_accent, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_grave_accent.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      e_with_grave_accent, e_with_acute_combining_mark, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_combining_mark.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      E_with_acute_accent, e_with_acute_accent, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_accent.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      E_with_grave_accent, e_with_acute_accent, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_accent.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      E_with_acute_combining_mark, e_with_grave_accent, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_grave_accent.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      E_with_grave_combining_mark, e_with_acute_accent, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_acute_accent.size(), length);

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      E_base, e_with_grave_accent, &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(e_with_grave_accent.size(), length);

  EXPECT_FALSE(StringSearchIgnoringCaseAndAccents(
      a_with_acute_accent, e_with_acute_accent, &index, &length));

  EXPECT_FALSE(StringSearchIgnoringCaseAndAccents(
      a_with_acute_combining_mark, e_with_acute_combining_mark,
      &index, &length));

  if (locale_is_posix)
    SetICUDefaultLocale(default_locale.data());
}

TEST(StringSearchTest, UnicodeLocaleDependent) {
  // Base characters
  const string16 a_base = WideToUTF16(L"a");

  // Composed characters
  const string16 a_with_ring = WideToUTF16(L"\u00e5");

  EXPECT_TRUE(StringSearchIgnoringCaseAndAccents(
      a_base, a_with_ring, NULL, NULL));

  const char* default_locale = uloc_getDefault();
  SetICUDefaultLocale("da");

  EXPECT_FALSE(StringSearchIgnoringCaseAndAccents(
      a_base, a_with_ring, NULL, NULL));

  SetICUDefaultLocale(default_locale);
}

TEST(StringSearchTest, FixedPatternMultipleSearch) {
  std::string default_locale(uloc_getDefault());
  bool locale_is_posix = (default_locale == "en_US_POSIX");
  if (locale_is_posix)
    SetICUDefaultLocale("en_US");

  size_t index = 0;
  size_t length = 0;

  // Search "hello" over multiple texts.
  FixedPatternStringSearchIgnoringCaseAndAccents query(ASCIIToUTF16("hello"));
  EXPECT_TRUE(query.Search(ASCIIToUTF16("12hello34"), &index, &length));
  EXPECT_EQ(2U, index);
  EXPECT_EQ(5U, length);
  EXPECT_FALSE(query.Search(ASCIIToUTF16("bye"), &index, &length));
  EXPECT_TRUE(query.Search(ASCIIToUTF16("hELLo"), &index, &length));
  EXPECT_EQ(0U, index);
  EXPECT_EQ(5U, length);

  if (locale_is_posix)
    SetICUDefaultLocale(default_locale.data());
}

}  // namespace i18n
}  // namespace base
