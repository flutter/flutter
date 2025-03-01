// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "fml/closure.h"
#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "impeller/renderer/backend/vulkan/free_queue_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "vulkan/vulkan_handles.hpp"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {
namespace testing {

TEST(FreeQueueVK, CanPushFences) {
  auto const context = MockVulkanContextBuilder().Build();
  auto free_queue = std::make_shared<FreeQueueVK>(context->GetDeviceHolder());

  bool signaled = false;
  auto [result, fence] =
      context->GetDeviceHolder()->GetDevice().createFenceUnique({});
  EXPECT_EQ(result, vk::Result::eSuccess);

  free_queue->PushEntry(std::move(fence), [&]() { signaled = true; });
  EXPECT_FALSE(signaled);
  free_queue->PopEntries();

  EXPECT_TRUE(signaled);
}

TEST(FreeQueueVK, CanPushManyFences) {
  auto const context = MockVulkanContextBuilder().Build();
  auto free_queue = std::make_shared<FreeQueueVK>(context->GetDeviceHolder());

  std::array<bool, 3> signals = {false, false, false};
  for (int i = 0; i < 3; i++) {
    auto [result, fence] =
        context->GetDeviceHolder()->GetDevice().createFenceUnique({});
    EXPECT_EQ(result, vk::Result::eSuccess);

    free_queue->PushEntry(std::move(fence),
                          [&, j = i]() { signals[j] = true; });
  }
  EXPECT_FALSE(signals[0]);
  EXPECT_FALSE(signals[1]);
  EXPECT_FALSE(signals[2]);

  free_queue->PopEntries();

  EXPECT_TRUE(signals[0]);
  EXPECT_TRUE(signals[1]);
  EXPECT_TRUE(signals[2]);
}

}  // namespace testing
}  // namespace impeller
