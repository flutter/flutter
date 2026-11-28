// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <chrono>
#include <thread>

#include "gtest/gtest.h"

#include "impeller/renderer/backend/vulkan/android/android_test_utils.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain/ahb/ahb_swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/toolkit/android/proc_table.h"
#include "impeller/toolkit/android/surface_control.h"

namespace impeller::android::testing {

using impeller::testing::GetMockVulkanFunctions;
using impeller::testing::MockVulkanContextBuilder;

class FakeSurfaceControl : public SurfaceControl {
 public:
  bool IsValid() const override { return valid; }

  ASurfaceControl* GetHandle() const override { return nullptr; }

  bool RemoveFromParent() const override { return true; }

  bool valid = true;
};

// Mocks ASurfaceTransaction procs in the global ProcTable so FakeSurfaceControl
// (whose GetHandle() returns nullptr) does not pass null to real NDK APIs.
class ScopedMockSurfaceTransactionProcs {
 public:
  ScopedMockSurfaceTransactionProcs()
      : table_(GetMutableProcTable()),
        real_create_(table_.ASurfaceTransaction_create.proc),
        real_delete_(table_.ASurfaceTransaction_delete.proc),
        real_set_buffer_(table_.ASurfaceTransaction_setBuffer.proc),
        real_set_on_complete_(table_.ASurfaceTransaction_setOnComplete.proc),
        real_apply_(table_.ASurfaceTransaction_apply.proc),
        real_get_fence_(
            table_.ASurfaceTransactionStats_getPreviousReleaseFenceFd.proc) {
    pending_callback() = {};
    table_.ASurfaceTransaction_create.proc = []() -> ASurfaceTransaction* {
      return reinterpret_cast<ASurfaceTransaction*>(0x1);
    };
    table_.ASurfaceTransaction_delete.proc = [](ASurfaceTransaction*) {};
    table_.ASurfaceTransaction_setBuffer.proc = [](auto*, auto*, auto*, auto) {
    };
    table_.ASurfaceTransaction_setOnComplete.proc =
        [](ASurfaceTransaction*, void* ctx, ASurfaceTransaction_OnComplete fn) {
          pending_callback() = {ctx, fn};
        };
    table_.ASurfaceTransaction_apply.proc = [](ASurfaceTransaction*) {
      if (pending_callback().func) {
        auto cb = pending_callback();
        pending_callback() = {};
        cb.func(cb.context, reinterpret_cast<ASurfaceTransactionStats*>(0x1));
      }
    };
    table_.ASurfaceTransactionStats_getPreviousReleaseFenceFd.proc =
        [](auto*, auto*) -> int { return -1; };
  }

  ~ScopedMockSurfaceTransactionProcs() {
    table_.ASurfaceTransaction_create.proc = real_create_;
    table_.ASurfaceTransaction_delete.proc = real_delete_;
    table_.ASurfaceTransaction_setBuffer.proc = real_set_buffer_;
    table_.ASurfaceTransaction_setOnComplete.proc = real_set_on_complete_;
    table_.ASurfaceTransaction_apply.proc = real_apply_;
    table_.ASurfaceTransactionStats_getPreviousReleaseFenceFd.proc =
        real_get_fence_;
    pending_callback() = {};
  }

 private:
  struct PendingCallback {
    void* context = nullptr;
    ASurfaceTransaction_OnComplete func = nullptr;
  };

  static PendingCallback& pending_callback() {
    static PendingCallback callback;
    return callback;
  }

