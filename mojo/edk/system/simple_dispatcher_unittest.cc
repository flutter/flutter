// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE(vtl): Some of these tests are inherently flaky (e.g., if run on a
// heavily-loaded system). Sorry. |test::EpsilonDeadline()| may be increased to
// increase tolerance and reduce observed flakiness (though doing so reduces the
// meaningfulness of the test).

#include "mojo/edk/system/simple_dispatcher.h"

#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_vector.h"
#include "base/synchronization/lock.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/edk/system/waiter_test_utils.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

class MockSimpleDispatcher final : public SimpleDispatcher {
 public:
  MockSimpleDispatcher()
      : state_(MOJO_HANDLE_SIGNAL_NONE,
               MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE) {}
  explicit MockSimpleDispatcher(const HandleSignalsState& state)
      : state_(state) {}

  void SetSatisfiedSignals(MojoHandleSignals new_satisfied_signals) {
    MutexLocker locker(&mutex());

    // Any new signals that are set should be satisfiable.
    CHECK_EQ(new_satisfied_signals & ~state_.satisfied_signals,
             new_satisfied_signals & ~state_.satisfied_signals &
                 state_.satisfiable_signals);

    if (new_satisfied_signals == state_.satisfied_signals)
      return;

    state_.satisfied_signals = new_satisfied_signals;
    HandleSignalsStateChangedNoLock();
  }

  void SetSatisfiableSignals(MojoHandleSignals new_satisfiable_signals) {
    MutexLocker locker(&mutex());

    // Satisfied implies satisfiable.
    CHECK_EQ(new_satisfiable_signals & state_.satisfied_signals,
             state_.satisfied_signals);

    if (new_satisfiable_signals == state_.satisfiable_signals)
      return;

    state_.satisfiable_signals = new_satisfiable_signals;
    HandleSignalsStateChangedNoLock();
  }

  Type GetType() const override { return Type::UNKNOWN; }

 private:
  friend class base::RefCountedThreadSafe<MockSimpleDispatcher>;
  ~MockSimpleDispatcher() override {}

  scoped_refptr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock()
      override {
    scoped_refptr<MockSimpleDispatcher> rv(new MockSimpleDispatcher(state_));
    return scoped_refptr<Dispatcher>(rv.get());
  }

  // |Dispatcher| override:
  HandleSignalsState GetHandleSignalsStateImplNoLock() const override {
    mutex().AssertHeld();
    return state_;
  }

  HandleSignalsState state_ MOJO_GUARDED_BY(mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(MockSimpleDispatcher);
};

#if defined(OS_WIN)
// http://crbug.com/396404
#define MAYBE_Basic DISABLED_Basic
#else
#define MAYBE_Basic Basic
#endif
TEST(SimpleDispatcherTest, MAYBE_Basic) {
  test::Stopwatch stopwatch;

  scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
  Waiter w;
  uint32_t context = 0;
  HandleSignalsState hss;

  // Try adding a readable waiter when already readable.
  w.Init();
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_READABLE, 0, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);
  // Shouldn't need to remove the waiter (it was not added).

