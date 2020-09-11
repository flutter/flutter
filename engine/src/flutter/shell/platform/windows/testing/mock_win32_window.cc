// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
