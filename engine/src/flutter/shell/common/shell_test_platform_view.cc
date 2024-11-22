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

#include "flutter/shell/common/vsync_waiter_fallback.h"

namespace flutter {
namespace testing {

std::unique_ptr<ShellTestPlatformView> ShellTestPlatformView::Create(
    BackendType backend,
    PlatformView::Delegate& delegate,
    const TaskRunners& task_runners,
    const std::shared_ptr<ShellTestVsyncClock>& vsync_clock,
    const CreateVsyncWaiter& create_vsync_waiter,
    const std::shared_ptr<ShellTestExternalViewEmbedder>&
        shell_test_external_view_embedder,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch) {
  // TODO(gw280): https://github.com/flutter/flutter/issues/50298
  // Make this fully runtime configurable
  switch (backend) {
    case BackendType::kGLBackend:
#ifdef SHELL_ENABLE_GL
      return std::make_unique<ShellTestPlatformViewGL>(
          delegate, task_runners, vsync_clock, create_vsync_waiter,
          shell_test_external_view_embedder);
#else
      FML_LOG(FATAL) << "OpenGL not enabled in this build";
      return nullptr;
#endif  // SHELL_ENABLE_GL
    case BackendType::kVulkanBackend:
#ifdef SHELL_ENABLE_VULKAN
      return std::make_unique<ShellTestPlatformViewVulkan>(
          delegate, task_runners, vsync_clock, create_vsync_waiter,
          shell_test_external_view_embedder);
#else
      FML_LOG(FATAL) << "Vulkan not enabled in this build";
      return nullptr;
#endif  // SHELL_ENABLE_VULKAN
    case BackendType::kMetalBackend:
#ifdef SHELL_ENABLE_METAL
      return std::make_unique<ShellTestPlatformViewMetal>(
          delegate, task_runners, vsync_clock, create_vsync_waiter,
          shell_test_external_view_embedder, is_gpu_disabled_sync_switch);
#else
      FML_LOG(FATAL) << "Metal not enabled in this build";
      return nullptr;
#endif  // SHELL_ENABLE_METAL
  }
}

ShellTestPlatformViewBuilder::ShellTestPlatformViewBuilder(Config config)
    : config_(std::move(config)) {}

std::unique_ptr<PlatformView> ShellTestPlatformViewBuilder::operator()(
    Shell& shell) {
  const TaskRunners& task_runners = shell.GetTaskRunners();
  const auto vsync_clock = std::make_shared<ShellTestVsyncClock>();
  CreateVsyncWaiter create_vsync_waiter = [&task_runners, vsync_clock,
                                           simulate_vsync =
                                               config_.simulate_vsync]() {
    if (simulate_vsync) {
      return static_cast<std::unique_ptr<VsyncWaiter>>(
          std::make_unique<ShellTestVsyncWaiter>(task_runners, vsync_clock));
    } else {
      return static_cast<std::unique_ptr<VsyncWaiter>>(
          std::make_unique<VsyncWaiterFallback>(task_runners, true));
    }
  };
  return ShellTestPlatformView::Create(
      config_.rendering_backend,                  //
      shell,                                      //
      task_runners,                               //
      vsync_clock,                                //
      create_vsync_waiter,                        //
      config_.shell_test_external_view_embedder,  //
      shell.GetIsGpuDisabledSyncSwitch()          //
  );
}

}  // namespace testing
}  // namespace flutter
