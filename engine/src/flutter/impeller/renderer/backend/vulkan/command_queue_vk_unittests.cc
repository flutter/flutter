// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(CommandQueueVKTest, QueueSubmit) {
  const auto context = MockVulkanContextBuilder().Build();
  auto buffer = context->CreateCommandBuffer();
  auto status = context->GetCommandQueue()->Submit({buffer});
  EXPECT_TRUE(status.ok());

  const auto called = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_NE(std::find(called->begin(), called->end(), "vkQueueSubmit"),
            called->end());
}

TEST(CommandQueueVKTest, SubmitAfterFenceWaiterTerminated) {
  const auto context = MockVulkanContextBuilder().Build();
  auto buffer = context->CreateCommandBuffer();
  context->GetFenceWaiter()->Terminate();
  auto status = context->GetCommandQueue()->Submit({buffer});
  EXPECT_EQ(status.code(), fml::StatusCode::kCancelled);

  // The command buffer should not be submitted to the Vulkan queue if the
  // fence waiter has been terminated.
  const auto called = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(std::find(called->begin(), called->end(), "vkQueueSubmit"),
            called->end());
}

TEST(CommandQueueVKTest, SubmitAfterDeviceLostIsCancelled) {
  const auto context = MockVulkanContextBuilder().Build();
  auto buffer = context->CreateCommandBuffer();
  context->MarkDeviceLost();
  auto status = context->GetCommandQueue()->Submit({buffer});
  EXPECT_EQ(status.code(), fml::StatusCode::kCancelled);

  // No submission may reach the queue once the device is lost; any Vulkan
  // call on a driver in a corrupted state can crash inside the ICD.
  const auto called = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(std::find(called->begin(), called->end(), "vkQueueSubmit"),
            called->end());
}

TEST(CommandQueueVKTest, ThrottleAllowsSustainedSubmissions) {
  const auto context = MockVulkanContextBuilder().Build();
  // Submit more batches than kMaxInFlightSubmissions. If in-flight slots
  // were not released when submissions complete, this would exhaust the
  // slots and fail on the slot timeout.
  for (int i = 0; i < 10; i++) {
    auto buffer = context->CreateCommandBuffer();
    ASSERT_TRUE(buffer);
    ASSERT_TRUE(context->GetCommandQueue()->Submit({buffer}).ok());
  }
}

}  // namespace testing
}  // namespace impeller
