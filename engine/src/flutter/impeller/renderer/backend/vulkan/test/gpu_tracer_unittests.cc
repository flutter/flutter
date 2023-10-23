// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "fml/synchronization/count_down_latch.h"
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
  auto tracer = context->GetGPUTracer();

  ASSERT_TRUE(tracer->IsEnabled());
  tracer->MarkFrameStart();

  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands(context->GetResourceAllocator());

  auto latch = std::make_shared<fml::CountDownLatch>(1u);

  if (!cmd_buffer->SubmitCommands(
          [latch](CommandBuffer::Status status) { latch->CountDown(); })) {
    GTEST_FAIL() << "Failed to submit cmd buffer";
  }

  tracer->MarkFrameEnd();
  latch->Wait();

  auto called = GetMockVulkanFunctions(context->GetDevice());
  ASSERT_NE(called, nullptr);
  ASSERT_TRUE(std::find(called->begin(), called->end(), "vkCreateQueryPool") !=
              called->end());
  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") != called->end());
}

TEST(GPUTracerVK, DoesNotTraceOutsideOfFrameWorkload) {
  auto const context = MockVulkanContextBuilder().Build();
  auto tracer = context->GetGPUTracer();

  ASSERT_TRUE(tracer->IsEnabled());

  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands(context->GetResourceAllocator());

  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  if (!cmd_buffer->SubmitCommands(
          [latch](CommandBuffer::Status status) { latch->CountDown(); })) {
    GTEST_FAIL() << "Failed to submit cmd buffer";
  }

  latch->Wait();

  auto called = GetMockVulkanFunctions(context->GetDevice());

  ASSERT_NE(called, nullptr);
  ASSERT_TRUE(std::find(called->begin(), called->end(), "vkCreateQueryPool") ==
              called->end());
  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") == called->end());
}

// This cmd buffer starts when there is a frame but finishes when there is none.
// This should result in the same recorded work.
TEST(GPUTracerVK, TracesWithPartialFrameOverlap) {
  auto const context = MockVulkanContextBuilder().Build();
  auto tracer = context->GetGPUTracer();

  ASSERT_TRUE(tracer->IsEnabled());
  tracer->MarkFrameStart();

  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands(context->GetResourceAllocator());
  tracer->MarkFrameEnd();

  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  if (!cmd_buffer->SubmitCommands(
          [latch](CommandBuffer::Status status) { latch->CountDown(); })) {
    GTEST_FAIL() << "Failed to submit cmd buffer";
  }

  latch->Wait();

  auto called = GetMockVulkanFunctions(context->GetDevice());
  ASSERT_NE(called, nullptr);
  ASSERT_TRUE(std::find(called->begin(), called->end(), "vkCreateQueryPool") !=
              called->end());
  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") != called->end());
}

#endif  // IMPELLER_DEBUG

}  // namespace testing
}  // namespace impeller
