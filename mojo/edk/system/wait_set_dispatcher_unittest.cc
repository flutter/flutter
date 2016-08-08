// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE(vtl): Some of these tests are inherently flaky (e.g., if run on a
// heavily-loaded system). Sorry. |test::EpsilonTimeout()| may be increased to
// increase tolerance and reduce observed flakiness (though doing so reduces the
// meaningfulness of the test).

#include "mojo/edk/system/wait_set_dispatcher.h"

#include <map>
#include <thread>
#include <utility>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/platform/test_stopwatch.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/mock_simple_dispatcher.h"
#include "mojo/edk/system/test/random.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/util/mutex.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::test::Stopwatch;
using mojo::platform::ThreadSleep;
using mojo::util::MakeRefCounted;
using mojo::util::Mutex;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

// Helper to check if an array of |MojoWaitSetResult|s has a result |r| for the
// given cookie, in which case:
//    - |r.wait_result| must equal |wait_result|.
//    - If |wait_result| is |MOJO_RESULT_OK| or
//      |MOJO_RESULT_FAILED_PRECONDITION|, then
//        - |r.signals_state.satisfied_signals & signals| must equal
//          |signals_state.satisfied_signals & signals|, and
//        - |r.signals_state.satisfiable & signals| must equal
//          |signals_state.satisfiable_signals & signals|.
//    - Otherwise, |r.signals_state| must equals |signals_state|.
// (This doesn't check that the result is unique; you should check |num_results|
// versus the expect number and exhaustively check every expected result.)
bool CheckHasResult(uint32_t num_results,
                    const MojoWaitSetResult* results,
                    uint64_t cookie,
                    MojoHandleSignals signals,
                    MojoResult wait_result,
                    const MojoHandleSignalsState& signals_state) {
  for (uint32_t i = 0; i < num_results; i++) {
    if (results[i].cookie == cookie) {
      EXPECT_EQ(wait_result, results[i].wait_result) << cookie;
      EXPECT_EQ(0u, results[i].reserved) << cookie;
      if (wait_result == MOJO_RESULT_OK ||
          wait_result == MOJO_RESULT_FAILED_PRECONDITION) {
        EXPECT_EQ(signals_state.satisfied_signals & signals,
                  results[i].signals_state.satisfied_signals & signals)
            << cookie;
        EXPECT_EQ(signals_state.satisfiable_signals & signals,
                  results[i].signals_state.satisfiable_signals & signals)
            << cookie;
      } else {
        EXPECT_EQ(signals_state.satisfied_signals,
                  results[i].signals_state.satisfied_signals)
            << cookie;
        EXPECT_EQ(signals_state.satisfiable_signals,
                  results[i].signals_state.satisfiable_signals)
            << cookie;
      }
      return true;
    }
  }
  return false;
}

