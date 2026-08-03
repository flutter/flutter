// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/testing/testing.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/metal/allocator_mtl.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/capabilities.h"

#include <QuartzCore/CAMetalLayer.h>
#include <atomic>
#include <memory>
#include <thread>

#include "gtest/gtest.h"

namespace impeller {
namespace testing {

namespace {

class BlockingSchedulingReceipt final : public CommandBufferSchedulingReceipt {
 public:
  explicit BlockingSchedulingReceipt(
      fml::CountDownLatch* any_wait_started = nullptr)
      : any_wait_started_(any_wait_started) {}

  void WaitUntilScheduled() const override {
    wait_count_++;
    if (any_wait_started_) {
      any_wait_started_->CountDown();
    }
    wait_started_.Signal();
    state_.WaitUntilScheduled();
  }

  bool IsScheduledOrTerminal() const override {
    return state_.IsScheduledOrTerminal();
  }

  void AddScheduledOrTerminalCallback(fml::closure callback) override {
    state_.AddScheduledOrTerminalCallback(std::move(callback));
  }

  void MarkScheduled() { state_.MarkScheduled(); }

  void MarkTerminal() { state_.MarkTerminal(); }

  void WaitForWaitCall() { wait_started_.Wait(); }

  size_t GetWaitCount() const { return wait_count_; }

