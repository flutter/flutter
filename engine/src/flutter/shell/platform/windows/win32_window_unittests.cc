// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/mock_win32_window.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(MockWin32Window, CreateDestroy) {
  MockWin32Window window;
  ASSERT_TRUE(TRUE);
}

TEST(MockWin32Window, GetDpiAfterCreate) {
  MockWin32Window window;
  ASSERT_TRUE(window.GetDpi() > 0);
}

TEST(MockWin32Window, VerticalScroll) {
  MockWin32Window window;
  const int scroll_amount = 10;
  // Vertical scroll should be passed along, adjusted for scroll tick size
  // and direction.
  EXPECT_CALL(window, OnScroll(0, -scroll_amount / 120.0)).Times(1);

  window.InjectWindowMessage(WM_MOUSEWHEEL, MAKEWPARAM(0, scroll_amount), 0);
}

TEST(MockWin32Window, HorizontalScroll) {
  MockWin32Window window;
  const int scroll_amount = 10;
  // Vertical scroll should be passed along, adjusted for scroll tick size.
  EXPECT_CALL(window, OnScroll(scroll_amount / 120.0, 0)).Times(1);

  window.InjectWindowMessage(WM_MOUSEHWHEEL, MAKEWPARAM(0, scroll_amount), 0);
}

}  // namespace testing
}  // namespace flutter
