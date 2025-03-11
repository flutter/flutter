// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep.
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(DescriptorPoolRecyclerVKTest, GetDescriptorPoolRecyclerCreatesNewPools) {
  auto const context = MockVulkanContextBuilder().Build();

  auto const pool1 = context->GetDescriptorPoolRecycler()->Get();
  auto const pool2 = context->GetDescriptorPoolRecycler()->Get();

  // The two descriptor pools should be different.
  EXPECT_NE(pool1.get(), pool2.get());

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, ReclaimMakesDescriptorPoolAvailable) {
  auto const context = MockVulkanContextBuilder().Build();

  {
    // Fetch a pool (which will be created).
    auto pool = DescriptorPoolVK(context);
    pool.AllocateDescriptorSets({}, 0, *context);
  }

  auto const pool = context->GetDescriptorPoolRecycler()->GetDescriptorPool();

  // Now check that we only ever created one pool.
  auto const called = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkCreateDescriptorPool"), 1u);

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, ReclaimDropsDescriptorPoolIfSizeIsExceeded) {
  auto const context = MockVulkanContextBuilder().Build();

  // Create 33 pools
  {
    std::vector<std::unique_ptr<DescriptorPoolVK>> pools;
    for (auto i = 0u; i < 33; i++) {
      auto pool = std::make_unique<DescriptorPoolVK>(context);
      pool->AllocateDescriptorSets({}, 0, *context);
      pools.push_back(std::move(pool));
    }
  }

  auto const called = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkCreateDescriptorPool"),
      33u);

  // Now create 33 more descriptor pools and observe that only one more is
  // allocated.
  {
    std::vector<std::shared_ptr<DescriptorPoolVK>> pools;
    for (auto i = 0u; i < 33; i++) {
      auto pool = context->GetDescriptorPoolRecycler()->GetDescriptorPool();
      pool->AllocateDescriptorSets({}, 0, *context);
      pools.push_back(std::move(pool));
    }
  }

  auto const called_twice = GetMockVulkanFunctions(context->GetDevice());
  // 32 of the descriptor pools were recycled, so only one more is created.
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkCreateDescriptorPool"),
      34u);

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, MultipleCommandBuffersShareDescriptorPool) {
  auto const context = MockVulkanContextBuilder().Build();

  auto cmd_buffer_1 = context->CreateCommandBuffer();
  auto cmd_buffer_2 = context->CreateCommandBuffer();

  CommandBufferVK& vk_1 = CommandBufferVK::Cast(*cmd_buffer_1);
  CommandBufferVK& vk_2 = CommandBufferVK::Cast(*cmd_buffer_2);

  EXPECT_EQ(&vk_1.GetDescriptorPool(), &vk_2.GetDescriptorPool());

  // Resetting resources creates a new pool.
  context->DisposeThreadLocalCachedResources();

  auto cmd_buffer_3 = context->CreateCommandBuffer();
  CommandBufferVK& vk_3 = CommandBufferVK::Cast(*cmd_buffer_3);

  EXPECT_NE(&vk_1.GetDescriptorPool(), &vk_3.GetDescriptorPool());

  context->Shutdown();
}

}  // namespace testing
}  // namespace impeller
