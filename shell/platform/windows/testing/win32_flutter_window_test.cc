#include "flutter/shell/platform/windows/testing/win32_flutter_window_test.h"

namespace flutter {
namespace testing {

Win32FlutterWindowTest::Win32FlutterWindowTest(int width, int height)
    : Win32FlutterWindow(width, height){};

Win32FlutterWindowTest::~Win32FlutterWindowTest() = default;

void Win32FlutterWindowTest::OnFontChange() {
  on_font_change_called_ = true;
}

bool Win32FlutterWindowTest::OnFontChangeWasCalled() {
  return on_font_change_called_;
}
}  // namespace testing
}  // namespace flutter
