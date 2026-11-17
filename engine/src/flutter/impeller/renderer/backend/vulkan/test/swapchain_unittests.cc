// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <chrono>
#include <thread>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
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

  auto query_counts = GetQueryPoolResultCounts(context->GetDevice());
  ASSERT_EQ(query_counts.size(), 3u);
  for (uint32_t count : query_counts) {
    EXPECT_EQ(count, 2u);
  }
}
#endif  // IMPELLER_DEBUG

TEST(SwapchainTest, TracksOnscreenSubmissions) {
  auto const context = MockVulkanContextBuilder().Build();
  auto tracker = context->GetSubmissionTracker();
  ASSERT_NE(tracker, nullptr);
  EXPECT_EQ(tracker->LatestSubmission(), 0u);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);

  auto surface = CreateSurface(*context);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1});
  ASSERT_TRUE(swapchain->IsValid());

  // Frame 0: SubmitOnscreen records a pending submission before Present().
  auto frame0 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame0, nullptr);
  auto cmd0 = context->CreateCommandBuffer();
  ASSERT_NE(cmd0, nullptr);
  swapchain->AddFinalCommandBuffer(cmd0);
  EXPECT_EQ(tracker->LatestSubmission(), 1u);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);
  EXPECT_TRUE(frame0->Present());

  // Even without acquiring another frame on this swapchain, FenceWaiterVK
  // completes the submission asynchronously.
  for (int i = 0; i < 100 && tracker->CompletedThrough() < 1u; ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
  }
  EXPECT_EQ(tracker->CompletedThrough(), 1u);

  // Terminate FenceWaiterVK so we can also verify the synchronous teardown
  // backstop when a pending submission outlives the swapchain.
  context->GetFenceWaiter()->Terminate();

  auto frame1 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame1, nullptr);
  auto cmd1 = context->CreateCommandBuffer();
  ASSERT_NE(cmd1, nullptr);
  swapchain->AddFinalCommandBuffer(cmd1);
  EXPECT_EQ(tracker->LatestSubmission(), 2u);
  EXPECT_EQ(tracker->CompletedThrough(), 1u);
  EXPECT_TRUE(frame1->Present());
  EXPECT_EQ(tracker->CompletedThrough(), 1u);

  // Destroying the swapchain completes any remaining pending submission (2).
  swapchain.reset();
  EXPECT_EQ(tracker->CompletedThrough(), 2u);
}

TEST(SwapchainTest, WaitForFenceFailureDoesNotCompleteSubmission) {
  VkResult wait_result = VK_SUCCESS;
  auto const context =
      MockVulkanContextBuilder()
          .SetWaitForFencesCallback(
              [&](VkDevice, uint32_t, const VkFence*, VkBool32,
                  uint64_t) -> VkResult { return wait_result; })
          .Build();
  context->GetFenceWaiter()->Terminate();
  auto tracker = context->GetSubmissionTracker();
  ASSERT_NE(tracker, nullptr);

  auto surface = CreateSurface(*context);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1});
  ASSERT_TRUE(swapchain->IsValid());

  auto frame0 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame0, nullptr);
  swapchain->AddFinalCommandBuffer(context->CreateCommandBuffer());
  EXPECT_EQ(tracker->LatestSubmission(), 1u);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);
  EXPECT_TRUE(frame0->Present());
  EXPECT_EQ(tracker->CompletedThrough(), 0u);

  auto frame1 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame1, nullptr);
  EXPECT_TRUE(frame1->Present());

  // Next acquire cycles back to slot 0; if WaitForFence fails, submission 1
  // must stay pending until teardown.
  wait_result = VK_ERROR_DEVICE_LOST;
  EXPECT_EQ(swapchain->AcquireNextDrawable(), nullptr);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);

  swapchain.reset();
  EXPECT_EQ(tracker->CompletedThrough(), 1u);
}