 private:
  fml::CountDownLatch* const any_wait_started_;
  CommandBufferSchedulingReceiptState state_;
  mutable std::atomic_size_t wait_count_ = 0u;
  mutable fml::ManualResetWaitableEvent wait_started_;
};

}  // namespace

using ContextMTLTest = PlaygroundTest;
INSTANTIATE_METAL_PLAYGROUND_SUITE(ContextMTLTest);

TEST_P(ContextMTLTest, FlushTask) {
  auto& context_mtl = ContextMTL::Cast(*GetContext());

  int executed = 0;
  int failed = 0;
  context_mtl.StoreTaskForGPU([&]() { executed++; }, [&]() { failed++; });

  context_mtl.FlushTasksAwaitingGPU();

  EXPECT_EQ(executed, 1);
  EXPECT_EQ(failed, 0);
}

TEST_P(ContextMTLTest, FlushTaskWithGPULoss) {
  auto& context_mtl = ContextMTL::Cast(*GetContext());

  int executed = 0;
  int failed = 0;
  context_mtl.StoreTaskForGPU([&]() { executed++; }, [&]() { failed++; });

  // If tasks are flushed while the GPU is disabled, then
  // they should not be executed.
  SetGPUDisabled(/*disabled=*/true);
  context_mtl.FlushTasksAwaitingGPU();

  EXPECT_EQ(executed, 0);
  EXPECT_EQ(failed, 0);

  // Toggling availibility should flush tasks.
  SetGPUDisabled(/*disabled=*/false);

  EXPECT_EQ(executed, 1);
  EXPECT_EQ(failed, 0);
}

TEST_P(ContextMTLTest, SubmissionReturnsSchedulingReceipt) {
  const std::shared_ptr<Context>& context = GetContext();
  std::shared_ptr<CommandBuffer> command_buffer =
      context->CreateCommandBuffer();
  ASSERT_NE(command_buffer, nullptr);
  std::atomic<CommandBuffer::Status> completion_status =
      CommandBuffer::Status::kPending;
  fml::ManualResetWaitableEvent completed;

  CommandQueue::SubmitResult result =
      context->GetCommandQueue()->SubmitWithReceipt(
          command_buffer, [&](CommandBuffer::Status status) {
            completion_status = status;
            completed.Signal();
          });

  ASSERT_TRUE(result.status.ok());
  ASSERT_NE(result.scheduling_receipt, nullptr);
  fml::ManualResetWaitableEvent satisfied;
  result.scheduling_receipt->AddScheduledOrTerminalCallback(
      [&]() { satisfied.Signal(); });
  EXPECT_FALSE(satisfied.WaitWithTimeout(fml::TimeDelta::FromSeconds(5.0)));
  result.scheduling_receipt->WaitUntilScheduled();
  EXPECT_FALSE(completed.WaitWithTimeout(fml::TimeDelta::FromSeconds(5.0)));
  EXPECT_EQ(completion_status.load(), CommandBuffer::Status::kCompleted);
}

TEST_P(ContextMTLTest, GpuDisableWaitsForAllPendingImageUploads) {
  auto& context_mtl = ContextMTL::Cast(*GetContext());
  fml::CountDownLatch any_wait_started(1u);
  auto scheduled_receipt =
      std::make_shared<BlockingSchedulingReceipt>(&any_wait_started);
  auto terminal_receipt =
      std::make_shared<BlockingSchedulingReceipt>(&any_wait_started);
  context_mtl.TrackPendingImageUpload(scheduled_receipt);
  context_mtl.TrackPendingImageUpload(terminal_receipt);

  fml::ManualResetWaitableEvent transition_started;
  fml::ManualResetWaitableEvent transition_returned;
  std::thread disable_thread([&]() {
    transition_started.Signal();
    SetGPUDisabled(/*disabled=*/true);
    transition_returned.Signal();
  });
  transition_started.Wait();
  any_wait_started.Wait();

  EXPECT_FALSE(transition_returned.IsSignaledForTest());
  // The tracker snapshots both receipts before its first wait. Satisfying them
  // through both terminal paths verifies that the transition drains the full
  // snapshot even when the receipts finish out of order.
  terminal_receipt->MarkTerminal();
  scheduled_receipt->MarkScheduled();

  disable_thread.join();
  EXPECT_TRUE(transition_returned.IsSignaledForTest());
  EXPECT_EQ(scheduled_receipt->GetWaitCount(), 1u);
  EXPECT_EQ(terminal_receipt->GetWaitCount(), 1u);
}

TEST_P(ContextMTLTest, DisableCannotMissReceiptRegistration) {
  auto& context_mtl = ContextMTL::Cast(*GetContext());
  const std::shared_ptr<const fml::SyncSwitch> gpu_disabled_switch =
      context_mtl.GetIsGpuDisabledSyncSwitch();
  auto receipt = std::make_shared<BlockingSchedulingReceipt>();
  fml::ManualResetWaitableEvent upload_handler_entered;
  fml::ManualResetWaitableEvent allow_registration;
  fml::ManualResetWaitableEvent disable_started;
  fml::ManualResetWaitableEvent disable_returned;

  std::thread upload_thread([&]() {
    gpu_disabled_switch->Execute(fml::SyncSwitch::Handlers().SetIfFalse([&]() {
      upload_handler_entered.Signal();
      allow_registration.Wait();
      context_mtl.TrackPendingImageUpload(receipt);
    }));
  });
  upload_handler_entered.Wait();

  std::thread disable_thread([&]() {
    disable_started.Signal();
    SetGPUDisabled(/*disabled=*/true);
    disable_returned.Signal();
  });
  disable_started.Wait();

  // SetSwitch cannot acquire its unique lock while the enabled upload handler
  // holds the shared lock, so it cannot notify the observer before this
  // registration completes.
  EXPECT_FALSE(disable_returned.IsSignaledForTest());
  allow_registration.Signal();
  upload_thread.join();
  receipt->WaitForWaitCall();
  EXPECT_FALSE(disable_returned.IsSignaledForTest());

  receipt->MarkTerminal();
  disable_thread.join();
  EXPECT_TRUE(disable_returned.IsSignaledForTest());
  EXPECT_EQ(receipt->GetWaitCount(), 1u);
}

TEST_P(ContextMTLTest, RepeatedGpuDisableDoesNotWaitOnSatisfiedReceipt) {
  auto& context_mtl = ContextMTL::Cast(*GetContext());
  auto receipt = std::make_shared<BlockingSchedulingReceipt>();
  receipt->MarkScheduled();
  context_mtl.TrackPendingImageUpload(receipt);

  SetGPUDisabled(/*disabled=*/true);
  SetGPUDisabled(/*disabled=*/true);
  EXPECT_EQ(receipt->GetWaitCount(), 0u);
}

}  // namespace testing
}  // namespace impeller
