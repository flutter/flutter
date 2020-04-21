#include "flutter/shell/platform/windows/testing/win32_window_test.h"

namespace flutter {
namespace testing {

Win32WindowTest::Win32WindowTest() : Win32Window(){};

Win32WindowTest::~Win32WindowTest() = default;

void Win32WindowTest::OnDpiScale(unsigned int dpi){};

void Win32WindowTest::OnResize(unsigned int width, unsigned int height) {}

void Win32WindowTest::OnPointerMove(double x, double y) {}

void Win32WindowTest::OnPointerDown(double x, double y, UINT button) {}

void Win32WindowTest::OnPointerUp(double x, double y, UINT button) {}

void Win32WindowTest::OnPointerLeave() {}

void Win32WindowTest::OnText(const std::u16string& text) {}

void Win32WindowTest::OnKey(int key,
                            int scancode,
                            int action,
                            char32_t character) {}

void Win32WindowTest::OnScroll(double delta_x, double delta_y) {}

void Win32WindowTest::OnFontChange() {}

UINT Win32WindowTest::GetDpi() {
  return GetCurrentDPI();
}

}  // namespace testing
}  // namespace flutter
