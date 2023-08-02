// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WIN32_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WIN32_WINDOW_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/testing/test_keyboard.h"
#include "flutter/shell/platform/windows/window.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

/// Mock for the |Window| base class.
class MockWindow : public Window {
 public:
  MockWindow();
  MockWindow(std::unique_ptr<WindowsProcTable> windows_proc_table,
             std::unique_ptr<TextInputManager> text_input_manager);
  virtual ~MockWindow();

  // Wrapper for GetCurrentDPI() which is a protected method.
  UINT GetDpi();

  // Set the Direct Manipulation owner for testing purposes.
  void SetDirectManipulationOwner(
      std::unique_ptr<DirectManipulationOwner> owner);

  // Simulates a WindowProc message from the OS.
  LRESULT InjectWindowMessage(UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam);

  void InjectMessageList(int count, const Win32Message* messages);

  MOCK_METHOD1(OnDpiScale, void(unsigned int));
  MOCK_METHOD2(OnResize, void(unsigned int, unsigned int));
  MOCK_METHOD0(OnPaint, void());
  MOCK_METHOD5(OnPointerMove,
               void(double, double, FlutterPointerDeviceKind, int32_t, int));
  MOCK_METHOD5(OnPointerDown,
               void(double, double, FlutterPointerDeviceKind, int32_t, UINT));
  MOCK_METHOD5(OnPointerUp,
               void(double, double, FlutterPointerDeviceKind, int32_t, UINT));
  MOCK_METHOD4(OnPointerLeave,
               void(double, double, FlutterPointerDeviceKind, int32_t));
  MOCK_METHOD0(OnSetCursor, void());
  MOCK_METHOD1(OnText, void(const std::u16string&));
  MOCK_METHOD7(OnKey,
               void(int, int, int, char32_t, bool, bool, KeyEventCallback));
  MOCK_METHOD1(OnUpdateSemanticsEnabled, void(bool));
  MOCK_METHOD0(GetNativeViewAccessible, gfx::NativeViewAccessible());
  MOCK_METHOD4(OnScroll,
               void(double, double, FlutterPointerDeviceKind, int32_t));
  MOCK_METHOD0(OnComposeBegin, void());
  MOCK_METHOD0(OnComposeCommit, void());
  MOCK_METHOD0(OnComposeEnd, void());
  MOCK_METHOD2(OnComposeChange, void(const std::u16string&, int));
  MOCK_METHOD3(OnImeComposition, void(UINT const, WPARAM const, LPARAM const));

  MOCK_METHOD0(OnThemeChange, void());

  MOCK_METHOD0(GetAxFragmentRootDelegate, ui::AXFragmentRootDelegateWin*());

  MOCK_METHOD3(OnGetObject, LRESULT(UINT, WPARAM, LPARAM));

  void CallOnImeComposition(UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam);

 protected:
  LRESULT Win32DefWindowProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockWindow);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_WIN32_WINDOW_H_
