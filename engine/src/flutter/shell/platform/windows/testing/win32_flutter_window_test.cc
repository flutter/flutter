// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/win32_flutter_window_test.h"

namespace flutter {
namespace testing {

Win32FlutterWindowTest::Win32FlutterWindowTest(int width, int height)
    : Win32FlutterWindow(width, height){};

Win32FlutterWindowTest::~Win32FlutterWindowTest() = default;

}  // namespace testing
}  // namespace flutter
