// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/pending_image_upload_schedule_tracker.h"

#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {
namespace {

class TestSchedulingReceipt final : public CommandBufferSchedulingReceipt {
 public:
  /// When `satisfy_when_waited` is true, waiting satisfies the receipt before
  /// blocking.
  explicit TestSchedulingReceipt(bool satisfy_when_waited = false)
      : satisfy_when_waited_(satisfy_when_waited) {}

  void WaitUntilScheduled() override {
    wait_count_++;
    wait_started_.Signal();
    if (satisfy_when_waited_) {
      Satisfy();
    }
    satisfied_event_.Wait();
  }

  bool IsScheduledOrTerminal() const override {
    std::scoped_lock lock(mutex_);
    return satisfied_;
  }

  void AddScheduledOrTerminalCallback(fml::closure callback) override {
    bool run_now = false;
    {
      std::scoped_lock lock(mutex_);
      if (satisfied_) {
        run_now = true;
      } else {
        callbacks_.push_back(std::move(callback));
      }
    }
    if (run_now) {
      callback();
    }
  }

  void Satisfy() {
    std::vector<fml::closure> callbacks;
    {
      std::scoped_lock lock(mutex_);
      if (satisfied_) {
        return;
      }
      satisfied_ = true;
      callbacks.swap(callbacks_);
    }
    satisfied_event_.Signal();
    for (const auto& callback : callbacks) {
      callback();
    }
  }

  void WaitForWaitCall() { wait_started_.Wait(); }

  size_t GetWaitCount() const { return wait_count_; }

 private:
  const bool satisfy_when_waited_;
  mutable std::mutex mutex_;
  bool satisfied_ = false;
  std::vector<fml::closure> callbacks_;
  fml::ManualResetWaitableEvent wait_started_;
  fml::ManualResetWaitableEvent satisfied_event_;
  std::atomic_size_t wait_count_ = 0u;
};

}  // namespace

TEST(PendingImageUploadScheduleTrackerTest, TrackDoesNotWait) {
  PendingImageUploadScheduleTracker tracker;
  auto receipt = std::make_shared<TestSchedulingReceipt>();

  tracker.Track(receipt);

  EXPECT_EQ(receipt->GetWaitCount(), 0u);
  EXPECT_EQ(tracker.GetPendingCount(), 1u);
  receipt->Satisfy();
  EXPECT_EQ(tracker.GetPendingCount(), 0u);
}

TEST(PendingImageUploadScheduleTrackerTest, SatisfiedBeforeTrackIsNotRetained) {
  PendingImageUploadScheduleTracker tracker;
  auto receipt = std::make_shared<TestSchedulingReceipt>();
  receipt->Satisfy();

  tracker.Track(receipt);

  EXPECT_EQ(tracker.GetPendingCount(), 0u);
  EXPECT_EQ(receipt->GetWaitCount(), 0u);
}

TEST(PendingImageUploadScheduleTrackerTest, WaitsForAllReceipts) {
  PendingImageUploadScheduleTracker tracker;
  auto first = std::make_shared<TestSchedulingReceipt>();
  auto second = std::make_shared<TestSchedulingReceipt>();
  tracker.Track(first);
  tracker.Track(second);

  second->Satisfy();
  fml::ManualResetWaitableEvent drain_returned;
  std::thread drain([&]() {
    tracker.WaitUntilScheduled();
    drain_returned.Signal();
  });
  first->WaitForWaitCall();

  EXPECT_FALSE(drain_returned.IsSignaledForTest());
  first->Satisfy();

  drain.join();
  EXPECT_EQ(tracker.GetPendingCount(), 0u);
  EXPECT_EQ(first->GetWaitCount(), 1u);
}

TEST(PendingImageUploadScheduleTrackerTest, DoesNotWaitWhileHoldingMutex) {
  PendingImageUploadScheduleTracker tracker;
  auto receipt = std::make_shared<TestSchedulingReceipt>(
      /*satisfy_when_waited=*/true);
  tracker.Track(receipt);

  tracker.WaitUntilScheduled();

  EXPECT_EQ(tracker.GetPendingCount(), 0u);
  EXPECT_EQ(receipt->GetWaitCount(), 1u);
}

TEST(PendingImageUploadScheduleTrackerTest,
     CallbackIsSafeAfterTrackerDestruction) {
  auto receipt = std::make_shared<TestSchedulingReceipt>();
  {
    PendingImageUploadScheduleTracker tracker;
    tracker.Track(receipt);
    EXPECT_EQ(tracker.GetPendingCount(), 1u);
  }

  receipt->Satisfy();
  EXPECT_TRUE(receipt->IsScheduledOrTerminal());
}

}  // namespace testing
}  // namespace impeller
