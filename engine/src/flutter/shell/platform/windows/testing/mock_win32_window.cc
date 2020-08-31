#include "flutter/shell/platform/windows/testing/mock_win32_window.h"

namespace flutter {
namespace testing {

MockWin32Window::MockWin32Window() : Win32Window(){};

MockWin32Window::~MockWin32Window() = default;

UINT MockWin32Window::GetDpi() {
  return GetCurrentDPI();
}

void MockWin32Window::InjectWindowMessage(UINT const message,
                                          WPARAM const wparam,
                                          LPARAM const lparam) {
  HandleMessage(message, wparam, lparam);
}

}  // namespace testing
}  // namespace flutter
