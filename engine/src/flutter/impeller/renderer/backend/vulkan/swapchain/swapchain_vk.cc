// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain/swapchain_vk.h"

#include "flutter/fml/trace_event.h"
#include "impeller/core/gpu_submission_tracker.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain/khr/khr_swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

#if FML_OS_ANDROID
#include "impeller/renderer/backend/vulkan/swapchain/ahb/ahb_swapchain_vk.h"
#endif  // FML_OS_ANDROID

namespace impeller {

std::shared_ptr<SwapchainVK> SwapchainVK::Create(
    const std::shared_ptr<Context>& context,
    vk::UniqueSurfaceKHR surface,
    const ISize& size,
    bool enable_msaa) {
  auto swapchain = std::shared_ptr<KHRSwapchainVK>(
      new KHRSwapchainVK(context, std::move(surface), size, enable_msaa));
  if (!swapchain->IsValid()) {
    VALIDATION_LOG << "Could not create valid swapchain.";
    return nullptr;
  }
  return swapchain;
}

#if FML_OS_ANDROID
std::shared_ptr<SwapchainVK> SwapchainVK::Create(
    const std::shared_ptr<Context>& context,
    ANativeWindow* p_window,
    const CreateTransactionCB& cb,
    bool enable_msaa) {
  TRACE_EVENT0("impeller", "CreateAndroidSwapchain");
  if (!context) {
    return nullptr;
  }

  android::NativeWindow window(p_window);
  if (!window.IsValid()) {
    return nullptr;
  }

  // Use AHB Swapchains if they are opted in.
  if (ContextVK::Cast(*context).GetShouldEnableSurfaceControlSwapchain() &&
      AHBSwapchainVK::IsAvailableOnPlatform()) {
    CreateTransactionCB callback =
        android_get_device_api_level() >= 34 ? cb : CreateTransactionCB({});
    auto surface_control = std::shared_ptr(
        android::SurfaceControl::Create(window.GetHandle(), "ImpellerSurface"));
    auto ahb_swapchain =
        std::shared_ptr<AHBSwapchainVK>(new AHBSwapchainVK(context,           //
                                                           surface_control,   //
                                                           callback,          //
                                                           window.GetSize(),  //
                                                           enable_msaa        //
                                                           ));

    if (ahb_swapchain->IsValid()) {
      return ahb_swapchain;
    } else {
      VALIDATION_LOG
          << "Could not create AHB swapchain. Falling back to KHR variant.";
    }
  }

  vk::AndroidSurfaceCreateInfoKHR surface_info;
  surface_info.setWindow(window.GetHandle());
  auto [result, surface] =
      ContextVK::Cast(*context).GetInstance().createAndroidSurfaceKHRUnique(
          surface_info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create KHR Android Surface: "
                   << vk::to_string(result);
    return nullptr;
  }

  // Fallback to KHR swapchains if AHB swapchains aren't available.
  return Create(context, std::move(surface), window.GetSize(), enable_msaa);
}
#endif  // FML_OS_ANDROID

SwapchainVK::SwapchainVK() = default;

SwapchainVK::~SwapchainVK() = default;

void TrackSwapchainSubmissionWithFenceWaiter(
    const ContextVK& context,
    const PendingGpuSubmission& submission) {
  if (!submission.IsPending()) {
    return;
  }
  auto fence_result = context.GetDevice().createFenceUnique({});
  if (fence_result.result != vk::Result::eSuccess) {
    return;
  }
  auto submit_callback = [&context](vk::Fence fence) {
    auto status = context.GetGraphicsQueue()->Submit(fence);
    if (status != vk::Result::eSuccess) {
      return absl::Status(absl::StatusCode::kCancelled,
                          "Failed to submit swapchain completion fence.");
    }
    return absl::OkStatus();
  };
  const auto& tracker = submission.GetTracker();
  uint64_t id = submission.GetId();
  // Queue a separate fence for FenceWaiterVK because the swapchain retains
  // sync->acquire for AcquireNextDrawable(), and relying solely on
  // WaitForFence() would freeze CompletedThrough() for the whole ContextVK if
  // this swapchain goes idle. WaitForFence() and ~FrameSynchronizer() still
  // act as backstops if FenceWaiterVK is unavailable or terminating.
  [[maybe_unused]] auto status = context.GetFenceWaiter()->AddFence(
      std::move(fence_result.value), submit_callback,
      [tracker, id]() { tracker->RecordCompletion(id); });
}

}  // namespace impeller