  // Wait (forever) for writable when already writable.
  w.Init();
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 1, nullptr));
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_WRITABLE);
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_OK, w.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(1u, context);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);

  // Wait for zero time for writable when already writable.
  w.Init();
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 2, nullptr));
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_WRITABLE);
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_OK, w.Wait(0, &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(2u, context);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);

  // Wait for non-zero, finite time for writable when already writable.
  w.Init();
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 3, nullptr));
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_WRITABLE);
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_OK, w.Wait(2 * test::EpsilonDeadline(), &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(3u, context);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);

  // Wait for zero time for writable when not writable (will time out).
  w.Init();
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 4, nullptr));
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, w.Wait(0, nullptr));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);

  // Wait for non-zero, finite time for writable when not writable (will time
  // out).
  w.Init();
  d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 5, nullptr));
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
            w.Wait(2 * test::EpsilonDeadline(), nullptr));
  MojoDeadline elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
  EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST(SimpleDispatcherTest, BasicUnsatisfiable) {
  test::Stopwatch stopwatch;

  scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
  Waiter w;
  uint32_t context = 0;
  HandleSignalsState hss;

  // Try adding a writable waiter when it can never be writable.
  w.Init();
  d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE);
  d->SetSatisfiedSignals(0);
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 1, &hss));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfiable_signals);
  // Shouldn't need to remove the waiter (it was not added).

  // Wait (forever) for writable and then it becomes never writable.
  w.Init();
  d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE |
                           MOJO_HANDLE_SIGNAL_WRITABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 2, nullptr));
  d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE);
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            w.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(2u, context);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfiable_signals);

  // Wait for zero time for writable and then it becomes never writable.
  w.Init();
  d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE |
                           MOJO_HANDLE_SIGNAL_WRITABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 3, nullptr));
  d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE);
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, w.Wait(0, &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(3u, context);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfiable_signals);

  // Wait for non-zero, finite time for writable and then it becomes never
  // writable.
  w.Init();
  d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE |
                           MOJO_HANDLE_SIGNAL_WRITABLE);
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 4, nullptr));
  d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE);
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            w.Wait(2 * test::EpsilonDeadline(), &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(4u, context);
  hss = HandleSignalsState();
  d->RemoveAwakable(&w, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfiable_signals);

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST(SimpleDispatcherTest, BasicClosed) {
  test::Stopwatch stopwatch;

  scoped_refptr<MockSimpleDispatcher> d;
  Waiter w;
  uint32_t context = 0;
  HandleSignalsState hss;

  // Try adding a writable waiter when the dispatcher has been closed.
  d = new MockSimpleDispatcher();
  w.Init();
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 1, &hss));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
  // Shouldn't need to remove the waiter (it was not added).

  // Wait (forever) for writable and then the dispatcher is closed.
  d = new MockSimpleDispatcher();
  w.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 2, nullptr));
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_CANCELLED, w.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(2u, context);
  // Don't need to remove waiters from closed dispatchers.

  // Wait for zero time for writable and then the dispatcher is closed.
  d = new MockSimpleDispatcher();
  w.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 3, nullptr));
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_CANCELLED, w.Wait(0, &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(3u, context);
  // Don't need to remove waiters from closed dispatchers.

  // Wait for non-zero, finite time for writable and then the dispatcher is
  // closed.
  d = new MockSimpleDispatcher();
  w.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            d->AddAwakable(&w, MOJO_HANDLE_SIGNAL_WRITABLE, 4, nullptr));
  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  stopwatch.Start();
  EXPECT_EQ(MOJO_RESULT_CANCELLED,
            w.Wait(2 * test::EpsilonDeadline(), &context));
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_EQ(4u, context);
  // Don't need to remove waiters from closed dispatchers.
}

#if defined(OS_WIN)
// http://crbug.com/396393
#define MAYBE_BasicThreaded DISABLED_BasicThreaded
#else
#define MAYBE_BasicThreaded BasicThreaded
#endif
TEST(SimpleDispatcherTest, MAYBE_BasicThreaded) {
  test::Stopwatch stopwatch;
  bool did_wait;
  MojoResult result;
  uint32_t context;
  HandleSignalsState hss;

  // Wait for readable (already readable).
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    {
      d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
      test::WaiterThread thread(d, MOJO_HANDLE_SIGNAL_READABLE,
                                MOJO_DEADLINE_INDEFINITE, 1, &did_wait, &result,
                                &context, &hss);
      stopwatch.Start();
      thread.Start();
    }  // Joins the thread.
    // If we closed earlier, then probably we'd get a |MOJO_RESULT_CANCELLED|.
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }
  EXPECT_LT(stopwatch.Elapsed(), test::EpsilonDeadline());
  EXPECT_FALSE(did_wait);
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS, result);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);

  // Wait for readable and becomes readable after some time.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    {
      test::WaiterThread thread(d, MOJO_HANDLE_SIGNAL_READABLE,
                                MOJO_DEADLINE_INDEFINITE, 2, &did_wait, &result,
                                &context, &hss);
      stopwatch.Start();
      thread.Start();
      test::Sleep(2 * test::EpsilonDeadline());
      d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
    }  // Joins the thread.
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }
  MojoDeadline elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
  EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  EXPECT_TRUE(did_wait);
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(2u, context);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);

  // Wait for readable and becomes never-readable after some time.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    {
      test::WaiterThread thread(d, MOJO_HANDLE_SIGNAL_READABLE,
                                MOJO_DEADLINE_INDEFINITE, 3, &did_wait, &result,
                                &context, &hss);
      stopwatch.Start();
      thread.Start();
      test::Sleep(2 * test::EpsilonDeadline());
      d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_NONE);
    }  // Joins the thread.
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }
  elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
  EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  EXPECT_TRUE(did_wait);
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
  EXPECT_EQ(3u, context);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);

  // Wait for readable and dispatcher gets closed.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    test::WaiterThread thread(d, MOJO_HANDLE_SIGNAL_READABLE,
                              MOJO_DEADLINE_INDEFINITE, 4, &did_wait, &result,
                              &context, &hss);
    stopwatch.Start();
    thread.Start();
    test::Sleep(2 * test::EpsilonDeadline());
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }  // Joins the thread.
  elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
  EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  EXPECT_TRUE(did_wait);
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
  EXPECT_EQ(4u, context);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);

  // Wait for readable and times out.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    {
      test::WaiterThread thread(d, MOJO_HANDLE_SIGNAL_READABLE,
                                2 * test::EpsilonDeadline(), 5, &did_wait,
                                &result, &context, &hss);
      stopwatch.Start();
      thread.Start();
      test::Sleep(1 * test::EpsilonDeadline());
      // Not what we're waiting for.
      d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_WRITABLE);
    }  // Joins the thread (after its wait times out).
    // If we closed earlier, then probably we'd get a |MOJO_RESULT_CANCELLED|.
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }
  elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, (2 - 1) * test::EpsilonDeadline());
  EXPECT_LT(elapsed, (2 + 1) * test::EpsilonDeadline());
  EXPECT_TRUE(did_wait);
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, result);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfiable_signals);
}

