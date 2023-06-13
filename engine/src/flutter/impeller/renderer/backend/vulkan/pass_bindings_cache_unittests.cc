// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/pass_bindings_cache.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

namespace {
int32_t CountStringViewInstances(const std::vector<std::string>& strings,
                                 std::string_view target) {
  int32_t count = 0;
  for (const std::string& str : strings) {
    if (str == target) {
      count++;
    }
  }
  return count;
}
}  // namespace

TEST(PassBindingsCacheTest, bindPipeline) {
  auto context = CreateMockVulkanContext();
  PassBindingsCache cache;
  auto pool = CommandPoolVK::GetThreadLocal(context.get());
  CommandEncoderVK encoder(context->GetDeviceHolder(),
                           context->GetGraphicsQueue(), pool,
                           context->GetFenceWaiter());
  auto buffer = encoder.GetCommandBuffer();
  VkPipeline vk_pipeline = reinterpret_cast<VkPipeline>(0xfeedface);
  vk::Pipeline pipeline(vk_pipeline);
  cache.BindPipeline(buffer, vk::PipelineBindPoint::eGraphics, pipeline);
  cache.BindPipeline(buffer, vk::PipelineBindPoint::eGraphics, pipeline);
  std::shared_ptr<std::vector<std::string>> functions =
      GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(CountStringViewInstances(*functions, "vkCmdBindPipeline"), 1);
}

TEST(PassBindingsCacheTest, setStencilReference) {
  auto context = CreateMockVulkanContext();
  PassBindingsCache cache;
  auto pool = CommandPoolVK::GetThreadLocal(context.get());
  CommandEncoderVK encoder(context->GetDeviceHolder(),
                           context->GetGraphicsQueue(), pool,
                           context->GetFenceWaiter());
  auto buffer = encoder.GetCommandBuffer();
  cache.SetStencilReference(
      buffer, vk::StencilFaceFlagBits::eVkStencilFrontAndBack, 123);
  cache.SetStencilReference(
      buffer, vk::StencilFaceFlagBits::eVkStencilFrontAndBack, 123);
  std::shared_ptr<std::vector<std::string>> functions =
      GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(CountStringViewInstances(*functions, "vkCmdSetStencilReference"),
            1);
}

TEST(PassBindingsCacheTest, setScissor) {
  auto context = CreateMockVulkanContext();
  PassBindingsCache cache;
  auto pool = CommandPoolVK::GetThreadLocal(context.get());
  CommandEncoderVK encoder(context->GetDeviceHolder(),
                           context->GetGraphicsQueue(), pool,
                           context->GetFenceWaiter());
  auto buffer = encoder.GetCommandBuffer();
  vk::Rect2D scissors;
  cache.SetScissor(buffer, 0, 1, &scissors);
  cache.SetScissor(buffer, 0, 1, &scissors);
  std::shared_ptr<std::vector<std::string>> functions =
      GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(CountStringViewInstances(*functions, "vkCmdSetScissor"), 1);
}

TEST(PassBindingsCacheTest, setViewport) {
  auto context = CreateMockVulkanContext();
  PassBindingsCache cache;
  auto pool = CommandPoolVK::GetThreadLocal(context.get());
  CommandEncoderVK encoder(context->GetDeviceHolder(),
                           context->GetGraphicsQueue(), pool,
                           context->GetFenceWaiter());
  auto buffer = encoder.GetCommandBuffer();
  vk::Viewport viewports;
  cache.SetViewport(buffer, 0, 1, &viewports);
  cache.SetViewport(buffer, 0, 1, &viewports);
  std::shared_ptr<std::vector<std::string>> functions =
      GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(CountStringViewInstances(*functions, "vkCmdSetViewport"), 1);
}

}  // namespace testing
}  // namespace impeller
