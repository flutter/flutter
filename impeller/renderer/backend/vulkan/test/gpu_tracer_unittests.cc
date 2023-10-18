// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer//backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

#ifdef IMPELLER_DEBUG
TEST(GPUTracerVK, CanTraceCmdBuffer) {
  auto const context = MockVulkanContextBuilder().Build();

  auto tracer = std::make_shared<GPUTracerVK>(context->GetDeviceHolder());

  ASSERT_TRUE(tracer->IsEnabled());

  auto cmd_buffer = context->CreateCommandBuffer();
  auto vk_cmd_buffer = CommandBufferVK::Cast(cmd_buffer.get());
  auto blit_pass = cmd_buffer->CreateBlitPass();

  tracer->MarkFrameStart();
  tracer->RecordCmdBufferStart(vk_cmd_buffer->GetEncoder()->GetCommandBuffer());
  auto frame_id = tracer->RecordCmdBufferEnd(
      vk_cmd_buffer->GetEncoder()->GetCommandBuffer());
  tracer->MarkFrameEnd();

  ASSERT_EQ(frame_id, 0u);
  auto called = GetMockVulkanFunctions(context->GetDevice());
  ASSERT_NE(called, nullptr);
  ASSERT_TRUE(std::find(called->begin(), called->end(), "vkCreateQueryPool") !=
              called->end());
  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") == called->end());

  tracer->OnFenceComplete(frame_id, true);

  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") != called->end());
}

TEST(GPUTracerVK, DoesNotTraceOutsideOfFrameWorkload) {
  auto const context = MockVulkanContextBuilder().Build();

  auto tracer = std::make_shared<GPUTracerVK>(context->GetDeviceHolder());

  ASSERT_TRUE(tracer->IsEnabled());

  auto cmd_buffer = context->CreateCommandBuffer();
  auto vk_cmd_buffer = CommandBufferVK::Cast(cmd_buffer.get());
  auto blit_pass = cmd_buffer->CreateBlitPass();

  tracer->RecordCmdBufferStart(vk_cmd_buffer->GetEncoder()->GetCommandBuffer());
  auto frame_id = tracer->RecordCmdBufferEnd(
      vk_cmd_buffer->GetEncoder()->GetCommandBuffer());

  ASSERT_TRUE(!frame_id.has_value());
  auto called = GetMockVulkanFunctions(context->GetDevice());

  ASSERT_NE(called, nullptr);
  ASSERT_TRUE(std::find(called->begin(), called->end(), "vkCreateQueryPool") ==
              called->end());
  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") == called->end());

  tracer->OnFenceComplete(frame_id, true);

  ASSERT_TRUE(std::find(called->begin(), called->end(), "vkCreateQueryPool") ==
              called->end());
  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") == called->end());
}

#endif  // IMPELLER_DEBUG

}  // namespace testing
}  // namespace impeller
