// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windowsx.h>

#include "flutter/shell/platform/windows/win32_flutter_window.h"

namespace flutter {
namespace testing {

/// Test class for Win32FlutterWindow.
class Win32FlutterWindowTest : public Win32FlutterWindow {
 public:
  Win32FlutterWindowTest(int width, int height);
  virtual ~Win32FlutterWindowTest();

  // Prevent copying.
  Win32FlutterWindowTest(Win32FlutterWindowTest const&) = delete;
  Win32FlutterWindowTest& operator=(Win32FlutterWindowTest const&) = delete;

 private:
  bool on_font_change_called_ = false;
};

}  // namespace testing
}  // namespace flutter
