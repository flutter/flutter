// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windowsx.h>

#include "flutter/shell/platform/windows/win32_window.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

/// Mock for the Win32Window base class.
class MockWin32Window : public Win32Window {
 public:
  MockWin32Window();
  virtual ~MockWin32Window();

  // Prevent copying.
  MockWin32Window(MockWin32Window const&) = delete;
  MockWin32Window& operator=(MockWin32Window const&) = delete;

  // Wrapper for GetCurrentDPI() which is a protected method.
  UINT GetDpi();

  // Simulates a WindowProc message from the OS.
  void InjectWindowMessage(UINT const message,
                           WPARAM const wparam,
                           LPARAM const lparam);

  MOCK_METHOD1(OnDpiScale, void(unsigned int));
  MOCK_METHOD2(OnResize, void(unsigned int, unsigned int));
  MOCK_METHOD2(OnPointerMove, void(double, double));
  MOCK_METHOD3(OnPointerDown, void(double, double, UINT));
  MOCK_METHOD3(OnPointerUp, void(double, double, UINT));
  MOCK_METHOD0(OnPointerLeave, void());
  MOCK_METHOD0(OnSetCursor, void());
  MOCK_METHOD1(OnText, void(const std::u16string&));
  MOCK_METHOD4(OnKey, void(int, int, int, char32_t));
  MOCK_METHOD2(OnScroll, void(double, double));
};

}  // namespace testing
}  // namespace flutter