TEST(SwapchainTest, SurfaceContextSubmitOnscreenRetiresHostBuffer) {
  class TestDeviceBuffer final : public DeviceBuffer {
   public:
    explicit TestDeviceBuffer(DeviceBufferDescriptor desc)
        : DeviceBuffer(desc), contents_(desc.size, 0) {}

    bool SetLabel(std::string_view label) override { return true; }
    bool SetLabel(std::string_view label, Range range) override { return true; }
    uint8_t* OnGetContents() const override {
      return const_cast<uint8_t*>(contents_.data());
    }
    bool OnCopyHostBuffer(const uint8_t* source,
                          Range source_range,
                          size_t offset) override {
      return true;
    }

   private:
    std::vector<uint8_t> contents_;
  };

  class TestAllocator final : public Allocator {
   public:
    ISize GetMaxTextureSizeSupported() const override { return {1024, 1024}; }
    std::shared_ptr<DeviceBuffer> OnCreateBuffer(
        const DeviceBufferDescriptor& desc) override {
      auto buffer = std::make_shared<TestDeviceBuffer>(desc);
      allocated_buffers.emplace_back(buffer);
      return buffer;
    }
    std::shared_ptr<Texture> OnCreateTexture(const TextureDescriptor& desc,
                                             bool threadsafe) override {
      return nullptr;
    }

    std::vector<std::weak_ptr<DeviceBuffer>> allocated_buffers;
  };

  auto const context = MockVulkanContextBuilder().Build();
  auto surface = CreateSurface(*context);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1});
  ASSERT_TRUE(swapchain->IsValid());

  SurfaceContextVK surface_context(context);
  ASSERT_TRUE(surface_context.SetSwapchain(swapchain));

  auto allocator = std::make_shared<TestAllocator>();
  auto host_buffer =
      HostBuffer::Create(allocator, surface_context.GetIdleWaiter(), 256,
                         surface_context.GetSubmissionTracker());

  // Onscreen frame records submission before HostBuffer::Reset() stamps slot 0.
  auto frame0 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame0, nullptr);
  ASSERT_TRUE(surface_context.SubmitOnscreen(context->CreateCommandBuffer()));
  auto original_slot0 = host_buffer->Emplace(nullptr, 16, 4).GetBuffer();
  ASSERT_NE(original_slot0, nullptr);
  std::weak_ptr<DeviceBuffer> original_slot0_weak;
  for (const auto& weak : allocator->allocated_buffers) {
    if (auto locked = weak.lock(); locked.get() == original_slot0) {
      original_slot0_weak = weak;
      break;
    }
  }
  ASSERT_FALSE(original_slot0_weak.expired());
  host_buffer->Reset();

  // Rapid offscreen resets wrap back to slot 0 while onscreen is pending;
  // HostBuffer must retire/replace slot 0 instead of reusing original_slot0.
  for (size_t i = 0; i < kHostBufferArenaSize - 1; ++i) {
    host_buffer->Reset();
  }
  EXPECT_NE(host_buffer->Emplace(nullptr, 16, 4).GetBuffer(), original_slot0);
  EXPECT_FALSE(original_slot0_weak.expired());

  // Presenting triggers FenceWaiterVK to advance CompletedThrough() without
  // another AcquireNextDrawable(), allowing the next Reset() to reclaim the
  // retired slot 0 buffer.
  EXPECT_TRUE(frame0->Present());
  auto tracker = context->GetSubmissionTracker();
  for (int i = 0; i < 100 && tracker->CompletedThrough() < 1u; ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
  }
  EXPECT_GE(tracker->CompletedThrough(), 1u);
  host_buffer->Reset();
  EXPECT_TRUE(original_slot0_weak.expired());
}

TEST(SwapchainTest, PresentFailureCompletesSubmission) {
  auto const context = MockVulkanContextBuilder().Build();
  context->GetFenceWaiter()->Terminate();
  auto tracker = context->GetSubmissionTracker();
  ASSERT_NE(tracker, nullptr);

  auto surface = CreateSurface(*context);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1});
  ASSERT_TRUE(swapchain->IsValid());

  // Passing a null final command buffer makes Present() fail before
  // Queue::Submit, which must still complete the pending submission.
  auto frame0 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame0, nullptr);
  swapchain->AddFinalCommandBuffer(nullptr);
  EXPECT_EQ(tracker->LatestSubmission(), 1u);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);
  EXPECT_FALSE(frame0->Present());
  EXPECT_EQ(tracker->CompletedThrough(), 1u);

  // Subsequent Present() without AddFinalCommandBuffer must not reuse stale
  // onscreen state or record a new submission.
  auto frame1 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame1, nullptr);
  EXPECT_TRUE(frame1->Present());
  EXPECT_EQ(tracker->LatestSubmission(), 1u);
}

TEST(SwapchainTest, PresentUsesAcquiredFrameSlot) {
  auto const context = MockVulkanContextBuilder().Build();
  context->GetFenceWaiter()->Terminate();
  auto tracker = context->GetSubmissionTracker();
  ASSERT_NE(tracker, nullptr);

  auto surface = CreateSurface(*context);
  auto swapchain =
      KHRSwapchainVK::Create(context, std::move(surface), ISize{1, 1});
  ASSERT_TRUE(swapchain->IsValid());

  auto frame0 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame0, nullptr);
  swapchain->AddFinalCommandBuffer(context->CreateCommandBuffer());

  // Acquire frame1 before frame0->Present() advances current_frame_ to slot 1.
  auto frame1 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame1, nullptr);
  swapchain->AddFinalCommandBuffer(context->CreateCommandBuffer());

  EXPECT_TRUE(frame0->Present());
  EXPECT_TRUE(frame1->Present());
  EXPECT_EQ(tracker->CompletedThrough(), 0u);

  // Cycling back to slot 0 waits on frame0's fence and completes id 1.
  auto frame2 = swapchain->AcquireNextDrawable();
  ASSERT_NE(frame2, nullptr);
  EXPECT_EQ(tracker->CompletedThrough(), 1u);

  swapchain.reset();
  EXPECT_EQ(tracker->CompletedThrough(), 2u);
}

}  // namespace testing
}  // namespace impeller
