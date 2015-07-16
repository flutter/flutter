// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains unit tests for Windows internationalization funcs.

#include "testing/gtest/include/gtest/gtest.h"

#include "base/win/i18n.h"
#include "base/win/windows_version.h"

namespace base {
namespace win {
namespace i18n {

// Tests that at least one user preferred UI language can be obtained.
TEST(I18NTest, GetUserPreferredUILanguageList) {
  std::vector<std::wstring> languages;
  EXPECT_TRUE(GetUserPreferredUILanguageList(&languages));
  EXPECT_NE(static_cast<std::vector<std::wstring>::size_type>(0),
            languages.size());
  for (std::vector<std::wstring>::const_iterator scan = languages.begin(),
          end = languages.end(); scan != end; ++scan) {
    EXPECT_FALSE((*scan).empty());
  }
}

// Tests that at least one thread preferred UI language can be obtained.
TEST(I18NTest, GetThreadPreferredUILanguageList) {
  std::vector<std::wstring> languages;
  EXPECT_TRUE(GetThreadPreferredUILanguageList(&languages));
  EXPECT_NE(static_cast<std::vector<std::wstring>::size_type>(0),
            languages.size());
  for (std::vector<std::wstring>::const_iterator scan = languages.begin(),
          end = languages.end(); scan != end; ++scan) {
    EXPECT_FALSE((*scan).empty());
  }
}

}  // namespace i18n
}  // namespace win
}  // namespace base
