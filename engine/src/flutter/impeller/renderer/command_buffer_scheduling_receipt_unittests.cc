// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command_buffer_scheduling_receipt.h"

#include <atomic>
#include <thread>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {

TEST(CommandBufferSchedulingReceiptTest, ScheduledWakesAllWaiters) {
  auto receipt = std::make_shared<CommandBufferSchedulingReceiptState>();
  fml::CountDownLatch waiters_started(2u);
  std::atomic_size_t waiters_finished = 0u;
  auto wait = [&]() {
    waiters_started.CountDown();
    receipt->WaitUntilScheduled();
    waiters_finished++;
  };

  std::thread first(wait);
  std::thread second(wait);
  waiters_started.Wait();

  EXPECT_FALSE(receipt->IsScheduledOrTerminal());
  receipt->MarkScheduled();

  first.join();
  second.join();
  EXPECT_EQ(waiters_finished, 2u);
  EXPECT_TRUE(receipt->IsScheduledOrTerminal());
}

TEST(CommandBufferSchedulingReceiptTest, TerminalWakesWaiter) {
  auto receipt = std::make_shared<CommandBufferSchedulingReceiptState>();
  fml::CountDownLatch waiter_started(1u);
  std::thread waiter([&]() {
    waiter_started.CountDown();
    receipt->WaitUntilScheduled();
  });
  waiter_started.Wait();

  receipt->MarkTerminal();

  waiter.join();
  EXPECT_TRUE(receipt->IsScheduledOrTerminal());
}

TEST(CommandBufferSchedulingReceiptTest, NotificationsAreIdempotent) {
  auto receipt = std::make_shared<CommandBufferSchedulingReceiptState>();
  std::atomic_size_t callbacks = 0u;
  receipt->AddScheduledOrTerminalCallback([&]() { callbacks++; });

  receipt->MarkScheduled();
  receipt->MarkScheduled();
  receipt->MarkTerminal();

  EXPECT_EQ(callbacks, 1u);
  receipt->WaitUntilScheduled();
}

TEST(CommandBufferSchedulingReceiptTest,
     CallbackForSatisfiedReceiptRunsImmediately) {
  auto receipt = std::make_shared<CommandBufferSchedulingReceiptState>();
  receipt->MarkTerminal();

  bool callback_ran = false;
  receipt->AddScheduledOrTerminalCallback([&]() { callback_ran = true; });

  EXPECT_TRUE(callback_ran);
  receipt->WaitUntilScheduled();
}

}  // namespace testing
}  // namespace impeller
