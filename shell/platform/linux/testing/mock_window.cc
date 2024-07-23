// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_window.h"

using namespace flutter::testing;

static MockWindow* mock = nullptr;

MockWindow::MockWindow() {
  mock = this;
}

GdkWindowState gdk_window_get_state(GdkWindow* window) {
  return mock->gdk_window_get_state(window);
}