TEST(WaitSetDispatcherTest, Basic) {
  static constexpr auto kR = MOJO_HANDLE_SIGNAL_READABLE;
  static constexpr auto kW = MOJO_HANDLE_SIGNAL_WRITABLE;

  static constexpr auto kIndefinite = MOJO_DEADLINE_INDEFINITE;
  static constexpr auto k10ms = static_cast<MojoDeadline>(10 * 1000u);

  auto d = WaitSetDispatcher::Create(WaitSetDispatcher::kDefaultCreateOptions);

  // These will be members of our wait set.
  auto d_member0 = MakeRefCounted<test::MockSimpleDispatcher>(kW, kR | kW);
  auto d_member1 = MakeRefCounted<test::MockSimpleDispatcher>(kR, kR);

  // Add |d_member0|, for something not satisfied, but satisfiable.
  static constexpr uint64_t kCookie0 = 0x123456789abcdef0ULL;
  static constexpr auto kSignals0 = kR;
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member0.Clone(), kSignals0,
                                          kCookie0, NullUserPointer()));

  // Add |d_member1|, for something satisfied.
  static constexpr uint64_t kCookie1 = 0x23456789abcdef01ULL;
  static constexpr auto kSignals1 = kR;
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member1.Clone(), kSignals1,
                                          kCookie1, NullUserPointer()));

  // Can add |d_member0| again (satisfied), with a different cookie.
  static constexpr uint64_t kCookie2 = 0x3456789abcdef012ULL;
  static constexpr auto kSignals2 = kW;
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member0.Clone(), kSignals2,
                                          kCookie2, NullUserPointer()));

  // Adding something with the same cookie yields "already exists".
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            d->WaitSetAdd(d_member1.Clone(), kR, kCookie2, NullUserPointer()));

  // Can remove something based on a cookie.
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetRemove(kCookie0));

  // Trying to remove the same cookie again should fail.
  EXPECT_EQ(MOJO_RESULT_NOT_FOUND, d->WaitSetRemove(kCookie0));

  // Can re-add it (still not satisfied, but satisfiable).
  EXPECT_EQ(MOJO_RESULT_OK,
            d->WaitSetAdd(d_member0.Clone(), kR, kCookie0, NullUserPointer()));

  // Wait. Recall:
  //   - |kCookie0| is for |d_member0| and is not satisfied (but satisfiable).
  //   - |kCookie1| is for |d_member1| and is satisfied.
  //   - |kCookie2| is for |d_member0| and is satisfied.
  {
    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    uint32_t max_results = static_cast<uint32_t>(-1);
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(k10ms, MakeUserPointer(&num_results),
                             MakeUserPointer(results),
                             MakeUserPointer(&max_results)));
    EXPECT_EQ(2u, num_results);
    EXPECT_EQ(2u, max_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie1, kSignals1,
                               MOJO_RESULT_OK,
                               d_member1->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_OK,
                               d_member0->GetHandleSignalsState()));
  }

  // Do the same, but test the "indefinite" (forever) wait code path and only
  // allow one result.
  {
    uint32_t num_results = 1u;
    MojoWaitSetResult results[1] = {};
    uint32_t max_results = static_cast<uint32_t>(-1);
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(kIndefinite, MakeUserPointer(&num_results),
                             MakeUserPointer(results),
                             MakeUserPointer(&max_results)));
    EXPECT_EQ(1u, num_results);
    EXPECT_EQ(2u, max_results);

    // We should have *one* of the results.
    EXPECT_TRUE(
        CheckHasResult(num_results, results, kCookie1, kSignals1,
                       MOJO_RESULT_OK, d_member1->GetHandleSignalsState()) ||
        CheckHasResult(num_results, results, kCookie2, kSignals2,
                       MOJO_RESULT_OK, d_member0->GetHandleSignalsState()));
  }

  // Change the state of |d_member0|. This makes |kCookie0| satisfied.
  d_member0->SetSatisfiedSignals(kR | kW);

  // Wait.
  {
    uint32_t num_results = 3u;
    MojoWaitSetResult results[3] = {};
    uint32_t max_results = static_cast<uint32_t>(-1);
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(k10ms, MakeUserPointer(&num_results),
                             MakeUserPointer(results),
                             MakeUserPointer(&max_results)));
    EXPECT_EQ(3u, num_results);
    EXPECT_EQ(3u, max_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie0, kSignals0,
                               MOJO_RESULT_OK,
                               d_member0->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie1, kSignals1,
                               MOJO_RESULT_OK,
                               d_member1->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_OK,
                               d_member0->GetHandleSignalsState()));
  }

  // Change the state of |d_member0| in two steps. |kCookie0| remains satisfied,
  // but |kCookie2| becomes unsatisfiable.
  d_member0->SetSatisfiedSignals(kR);
  d_member0->SetSatisfiableSignals(kR);

  // Wait.
  {
    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    uint32_t max_results = static_cast<uint32_t>(-1);
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(k10ms, MakeUserPointer(&num_results),
                             MakeUserPointer(results),
                             MakeUserPointer(&max_results)));
    EXPECT_EQ(3u, num_results);
    EXPECT_EQ(3u, max_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie0, kSignals0,
                               MOJO_RESULT_OK,
                               d_member0->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie1, kSignals1,
                               MOJO_RESULT_OK,
                               d_member1->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_FAILED_PRECONDITION,
                               d_member0->GetHandleSignalsState()));
  }

  // Can close a dispatcher that's "in" the wait set. This should make
  // |kCookie1| "cancelled".
  EXPECT_EQ(MOJO_RESULT_OK, d_member1->Close());

  // Wait.
  {
    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    // Try passing null for |max_results|.
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(k10ms, MakeUserPointer(&num_results),
                             MakeUserPointer(results), NullUserPointer()));
    EXPECT_EQ(3u, num_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie0, kSignals0,
                               MOJO_RESULT_OK,
                               d_member0->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie1, kSignals1,
                               MOJO_RESULT_CANCELLED,
                               MojoHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_FAILED_PRECONDITION,
                               d_member0->GetHandleSignalsState()));
  }

  // Wait with zero |num_results| (in which case a null |results| is OK).
  {
    uint32_t num_results = 0u;
    uint32_t max_results = static_cast<uint32_t>(-1);
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(k10ms, MakeUserPointer(&num_results),
                             NullUserPointer(), MakeUserPointer(&max_results)));
    EXPECT_EQ(0u, num_results);
    EXPECT_EQ(3u, max_results);
  }

  // Can remove something whose dispatcher has been closed.
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetRemove(kCookie1));

  // Can close the wait set when it's not empty.
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());

  EXPECT_EQ(MOJO_RESULT_OK, d_member0->Close());
}

