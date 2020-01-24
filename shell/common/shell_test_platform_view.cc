// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/shell_test_platform_view.h"
#include "flutter/shell/common/shell_test_platform_view_gl.h"

namespace flutter {
namespace testing {

std::unique_ptr<ShellTestPlatformView> ShellTestPlatformView::Create(
    PlatformView::Delegate& delegate,
    TaskRunners task_runners,
    std::shared_ptr<ShellTestVsyncClock> vsync_clock,
    CreateVsyncWaiter create_vsync_waiter) {
  return std::make_unique<ShellTestPlatformViewGL>(
      delegate, task_runners, vsync_clock, create_vsync_waiter);
}

}  // namespace testing
}  // namespace flutter
