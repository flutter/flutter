// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/win32_window_test.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(Win32WindowTest, CreateDestroy) {
  Win32WindowTest window;
  ASSERT_TRUE(TRUE);
}

TEST(Win32WindowTest, GetDpiAfterCreate) {
  Win32WindowTest window;
  ASSERT_TRUE(window.GetDpi() > 0);
}

}  // namespace testing
}  // namespace flutter
