#include "flutter/shell/platform/windows/testing/win32_flutter_window_test.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(Win32FlutterWindowTest, CreateDestroy) {
  Win32FlutterWindowTest window(800, 600);
  ASSERT_TRUE(TRUE);
}

TEST(Win32FlutterWindowTest, CanFontChange) {
  Win32FlutterWindowTest window(800, 600);
  HWND hwnd = window.GetWindowHandle();
  LRESULT result = SendMessage(hwnd, WM_FONTCHANGE, NULL, NULL);
  ASSERT_EQ(result, 0);
  ASSERT_TRUE(window.OnFontChangeWasCalled());
}

}  // namespace testing
}  // namespace flutter
