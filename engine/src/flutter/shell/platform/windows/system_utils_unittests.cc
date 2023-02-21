// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstring>
#include <cwchar>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/system_utils.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class MockWindowsRegistry : public WindowsRegistry {
 public:
  MockWindowsRegistry() = default;
  virtual ~MockWindowsRegistry() = default;

  virtual LSTATUS GetRegistryValue(HKEY hkey,
                                   LPCWSTR key,
                                   LPCWSTR value,
                                   DWORD flags,
                                   LPDWORD type,
                                   PVOID data,
                                   LPDWORD data_size) const {
    using namespace std::string_literals;
    static const std::wstring locales =
        L"en-US\0zh-Hans-CN\0ja\0zh-Hant-TW\0he\0\0"s;
    static DWORD locales_len = locales.size() * sizeof(wchar_t);
    if (data != nullptr) {
      if (*data_size < locales_len) {
        return ERROR_MORE_DATA;
      }
      std::memcpy(data, locales.data(), locales_len);
      *data_size = locales_len;
    } else if (data_size != NULL) {
      *data_size = locales_len;
    }
    return ERROR_SUCCESS;
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockWindowsRegistry);
};

TEST(SystemUtils, GetPreferredLanguageInfo) {
  WindowsRegistry registry;
  std::vector<LanguageInfo> languages = GetPreferredLanguageInfo(registry);
  // There should be at least one language.
  ASSERT_GE(languages.size(), 1);
  // The info should have a valid languge.
  EXPECT_GE(languages[0].language.size(), 2);
}

TEST(SystemUtils, GetPreferredLanguages) {
  WindowsRegistry registry;
  std::vector<std::wstring> languages = GetPreferredLanguages(registry);
  // There should be at least one language.
  ASSERT_GE(languages.size(), 1);
  // The language should be non-empty.
  EXPECT_FALSE(languages[0].empty());
  // There should not be a trailing null from the parsing step.
  EXPECT_EQ(languages[0].size(), wcslen(languages[0].c_str()));

  // Test mock results
  MockWindowsRegistry mock_registry;
  languages = GetPreferredLanguages(mock_registry);
  ASSERT_EQ(languages.size(), 5);
  ASSERT_EQ(languages[0], std::wstring(L"en-US"));
  ASSERT_EQ(languages[1], std::wstring(L"zh-Hans-CN"));
  ASSERT_EQ(languages[2], std::wstring(L"ja"));
  ASSERT_EQ(languages[3], std::wstring(L"zh-Hant-TW"));
  ASSERT_EQ(languages[4], std::wstring(L"he"));
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

TEST(SystemUtils, GetUserTimeFormat) {
  // The value varies based on machine; just ensure that something is returned.
  EXPECT_FALSE(GetUserTimeFormat().empty());
}

TEST(SystemUtils, Prefer24HourTimeHandlesEmptyFormat) {
  EXPECT_FALSE(Prefer24HourTime(L""));
}

TEST(SystemUtils, Prefer24HourTimeHandles12Hour) {
  EXPECT_FALSE(Prefer24HourTime(L"h:mm:ss tt"));
}

TEST(SystemUtils, Prefer24HourTimeHandles24Hour) {
  EXPECT_TRUE(Prefer24HourTime(L"HH:mm:ss"));
}

}  // namespace testing
}  // namespace flutter
