// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/waitable_event.h"

#include <stdint.h>
#include <stdlib.h>

#include <atomic>
#include <thread>
#include <type_traits>
#include <vector>

#include "mojo/edk/platform/test_stopwatch.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::test::Stopwatch;
using mojo::platform::ThreadSleep;
using mojo::system::test::ActionTimeout;
using mojo::system::test::DeadlineFromMilliseconds;
using mojo::system::test::EpsilonTimeout;
using mojo::system::test::TinyTimeout;

namespace mojo {
namespace util {
namespace {

// Sleeps for a "very small" amount of time.
void EpsilonRandomSleep() {
  ThreadSleep(DeadlineFromMilliseconds(static_cast<unsigned>(rand()) % 20u));
}

// We'll use |MojoDeadline| with |uint64_t| (for |WaitWithTimeout()|'s timeout
// argument), though note that |WaitWithTimeout()| doesn't support
// |MOJO_DEADLINE_INDEFINITE|.
static_assert(std::is_same<uint64_t, MojoDeadline>::value,
              "MojoDeadline isn't uint64_t!");

// AutoResetWaitableEvent ------------------------------------------------------

TEST(AutoResetWaitableEventTest, Basic) {
  AutoResetWaitableEvent ev;
  EXPECT_FALSE(ev.IsSignaledForTest());
  ev.Signal();
  EXPECT_TRUE(ev.IsSignaledForTest());
  ev.Wait();
  EXPECT_FALSE(ev.IsSignaledForTest());
  ev.Reset();
  EXPECT_FALSE(ev.IsSignaledForTest());
  ev.Signal();
  EXPECT_TRUE(ev.IsSignaledForTest());
  ev.Reset();
  EXPECT_FALSE(ev.IsSignaledForTest());
  EXPECT_TRUE(ev.WaitWithTimeout(0));
  EXPECT_FALSE(ev.IsSignaledForTest());
  EXPECT_TRUE(ev.WaitWithTimeout(DeadlineFromMilliseconds(1)));
  EXPECT_FALSE(ev.IsSignaledForTest());
  ev.Signal();
  EXPECT_TRUE(ev.IsSignaledForTest());
  EXPECT_FALSE(ev.WaitWithTimeout(0));
  EXPECT_FALSE(ev.IsSignaledForTest());
  EXPECT_TRUE(ev.WaitWithTimeout(DeadlineFromMilliseconds(1)));
  EXPECT_FALSE(ev.IsSignaledForTest());
  ev.Signal();
  EXPECT_FALSE(ev.WaitWithTimeout(DeadlineFromMilliseconds(1)));
  EXPECT_FALSE(ev.IsSignaledForTest());
}

TEST(AutoResetWaitableEventTest, MultipleWaiters) {
  AutoResetWaitableEvent ev;

  for (size_t i = 0u; i < 5u; i++) {
    std::atomic_uint wake_count(0u);
    std::vector<std::thread> threads;
    for (size_t j = 0u; j < 4u; j++) {
      threads.push_back(std::thread([&ev, &wake_count]() {
        if (rand() % 2 == 0)
          ev.Wait();
        else
          EXPECT_FALSE(ev.WaitWithTimeout(ActionTimeout()));
        wake_count.fetch_add(1u);
        // Note: We can't say anything about the signaled state of |ev| here,
        // since the main thread may have already signaled it again.
      }));
    }

    // Unfortunately, we can't really wait for the threads to be waiting, so we
    // just sleep for a bit, and count on them having started and advanced to
    // waiting.
    ThreadSleep(2 * TinyTimeout());

    for (size_t j = 0u; j < threads.size(); j++) {
      unsigned old_wake_count = wake_count.load();
      EXPECT_EQ(j, old_wake_count);

      // Each |Signal()| should wake exactly one thread.
      ev.Signal();

      // Poll for |wake_count| to change.
      while (wake_count.load() == old_wake_count)
        ThreadSleep(EpsilonTimeout());

      EXPECT_FALSE(ev.IsSignaledForTest());

      // And once it's changed, wait a little longer, to see if any other
      // threads are awoken (they shouldn't be).
      ThreadSleep(EpsilonTimeout());

      EXPECT_EQ(old_wake_count + 1u, wake_count.load());

      EXPECT_FALSE(ev.IsSignaledForTest());
    }

    // Having done that, if we signal |ev| now, it should stay signaled.
    ev.Signal();
    ThreadSleep(EpsilonTimeout());
    EXPECT_TRUE(ev.IsSignaledForTest());

    for (auto& thread : threads)
      thread.join();

    ev.Reset();
  }
}

TEST(AutoResetWaitableEventTest, Timeouts) {
  static const unsigned kTestTimeoutsMs[] = {0, 10, 20, 40, 80};

  Stopwatch stopwatch;

  AutoResetWaitableEvent ev;

  for (size_t i = 0u; i < MOJO_ARRAYSIZE(kTestTimeoutsMs); i++) {
    uint64_t timeout = DeadlineFromMilliseconds(kTestTimeoutsMs[i]);

    stopwatch.Start();
    EXPECT_TRUE(ev.WaitWithTimeout(timeout));
    MojoDeadline elapsed = stopwatch.Elapsed();

    // It should time out after *at least* the specified amount of time.
    EXPECT_GE(elapsed, timeout);
    // But we expect that it should time out soon after that amount of time.
    EXPECT_LT(elapsed, timeout + EpsilonTimeout());
  }
}

// ManualResetWaitableEvent ----------------------------------------------------

TEST(ManualResetWaitableEventTest, Basic) {
  ManualResetWaitableEvent ev;
  EXPECT_FALSE(ev.IsSignaledForTest());
  ev.Signal();
  EXPECT_TRUE(ev.IsSignaledForTest());
  ev.Wait();
  EXPECT_TRUE(ev.IsSignaledForTest());
  ev.Reset();
  EXPECT_FALSE(ev.IsSignaledForTest());
  EXPECT_TRUE(ev.WaitWithTimeout(0));
  EXPECT_FALSE(ev.IsSignaledForTest());
  EXPECT_TRUE(ev.WaitWithTimeout(DeadlineFromMilliseconds(1)));
  EXPECT_FALSE(ev.IsSignaledForTest());
  ev.Signal();
  EXPECT_TRUE(ev.IsSignaledForTest());
  EXPECT_FALSE(ev.WaitWithTimeout(0));
  EXPECT_TRUE(ev.IsSignaledForTest());
  EXPECT_FALSE(ev.WaitWithTimeout(DeadlineFromMilliseconds(1)));
  EXPECT_TRUE(ev.IsSignaledForTest());
}

TEST(ManualResetWaitableEventTest, SignalMultiple) {
  ManualResetWaitableEvent ev;

  for (size_t i = 0u; i < 10u; i++) {
    for (size_t num_waiters = 1u; num_waiters < 5u; num_waiters++) {
      std::vector<std::thread> threads;
      for (size_t j = 0u; j < num_waiters; j++) {
        threads.push_back(std::thread([&ev]() {
          EpsilonRandomSleep();

          if (rand() % 2 == 0)
            ev.Wait();
          else
            EXPECT_FALSE(ev.WaitWithTimeout(ActionTimeout()));
        }));
      }

      EpsilonRandomSleep();

      ev.Signal();

      // The threads will only terminate once they've successfully waited (or
      // timed out).
      for (auto& thread : threads)
        thread.join();

      ev.Reset();
    }
  }
}

// Tries to test that threads that are awoken may immediately call |Reset()|
// without affecting other threads that are awoken.
TEST(ManualResetWaitableEventTest, SignalMultipleWaitReset) {
  ManualResetWaitableEvent ev;

  for (size_t i = 0u; i < 5u; i++) {
    std::vector<std::thread> threads;
    for (size_t j = 0u; j < 4u; j++) {
      threads.push_back(std::thread([&ev]() {
        if (rand() % 2 == 0)
          ev.Wait();
        else
          EXPECT_FALSE(ev.WaitWithTimeout(ActionTimeout()));
        ev.Reset();
      }));
    }

    // Unfortunately, we can't really wait for the threads to be waiting, so we
    // just sleep for a bit, and count on them having started and advanced to
    // waiting.
    ThreadSleep(2 * TinyTimeout());

    ev.Signal();

    // In fact, we may ourselves call |Reset()| immediately.
    ev.Reset();

    // The threads will only terminate once they've successfully waited (or
    // timed out).
    for (auto& thread : threads)
      thread.join();

    ASSERT_FALSE(ev.IsSignaledForTest());
  }
}

TEST(ManualResetWaitableEventTest, Timeouts) {
  static const unsigned kTestTimeoutsMs[] = {0, 10, 20, 40, 80};

  Stopwatch stopwatch;

  ManualResetWaitableEvent ev;

  for (size_t i = 0u; i < MOJO_ARRAYSIZE(kTestTimeoutsMs); i++) {
    uint64_t timeout = DeadlineFromMilliseconds(kTestTimeoutsMs[i]);

    stopwatch.Start();
    EXPECT_TRUE(ev.WaitWithTimeout(timeout));
    MojoDeadline elapsed = stopwatch.Elapsed();

    // It should time out after *at least* the specified amount of time.
    EXPECT_GE(elapsed, timeout);
    // But we expect that it should time out soon after that amount of time.
    EXPECT_LT(elapsed, timeout + EpsilonTimeout());
  }
}

}  // namespace
}  // namespace util
}  // namespace mojo
