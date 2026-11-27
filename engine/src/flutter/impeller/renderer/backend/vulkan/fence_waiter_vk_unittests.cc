// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <atomic>

#include "fml/synchronization/waitable_event.h"
#include "gtest/gtest.h"  // IWYU pragma: keep
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"  // IWYU pragma: keep
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

namespace {
auto default_submit_callback = [](vk::Fence) { return absl::OkStatus(); };
}  // namespace

TEST(FenceWaiterVKTest, IgnoresNullFence) {
  auto const context = MockVulkanContextBuilder().Build();
  auto const waiter = context->GetFenceWaiter();
  const auto add_status =
      waiter->AddFence(vk::UniqueFence(), default_submit_callback, [](bool) {});
  EXPECT_EQ(add_status.code(), absl::StatusCode::kInvalidArgument);
}

TEST(FenceWaiterVKTest, IgnoresNullCallback) {
  auto const context = MockVulkanContextBuilder().Build();
  auto const device = context->GetDevice();
  auto const waiter = context->GetFenceWaiter();

  auto fence = device.createFenceUnique({}).value;
  const auto add_status =
      waiter->AddFence(std::move(fence), default_submit_callback, nullptr);
  EXPECT_EQ(add_status.code(), absl::StatusCode::kInvalidArgument);
}

TEST(FenceWaiterVKTest, ReturnsSubmitError) {
  auto const context = MockVulkanContextBuilder().Build();
  auto const device = context->GetDevice();
  auto const waiter = context->GetFenceWaiter();

  auto submit_callback = [&](vk::Fence) {
    return absl::Status(absl::StatusCode::kCancelled, "Submit failed");
  };

  auto fence = device.createFenceUnique({}).value;
  const auto add_status =
      waiter->AddFence(std::move(fence), submit_callback, [](bool) {});
  EXPECT_EQ(add_status.code(), absl::StatusCode::kCancelled);
}

TEST(FenceWaiterVKTest, ExecutesFenceCallback) {
  auto const context = MockVulkanContextBuilder().Build();
  auto const device = context->GetDevice();
  auto const waiter = context->GetFenceWaiter();

  bool submit_called = false;
  auto submit_callback = [&](vk::Fence) {
    submit_called = true;
    return absl::OkStatus();
  };

  auto signal = fml::ManualResetWaitableEvent();
  auto fence = device.createFenceUnique({}).value;
  EXPECT_TRUE(waiter
                  ->AddFence(std::move(fence), submit_callback,
                             [&signal](bool signaled) {
                               EXPECT_TRUE(signaled);
                               signal.Signal();
                             })
                  .ok());
  EXPECT_TRUE(submit_called);

  signal.Wait();
}

TEST(FenceWaiterVKTest, ExecutesFenceCallbackX2) {
  auto const context = MockVulkanContextBuilder().Build();
  auto const device = context->GetDevice();
  auto const waiter = context->GetFenceWaiter();

  auto signal = fml::ManualResetWaitableEvent();
  auto fence = device.createFenceUnique({}).value;
  EXPECT_TRUE(waiter
                  ->AddFence(std::move(fence), default_submit_callback,
                             [&signal](bool signaled) {
                               EXPECT_TRUE(signaled);
                               signal.Signal();
                             })
                  .ok());

  auto signal2 = fml::ManualResetWaitableEvent();
  auto fence2 = device.createFenceUnique({}).value;
  EXPECT_TRUE(waiter
                  ->AddFence(std::move(fence2), default_submit_callback,
                             [&signal2](bool signaled) {
                               EXPECT_TRUE(signaled);
                               signal2.Signal();
                             })
                  .ok());

  signal.Wait();
  signal2.Wait();
}

