// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE(vtl): Some of these tests are inherently flaky (e.g., if run on a
// heavily-loaded system). Sorry. |test::EpsilonDeadline()| may be increased to
// increase tolerance and reduce observed flakiness (though doing so reduces the
// meaningfulness of the test).

#include "mojo/edk/system/waiter.h"

#include <stdint.h>

#include "base/threading/simple_thread.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

const unsigned kPollTimeMs = 10;

class WaitingThread : public base::SimpleThread {
 public:
  explicit WaitingThread(MojoDeadline deadline)
      : base::SimpleThread("waiting_thread"),
        deadline_(deadline),
        done_(false),
        result_(MOJO_RESULT_UNKNOWN),
        context_(static_cast<uint32_t>(-1)) {
    waiter_.Init();
  }

  ~WaitingThread() override { Join(); }

  void WaitUntilDone(MojoResult* result,
                     uint32_t* context,
                     MojoDeadline* elapsed) {
    for (;;) {
      {
        MutexLocker locker(&mutex_);
        if (done_) {
          *result = result_;
          *context = context_;
          *elapsed = elapsed_;
          break;
        }
      }

      test::Sleep(test::DeadlineFromMilliseconds(kPollTimeMs));
    }
  }

  Waiter* waiter() { return &waiter_; }

 private:
  void Run() override {
    test::Stopwatch stopwatch;
    MojoResult result;
    uint32_t context = static_cast<uint32_t>(-1);
    MojoDeadline elapsed;

    stopwatch.Start();
    result = waiter_.Wait(deadline_, &context);
    elapsed = stopwatch.Elapsed();

    {
      MutexLocker locker(&mutex_);
      done_ = true;
      result_ = result;
      context_ = context;
      elapsed_ = elapsed;
    }
  }

  const MojoDeadline deadline_;
  Waiter waiter_;  // Thread-safe.

  Mutex mutex_;
  bool done_ MOJO_GUARDED_BY(mutex_);
  MojoResult result_ MOJO_GUARDED_BY(mutex_);
  uint32_t context_ MOJO_GUARDED_BY(mutex_);
  MojoDeadline elapsed_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(WaitingThread);
};

TEST(WaiterTest, Basic) {
  MojoResult result;
  uint32_t context;
  MojoDeadline elapsed;

  // Finite deadline.

  // Awake immediately after thread start.
  {
    WaitingThread thread(10 * test::EpsilonDeadline());
    thread.Start();
    thread.waiter()->Awake(MOJO_RESULT_OK, 1);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(MOJO_RESULT_OK, result);
    EXPECT_EQ(1u, context);
    EXPECT_LT(elapsed, test::EpsilonDeadline());
  }

  // Awake before after thread start.
  {
    WaitingThread thread(10 * test::EpsilonDeadline());
    thread.waiter()->Awake(MOJO_RESULT_CANCELLED, 2);
    thread.Start();
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
    EXPECT_EQ(2u, context);
    EXPECT_LT(elapsed, test::EpsilonDeadline());
  }

  // Awake some time after thread start.
  {
    WaitingThread thread(10 * test::EpsilonDeadline());
    thread.Start();
    test::Sleep(2 * test::EpsilonDeadline());
    thread.waiter()->Awake(1, 3);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(1u, result);
    EXPECT_EQ(3u, context);
    EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
    EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  }

  // Awake some longer time after thread start.
  {
    WaitingThread thread(10 * test::EpsilonDeadline());
    thread.Start();
    test::Sleep(5 * test::EpsilonDeadline());
    thread.waiter()->Awake(2, 4);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(2u, result);
    EXPECT_EQ(4u, context);
    EXPECT_GT(elapsed, (5 - 1) * test::EpsilonDeadline());
    EXPECT_LT(elapsed, (5 + 1) * test::EpsilonDeadline());
  }

  // Don't awake -- time out (on another thread).
  {
    WaitingThread thread(2 * test::EpsilonDeadline());
    thread.Start();
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, result);
    EXPECT_EQ(static_cast<uint32_t>(-1), context);
    EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
    EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  }

  // No (indefinite) deadline.

  // Awake immediately after thread start.
  {
    WaitingThread thread(MOJO_DEADLINE_INDEFINITE);
    thread.Start();
    thread.waiter()->Awake(MOJO_RESULT_OK, 5);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(MOJO_RESULT_OK, result);
    EXPECT_EQ(5u, context);
    EXPECT_LT(elapsed, test::EpsilonDeadline());
  }

  // Awake before after thread start.
  {
    WaitingThread thread(MOJO_DEADLINE_INDEFINITE);
    thread.waiter()->Awake(MOJO_RESULT_CANCELLED, 6);
    thread.Start();
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
    EXPECT_EQ(6u, context);
    EXPECT_LT(elapsed, test::EpsilonDeadline());
  }

  // Awake some time after thread start.
  {
    WaitingThread thread(MOJO_DEADLINE_INDEFINITE);
    thread.Start();
    test::Sleep(2 * test::EpsilonDeadline());
    thread.waiter()->Awake(1, 7);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(1u, result);
    EXPECT_EQ(7u, context);
    EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
    EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  }

  // Awake some longer time after thread start.
  {
    WaitingThread thread(MOJO_DEADLINE_INDEFINITE);
    thread.Start();
    test::Sleep(5 * test::EpsilonDeadline());
    thread.waiter()->Awake(2, 8);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(2u, result);
    EXPECT_EQ(8u, context);
    EXPECT_GT(elapsed, (5 - 1) * test::EpsilonDeadline());
    EXPECT_LT(elapsed, (5 + 1) * test::EpsilonDeadline());
  }
}

