// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "impeller/renderer/backend/vulkan/swapchain/ahb/ahb_swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/toolkit/android/surface_control.h"

namespace impeller::android::testing {

using impeller::testing::MockVulkanContextBuilder;

const std::vector<std::string> kAndroidDeviceExtensions = {
    "VK_KHR_swapchain",
    "VK_ANDROID_external_memory_android_hardware_buffer",
    "VK_KHR_sampler_ycbcr_conversion",
    "VK_KHR_external_memory",
    "VK_EXT_queue_family_foreign",
    "VK_KHR_dedicated_allocation",
};

class FakeSurfaceControl : public SurfaceControl {
 public:
  bool IsValid() const override { return true; }

  ASurfaceControl* GetHandle() const override { return nullptr; }

  bool RemoveFromParent() const override { return true; }
};

TEST(AndroidAHBSwapchainTest,
     AHBSwapchainNoFenceWaitAfterAcquireNextImageFailure) {
  bool wait_for_fences_called = false;
  auto const context =
      MockVulkanContextBuilder()
          .SetDeviceExtensions(kAndroidDeviceExtensions)
          .SetAcquireNextImageCallback(
              [](VkDevice, VkSwapchainKHR, uint64_t, VkSemaphore, VkFence,
                 uint32_t*) -> VkResult { return VK_ERROR_SURFACE_LOST_KHR; })
          .SetWaitForFencesCallback([&](VkDevice, uint32_t, const VkFence*,
                                        VkBool32, uint64_t) -> VkResult {
            wait_for_fences_called = true;
            return VK_SUCCESS;
          })
          .Build();

  auto ahb_swapchain = std::shared_ptr<AHBSwapchainVK>(new AHBSwapchainVK(
      context, std::make_shared<FakeSurfaceControl>(), {}, {100, 100}, false));

  auto image = ahb_swapchain->AcquireNextDrawable();
  EXPECT_FALSE(image);

  ahb_swapchain->AcquireNextDrawable();
  EXPECT_FALSE(wait_for_fences_called);
}

}  // namespace impeller::android::testing
