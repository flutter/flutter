// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "vulkan/vulkan_enums.hpp"

namespace impeller {
namespace testing {

vk::UniqueSurfaceKHR CreateSurface(const ContextVK& context) {
#if FML_OS_DARWIN
  impeller::vk::MetalSurfaceCreateInfoEXT createInfo = {};
  auto [result, surface] =
      context.GetInstance().createMetalSurfaceEXTUnique(createInfo);
  FML_DCHECK(result == vk::Result::eSuccess);
  return std::move(surface);
#else
  return {};
#endif  // FML_OS_DARWIN
}

TEST(SwapchainTest, CanCreateSwapchain) {
  auto const context = MockVulkanContextBuilder().Build();

  auto surface = CreateSurface(*context);
  auto swapchain =
      SwapchainVK::Create(context, std::move(surface), ISize{1, 1});

  EXPECT_TRUE(swapchain->IsValid());
}

TEST(SwapchainTest, RecreateSwapchainWhenSizeChanges) {
  auto const context = MockVulkanContextBuilder().Build();

  auto surface = CreateSurface(*context);
  SetSwapchainImageSize(ISize{1, 1});
  auto swapchain = SwapchainVK::Create(context, std::move(surface), ISize{1, 1},
                                       /*enable_msaa=*/false);
  auto image = swapchain->AcquireNextDrawable();
  auto expected_size = ISize{1, 1};
  EXPECT_EQ(image->GetSize(), expected_size);

  SetSwapchainImageSize(ISize{100, 100});
  swapchain->UpdateSurfaceSize(ISize{100, 100});

  auto image_b = swapchain->AcquireNextDrawable();
  expected_size = ISize{100, 100};
  EXPECT_EQ(image_b->GetSize(), expected_size);
}

}  // namespace testing
}  // namespace impeller
