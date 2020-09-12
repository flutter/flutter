// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cwchar>

#include "flutter/shell/platform/windows/system_utils.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(SystemUtils, GetPreferredLanguageInfo) {
  std::vector<LanguageInfo> languages = GetPreferredLanguageInfo();
  // There should be at least one language.
  ASSERT_GE(languages.size(), 1);
  // The info should have a valid languge.
  EXPECT_GE(languages[0].language.size(), 2);
}

TEST(SystemUtils, GetPreferredLanguages) {
  std::vector<std::wstring> languages = GetPreferredLanguages();
  // There should be at least one language.
  ASSERT_GE(languages.size(), 1);
  // The language should be non-empty.
  EXPECT_FALSE(languages[0].empty());
  // There should not be a trailing null from the parsing step.
  EXPECT_EQ(languages[0].size(), wcslen(languages[0].c_str()));
}

TEST(SystemUtils, ParseLanguageNameGeneric) {
  LanguageInfo info = ParseLanguageName(L"en");
  EXPECT_EQ(info.language, "en");
  EXPECT_TRUE(info.region.empty());
  EXPECT_TRUE(info.script.empty());
}

TEST(SystemUtils, ParseLanguageNameWithRegion) {
  LanguageInfo info = ParseLanguageName(L"hu-HU");
  EXPECT_EQ(info.language, "hu");
  EXPECT_EQ(info.region, "HU");
  EXPECT_TRUE(info.script.empty());
}

TEST(SystemUtils, ParseLanguageNameWithScript) {
  LanguageInfo info = ParseLanguageName(L"us-Latn");
  EXPECT_EQ(info.language, "us");
  EXPECT_TRUE(info.region.empty());
  EXPECT_EQ(info.script, "Latn");
}

TEST(SystemUtils, ParseLanguageNameWithRegionAndScript) {
  LanguageInfo info = ParseLanguageName(L"uz-Latn-UZ");
  EXPECT_EQ(info.language, "uz");
  EXPECT_EQ(info.region, "UZ");
  EXPECT_EQ(info.script, "Latn");
}

TEST(SystemUtils, ParseLanguageNameWithSuplementalLanguage) {
  LanguageInfo info = ParseLanguageName(L"en-US-x-fabricam");
  EXPECT_EQ(info.language, "en");
  EXPECT_EQ(info.region, "US");
  EXPECT_TRUE(info.script.empty());
}

// Ensure that ISO 639-2/T codes are handled.
TEST(SystemUtils, ParseLanguageNameWithThreeCharacterLanguage) {
  LanguageInfo info = ParseLanguageName(L"ale-ZZ");
  EXPECT_EQ(info.language, "ale");
  EXPECT_EQ(info.region, "ZZ");
  EXPECT_TRUE(info.script.empty());
}

}  // namespace testing
}  // namespace flutter
