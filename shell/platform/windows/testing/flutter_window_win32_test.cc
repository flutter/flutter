// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/flutter_window_win32_test.h"

namespace flutter {
namespace testing {

FlutterWindowWin32Test::FlutterWindowWin32Test(int width, int height)
    : FlutterWindowWin32(width, height){};

FlutterWindowWin32Test::~FlutterWindowWin32Test() = default;

}  // namespace testing
}  // namespace flutter