  ProcTable& table_;
  decltype(table_.ASurfaceTransaction_create.proc) real_create_;
  decltype(table_.ASurfaceTransaction_delete.proc) real_delete_;
  decltype(table_.ASurfaceTransaction_setBuffer.proc) real_set_buffer_;
  decltype(table_.ASurfaceTransaction_setOnComplete.proc) real_set_on_complete_;
  decltype(table_.ASurfaceTransaction_apply.proc) real_apply_;
  decltype(table_.ASurfaceTransactionStats_getPreviousReleaseFenceFd
               .proc) real_get_fence_;
};

TEST(AndroidAHBSwapchainTest,
     AHBSwapchainNoFenceWaitAfterAcquireNextImageFailure) {
  bool wait_for_fences_called = false;
  auto const context =
      MockVulkanContextBuilder()
          .SetDeviceExtensions(kAndroidDeviceExtensions)
          .SetAcquireNextImageCallback(
              [](VkDevice, VkSwapchainKHR, uint64_t, VkSemaphore, VkFence,
                 uint32_t*) -> VkResult { return VK_ERROR_SURFACE_LOST_KHR; })
          .SetWaitForFencesCallback([&](VkDevice, uint32_t, const VkFence*,
                                        VkBool32, uint64_t) -> VkResult {
            wait_for_fences_called = true;
            return VK_SUCCESS;
          })
          .Build();

  auto ahb_swapchain = std::shared_ptr<AHBSwapchainVK>(new AHBSwapchainVK(
      context, std::make_shared<FakeSurfaceControl>(), {}, {100, 100}, false));

  // Acquire a drawable but do not present it.
  auto image = ahb_swapchain->AcquireNextDrawable();
  EXPECT_TRUE(image);

  // Call AcquireNextDrawable again.  vkWaitForFences should not be called
  // because no command was submitted and no fences are pending.
  ahb_swapchain->AcquireNextDrawable();
  EXPECT_FALSE(wait_for_fences_called);
}

TEST(AndroidAHBSwapchainTest, AHBSwapchainDtorCallsWaitIdle) {
  const auto context = MockVulkanContextBuilder()
                           .SetDeviceExtensions(kAndroidDeviceExtensions)
                           .Build();

  auto ahb_swapchain = std::shared_ptr<AHBSwapchainVK>(new AHBSwapchainVK(
      context, std::make_shared<FakeSurfaceControl>(), {}, {100, 100}, false));

  ahb_swapchain.reset();

  auto called_functions = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_NE(std::find(called_functions->begin(), called_functions->end(),
                      "vkDeviceWaitIdle"),
            called_functions->end());
}

#ifdef IMPELLER_DEBUG
TEST(AndroidAHBSwapchainTest, TracesOnscreenCommandBufferStartAndEnd) {
  ScopedMockSurfaceTransactionProcs mock_surface_transaction;

  auto const context =
      MockVulkanContextBuilder()
          .SetDeviceExtensions(kAndroidDeviceExtensions)
          .SetSettingsCallback([](ContextVK::Settings& settings) {
            settings.enable_gpu_tracing = true;
          })
          .Build();
  ASSERT_TRUE(context->GetGPUTracer()->IsEnabled());

  auto surface_control = std::make_shared<FakeSurfaceControl>();
  auto ahb_swapchain = AHBSwapchainImplVK::Create(
      context, surface_control, {}, {100, 100}, /*enable_msaa=*/false);
  ASSERT_NE(ahb_swapchain, nullptr);
  ASSERT_TRUE(ahb_swapchain->IsValid());

  // Render 3 frames so the first frame's synchronizer slot
  // (kMaxPendingPresents == 2) is reused and its GPUProbe completes.
  for (size_t i = 0; i < 3u; ++i) {
    auto drawable = ahb_swapchain->AcquireNextDrawable();
    ASSERT_NE(drawable, nullptr);

    auto command_buffer = context->CreateCommandBuffer();
    ASSERT_NE(command_buffer, nullptr);
    VkCommandBuffer vk_cmd_buffer =
        CommandBufferVK::Cast(*command_buffer).GetCommandBuffer();

    auto render_pass =
        command_buffer->CreateRenderPass(drawable->GetRenderTarget());
    ASSERT_NE(render_pass, nullptr);
    ASSERT_TRUE(render_pass->EncodeCommands());

    ahb_swapchain->AddFinalCommandBuffer(command_buffer);
    command_buffer.reset();

    ASSERT_TRUE(drawable->Present());

    const auto& stages =
        impeller::testing::GetRecordedTimestamps(vk_cmd_buffer);
    ASSERT_EQ(stages.size(), 2u);
    EXPECT_EQ(stages[0], VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);
    EXPECT_EQ(stages[1], VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT);
  }

  ahb_swapchain.reset();

  auto query_counts =
      impeller::testing::GetQueryPoolResultCounts(context->GetDevice());
  ASSERT_EQ(query_counts.size(), 3u);
  for (uint32_t count : query_counts) {
    EXPECT_EQ(count, 2u);
  }
}
#endif  // IMPELLER_DEBUG

TEST(AndroidAHBSwapchainTest, AHBSwapchainTracksOnscreenSubmissions) {
  ScopedMockSurfaceTransactionProcs mock_surface_transaction;
  const auto context = MockVulkanContextBuilder()
                           .SetDeviceExtensions(kAndroidDeviceExtensions)
                           .Build();
  auto tracker = context->GetSubmissionTracker();
  ASSERT_NE(tracker, nullptr);
  EXPECT_EQ(tracker->LatestSubmission(), 0u);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);

