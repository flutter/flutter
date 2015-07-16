// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/case_conversion.h"
#include "base/i18n/rtl.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/icu/source/i18n/unicode/usearch.h"

namespace base {
namespace {

// Test upper and lower case string conversion.
TEST(CaseConversionTest, UpperLower) {
  const string16 mixed(ASCIIToUTF16("Text with UPPer & lowER casE."));
  const string16 expected_lower(ASCIIToUTF16("text with upper & lower case."));
  const string16 expected_upper(ASCIIToUTF16("TEXT WITH UPPER & LOWER CASE."));

  string16 result = base::i18n::ToLower(mixed);
  EXPECT_EQ(expected_lower, result);

  result = base::i18n::ToUpper(mixed);
  EXPECT_EQ(expected_upper, result);
}

TEST(CaseConversionTest, NonASCII) {
  const string16 mixed(WideToUTF16(
      L"\xC4\xD6\xE4\xF6\x20\xCF\xEF\x20\xF7\x25"
      L"\xA4\x23\x2A\x5E\x60\x40\xA3\x24\x2030\x201A\x7E\x20\x1F07\x1F0F"
      L"\x20\x1E00\x1E01"));
  const string16 expected_lower(WideToUTF16(
      L"\xE4\xF6\xE4\xF6\x20\xEF\xEF"
      L"\x20\xF7\x25\xA4\x23\x2A\x5E\x60\x40\xA3\x24\x2030\x201A\x7E\x20\x1F07"
      L"\x1F07\x20\x1E01\x1E01"));
  const string16 expected_upper(WideToUTF16(
      L"\xC4\xD6\xC4\xD6\x20\xCF\xCF"
      L"\x20\xF7\x25\xA4\x23\x2A\x5E\x60\x40\xA3\x24\x2030\x201A\x7E\x20\x1F0F"
      L"\x1F0F\x20\x1E00\x1E00"));

  string16 result = base::i18n::ToLower(mixed);
  EXPECT_EQ(expected_lower, result);

  result = base::i18n::ToUpper(mixed);
  EXPECT_EQ(expected_upper, result);
}

TEST(CaseConversionTest, TurkishLocaleConversion) {
  const string16 mixed(WideToUTF16(L"\x49\x131"));
  const string16 expected_lower(WideToUTF16(L"\x69\x131"));
  const string16 expected_upper(WideToUTF16(L"\x49\x49"));

  std::string default_locale(uloc_getDefault());
  i18n::SetICUDefaultLocale("en_US");

  string16 result = base::i18n::ToLower(mixed);
  EXPECT_EQ(expected_lower, result);

  result = base::i18n::ToUpper(mixed);
  EXPECT_EQ(expected_upper, result);

  i18n::SetICUDefaultLocale("tr");

  const string16 expected_lower_turkish(WideToUTF16(L"\x131\x131"));
  const string16 expected_upper_turkish(WideToUTF16(L"\x49\x49"));

  result = base::i18n::ToLower(mixed);
  EXPECT_EQ(expected_lower_turkish, result);

  result = base::i18n::ToUpper(mixed);
  EXPECT_EQ(expected_upper_turkish, result);

  base::i18n::SetICUDefaultLocale(default_locale.data());
}

}  // namespace
}  // namespace base



