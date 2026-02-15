// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sys/types.h>
#include <memory>
#include <utility>

#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/surface.h"

namespace impeller {
namespace testing {

namespace {
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
}  // namespace

TEST(SurfaceContextVK, TearsDownSwapchain) {
  SetSwapchainImageSize({100, 100});
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  vk::UniqueSurfaceKHR surface = CreateSurface(*context);
  SurfaceContextVK surface_context(context);

  EXPECT_TRUE(surface_context.SetWindowSurface(std::move(surface), {100, 100}));
  EXPECT_NE(surface_context.AcquireNextSurface(), nullptr);

  surface_context.TeardownSwapchain();

  EXPECT_EQ(surface_context.AcquireNextSurface(), nullptr);
}

}  // namespace testing
}  // namespace impeller