TEST(WaiterTest, TimeOut) {
  test::Stopwatch stopwatch;
  MojoDeadline elapsed;

  Waiter waiter;
  uint32_t context = 123;

  waiter.Init();
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, &context));
  elapsed = stopwatch.Elapsed();
  EXPECT_LT(elapsed, test::EpsilonDeadline());
  EXPECT_EQ(123u, context);

  waiter.Init();
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
            waiter.Wait(2 * test::EpsilonDeadline(), &context));
  elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
  EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  EXPECT_EQ(123u, context);

  waiter.Init();
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
            waiter.Wait(5 * test::EpsilonDeadline(), &context));
  elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, (5 - 1) * test::EpsilonDeadline());
  EXPECT_LT(elapsed, (5 + 1) * test::EpsilonDeadline());
  EXPECT_EQ(123u, context);
}

// The first |Awake()| should always win.
TEST(WaiterTest, MultipleAwakes) {
  MojoResult result;
  uint32_t context;
  MojoDeadline elapsed;

  {
    WaitingThread thread(MOJO_DEADLINE_INDEFINITE);
    thread.Start();
    thread.waiter()->Awake(MOJO_RESULT_OK, 1);
    thread.waiter()->Awake(1, 2);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(MOJO_RESULT_OK, result);
    EXPECT_EQ(1u, context);
    EXPECT_LT(elapsed, test::EpsilonDeadline());
  }

  {
    WaitingThread thread(MOJO_DEADLINE_INDEFINITE);
    thread.waiter()->Awake(1, 3);
    thread.Start();
    thread.waiter()->Awake(MOJO_RESULT_OK, 4);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(1u, result);
    EXPECT_EQ(3u, context);
    EXPECT_LT(elapsed, test::EpsilonDeadline());
  }

  {
    WaitingThread thread(MOJO_DEADLINE_INDEFINITE);
    thread.Start();
    thread.waiter()->Awake(10, 5);
    test::Sleep(2 * test::EpsilonDeadline());
    thread.waiter()->Awake(20, 6);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(10u, result);
    EXPECT_EQ(5u, context);
    EXPECT_LT(elapsed, test::EpsilonDeadline());
  }

  {
    WaitingThread thread(10 * test::EpsilonDeadline());
    thread.Start();
    test::Sleep(1 * test::EpsilonDeadline());
    thread.waiter()->Awake(MOJO_RESULT_FAILED_PRECONDITION, 7);
    test::Sleep(2 * test::EpsilonDeadline());
    thread.waiter()->Awake(MOJO_RESULT_OK, 8);
    thread.WaitUntilDone(&result, &context, &elapsed);
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
    EXPECT_EQ(7u, context);
    EXPECT_GT(elapsed, (1 - 1) * test::EpsilonDeadline());
    EXPECT_LT(elapsed, (1 + 1) * test::EpsilonDeadline());
  }
}

}  // namespace
}  // namespace system
}  // namespace mojo