TEST(FenceWaiterVKTest, ExecutesNewFenceThenOldFence) {
  auto const context = MockVulkanContextBuilder().Build();
  auto const device = context->GetDevice();
  auto const waiter = context->GetFenceWaiter();

  auto signal = fml::ManualResetWaitableEvent();
  auto fence = device.createFenceUnique({}).value;
  MockFence::SetStatus(fence, vk::Result::eNotReady);
  auto raw_fence = MockFence::GetRawPointer(fence);
  EXPECT_TRUE(waiter
                  ->AddFence(std::move(fence), default_submit_callback,
                             [&signal](bool signaled) {
                               EXPECT_TRUE(signaled);
                               signal.Signal();
                             })
                  .ok());

  // The easiest way to verify that the callback was _not_ called is to wait
  // for a timeout, but that could introduce flakiness. Instead, we'll add a
  // second fence that will signal immediately, and wait for that one instead.
  {
    auto signal2 = fml::ManualResetWaitableEvent();
    auto fence2 = device.createFenceUnique({}).value;
    MockFence::SetStatus(fence2, vk::Result::eSuccess);
    EXPECT_TRUE(waiter
                    ->AddFence(std::move(fence2), default_submit_callback,
                               [&signal2](bool signaled) {
                                 EXPECT_TRUE(signaled);
                                 signal2.Signal();
                               })
                    .ok());
    signal2.Wait();
  }

  // Now, we'll signal the first fence, and wait for the callback to be called.
  raw_fence->SetStatus(vk::Result::eSuccess);

  // Now, we'll signal the first fence, and wait for the callback to be called.
  signal.Wait();
}

TEST(FenceWaiterVKTest, DeviceLossFailsAllAcceptedSubmissions) {
  fml::ManualResetWaitableEvent waiting;
  fml::ManualResetWaitableEvent release_wait;
  fml::AutoResetWaitableEvent both_failed;
  std::array<std::atomic_int, 3> calls = {};
  std::atomic_int failures = 0;
  std::atomic_bool drained_both = false;
  const auto deadline = fml::TimeDelta::FromSeconds(5);
  auto context =
      MockVulkanContextBuilder()
          .SetWaitForFencesCallback([&](VkDevice, uint32_t count,
                                        const VkFence*, VkBool32 wait_all,
                                        uint64_t) -> VkResult {
            if (wait_all) {
              drained_both = count == 2u;
              EXPECT_EQ(count, 2u);
            } else {
              waiting.Signal();
              EXPECT_FALSE(release_wait.WaitWithTimeout(deadline));
            }
            return VK_ERROR_DEVICE_LOST;
          })
          .Build();
  ASSERT_TRUE(context);
  auto queue = context->GetCommandQueue();
  auto tracker = context->GetSubmissionTracker();
  const auto before = tracker->LatestSubmission();
  auto submit = [&](size_t index) {
    return queue->Submit({context->CreateCommandBuffer()},
                         [&, index](auto status) {
                           EXPECT_EQ(status, CommandBuffer::Status::kError);
                           ++calls[index];
                           if (++failures == 2) {
                             both_failed.Signal();
                           }
                         });
  };
  ASSERT_TRUE(submit(0).ok());
  ASSERT_FALSE(waiting.WaitWithTimeout(deadline));
  // Submit another command while the waiter is examining only the first.
  ASSERT_TRUE(submit(1).ok());
  release_wait.Signal();
  EXPECT_FALSE(both_failed.WaitWithTimeout(deadline));
  EXPECT_TRUE(drained_both.load());
  EXPECT_EQ(tracker->CompletedThrough(), before + 2);
  EXPECT_FALSE(submit(2).ok());
  context->Shutdown();
  for (const auto& count : calls) {
    EXPECT_EQ(count.load(), 1);
  }
  EXPECT_EQ(tracker->CompletedThrough(), tracker->LatestSubmission());
}

