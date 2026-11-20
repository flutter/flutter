// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "fml/synchronization/count_down_latch.h"
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain/khr/khr_swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {
namespace testing {

vk::UniqueSurfaceKHR CreateSurface(const ContextVK& context) {
#if FML_OS_DARWIN
  impeller::vk::MetalSurfaceCreateInfoEXT createInfo = {};
  auto [result, surface] =
      context.GetInstance().createMetalSurfaceEXTUnique(createInfo);
  FML_DCHECK(result == vk::Result::eSuccess);
  return std::move(surface);
#else
  return {};
#endif  // FML_OS_DARWIN
}

TEST(SwapchainTest, CanCreateSwapchain) {
  auto const context = MockVulkanContextBuilder().Build();

  auto surface = CreateSurface(*context);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1});

  EXPECT_TRUE(swapchain->IsValid());
}

TEST(SwapchainTest, RecreateSwapchainWhenSizeChanges) {
  auto const context = MockVulkanContextBuilder().Build();

  auto surface = CreateSurface(*context);
  SetSwapchainImageSize(ISize{1, 1});
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1},
                             /*enable_msaa=*/false);
  auto image = swapchain->AcquireNextDrawable();
  auto expected_size = ISize{1, 1};
  EXPECT_EQ(image->GetSize(), expected_size);

  SetSwapchainImageSize(ISize{100, 100});
  swapchain->UpdateSurfaceSize(ISize{100, 100});

  auto image_b = swapchain->AcquireNextDrawable();
  expected_size = ISize{100, 100};
  EXPECT_EQ(image_b->GetSize(), expected_size);
}

TEST(SwapchainTest, CachesRenderPassOnSwapchainImage) {
  auto const context = MockVulkanContextBuilder().Build();

  auto surface = CreateSurface(*context);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1});

  EXPECT_TRUE(swapchain->IsValid());

  // The mock swapchain will always create 3 images, verify each one starts
  // out with the same MSAA and depth+stencil texture, and no cached
  // framebuffer.
  std::vector<std::shared_ptr<Texture>> msaa_textures;
  std::vector<std::shared_ptr<Texture>> depth_stencil_textures;
  for (auto i = 0u; i < 3u; i++) {
    auto drawable = swapchain->AcquireNextDrawable();
    RenderTarget render_target = drawable->GetRenderTarget();

    auto texture = render_target.GetRenderTargetTexture();
    auto& texture_vk = TextureVK::Cast(*texture);
    EXPECT_EQ(texture_vk.GetCachedFrameData(SampleCount::kCount4).framebuffer,
              nullptr);
    EXPECT_EQ(texture_vk.GetCachedFrameData(SampleCount::kCount4).render_pass,
              nullptr);

    auto command_buffer = context->CreateCommandBuffer();
    auto render_pass = command_buffer->CreateRenderPass(render_target);
    render_pass->EncodeCommands();

    auto& depth = render_target.GetDepthAttachment();
    depth_stencil_textures.push_back(depth.has_value() ? depth->texture
                                                       : nullptr);
    msaa_textures.push_back(render_target.GetColorAttachment(0).texture);
  }

  for (auto i = 1; i < 3; i++) {
    EXPECT_EQ(msaa_textures[i - 1], msaa_textures[i]);
    EXPECT_EQ(depth_stencil_textures[i - 1], depth_stencil_textures[i]);
  }

  // After each images has been acquired once and the render pass presented,
  // each should have a cached framebuffer and render pass.

  std::vector<SharedHandleVK<vk::Framebuffer>> framebuffers;
  std::vector<SharedHandleVK<vk::RenderPass>> render_passes;
  for (auto i = 0u; i < 3u; i++) {
    auto drawable = swapchain->AcquireNextDrawable();
    RenderTarget render_target = drawable->GetRenderTarget();

    auto texture = render_target.GetRenderTargetTexture();
    auto& texture_vk = TextureVK::Cast(*texture);

    EXPECT_NE(texture_vk.GetCachedFrameData(SampleCount::kCount4).framebuffer,
              nullptr);
    EXPECT_NE(texture_vk.GetCachedFrameData(SampleCount::kCount4).render_pass,
              nullptr);
    framebuffers.push_back(
        texture_vk.GetCachedFrameData(SampleCount::kCount4).framebuffer);
    render_passes.push_back(
        texture_vk.GetCachedFrameData(SampleCount::kCount4).render_pass);
  }

  // Iterate through once more to verify render passes and framebuffers are
  // unchanged.
  for (auto i = 0u; i < 3u; i++) {
    auto drawable = swapchain->AcquireNextDrawable();
    RenderTarget render_target = drawable->GetRenderTarget();

    auto texture = render_target.GetRenderTargetTexture();
    auto& texture_vk = TextureVK::Cast(*texture);

    EXPECT_EQ(texture_vk.GetCachedFrameData(SampleCount::kCount4).framebuffer,
              framebuffers[i]);
    EXPECT_EQ(texture_vk.GetCachedFrameData(SampleCount::kCount4).render_pass,
              render_passes[i]);
    EXPECT_NE(texture_vk.GetCachedFrameData(SampleCount::kCount1).framebuffer,
              framebuffers[i]);
    EXPECT_NE(texture_vk.GetCachedFrameData(SampleCount::kCount1).render_pass,
              render_passes[i]);
  }
}

