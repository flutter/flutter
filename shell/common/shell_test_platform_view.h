// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SHELL_TEST_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_COMMON_SHELL_TEST_PLATFORM_VIEW_H_

#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell_test_external_view_embedder.h"
#include "flutter/shell/common/vsync_waiters_test.h"

namespace flutter {
namespace testing {

class ShellTestPlatformView : public PlatformView {
 public:
  enum class BackendType {
    kGLBackend,
    kVulkanBackend,
    kDefaultBackend,
  };

  static std::unique_ptr<ShellTestPlatformView> Create(
      PlatformView::Delegate& delegate,
      TaskRunners task_runners,
      std::shared_ptr<ShellTestVsyncClock> vsync_clock,
      CreateVsyncWaiter create_vsync_waiter,
      BackendType backend,
      std::shared_ptr<ShellTestExternalViewEmbedder>
          shell_test_external_view_embedder);

  virtual void SimulateVSync() = 0;

 protected:
  ShellTestPlatformView(PlatformView::Delegate& delegate,
                        TaskRunners task_runners)
      : PlatformView(delegate, task_runners) {}

  FML_DISALLOW_COPY_AND_ASSIGN(ShellTestPlatformView);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SHELL_TEST_PLATFORM_VIEW_GL_H_