TEST(FenceWaiterVKTest, FenceStatusCanReportDeviceLoss) {
  fml::AutoResetWaitableEvent completed;
  auto context = MockVulkanContextBuilder().Build();
  auto fence = context->GetDevice().createFenceUnique({}).value;
  MockFence::SetStatus(fence, vk::Result::eErrorDeviceLost);
  ASSERT_TRUE(context->GetFenceWaiter()
                  ->AddFence(std::move(fence), default_submit_callback,
                             [&](bool signaled) {
                               EXPECT_FALSE(signaled);
                               completed.Signal();
                             })
                  .ok());
  EXPECT_FALSE(completed.WaitWithTimeout(fml::TimeDelta::FromSeconds(5)));
  context->Shutdown();
}

TEST(FenceWaiterVKTest, TransientWaitErrorPreservesAnUnsignaledFence) {
  fml::AutoResetWaitableEvent completed;
  std::atomic_int waits = 0;
  auto context = MockVulkanContextBuilder()
                     .SetWaitForFencesCallback(
                         [&](VkDevice, uint32_t count, const VkFence* fences,
                             VkBool32, uint64_t) -> VkResult {
                           if (++waits == 1) {
                             return VK_ERROR_OUT_OF_HOST_MEMORY;
                           }
                           EXPECT_EQ(count, 1u);
                           reinterpret_cast<MockFence*>(fences[0])->SetStatus(
                               vk::Result::eSuccess);
                           return VK_SUCCESS;
                         })
                     .Build();
  auto fence = context->GetDevice().createFenceUnique({}).value;
  MockFence::SetStatus(fence, vk::Result::eNotReady);
  ASSERT_TRUE(context->GetFenceWaiter()
                  ->AddFence(std::move(fence), default_submit_callback,
                             [&](bool signaled) {
                               EXPECT_TRUE(signaled);
                               completed.Signal();
                             })
                  .ok());
  EXPECT_FALSE(completed.WaitWithTimeout(fml::TimeDelta::FromSeconds(5)));
  context->Shutdown();
  EXPECT_GE(waits.load(), 2);
}

TEST(FenceWaiterVKTest, AddFenceDoesNothingIfTerminating) {
  auto signal = fml::ManualResetWaitableEvent();

  {
    auto const context = MockVulkanContextBuilder().Build();
    auto const device = context->GetDevice();
    auto const waiter = context->GetFenceWaiter();
    waiter->Terminate();

    auto fence = device.createFenceUnique({}).value;
    absl::Status status = waiter->AddFence(
        std::move(fence), default_submit_callback, [&signal](bool signaled) {
          EXPECT_TRUE(signaled);
          signal.Signal();
        });
    EXPECT_EQ(status.code(), absl::StatusCode::kCancelled);
  }

  // Ensure the fence did _not_ signal.
  EXPECT_TRUE(signal.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(100)));
}

TEST(FenceWaiterVKTest, InProgressFencesStillWaitIfTerminated) {
  MockFence* raw_fence = nullptr;
  auto signal = fml::ManualResetWaitableEvent();

  auto const context = MockVulkanContextBuilder().Build();
  auto const device = context->GetDevice();
  auto const waiter = context->GetFenceWaiter();

  // Add a fence that isn't signalled yet.
  auto fence = device.createFenceUnique({}).value;

  // Even if the fence is eSuccess, it's not guaranteed to be called in time.
  MockFence::SetStatus(fence, vk::Result::eNotReady);
  raw_fence = MockFence::GetRawPointer(fence);
  EXPECT_TRUE(waiter
                  ->AddFence(std::move(fence), default_submit_callback,
                             [&signal](bool signaled) {
                               EXPECT_TRUE(signaled);
                               signal.Signal();
                             })
                  .ok());

  // Signal the fence after a delay.
  std::thread thread([&]() {
    std::this_thread::sleep_for(std::chrono::milliseconds{100u});
    raw_fence->SetStatus(vk::Result::eSuccess);
  });

  // Terminate the waiter.  This will block until all pending fences are
  // signalled.
  waiter->Terminate();

  // This will hang if the fence was not signalled.
  signal.Wait();

  thread.join();
}

}  // namespace testing
}  // namespace impeller