TEST(SwapchainTest, NoFenceWaitAfterAcquireNextImageFailure) {
  bool wait_for_fences_called = false;
  auto const context =
      MockVulkanContextBuilder()
          .SetAcquireNextImageCallback(
              [](VkDevice, VkSwapchainKHR, uint64_t, VkSemaphore, VkFence,
                 uint32_t*) -> VkResult { return VK_ERROR_SURFACE_LOST_KHR; })
          .SetWaitForFencesCallback([&](VkDevice, uint32_t, const VkFence*,
                                        VkBool32, uint64_t) -> VkResult {
            wait_for_fences_called = true;
            return VK_SUCCESS;
          })
          .Build();

  auto surface = CreateSurface(*context);
  SetSwapchainImageSize(ISize{1, 1});
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1},
                             /*enable_msaa=*/false);
  auto image = swapchain->AcquireNextDrawable();
  EXPECT_FALSE(image);

  swapchain->AcquireNextDrawable();
  EXPECT_FALSE(wait_for_fences_called);
}

TEST(SwapchainTest, SwapchainSizeChangeDoesNotAcquireDrawable) {
  int acquire_call_count = 0;
  auto const context =
      MockVulkanContextBuilder()
          .SetAcquireNextImageCallback([&](VkDevice, VkSwapchainKHR, uint64_t,
                                           VkSemaphore, VkFence,
                                           uint32_t* pImageIndex) -> VkResult {
            *pImageIndex = 0;
            acquire_call_count++;
            return VK_SUCCESS;
          })
          .Build();

  auto surface = CreateSurface(*context);
  ISize original_size(1, 1);
  SetSwapchainImageSize(original_size);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), original_size,
                             /*enable_msaa=*/false);
  auto image = swapchain->AcquireNextDrawable();
  ASSERT_NE(image, nullptr);
  EXPECT_EQ(image->GetSize(), original_size);

  ISize new_size(100, 100);
  SetSwapchainImageSize(new_size);
  swapchain->UpdateSurfaceSize(new_size);

  acquire_call_count = 0;
  image = swapchain->AcquireNextDrawable();
  ASSERT_NE(image, nullptr);
  EXPECT_EQ(image->GetSize(), new_size);

  // Verify that the call to AcquireNextDrawable after the resize did not make
  // any extra calls to the underlying Vulkan API.
  EXPECT_EQ(acquire_call_count, 1);
}

