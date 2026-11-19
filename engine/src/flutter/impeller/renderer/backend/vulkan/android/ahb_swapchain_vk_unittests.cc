// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "impeller/renderer/backend/vulkan/android/android_test_utils.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
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
  bool IsValid() const override { return true; }

  ASurfaceControl* GetHandle() const override { return nullptr; }

  bool RemoveFromParent() const override { return true; }
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
  auto& proc_table = GetMutableProcTable();
  auto* real_create = proc_table.ASurfaceTransaction_create.proc;
  auto* real_delete = proc_table.ASurfaceTransaction_delete.proc;
  auto* real_set_buffer = proc_table.ASurfaceTransaction_setBuffer.proc;
  auto* real_set_on_complete =
      proc_table.ASurfaceTransaction_setOnComplete.proc;
  auto* real_apply = proc_table.ASurfaceTransaction_apply.proc;
  auto* real_get_fence =
      proc_table.ASurfaceTransactionStats_getPreviousReleaseFenceFd.proc;

  struct PendingCallback {
    void* context = nullptr;
    ASurfaceTransaction_OnComplete func = nullptr;
  };
  static PendingCallback pending_callback;
  pending_callback = {};

  proc_table.ASurfaceTransaction_create.proc = []() -> ASurfaceTransaction* {
    return reinterpret_cast<ASurfaceTransaction*>(0x1);
  };
  proc_table.ASurfaceTransaction_delete.proc = [](ASurfaceTransaction*) {};
  proc_table.ASurfaceTransaction_setBuffer.proc = [](auto*, auto*, auto*,
                                                     auto) {};
  proc_table.ASurfaceTransaction_setOnComplete.proc =
      [](ASurfaceTransaction*, void* ctx, ASurfaceTransaction_OnComplete fn) {
        pending_callback = {ctx, fn};
      };
  proc_table.ASurfaceTransaction_apply.proc = [](ASurfaceTransaction*) {
    if (pending_callback.func) {
      auto cb = pending_callback;
      pending_callback = {};
      cb.func(cb.context, reinterpret_cast<ASurfaceTransactionStats*>(0x1));
    }
  };
  proc_table.ASurfaceTransactionStats_getPreviousReleaseFenceFd.proc =
      [](auto*, auto*) -> int { return -1; };

  struct RestoreProcs {
    ProcTable& table;
    decltype(real_create) create;
    decltype(real_delete) del;
    decltype(real_set_buffer) set_buffer;
    decltype(real_set_on_complete) set_on_complete;
    decltype(real_apply) apply;
    decltype(real_get_fence) get_fence;
    ~RestoreProcs() {
      table.ASurfaceTransaction_create.proc = create;
      table.ASurfaceTransaction_delete.proc = del;
      table.ASurfaceTransaction_setBuffer.proc = set_buffer;
      table.ASurfaceTransaction_setOnComplete.proc = set_on_complete;
      table.ASurfaceTransaction_apply.proc = apply;
      table.ASurfaceTransactionStats_getPreviousReleaseFenceFd.proc = get_fence;
    }
  } restore{proc_table,           real_create, real_delete,   real_set_buffer,
            real_set_on_complete, real_apply,  real_get_fence};

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

}  // namespace impeller::android::testing
