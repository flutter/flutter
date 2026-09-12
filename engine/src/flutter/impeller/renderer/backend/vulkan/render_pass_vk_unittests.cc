// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/render_pass_builder_vk.h"
#include "impeller/renderer/backend/vulkan/render_pass_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/render_target.h"
#include "vulkan/vulkan_enums.hpp"

namespace impeller {
namespace testing {

TEST(RenderPassVK, DoesNotRedundantlySetStencil) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
  std::shared_ptr<Context> copy = context;
  auto cmd_buffer = context->CreateCommandBuffer();

  RenderTargetAllocator allocator(context->GetResourceAllocator());
  RenderTarget target = allocator.CreateOffscreenMSAA(*copy.get(), {1, 1}, 1);

  std::shared_ptr<RenderPass> render_pass =
      cmd_buffer->CreateRenderPass(target);

  // Stencil reference set once at buffer start.
  auto called_functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(std::count(called_functions->begin(), called_functions->end(),
                       "vkCmdSetStencilReference"),
            1);

  // Duplicate stencil ref is not replaced.
  render_pass->SetStencilReference(0);
  render_pass->SetStencilReference(0);
  render_pass->SetStencilReference(0);

  called_functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(std::count(called_functions->begin(), called_functions->end(),
                       "vkCmdSetStencilReference"),
            1);

  // Different stencil value is updated.
  render_pass->SetStencilReference(1);
  called_functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(std::count(called_functions->begin(), called_functions->end(),
                       "vkCmdSetStencilReference"),
            2);
}

// Regression guard for the bug where `RenderPassVK::SetViewport` silently
// dropped the user's X and Y offsets and the depth range, only honoring
// width and height.
TEST(RenderPassVK, SetViewportPropagatesAllUserSuppliedFields) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
  auto cmd_buffer = context->CreateCommandBuffer();

  RenderTargetAllocator allocator(context->GetResourceAllocator());
  RenderTarget target = allocator.CreateOffscreenMSAA(*context, {100, 100},
                                                      /*mip_count=*/1);

  std::shared_ptr<RenderPass> render_pass =
      cmd_buffer->CreateRenderPass(target);

  // The render pass constructor sets an initial full-target viewport. Capture
  // a reference to the recorded viewport list before the user-driven call so
  // we can isolate the call under test.
  VkCommandBuffer raw_cmd_buffer =
      CommandBufferVK::Cast(*cmd_buffer).GetCommandBuffer();
  const std::vector<VkViewport>& recorded =
      GetRecordedViewports(raw_cmd_buffer);
  ASSERT_EQ(recorded.size(), 1u);  // Initial full-target viewport.

  render_pass->SetViewport(Viewport{
      .rect = Rect::MakeXYWH(25, 10, 50, 80),
      .depth_range = DepthRange{.z_near = 0.25f, .z_far = 0.75f},
  });

  ASSERT_EQ(recorded.size(), 2u);
  const VkViewport& vp = recorded[1];
  EXPECT_FLOAT_EQ(vp.x, 25.0f);
  // Y is computed for the negative-height Y-flip: `y + height` of the
  // original rect.
  EXPECT_FLOAT_EQ(vp.y, 90.0f);
  EXPECT_FLOAT_EQ(vp.width, 50.0f);
  EXPECT_FLOAT_EQ(vp.height, -80.0f);
  EXPECT_FLOAT_EQ(vp.minDepth, 0.25f);
  EXPECT_FLOAT_EQ(vp.maxDepth, 0.75f);
}

// Regression guard: the framebuffer cache lives on color attachment zero's
// texture, and a framebuffer holds image views of *every* attachment. Two
// passes that share a color texture but bring different depth textures — a
// shadow atlas drawn with a depth buffer from a pool is the ordinary case —
// used to be handed the same framebuffer, which still referred to the first
// pass's depth. Vulkan reports the stale view as
// VUID-VkRenderPassBeginInfo-framebuffer-parameter, and the driver
// dereferences it once that texture has been released.
TEST(RenderPassVK, DoesNotReuseAFramebufferWithADifferentDepthAttachment) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
  std::shared_ptr<Context> copy = context;
  std::shared_ptr<CommandBuffer> cmd_buffer = context->CreateCommandBuffer();

  RenderTargetAllocator allocator(context->GetResourceAllocator());
  RenderTarget first = allocator.CreateOffscreen(*copy.get(), {4, 4}, 1);

  // The same color texture, and whatever depth the allocator makes next.
  RenderTarget second = allocator.CreateOffscreen(
      *copy.get(),                                    //
      {4, 4},                                         //
      1,                                              //
      "Offscreen",                                    //
      RenderTarget::kDefaultColorAttachmentConfig,    //
      RenderTarget::kDefaultStencilAttachmentConfig,  //
      first.GetRenderTargetTexture()                  //
  );

  ASSERT_TRUE(first.GetDepthAttachment().has_value());
  ASSERT_TRUE(second.GetDepthAttachment().has_value());
  ASSERT_EQ(first.GetRenderTargetTexture(), second.GetRenderTargetTexture());
  ASSERT_NE(first.GetDepthAttachment()->texture,
            second.GetDepthAttachment()->texture);

  ASSERT_TRUE(cmd_buffer->CreateRenderPass(first));
  ASSERT_TRUE(cmd_buffer->CreateRenderPass(second));

  // One framebuffer per attachment set. The render pass itself is compatible
  // between the two and is cached separately, so the framebuffer is what says
  // whether the entry was reused: before the key included the depth
  // attachment, the second pass was handed the first's and only one was made.
  auto called_functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(std::count(called_functions->begin(), called_functions->end(),
                       "vkCreateFramebuffer"),
            2);
}

}  // namespace testing
}  // namespace impeller