#ifdef IMPELLER_DEBUG
TEST(SwapchainTest, TracesOnscreenCommandBufferStartAndEnd) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();
  ASSERT_TRUE(context->GetGPUTracer()->IsEnabled());

  auto surface = CreateSurface(*context);
  SetSwapchainImageSize(ISize{1, 1});
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1},
                             /*enable_msaa=*/false);
  ASSERT_TRUE(swapchain->IsValid());

  // Render 3 frames so the first frame's synchronizer slot (kMaxFramesInFlight
  // == 2) is reused and its GPUProbe is destroyed, triggering query readback.
  for (size_t i = 0; i < 3u; ++i) {
    auto drawable = swapchain->AcquireNextDrawable();
    ASSERT_NE(drawable, nullptr);

    auto command_buffer = context->CreateCommandBuffer();
    ASSERT_NE(command_buffer, nullptr);
    VkCommandBuffer vk_cmd_buffer =
        CommandBufferVK::Cast(*command_buffer).GetCommandBuffer();

    auto render_pass =
        command_buffer->CreateRenderPass(drawable->GetRenderTarget());
    ASSERT_NE(render_pass, nullptr);
    ASSERT_TRUE(render_pass->EncodeCommands());

    swapchain->AddFinalCommandBuffer(command_buffer);
    command_buffer.reset();

    ASSERT_TRUE(drawable->Present());

    const auto& stages = GetRecordedTimestamps(vk_cmd_buffer);
    ASSERT_EQ(stages.size(), 2u);
    EXPECT_EQ(stages[0], VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);
    EXPECT_EQ(stages[1], VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT);
  }

  swapchain.reset();

  for (int i = 0; i < 2; ++i) {
    auto latch = std::make_shared<fml::CountDownLatch>(1u);
    auto flush_cmd = context->CreateCommandBuffer();
    ASSERT_TRUE(
        context->GetCommandQueue()
            ->Submit({flush_cmd},
                     [latch](CommandBuffer::Status) { latch->CountDown(); })
            .ok());
    latch->Wait();
  }

  auto query_counts = GetQueryPoolResultCounts(context->GetDevice());
  ASSERT_EQ(query_counts.size(), 3u);
  for (uint32_t count : query_counts) {
    EXPECT_EQ(count, 2u);
  }
}
#endif  // IMPELLER_DEBUG

TEST(SwapchainTest, IdleSwapchainReleasesFinalCmdBufferProbe) {
  auto const context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();

  // Present once on swapchain1, then leave it idle.
  auto surface1 = CreateSurface(*context);
  auto swapchain1 = KHRSwapchainVK::Create(context, std::move(surface1),
                                           ISize(1, 1), /*enable_msaa=*/false);
  ASSERT_NE(swapchain1, nullptr);
  auto drawable1 = swapchain1->AcquireNextDrawable();
  ASSERT_NE(drawable1, nullptr);
  auto cmd_buffer = context->CreateCommandBuffer();
  ASSERT_NE(cmd_buffer, nullptr);
  swapchain1->AddFinalCommandBuffer(std::move(cmd_buffer));
  ASSERT_TRUE(drawable1->Present());

  // Flush the fence waiter with two sequential submits so the first batch's
  // erased_entries cleanup (including swapchain1's GPUProbe) has fully
  // completed before swapchain2 wraps around.
  for (int i = 0; i < 2; ++i) {
    auto latch = std::make_shared<fml::CountDownLatch>(1u);
    auto flush_cmd = context->CreateCommandBuffer();
    ASSERT_TRUE(
        context->GetCommandQueue()
            ->Submit({flush_cmd},
                     [latch](CommandBuffer::Status) { latch->CountDown(); })
            .ok());
    latch->Wait();
  }

#ifdef IMPELLER_DEBUG
  EXPECT_EQ(GetQueryPoolResultCounts(context->GetDevice()).size(), 1u);
#endif  // IMPELLER_DEBUG

  // Present 17 frames on swapchain2 (exceeding kTraceStatesSize = 16).
  // If swapchain1 retained its final_cmd_buffer GPUProbe, wrapping back to
  // state 0 trips FML_DCHECK(state.pending_buffers == 0u).
  auto surface2 = CreateSurface(*context);
  auto swapchain2 = KHRSwapchainVK::Create(context, std::move(surface2),
                                           ISize(1, 1), /*enable_msaa=*/false);
  ASSERT_NE(swapchain2, nullptr);
  for (int i = 0; i < 17; ++i) {
    auto drawable2 = swapchain2->AcquireNextDrawable();
    ASSERT_NE(drawable2, nullptr);
    ASSERT_TRUE(drawable2->Present());
  }
}

}  // namespace testing
}  // namespace impeller
