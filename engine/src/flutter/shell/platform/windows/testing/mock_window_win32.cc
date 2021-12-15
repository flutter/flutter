// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/mock_window_win32.h"

namespace flutter {
namespace testing {
MockWin32Window::MockWin32Window() : WindowWin32(){};
MockWin32Window::MockWin32Window(
    std::unique_ptr<TextInputManagerWin32> text_input_manager)
    : WindowWin32(std::move(text_input_manager)){};

MockWin32Window::~MockWin32Window() = default;

UINT MockWin32Window::GetDpi() {
  return GetCurrentDPI();
}

LRESULT MockWin32Window::Win32DefWindowProc(HWND hWnd,
                                            UINT Msg,
                                            WPARAM wParam,
                                            LPARAM lParam) {
  return kWmResultDefault;
}

LRESULT MockWin32Window::InjectWindowMessage(UINT const message,
                                             WPARAM const wparam,
                                             LPARAM const lparam) {
  return HandleMessage(message, wparam, lparam);
}

void MockWin32Window::InjectMessageList(int count,
                                        const Win32Message* messages) {
  for (int message_id = 0; message_id < count; message_id += 1) {
    const Win32Message& message = messages[message_id];
    LRESULT result =
        InjectWindowMessage(message.message, message.wParam, message.lParam);
    if (message.expected_result != kWmResultDontCheck) {
      EXPECT_EQ(result, message.expected_result);
    }
  }
}

void MockWin32Window::CallOnImeComposition(UINT const message,
                                           WPARAM const wparam,
                                           LPARAM const lparam) {
  WindowWin32::OnImeComposition(message, wparam, lparam);
}

}  // namespace testing
}  // namespace flutter
