// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/mock_win32_window.h"
#include "gtest/gtest.h"

using testing::_;

namespace flutter {
namespace testing {
namespace {

// Creates a valid Windows LPARAM for WM_KEYDOWN and WM_KEYUP from parameters
// given.
static LPARAM CreateKeyEventLparam(USHORT ScanCode,
                                   bool extended = false,
                                   USHORT RepeatCount = 1,
                                   bool ContextCode = 0,
                                   bool PreviousKeyState = 1,
                                   bool TransitionState = 1) {
  return ((LPARAM(TransitionState) << 31) | (LPARAM(PreviousKeyState) << 30) |
          (LPARAM(ContextCode) << 29) | (LPARAM(extended ? 0x1 : 0x0) << 24) |
          (LPARAM(ScanCode) << 16) | LPARAM(RepeatCount));
}

}  // namespace

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

TEST(MockWin32Window, KeyDown) {
  MockWin32Window window;
  EXPECT_CALL(window, OnKey(_, _, _, _, _)).Times(1);
  LPARAM lparam = CreateKeyEventLparam(42);
  // send a "Shift" key down event.
  window.InjectWindowMessage(WM_KEYDOWN, 16, lparam);
}

TEST(MockWin32Window, KeyUp) {
  MockWin32Window window;
  EXPECT_CALL(window, OnKey(_, _, _, _, _)).Times(1);
  LPARAM lparam = CreateKeyEventLparam(42);
  // send a "Shift" key up event.
  window.InjectWindowMessage(WM_KEYUP, 16, lparam);
}

TEST(MockWin32Window, KeyDownPrintable) {
  MockWin32Window window;
  LPARAM lparam = CreateKeyEventLparam(30);
  // OnKey shouldn't be called until the WM_CHAR message.
  EXPECT_CALL(window, OnKey(65, 30, WM_KEYDOWN, 65, false)).Times(0);
  // send a "A" key down event.
  window.InjectWindowMessage(WM_KEYDOWN, 65, lparam);

  EXPECT_CALL(window, OnKey(65, 30, WM_KEYDOWN, 65, false)).Times(1);
  EXPECT_CALL(window, OnText(_)).Times(1);
  window.InjectWindowMessage(WM_CHAR, 65, lparam);
}

}  // namespace testing
}  // namespace flutter
