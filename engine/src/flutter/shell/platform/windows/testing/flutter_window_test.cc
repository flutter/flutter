// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/flutter_window_test.h"

namespace flutter {
namespace testing {

FlutterWindowTest::FlutterWindowTest(int width, int height)
    : FlutterWindow(width, height){};

FlutterWindowTest::~FlutterWindowTest() = default;

}  // namespace testing
}  // namespace flutter
