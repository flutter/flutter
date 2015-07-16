// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windows.h>

#include "base/basictypes.h"
#include "base/strings/string_util.h"
#include "base/win/win_util.h"
#include "base/win/windows_version.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace win {

namespace {

// Saves the current thread's locale ID when initialized, and restores it when
// the instance is going out of scope.
class ThreadLocaleSaver {
 public:
  ThreadLocaleSaver() : original_locale_id_(GetThreadLocale()) {}
  ~ThreadLocaleSaver() { SetThreadLocale(original_locale_id_); }

 private:
  LCID original_locale_id_;

  DISALLOW_COPY_AND_ASSIGN(ThreadLocaleSaver);
};

}  // namespace

// The test is somewhat silly, because the Vista bots some have UAC enabled
// and some have it disabled. At least we check that it does not crash.
TEST(BaseWinUtilTest, TestIsUACEnabled) {
  if (GetVersion() >= base::win::VERSION_VISTA) {
    UserAccountControlIsEnabled();
  } else {
    EXPECT_TRUE(UserAccountControlIsEnabled());
  }
}

TEST(BaseWinUtilTest, TestGetUserSidString) {
  std::wstring user_sid;
  EXPECT_TRUE(GetUserSidString(&user_sid));
  EXPECT_TRUE(!user_sid.empty());
}

TEST(BaseWinUtilTest, TestGetNonClientMetrics) {
  NONCLIENTMETRICS_XP metrics = {0};
  GetNonClientMetrics(&metrics);
  EXPECT_GT(metrics.cbSize, 0u);
  EXPECT_GT(metrics.iScrollWidth, 0);
  EXPECT_GT(metrics.iScrollHeight, 0);
}

}  // namespace win
}  // namespace base
