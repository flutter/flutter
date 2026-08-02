// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <memory>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/timestamp_query_pool_vk.h"

namespace impeller {
namespace testing {

static bool Called(const std::shared_ptr<std::vector<std::string>>& functions,
                   const std::string& name) {
  return std::find(functions->begin(), functions->end(), name) !=
         functions->end();
}

TEST(TimestampQueryPoolVKTest, SupportedWhenTheDeviceReportsATimestampPeriod) {
  auto const context = MockVulkanContextBuilder().Build();
  EXPECT_TRUE(context->GetCapabilities()->SupportsTimestampQueries());
  context->Shutdown();
}

TEST(TimestampQueryPoolVKTest, UnsupportedWithoutComputeAndGraphicsTimestamps) {
  auto const context =
      MockVulkanContextBuilder()
          .SetPhysicalPropertiesCallback(
              [](VkPhysicalDevice device, VkPhysicalDeviceProperties* props) {
                props->limits.timestampComputeAndGraphics = VK_FALSE;
              })
          .Build();
  EXPECT_FALSE(context->GetCapabilities()->SupportsTimestampQueries());
  EXPECT_EQ(context->CreateTimestampQueryPool(2u), nullptr);
  context->Shutdown();
}

TEST(TimestampQueryPoolVKTest, CreatesAPoolOfTheRequestedSize) {
  auto const context = MockVulkanContextBuilder().Build();

  EXPECT_EQ(context->CreateTimestampQueryPool(0u), nullptr);

  std::shared_ptr<TimestampQueryPool> pool =
      context->CreateTimestampQueryPool(4u);
  ASSERT_NE(pool, nullptr);
  EXPECT_EQ(pool->GetQueryCount(), 4u);

  auto functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_TRUE(Called(functions, "vkCreateQueryPool"));

  context->Shutdown();
}

TEST(TimestampQueryPoolVKTest, ResetsASlotBeforeWritingIt) {
  auto const context = MockVulkanContextBuilder().Build();
  std::shared_ptr<TimestampQueryPool> pool =
      context->CreateTimestampQueryPool(2u);
  ASSERT_NE(pool, nullptr);

  std::shared_ptr<CommandBuffer> command_buffer =
      context->CreateCommandBuffer();
  TimestampQueryPoolVK::Cast(*pool).RecordTimestamp(
      CommandBufferVK::Cast(*command_buffer).GetCommandBuffer(),
      vk::PipelineStageFlagBits::eTopOfPipe, 0u);

  auto functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_TRUE(Called(functions, "vkCmdResetQueryPool"));
  EXPECT_TRUE(Called(functions, "vkCmdWriteTimestamp"));

  context->Shutdown();
}

TEST(TimestampQueryPoolVKTest, OutOfRangeWritesAreDropped) {
  auto const context = MockVulkanContextBuilder().Build();
  std::shared_ptr<TimestampQueryPool> pool =
      context->CreateTimestampQueryPool(2u);
  ASSERT_NE(pool, nullptr);

  std::shared_ptr<CommandBuffer> command_buffer =
      context->CreateCommandBuffer();
  TimestampQueryPoolVK::Cast(*pool).RecordTimestamp(
      CommandBufferVK::Cast(*command_buffer).GetCommandBuffer(),
      vk::PipelineStageFlagBits::eTopOfPipe, 2u);

  auto functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_FALSE(Called(functions, "vkCmdWriteTimestamp"));

  context->Shutdown();
}

TEST(TimestampQueryPoolVKTest, ResolveReportsAnEntryPerSlot) {
  auto const context = MockVulkanContextBuilder().Build();
  std::shared_ptr<TimestampQueryPool> pool =
      context->CreateTimestampQueryPool(3u);
  ASSERT_NE(pool, nullptr);

  TimestampQueryResults results = pool->Resolve();
  EXPECT_EQ(results.timestamps.size(), 3u);
  EXPECT_FALSE(results.disjoint);
  // The mock never marks a query as available, so nothing was written.
  for (const std::optional<uint64_t>& timestamp : results.timestamps) {
    EXPECT_FALSE(timestamp.has_value());
  }

  auto functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_TRUE(Called(functions, "vkGetQueryPoolResults"));

  context->Shutdown();
}

TEST(TimestampQueryPoolVKTest, WritesAreValidatedAgainstThePoolSize) {
  auto const context = MockVulkanContextBuilder().Build();
  std::shared_ptr<TimestampQueryPool> pool =
      context->CreateTimestampQueryPool(2u);
  ASSERT_NE(pool, nullptr);

  TimestampWrites writes;
  EXPECT_FALSE(writes.HasWrites());
  EXPECT_FALSE(writes.IsValid());

  writes.pool = pool;
  writes.beginning_of_pass_write_index = 0u;
  writes.end_of_pass_write_index = 1u;
  EXPECT_TRUE(writes.HasWrites());
  EXPECT_TRUE(writes.IsValid());

  writes.end_of_pass_write_index = 2u;
  EXPECT_FALSE(writes.IsValid());

  writes.end_of_pass_write_index = 0u;
  EXPECT_FALSE(writes.IsValid());

  context->Shutdown();
}

}  // namespace testing
}  // namespace impeller
