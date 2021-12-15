// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WIN32_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WIN32_WINDOW_H_

#include <windowsx.h>

#include "flutter/shell/platform/windows/testing/test_keyboard.h"
#include "flutter/shell/platform/windows/window_win32.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

/// Mock for the |WindowWin32| base class.
class MockWin32Window : public WindowWin32 {
 public:
  MockWin32Window();
  MockWin32Window(std::unique_ptr<TextInputManagerWin32> text_input_manager);
  virtual ~MockWin32Window();

  // Prevent copying.
  MockWin32Window(MockWin32Window const&) = delete;
  MockWin32Window& operator=(MockWin32Window const&) = delete;

  // Wrapper for GetCurrentDPI() which is a protected method.
  UINT GetDpi();

  // Simulates a WindowProc message from the OS.
  LRESULT InjectWindowMessage(UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam);

  void InjectMessageList(int count, const Win32Message* messages);

  MOCK_METHOD1(OnDpiScale, void(unsigned int));
  MOCK_METHOD2(OnResize, void(unsigned int, unsigned int));
  MOCK_METHOD4(OnPointerMove,
               void(double, double, FlutterPointerDeviceKind, int32_t));
  MOCK_METHOD5(OnPointerDown,
               void(double, double, FlutterPointerDeviceKind, int32_t, UINT));
  MOCK_METHOD5(OnPointerUp,
               void(double, double, FlutterPointerDeviceKind, int32_t, UINT));
  MOCK_METHOD2(OnPointerLeave, void(FlutterPointerDeviceKind, int32_t));
  MOCK_METHOD0(OnSetCursor, void());
  MOCK_METHOD1(OnText, void(const std::u16string&));
  MOCK_METHOD6(OnKey, bool(int, int, int, char32_t, bool, bool));
  MOCK_METHOD1(OnUpdateSemanticsEnabled, void(bool));
  MOCK_METHOD0(GetNativeViewAccessible, gfx::NativeViewAccessible());
  MOCK_METHOD4(OnScroll,
               void(double, double, FlutterPointerDeviceKind, int32_t));
  MOCK_METHOD0(OnComposeBegin, void());
  MOCK_METHOD0(OnComposeCommit, void());
  MOCK_METHOD0(OnComposeEnd, void());
  MOCK_METHOD2(OnComposeChange, void(const std::u16string&, int));
  MOCK_METHOD3(OnImeComposition, void(UINT const, WPARAM const, LPARAM const));

  void CallOnImeComposition(UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam);

 protected:
  LRESULT Win32DefWindowProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WIN32_WINDOW_H_