TEST(WaitSetDispatcherTest, TimeOut) {
  Stopwatch stopwatch;

  auto d = WaitSetDispatcher::Create(WaitSetDispatcher::kDefaultCreateOptions);

  // Wait with timeout without any entries.
  {
    uint32_t num_results = 1u;
    MojoWaitSetResult results[1] = {{456u}};
    uint32_t max_results = 789u;
    stopwatch.Start();
    EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
              d->WaitSetWait(
                  2 * test::EpsilonTimeout(), MakeUserPointer(&num_results),
                  MakeUserPointer(results), MakeUserPointer(&max_results)));
    MojoDeadline elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, test::EpsilonTimeout());
    EXPECT_LT(elapsed, 3 * test::EpsilonTimeout());
    // The inputs should be untouched.
    EXPECT_EQ(1u, num_results);
    EXPECT_EQ(456u, results[0].cookie);
    EXPECT_EQ(789u, max_results);
  }

  auto d_member = MakeRefCounted<test::MockSimpleDispatcher>(
      MOJO_HANDLE_SIGNAL_NONE, MOJO_HANDLE_SIGNAL_READABLE);
  EXPECT_EQ(MOJO_RESULT_OK,
            d->WaitSetAdd(d_member.Clone(), MOJO_HANDLE_SIGNAL_READABLE, 123u,
                          NullUserPointer()));

  // Wait with timeout with an unsatisfied (but satisfiable) entry.
  {
    uint32_t num_results = 1u;
    MojoWaitSetResult results[1] = {{456u}};
    uint32_t max_results = 789u;
    stopwatch.Start();
    EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
              d->WaitSetWait(
                  2 * test::EpsilonTimeout(), MakeUserPointer(&num_results),
                  MakeUserPointer(results), MakeUserPointer(&max_results)));
    MojoDeadline elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, test::EpsilonTimeout());
    EXPECT_LT(elapsed, 3 * test::EpsilonTimeout());
    // The inputs should be untouched.
    EXPECT_EQ(1u, num_results);
    EXPECT_EQ(456u, results[0].cookie);
    EXPECT_EQ(789u, max_results);
  }

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d_member->Close());
}

