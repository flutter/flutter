// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <thread>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(CommandEncoderVKTest, DeleteEncoderAfterThreadDies) {
  // Tests that when a CommandEncoderVK is deleted that it will clean up its
  // command buffers before it cleans up its command pool.
  std::shared_ptr<std::vector<std::string>> called_functions;
  {
    auto context = CreateMockVulkanContext();
    called_functions = GetMockVulkanFunctions(context->GetDevice());
    std::shared_ptr<CommandEncoderVK> encoder;
    std::thread thread([&] {
      CommandEncoderFactoryVK factory(context);
      encoder = factory.Create();
    });
    thread.join();
  }
  auto destroy_pool =
      std::find(called_functions->begin(), called_functions->end(),
                "vkDestroyCommandPool");
  auto free_buffers =
      std::find(called_functions->begin(), called_functions->end(),
                "vkFreeCommandBuffers");
  EXPECT_TRUE(destroy_pool != called_functions->end());
  EXPECT_TRUE(free_buffers != called_functions->end());
  EXPECT_TRUE(free_buffers < destroy_pool);
}

TEST(CommandEncoderVKTest, CleanupAfterSubmit) {
  // This tests deleting the TrackedObjects where the thread is killed before
  // the fence waiter has disposed of them, making sure the command buffer and
  // its pools are deleted in that order.
  std::shared_ptr<std::vector<std::string>> called_functions;
  {
    fml::AutoResetWaitableEvent wait_for_submit;
    fml::AutoResetWaitableEvent wait_for_thread_join;
    auto context = CreateMockVulkanContext();
    std::thread thread([&] {
      CommandEncoderFactoryVK factory(context);
      std::shared_ptr<CommandEncoderVK> encoder = factory.Create();
      encoder->Submit([&](bool success) {
        ASSERT_TRUE(success);
        wait_for_thread_join.Wait();
        wait_for_submit.Signal();
      });
    });
    thread.join();
    wait_for_thread_join.Signal();
    wait_for_submit.Wait();
    called_functions = GetMockVulkanFunctions(context->GetDevice());
  }
  auto destroy_pool =
      std::find(called_functions->begin(), called_functions->end(),
                "vkDestroyCommandPool");
  auto free_buffers =
      std::find(called_functions->begin(), called_functions->end(),
                "vkFreeCommandBuffers");
  EXPECT_TRUE(destroy_pool != called_functions->end());
  EXPECT_TRUE(free_buffers != called_functions->end());
  EXPECT_TRUE(free_buffers < destroy_pool);
}

}  // namespace testing
}  // namespace impeller
