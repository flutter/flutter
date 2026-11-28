// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <memory>
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "fml/synchronization/count_down_latch.h"
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

#ifdef IMPELLER_DEBUG
TEST(GPUTracerVK, CanBeDisabled) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = false;
          })
          .Build();
  auto tracer = context->GetGPUTracer();

  ASSERT_FALSE(tracer->IsEnabled());
}

TEST(GPUTracerVK, DisabledFrameCycle) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = false;
          })
          .Build();
  auto tracer = context->GetGPUTracer();

  // Check that a repeated frame start/end cycle does not fail any assertions.
  for (int i = 0; i < 2; i++) {
    tracer->MarkFrameStart();
    tracer->MarkFrameEnd();
  }
}

TEST(GPUTracerVK, CanTraceCmdBuffer) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();
  auto tracer = context->GetGPUTracer();

  ASSERT_TRUE(tracer->IsEnabled());
  tracer->MarkFrameStart();

  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands();

  auto latch = std::make_shared<fml::CountDownLatch>(1u);

  if (!context->GetCommandQueue()
           ->Submit(
               {cmd_buffer},
               [latch](CommandBuffer::Status status) { latch->CountDown(); })
           .ok()) {
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
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();
  auto tracer = context->GetGPUTracer();

  ASSERT_TRUE(tracer->IsEnabled());

  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands();

  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  if (!context->GetCommandQueue()
           ->Submit(
               {cmd_buffer},
               [latch](CommandBuffer::Status status) { latch->CountDown(); })
           .ok()) {
    GTEST_FAIL() << "Failed to submit cmd buffer";
  }

  latch->Wait();

  auto called = GetMockVulkanFunctions(context->GetDevice());

  ASSERT_NE(called, nullptr);
  ASSERT_TRUE(std::find(called->begin(), called->end(),
                        "vkGetQueryPoolResults") == called->end());
}

// This cmd buffer starts when there is a frame but finishes when there is none.
// This should result in the same recorded work.
TEST(GPUTracerVK, TracesWithPartialFrameOverlap) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();
  auto tracer = context->GetGPUTracer();

  ASSERT_TRUE(tracer->IsEnabled());
  tracer->MarkFrameStart();

  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands();

  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  if (!context->GetCommandQueue()
           ->Submit(
               {cmd_buffer},
               [latch](CommandBuffer::Status status) { latch->CountDown(); })
           .ok()) {
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

TEST(GPUTracerVK, RecordCmdBufferEndWritesToProbesOwnState) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();
  auto tracer = context->GetGPUTracer();
  ASSERT_TRUE(tracer->IsEnabled());

  // Start frame 0 and create a command buffer in state 0.
  tracer->MarkFrameStart();
  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands();
  tracer->MarkFrameEnd();

  // Start frame 1 before ending frame 0's command buffer. EndCommandBuffer
  // must write its end timestamp to state 0 (the probe's own state), not
  // state 1.
  tracer->MarkFrameStart();
  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [latch](CommandBuffer::Status) { latch->CountDown(); })
          .ok());
  tracer->MarkFrameEnd();

  latch->Wait();

  auto called = GetMockVulkanFunctions(context->GetDevice());
  ASSERT_NE(called, nullptr);
  EXPECT_EQ(std::count(called->begin(), called->end(), "vkGetQueryPoolResults"),
            1);
  EXPECT_EQ(GetQueryPoolResultCounts(context->GetDevice()),
            std::vector<uint32_t>({2}));
}

TEST(GPUTracerVK, RecordCmdBufferEndWritesBetweenFrames) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();
  auto tracer = context->GetGPUTracer();
  ASSERT_TRUE(tracer->IsEnabled());

  // Start frame 0, create a command buffer, and close frame 0 before ending it.
  tracer->MarkFrameStart();
  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->EncodeCommands();
  tracer->MarkFrameEnd();

  // Submit between frames (in_frame_ == false). EndCommandBuffer must still
  // record its end timestamp into state 0.
  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [latch](CommandBuffer::Status) { latch->CountDown(); })
          .ok());
  latch->Wait();

  EXPECT_EQ(GetQueryPoolResultCounts(context->GetDevice()),
            std::vector<uint32_t>({2}));
}

#endif  // IMPELLER_DEBUG

}  // namespace testing
}  // namespace impeller
