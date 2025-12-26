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
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  vk::UniqueDescriptorPool pool1 = context->GetDescriptorPoolRecycler()->Get();
  vk::UniqueDescriptorPool pool2 = context->GetDescriptorPoolRecycler()->Get();

  // The two descriptor pools should be different.
  EXPECT_NE(pool1.get(), pool2.get());

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, ReclaimMakesDescriptorPoolAvailable) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  {
    // Fetch a pool (which will be created).
    DescriptorPoolVK pool = DescriptorPoolVK(context);
    pool.AllocateDescriptorSets({}, /*pipeline_key=*/0, *context);
  }

  std::shared_ptr<DescriptorPoolVK> pool =
      context->GetDescriptorPoolRecycler()->GetDescriptorPool();

  // Now check that we only ever created one pool.
  std::shared_ptr<std::vector<std::string>> called =
      GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkCreateDescriptorPool"), 1u);

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, ReclaimDropsDescriptorPoolIfSizeIsExceeded) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  // Create 33 pools
  {
    std::vector<std::unique_ptr<DescriptorPoolVK>> pools;
    for (size_t i = 0u; i < 33; i++) {
      std::unique_ptr<DescriptorPoolVK> pool =
          std::make_unique<DescriptorPoolVK>(context);
      pool->AllocateDescriptorSets({}, /*pipeline_key=*/0, *context);
      pools.push_back(std::move(pool));
    }
  }

  std::shared_ptr<std::vector<std::string>> called =
      GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkCreateDescriptorPool"),
      33u);

  // Now create 33 more descriptor pools and observe that only one more is
  // allocated.
  {
    std::vector<std::shared_ptr<DescriptorPoolVK>> pools;
    for (size_t i = 0u; i < 33; i++) {
      std::shared_ptr<DescriptorPoolVK> pool =
          context->GetDescriptorPoolRecycler()->GetDescriptorPool();
      pool->AllocateDescriptorSets({}, /*pipeline_key=*/0, *context);
      pools.push_back(std::move(pool));
    }
  }

  std::shared_ptr<std::vector<std::string>> called_twice =
      GetMockVulkanFunctions(context->GetDevice());
  // 32 of the descriptor pools were recycled, so only one more is created.
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkCreateDescriptorPool"),
      34u);

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, MultipleCommandBuffersShareDescriptorPool) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  std::shared_ptr<CommandBuffer> cmd_buffer_1 = context->CreateCommandBuffer();
  std::shared_ptr<CommandBuffer> cmd_buffer_2 = context->CreateCommandBuffer();

  CommandBufferVK& vk_1 = CommandBufferVK::Cast(*cmd_buffer_1);
  CommandBufferVK& vk_2 = CommandBufferVK::Cast(*cmd_buffer_2);

  EXPECT_EQ(&vk_1.GetDescriptorPool(), &vk_2.GetDescriptorPool());

  // Resetting resources creates a new pool.
  context->DisposeThreadLocalCachedResources();

  std::shared_ptr<CommandBuffer> cmd_buffer_3 = context->CreateCommandBuffer();
  CommandBufferVK& vk_3 = CommandBufferVK::Cast(*cmd_buffer_3);

  EXPECT_NE(&vk_1.GetDescriptorPool(), &vk_3.GetDescriptorPool());

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, DescriptorsAreRecycled) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  {
    DescriptorPoolVK pool = DescriptorPoolVK(context);
    pool.AllocateDescriptorSets({}, /*pipeline_key=*/0, *context);
  }

  // Should reuse the same descriptor set allocated above.
  std::shared_ptr<DescriptorPoolVK> pool =
      context->GetDescriptorPoolRecycler()->GetDescriptorPool();
  pool->AllocateDescriptorSets({}, /*pipeline_key=*/0, *context);

  std::shared_ptr<std::vector<std::string>> called =
      GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkAllocateDescriptorSets"),
      1);

  // Should allocate a new descriptor set.
  pool->AllocateDescriptorSets({}, /*pipeline_key=*/0, *context);
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkAllocateDescriptorSets"),
      2);
}

}  // namespace testing
}  // namespace impeller
