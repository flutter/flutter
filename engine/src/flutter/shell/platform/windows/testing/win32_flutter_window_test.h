// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WIN32_FLUTTER_WINDOW_TEST_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WIN32_FLUTTER_WINDOW_TEST_H_

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
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WIN32_FLUTTER_WINDOW_TEST_H_