TEST(WaitSetDispatcherTest, BasicThreaded1) {
  static constexpr auto kNone = MOJO_HANDLE_SIGNAL_NONE;
  static constexpr auto kR = MOJO_HANDLE_SIGNAL_READABLE;
  static constexpr auto kW = MOJO_HANDLE_SIGNAL_WRITABLE;

  const auto epsilon = test::EpsilonTimeout();

  auto d = WaitSetDispatcher::Create(WaitSetDispatcher::kDefaultCreateOptions);

  // These will be members of our wait set.
  auto d_member0 = MakeRefCounted<test::MockSimpleDispatcher>(kNone, kR | kW);
  auto d_member1 = MakeRefCounted<test::MockSimpleDispatcher>(kNone, kR);

  // Add |d_member0|.
  static constexpr uint64_t kCookie0 = 123u;
  static constexpr auto kSignals0 = kR;
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member0.Clone(), kSignals0,
                                          kCookie0, NullUserPointer()));

  // Add |d_member1|.
  static constexpr uint64_t kCookie1 = 456u;
  static constexpr auto kSignals1 = kR;
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member1.Clone(), kSignals1,
                                          kCookie1, NullUserPointer()));

  // Can add |d_member0| again with a different cookie.
  static constexpr uint64_t kCookie2 = 789u;
  static constexpr auto kSignals2 = kW;
  EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member0.Clone(), kSignals2,
                                          kCookie2, NullUserPointer()));

  // We'll wait on the main thread, and do stuff on another thread.

  {
    // Trigger |kCookie0|.
    std::thread t([epsilon, d_member0]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      d_member0->SetSatisfiedSignals(kR);
    });

    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    uint32_t max_results = static_cast<uint32_t>(-1);
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(3 * epsilon, MakeUserPointer(&num_results),
                             MakeUserPointer(results),
                             MakeUserPointer(&max_results)));
    EXPECT_EQ(1u, num_results);
    EXPECT_EQ(1u, max_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie0, kSignals0,
                               MOJO_RESULT_OK,
                               d_member0->GetHandleSignalsState()));

    t.join();
  }

  // Untrigger |kCookie0|.
  d_member0->SetSatisfiedSignals(kNone);

  {
    // Make |kCookie2| unsatisfiable.
    std::thread t([epsilon, d_member0]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      d_member0->SetSatisfiableSignals(kR);
    });

    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(3 * epsilon, MakeUserPointer(&num_results),
                             MakeUserPointer(results), NullUserPointer()));
    EXPECT_EQ(1u, num_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_FAILED_PRECONDITION,
                               d_member0->GetHandleSignalsState()));

    t.join();
  }

  {
    // Trigger |kCookie1|.
    std::thread t(
        [epsilon, d_member1]() { d_member1->SetSatisfiedSignals(kR); });

    // Sleep to try to ensure that |kCookie1| has been triggered.
    ThreadSleep(epsilon);

    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(3 * epsilon, MakeUserPointer(&num_results),
                             MakeUserPointer(results), NullUserPointer()));
    EXPECT_EQ(2u, num_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie1, kSignals1,
                               MOJO_RESULT_OK,
                               d_member1->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_FAILED_PRECONDITION,
                               d_member0->GetHandleSignalsState()));

    t.join();
  }

  // Make |kCookie0| satisfiable again.
  d_member0->SetSatisfiableSignals(kR | kW);
  // Untrigger |kCookie1|.
  d_member1->SetSatisfiedSignals(kNone);

  {
    // Cancel |kCookie0| and |kCookie2| by closing |d_member0|.
    std::thread t([epsilon, d_member0]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      EXPECT_EQ(MOJO_RESULT_OK, d_member0->Close());
    });

    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(3 * epsilon, MakeUserPointer(&num_results),
                             MakeUserPointer(results), NullUserPointer()));
    EXPECT_EQ(2u, num_results);

    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie0, kSignals0,
                               MOJO_RESULT_CANCELLED,
                               MojoHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_CANCELLED,
                               MojoHandleSignalsState()));

    t.join();
  }

  EXPECT_EQ(MOJO_RESULT_OK, d_member1->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST(WaitSetDispatcherTest, BasicThreaded2) {
  static constexpr auto kNone = MOJO_HANDLE_SIGNAL_NONE;
  static constexpr auto kR = MOJO_HANDLE_SIGNAL_READABLE;
  static constexpr auto kW = MOJO_HANDLE_SIGNAL_WRITABLE;

  const auto epsilon = test::EpsilonTimeout();

  Stopwatch stopwatch;

  auto d = WaitSetDispatcher::Create(WaitSetDispatcher::kDefaultCreateOptions);
  auto d_member = MakeRefCounted<test::MockSimpleDispatcher>(kNone, kR | kW);

  static constexpr uint64_t kCookie0 = 123u;
  static constexpr auto kSignals0 = kR;
  static constexpr uint64_t kCookie1 = 456u;
  static constexpr auto kSignals1 = kW;
  static constexpr uint64_t kCookie2 = 789u;
  static constexpr auto kSignals2 = kR | kW;

  // We'll wait on the main thread, and do stuff on another thread.

  {
    // Add |kCookie0|.
    std::thread t0([epsilon, d, d_member]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member.Clone(), kSignals0,
                                              kCookie0, NullUserPointer()));
    });
    // Trigger |kCookie0| after |2 * epsilon| on another thread.
    stopwatch.Start();
    std::thread t1([epsilon, d_member]() {
      ThreadSleep(2 * epsilon);
      d_member->SetSatisfiedSignals(kR);
    });

    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    uint32_t max_results = static_cast<uint32_t>(-1);
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(3 * epsilon, MakeUserPointer(&num_results),
                             MakeUserPointer(results),
                             MakeUserPointer(&max_results)));
    MojoDeadline elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, epsilon);
    EXPECT_LT(elapsed, 3 * epsilon);
    EXPECT_EQ(1u, num_results);
    EXPECT_EQ(1u, max_results);
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie0, kSignals0,
                               MOJO_RESULT_OK,
                               d_member->GetHandleSignalsState()));

    t1.join();
    t0.join();
  }

  // Untrigger |kCookie0|.
  d_member->SetSatisfiedSignals(kNone);

  {
    // Remove |kCookie0|.
    std::thread t0([epsilon, d]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetRemove(kCookie0));
    });
    // Add |kCookie1|.
    std::thread t1([epsilon, d, d_member]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member.Clone(), kSignals1,
                                              kCookie1, NullUserPointer()));
    });
    // Add |kCookie2|.
    std::thread t2([epsilon, d, d_member]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      EXPECT_EQ(MOJO_RESULT_OK, d->WaitSetAdd(d_member.Clone(), kSignals2,
                                              kCookie2, NullUserPointer()));
    });
    // Trigger |kCookie1| and |kCookie2| after |2 * epsilon| on another thread.
    stopwatch.Start();
    std::thread t3([epsilon, d_member]() {
      ThreadSleep(2 * epsilon);
      d_member->SetSatisfiedSignals(kW);
    });

    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(3 * epsilon, MakeUserPointer(&num_results),
                             MakeUserPointer(results), NullUserPointer()));
    MojoDeadline elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, epsilon);
    EXPECT_LT(elapsed, 3 * epsilon);
    EXPECT_EQ(2u, num_results);
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie1, kSignals1,
                               MOJO_RESULT_OK,
                               d_member->GetHandleSignalsState()));
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie2, kSignals2,
                               MOJO_RESULT_OK,
                               d_member->GetHandleSignalsState()));

    t3.join();
    t2.join();
    t1.join();
    t0.join();
  }

  // Untrigger |kCookie1| and |kCookie2|.
  d_member->SetSatisfiedSignals(kNone);

  {
    // Make |kCookie1| unsatisfiable (|kCookie2| remains satisfiable but not
    // satisfied).
    std::thread t([epsilon, d_member]() {
      // Sleep to try to ensure that waiting has started.
      ThreadSleep(epsilon);
      d_member->SetSatisfiableSignals(kR);
    });

    uint32_t num_results = 10u;
    MojoWaitSetResult results[10] = {};
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetWait(3 * epsilon, MakeUserPointer(&num_results),
                             MakeUserPointer(results), NullUserPointer()));
    EXPECT_EQ(1u, num_results);
    EXPECT_TRUE(CheckHasResult(num_results, results, kCookie1, kSignals1,
                               MOJO_RESULT_FAILED_PRECONDITION,
                               d_member->GetHandleSignalsState()));

    t.join();
  }

  EXPECT_EQ(MOJO_RESULT_OK, d_member->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST(WaitSetDispatcherTest, BasicThreaded3) {
  static constexpr auto kNone = MOJO_HANDLE_SIGNAL_NONE;
  static constexpr auto kR = MOJO_HANDLE_SIGNAL_READABLE;

  const auto epsilon = test::EpsilonTimeout();

  Stopwatch stopwatch;

  auto d = WaitSetDispatcher::Create(WaitSetDispatcher::kDefaultCreateOptions);
  auto d_member = MakeRefCounted<test::MockSimpleDispatcher>(kNone, kR);

  {
    // Add an entry.
    EXPECT_EQ(MOJO_RESULT_OK,
              d->WaitSetAdd(d_member.Clone(), kR, 123u, NullUserPointer()));

    // Wait on a bunch of threads. We'll trigger on the main thread.
    std::vector<std::thread> threads;
    for (size_t i = 0; i < 4; i++) {
      threads.push_back(std::thread([epsilon, d, d_member]() {
        uint32_t num_results = 10u;
        MojoWaitSetResult results[10] = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  d->WaitSetWait(5 * epsilon, MakeUserPointer(&num_results),
                                 MakeUserPointer(results), NullUserPointer()));
        EXPECT_EQ(1u, num_results);
        EXPECT_TRUE(CheckHasResult(num_results, results, 123u, kR,
                                   MOJO_RESULT_OK,
                                   d_member->GetHandleSignalsState()));
      }));
    }

    // Sleep a bit, to try to ensure that all the threads are already waiting.
    ThreadSleep(epsilon);

    // Trigger the entry.
    d_member->SetSatisfiedSignals(kR);

    for (auto& t : threads)
      t.join();
  }

  EXPECT_EQ(MOJO_RESULT_OK, d_member->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

// The set-up for this test is as follows:
//   - We'll just use the "readable" handle signal everywhere.
//   - There's one wait set.
//       - It contains a single "quit" entry for a "quit" dispatcher ("owned" by
//         the main thread).
//   - There are a number of waiter threads waiting on it.
//       - Upon being awoken, a waiter thread looks at the results.
//       - If one of them was for "quit", the waiter thread ends.
//       - Otherwise, it resets the signal for the things it was awoken for.
//   - There are a bunch of "worker" threads.
//       - Each worker thread operates in a tight loop.
//       - In each iteration, it checks if the quit dispatcher is signaled; if
//         it is, the worker thread ends.
//       - Otherwise, it might create a dispatcher (which it owns) and add entry
//         for it.
//       - It might also signal an entry that it previously added.
//       - It might also remove an entry that it previously added.
//   - The main thread just sleeps for some desired amount of time, and then
//     signals the quit dispatcher and joins all of the above threads.
TEST(WaitSetDispatcherTest, ThreadedStress) {
  static constexpr auto kTestRunTime = static_cast<MojoDeadline>(1000 * 1000u);
  static constexpr size_t kNumWaiters = 4;
  static constexpr size_t kNumWorkers = 8;
  static constexpr size_t kMaxEntriesPerWorker = 100;

  static constexpr auto kNone = MOJO_HANDLE_SIGNAL_NONE;
  static constexpr auto kSignal = MOJO_HANDLE_SIGNAL_READABLE;
  static constexpr uint64_t kQuitCookie = 0;

  Mutex mu;
  // The next cookie to "allocate". Guarded by |mu|.
  uint64_t next_cookie = kQuitCookie + 1;
  // Cookie -> dispatcher map. Guarded by |mu|.
  std::map<uint64_t, RefPtr<test::MockSimpleDispatcher>>
      cookie_to_dispatcher_map;

  auto wait_set =
      WaitSetDispatcher::Create(WaitSetDispatcher::kDefaultCreateOptions);
  // The quit dispatcher and entry.
  auto quit = MakeRefCounted<test::MockSimpleDispatcher>(kNone, kSignal);
  EXPECT_EQ(MOJO_RESULT_OK,
            wait_set->WaitSetAdd(quit.Clone(), kSignal, kQuitCookie,
                                 NullUserPointer()));

  std::vector<std::thread> threads;

  // Add waiter threads.
  for (size_t i = 0; i < kNumWaiters; i++) {
    threads.push_back(std::thread([&mu, &cookie_to_dispatcher_map, &wait_set,
                                   i]() {
      uint64_t total_wakeups = 0;

      for (;;) {
        uint32_t num_results = 10u;
        MojoWaitSetResult results[10] = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  wait_set->WaitSetWait(
                      MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&num_results),
                      MakeUserPointer(results), NullUserPointer()));
        EXPECT_GE(num_results, 1u);
        total_wakeups++;

        // First, see if we were woken up for a quit cookie.
        for (uint32_t j = 0; j < num_results; j++) {
          if (results[j].cookie == kQuitCookie) {
            VLOG(1) << "Waiter thread #" << i
                    << ": total_wakeups = " << total_wakeups;
            return;
          }
        }

        // Otherwise, get the dispatcher for each cookie and reset its signals.
        MutexLocker locker(&mu);
        for (uint32_t j = 0; j < num_results; j++) {
          auto it = cookie_to_dispatcher_map.find(results[j].cookie);
          if (it == cookie_to_dispatcher_map.end()) {
            // This is not an error, since it may have been removed/destroyed by
            // a worker thread.
            continue;
          }
          it->second->SetSatisfiedSignals(kNone);
        }
      }
    }));
  }

  // Add worker threads.
  for (size_t i = 0; i < kNumWorkers; i++) {
    threads.push_back(std::thread([&mu, &next_cookie, &cookie_to_dispatcher_map,
                                   &wait_set, &quit, i]() {
      uint64_t total_adds = 0;
      uint64_t total_triggers = 0;
      uint64_t total_removes = 0;

      // These are parallel vectors.
      std::vector<RefPtr<test::MockSimpleDispatcher>> dispatchers;
      std::vector<uint64_t> cookies;

      for (;;) {
        // If |quit| is signaled, quit.
        if ((quit->GetHandleSignalsState().satisfied_signals & kSignal))
          break;

        // Should we add an entry (i.e., a dispatcher)? Make the probability be
        // 1 - (current number) / (maximum number).
        if (test::RandomInt(1, static_cast<int>(kMaxEntriesPerWorker)) >
            static_cast<int>(dispatchers.size())) {
          total_adds++;

          auto new_dispatcher =
              MakeRefCounted<test::MockSimpleDispatcher>(kNone, kSignal);
          uint64_t new_cookie;
          {
            MutexLocker locker(&mu);
            new_cookie = next_cookie++;
            cookie_to_dispatcher_map[new_cookie] = new_dispatcher;
            dispatchers.push_back(new_dispatcher);
            cookies.push_back(new_cookie);
          }
          EXPECT_NE(new_cookie, kQuitCookie);
          EXPECT_EQ(MOJO_RESULT_OK,
                    wait_set->WaitSetAdd(std::move(new_dispatcher), kSignal,
                                         new_cookie, NullUserPointer()));
        }

        // Should we trigger an entry? Make the probability be (current number)
        // / (maximum number).
        int j = test::RandomInt(0, static_cast<int>(kMaxEntriesPerWorker - 1));
        if (j < static_cast<int>(dispatchers.size())) {
          total_triggers++;

          // Just use |j| as an index into |dispatchers|/|cookies|.
          dispatchers[j]->SetSatisfiedSignals(kSignal);
        }

        // Should we remove an entry? Make the probability be (current number) /
        // (maximum number).
        j = test::RandomInt(0, static_cast<int>(kMaxEntriesPerWorker - 1));
        if (j < static_cast<int>(dispatchers.size())) {
          total_removes++;

          EXPECT_NE(cookies[j], kQuitCookie);
          EXPECT_EQ(MOJO_RESULT_OK, wait_set->WaitSetRemove(cookies[j]));
          {
            MutexLocker locker(&mu);
            cookie_to_dispatcher_map.erase(cookies[j]);
          }
          EXPECT_EQ(MOJO_RESULT_OK, dispatchers[j]->Close());
          dispatchers.erase(dispatchers.begin() + j);
          cookies.erase(cookies.begin() + j);
        }
      }

      // Remove remaining entries.
      for (auto cookie : cookies)
        EXPECT_EQ(MOJO_RESULT_OK, wait_set->WaitSetRemove(cookie));

      // Close all our dispatchers.
      for (auto& dispatcher : dispatchers)
        EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());

      VLOG(1) << "Worker thread #" << i << ": total_adds = " << total_adds
              << ", total_triggers = " << total_triggers
              << ", total_removes = " << total_removes;
    }));
  }

  // Main thread work: just sleep and then signal |quit|.
  ThreadSleep(kTestRunTime);
  quit->SetSatisfiedSignals(kSignal);

  for (auto& t : threads)
    t.join();

  EXPECT_EQ(MOJO_RESULT_OK, quit->Close());
  EXPECT_EQ(MOJO_RESULT_OK, wait_set->Close());
}

// TODO(vtl): Test options validation for "create" and "add" (not that there's
// much to test).

}  // namespace
}  // namespace system
}  // namespace mojo
