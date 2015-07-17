// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/case_conversion.h"
#include "base/i18n/rtl.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/icu/source/i18n/unicode/usearch.h"

namespace base {
namespace i18n {

namespace {

const wchar_t kNonASCIIMixed[] =
    L"\xC4\xD6\xE4\xF6\x20\xCF\xEF\x20\xF7\x25"
    L"\xA4\x23\x2A\x5E\x60\x40\xA3\x24\x2030\x201A\x7E\x20\x1F07\x1F0F"
    L"\x20\x1E00\x1E01";
const wchar_t kNonASCIILower[] =
    L"\xE4\xF6\xE4\xF6\x20\xEF\xEF"
    L"\x20\xF7\x25\xA4\x23\x2A\x5E\x60\x40\xA3\x24\x2030\x201A\x7E\x20\x1F07"
    L"\x1F07\x20\x1E01\x1E01";
const wchar_t kNonASCIIUpper[] =
    L"\xC4\xD6\xC4\xD6\x20\xCF\xCF"
    L"\x20\xF7\x25\xA4\x23\x2A\x5E\x60\x40\xA3\x24\x2030\x201A\x7E\x20\x1F0F"
    L"\x1F0F\x20\x1E00\x1E00";

}  // namespace

// Test upper and lower case string conversion.
TEST(CaseConversionTest, UpperLower) {
  const string16 mixed(ASCIIToUTF16("Text with UPPer & lowER casE."));
  const string16 expected_lower(ASCIIToUTF16("text with upper & lower case."));
  const string16 expected_upper(ASCIIToUTF16("TEXT WITH UPPER & LOWER CASE."));

  string16 result = ToLower(mixed);
  EXPECT_EQ(expected_lower, result);

  result = ToUpper(mixed);
  EXPECT_EQ(expected_upper, result);
}

TEST(CaseConversionTest, NonASCII) {
  const string16 mixed(WideToUTF16(kNonASCIIMixed));
  const string16 expected_lower(WideToUTF16(kNonASCIILower));
  const string16 expected_upper(WideToUTF16(kNonASCIIUpper));

  string16 result = ToLower(mixed);
  EXPECT_EQ(expected_lower, result);

  result = ToUpper(mixed);
  EXPECT_EQ(expected_upper, result);
}

TEST(CaseConversionTest, TurkishLocaleConversion) {
  const string16 mixed(WideToUTF16(L"\x49\x131"));
  const string16 expected_lower(WideToUTF16(L"\x69\x131"));
  const string16 expected_upper(WideToUTF16(L"\x49\x49"));

  std::string default_locale(uloc_getDefault());
  i18n::SetICUDefaultLocale("en_US");

  string16 result = ToLower(mixed);
  EXPECT_EQ(expected_lower, result);

  result = ToUpper(mixed);
  EXPECT_EQ(expected_upper, result);

  i18n::SetICUDefaultLocale("tr");

  const string16 expected_lower_turkish(WideToUTF16(L"\x131\x131"));
  const string16 expected_upper_turkish(WideToUTF16(L"\x49\x49"));

  result = ToLower(mixed);
  EXPECT_EQ(expected_lower_turkish, result);

  result = ToUpper(mixed);
  EXPECT_EQ(expected_upper_turkish, result);

  SetICUDefaultLocale(default_locale.data());
}

TEST(CaseConversionTest, FoldCase) {
  // Simple ASCII, should lower-case.
  EXPECT_EQ(ASCIIToUTF16("hello, world"),
            FoldCase(ASCIIToUTF16("Hello, World")));

  // Non-ASCII cases from above. They should all fold to the same result.
  EXPECT_EQ(FoldCase(WideToUTF16(kNonASCIIMixed)),
            FoldCase(WideToUTF16(kNonASCIILower)));
  EXPECT_EQ(FoldCase(WideToUTF16(kNonASCIIMixed)),
            FoldCase(WideToUTF16(kNonASCIIUpper)));

  // Turkish cases from above. This is the lower-case expected result from the
  // US locale. It should be the same even when the current locale is Turkish.
  const string16 turkish(WideToUTF16(L"\x49\x131"));
  const string16 turkish_expected(WideToUTF16(L"\x69\x131"));

  std::string default_locale(uloc_getDefault());
  i18n::SetICUDefaultLocale("en_US");
  EXPECT_EQ(turkish_expected, FoldCase(turkish));

  i18n::SetICUDefaultLocale("tr");
  EXPECT_EQ(turkish_expected, FoldCase(turkish));

  // Test a case that gets bigger when processed.
  // U+130 = LATIN CAPITAL LETTER I WITH DOT ABOVE gets folded to a lower case
  // "i" followed by U+307 COMBINING DOT ABOVE.
  EXPECT_EQ(WideToUTF16(L"i\u0307j"), FoldCase(WideToUTF16(L"\u0130j")));

  // U+00DF (SHARP S) and U+1E9E (CAPIRAL SHARP S) are both folded to "ss".
  EXPECT_EQ(ASCIIToUTF16("ssss"), FoldCase(WideToUTF16(L"\u00DF\u1E9E")));
}

}  // namespace i18n
}  // namespace base



