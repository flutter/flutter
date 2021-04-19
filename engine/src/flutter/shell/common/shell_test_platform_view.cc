// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/shell_test_platform_view.h"

#ifdef SHELL_ENABLE_GL
#include "flutter/shell/common/shell_test_platform_view_gl.h"
#endif  // SHELL_ENABLE_GL
#ifdef SHELL_ENABLE_VULKAN
#include "flutter/shell/common/shell_test_platform_view_vulkan.h"
#endif  // SHELL_ENABLE_VULKAN
#ifdef SHELL_ENABLE_METAL
#include "flutter/shell/common/shell_test_platform_view_metal.h"
#endif  // SHELL_ENABLE_METAL

namespace flutter {
namespace testing {

std::unique_ptr<ShellTestPlatformView> ShellTestPlatformView::Create(
    PlatformView::Delegate& delegate,
    TaskRunners task_runners,
    std::shared_ptr<ShellTestVsyncClock> vsync_clock,
    CreateVsyncWaiter create_vsync_waiter,
    BackendType backend,
    std::shared_ptr<ShellTestExternalViewEmbedder>
        shell_test_external_view_embedder) {
  // TODO(gw280): https://github.com/flutter/flutter/issues/50298
  // Make this fully runtime configurable
  switch (backend) {
    case BackendType::kDefaultBackend:
#ifdef SHELL_ENABLE_GL
    case BackendType::kGLBackend:
      return std::make_unique<ShellTestPlatformViewGL>(
          delegate, task_runners, vsync_clock, create_vsync_waiter,
          shell_test_external_view_embedder);
#endif  // SHELL_ENABLE_GL
#ifdef SHELL_ENABLE_VULKAN
    case BackendType::kVulkanBackend:
      return std::make_unique<ShellTestPlatformViewVulkan>(
          delegate, task_runners, vsync_clock, create_vsync_waiter,
          shell_test_external_view_embedder);
#endif  // SHELL_ENABLE_VULKAN
#ifdef SHELL_ENABLE_METAL
    case BackendType::kMetalBackend:
      return std::make_unique<ShellTestPlatformViewMetal>(
          delegate, task_runners, vsync_clock, create_vsync_waiter,
          shell_test_external_view_embedder);
#endif  // SHELL_ENABLE_METAL

    default:
      FML_LOG(FATAL) << "No backends supported for ShellTestPlatformView";
      return nullptr;
  }
}

}  // namespace testing
}  // namespace flutter