  auto ahb_swapchain = std::shared_ptr<AHBSwapchainVK>(new AHBSwapchainVK(
      context, std::make_shared<FakeSurfaceControl>(), {}, {100, 100}, false));
  ASSERT_TRUE(ahb_swapchain->IsValid());

  // Frame 0: AddFinalCommandBuffer + Present() exercises
  // SubmitSignalForPresentReady and FenceWaiterVK async completion.
  auto frame0 = ahb_swapchain->AcquireNextDrawable();
  ASSERT_NE(frame0, nullptr);
  auto cmd0 = context->CreateCommandBuffer();
  ASSERT_NE(cmd0, nullptr);
  ahb_swapchain->AddFinalCommandBuffer(cmd0);
  EXPECT_EQ(tracker->LatestSubmission(), 1u);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);
  EXPECT_TRUE(frame0->Present());
  for (int i = 0; i < 100 && tracker->CompletedThrough() < 1u; ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
  }
  EXPECT_EQ(tracker->CompletedThrough(), 1u);

  // Terminate FenceWaiterVK so we also exercise the synchronous WaitForFence
  // backstop when cycling back to the same synchronizer slot.
  context->GetFenceWaiter()->Terminate();

  auto frame1 = ahb_swapchain->AcquireNextDrawable();
  ASSERT_NE(frame1, nullptr);
  auto cmd1 = context->CreateCommandBuffer();
  ASSERT_NE(cmd1, nullptr);
  ahb_swapchain->AddFinalCommandBuffer(cmd1);
  EXPECT_EQ(tracker->LatestSubmission(), 2u);
  EXPECT_EQ(tracker->CompletedThrough(), 1u);
  EXPECT_TRUE(frame1->Present());
  EXPECT_EQ(tracker->CompletedThrough(), 1u);

  auto frame2 = ahb_swapchain->AcquireNextDrawable();
  ASSERT_NE(frame2, nullptr);
  ahb_swapchain->AddFinalCommandBuffer(context->CreateCommandBuffer());
  EXPECT_TRUE(frame2->Present());

  // Cycling back to frame1's slot runs WaitForFence on a pending fence.
  auto frame3 = ahb_swapchain->AcquireNextDrawable();
  ASSERT_NE(frame3, nullptr);
  EXPECT_EQ(tracker->CompletedThrough(), 2u);

  // Presenting without AddFinalCommandBuffer must not reuse frame1's stale
  // final_cmd_buffer (which would fail or double-end an already-submitted cmd).
  EXPECT_FALSE(frame3->Present());

  ahb_swapchain.reset();
  EXPECT_EQ(tracker->CompletedThrough(), 3u);
}

TEST(AndroidAHBSwapchainTest, AHBSwapchainPresentFailureCompletesSubmission) {
  const auto context = MockVulkanContextBuilder()
                           .SetDeviceExtensions(kAndroidDeviceExtensions)
                           .Build();
  context->GetFenceWaiter()->Terminate();
  auto tracker = context->GetSubmissionTracker();
  ASSERT_NE(tracker, nullptr);

  auto surface_control = std::make_shared<FakeSurfaceControl>();
  auto ahb_swapchain = std::shared_ptr<AHBSwapchainVK>(
      new AHBSwapchainVK(context, surface_control, {}, {100, 100}, false));
  ASSERT_TRUE(ahb_swapchain->IsValid());

  auto frame0 = ahb_swapchain->AcquireNextDrawable();
  ASSERT_NE(frame0, nullptr);
  ahb_swapchain->AddFinalCommandBuffer(context->CreateCommandBuffer());
  EXPECT_EQ(tracker->LatestSubmission(), 1u);
  EXPECT_EQ(tracker->CompletedThrough(), 0u);

  // Invalidating the surface control makes Present() fail before Queue::Submit,
  // which must immediately complete the pending submission.
  surface_control->valid = false;
  EXPECT_FALSE(frame0->Present());
  EXPECT_EQ(tracker->CompletedThrough(), 1u);
}

}  // namespace impeller::android::testing
