// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WIN32_FLUTTER_WINDOW_TEST_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WIN32_FLUTTER_WINDOW_TEST_H_

#include "flutter/shell/platform/windows/flutter_window_win32.h"

namespace flutter {
namespace testing {

/// Test class for FlutterWindowWin32.
class FlutterWindowWin32Test : public FlutterWindowWin32 {
 public:
  FlutterWindowWin32Test(int width, int height);
  virtual ~FlutterWindowWin32Test();

  // Prevent copying.
  FlutterWindowWin32Test(FlutterWindowWin32Test const&) = delete;
  FlutterWindowWin32Test& operator=(FlutterWindowWin32Test const&) = delete;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WIN32_FLUTTER_WINDOW_TEST_H_