#if defined(OS_WIN)
// http://crbug.com/387124
#define MAYBE_MultipleWaiters DISABLED_MultipleWaiters
#else
#define MAYBE_MultipleWaiters MultipleWaiters
#endif
TEST(SimpleDispatcherTest, MAYBE_MultipleWaiters) {
  static const uint32_t kNumWaiters = 20;

  bool did_wait[kNumWaiters];
  MojoResult result[kNumWaiters];
  uint32_t context[kNumWaiters];
  HandleSignalsState hss[kNumWaiters];

  // All wait for readable and becomes readable after some time.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    ScopedVector<test::WaiterThread> threads;
    for (uint32_t i = 0; i < kNumWaiters; i++) {
      threads.push_back(new test::WaiterThread(
          d, MOJO_HANDLE_SIGNAL_READABLE, MOJO_DEADLINE_INDEFINITE, i,
          &did_wait[i], &result[i], &context[i], &hss[i]));
      threads.back()->Start();
    }
    test::Sleep(2 * test::EpsilonDeadline());
    d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }  // Joins the threads.
  for (uint32_t i = 0; i < kNumWaiters; i++) {
    EXPECT_TRUE(did_wait[i]) << i;
    EXPECT_EQ(MOJO_RESULT_OK, result[i]) << i;
    EXPECT_EQ(i, context[i]) << i;
    // Since we closed before joining, we can't say much about what each thread
    // saw as the state.
  }

  // Some wait for readable, some for writable, and becomes readable after some
  // time.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    ScopedVector<test::WaiterThread> threads;
    for (uint32_t i = 0; i < kNumWaiters / 2; i++) {
      threads.push_back(new test::WaiterThread(
          d, MOJO_HANDLE_SIGNAL_READABLE, MOJO_DEADLINE_INDEFINITE, i,
          &did_wait[i], &result[i], &context[i], &hss[i]));
      threads.back()->Start();
    }
    for (uint32_t i = kNumWaiters / 2; i < kNumWaiters; i++) {
      threads.push_back(new test::WaiterThread(
          d, MOJO_HANDLE_SIGNAL_WRITABLE, MOJO_DEADLINE_INDEFINITE, i,
          &did_wait[i], &result[i], &context[i], &hss[i]));
      threads.back()->Start();
    }
    test::Sleep(2 * test::EpsilonDeadline());
    d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
    // This will wake up the ones waiting to write.
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }  // Joins the threads.
  for (uint32_t i = 0; i < kNumWaiters / 2; i++) {
    EXPECT_TRUE(did_wait[i]) << i;
    EXPECT_EQ(MOJO_RESULT_OK, result[i]) << i;
    EXPECT_EQ(i, context[i]) << i;
    // Since we closed before joining, we can't say much about what each thread
    // saw as the state.
  }
  for (uint32_t i = kNumWaiters / 2; i < kNumWaiters; i++) {
    EXPECT_TRUE(did_wait[i]) << i;
    EXPECT_EQ(MOJO_RESULT_CANCELLED, result[i]) << i;
    EXPECT_EQ(i, context[i]) << i;
    // Since we closed before joining, we can't say much about what each thread
    // saw as the state.
  }

  // Some wait for readable, some for writable, and becomes readable and
  // never-writable after some time.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    ScopedVector<test::WaiterThread> threads;
    for (uint32_t i = 0; i < kNumWaiters / 2; i++) {
      threads.push_back(new test::WaiterThread(
          d, MOJO_HANDLE_SIGNAL_READABLE, MOJO_DEADLINE_INDEFINITE, i,
          &did_wait[i], &result[i], &context[i], &hss[i]));
      threads.back()->Start();
    }
    for (uint32_t i = kNumWaiters / 2; i < kNumWaiters; i++) {
      threads.push_back(new test::WaiterThread(
          d, MOJO_HANDLE_SIGNAL_WRITABLE, MOJO_DEADLINE_INDEFINITE, i,
          &did_wait[i], &result[i], &context[i], &hss[i]));
      threads.back()->Start();
    }
    test::Sleep(1 * test::EpsilonDeadline());
    d->SetSatisfiableSignals(MOJO_HANDLE_SIGNAL_READABLE);
    test::Sleep(1 * test::EpsilonDeadline());
    d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }  // Joins the threads.
  for (uint32_t i = 0; i < kNumWaiters / 2; i++) {
    EXPECT_TRUE(did_wait[i]) << i;
    EXPECT_EQ(MOJO_RESULT_OK, result[i]) << i;
    EXPECT_EQ(i, context[i]) << i;
    // Since we closed before joining, we can't say much about what each thread
    // saw as the state.
  }
  for (uint32_t i = kNumWaiters / 2; i < kNumWaiters; i++) {
    EXPECT_TRUE(did_wait[i]) << i;
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result[i]) << i;
    EXPECT_EQ(i, context[i]) << i;
    // Since we closed before joining, we can't say much about what each thread
    // saw as the state.
  }

  // Some wait for readable, some for writable, and becomes readable after some
  // time.
  {
    scoped_refptr<MockSimpleDispatcher> d(new MockSimpleDispatcher());
    ScopedVector<test::WaiterThread> threads;
    for (uint32_t i = 0; i < kNumWaiters / 2; i++) {
      threads.push_back(new test::WaiterThread(
          d, MOJO_HANDLE_SIGNAL_READABLE, 3 * test::EpsilonDeadline(), i,
          &did_wait[i], &result[i], &context[i], &hss[i]));
      threads.back()->Start();
    }
    for (uint32_t i = kNumWaiters / 2; i < kNumWaiters; i++) {
      threads.push_back(new test::WaiterThread(
          d, MOJO_HANDLE_SIGNAL_WRITABLE, 1 * test::EpsilonDeadline(), i,
          &did_wait[i], &result[i], &context[i], &hss[i]));
      threads.back()->Start();
    }
    test::Sleep(2 * test::EpsilonDeadline());
    d->SetSatisfiedSignals(MOJO_HANDLE_SIGNAL_READABLE);
    // All those waiting for writable should have timed out.
    EXPECT_EQ(MOJO_RESULT_OK, d->Close());
  }  // Joins the threads.
  for (uint32_t i = 0; i < kNumWaiters / 2; i++) {
    EXPECT_TRUE(did_wait[i]) << i;
    EXPECT_EQ(MOJO_RESULT_OK, result[i]) << i;
    EXPECT_EQ(i, context[i]) << i;
    // Since we closed before joining, we can't say much about what each thread
    // saw as the state.
  }
  for (uint32_t i = kNumWaiters / 2; i < kNumWaiters; i++) {
    EXPECT_TRUE(did_wait[i]) << i;
    EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, result[i]) << i;
    // Since we closed before joining, we can't say much about what each thread
    // saw as the state.
  }
}

// TODO(vtl): Stress test?

}  // namespace
}  // namespace system
}  // namespace mojo
