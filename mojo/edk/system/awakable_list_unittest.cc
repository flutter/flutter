// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE(vtl): Some of these tests are inherently flaky (e.g., if run on a
// heavily-loaded system). Sorry. |test::EpsilonTimeout()| may be increased to
// increase tolerance and reduce observed flakiness (though doing so reduces the
// meaningfulness of the test).

#include "mojo/edk/system/awakable_list.h"

#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/edk/system/waiter_test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::ThreadSleep;

namespace mojo {
namespace system {
namespace {

TEST(AwakableListTest, BasicCancelAndRemoveAll) {
  MojoResult result;
  uint64_t context;

  // Cancel immediately after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    awakable_list.Add(thread.waiter(), 1, false, MOJO_HANDLE_SIGNAL_READABLE,
                      HandleSignalsState());
    thread.Start();
    awakable_list.CancelAndRemoveAll();
    // Double-remove okay:
    awakable_list.Remove(false, thread.waiter(), 0);
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
  EXPECT_EQ(1u, context);

  // Cancel before after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    awakable_list.Add(thread.waiter(), 2, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      HandleSignalsState());
    awakable_list.CancelAndRemoveAll();
    thread.Start();
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
  EXPECT_EQ(2u, context);

  // Cancel some time after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    awakable_list.Add(thread.waiter(), 3, false, MOJO_HANDLE_SIGNAL_READABLE,
                      HandleSignalsState());
    thread.Start();
    ThreadSleep(2 * test::EpsilonTimeout());
    awakable_list.CancelAndRemoveAll();
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
  EXPECT_EQ(3u, context);
}

TEST(AwakableListTest, BasicAwakeSatisfied) {
  MojoResult result;
  uint64_t context;

  // Awake immediately after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 1, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread.Start();
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_READABLE,
                                      MOJO_HANDLE_SIGNAL_READABLE |
                                          MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(false, thread.waiter(), 0);
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(1u, context);

  // Awake before after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 2, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      old_state);
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_WRITABLE,
                                      MOJO_HANDLE_SIGNAL_READABLE |
                                          MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(false, thread.waiter(), 0);
    // Double-remove okay:
    awakable_list.Remove(false, thread.waiter(), 0);
    thread.Start();
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(2u, context);

  // Awake some time after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 3, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread.Start();
    ThreadSleep(2 * test::EpsilonTimeout());
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_READABLE,
                                      MOJO_HANDLE_SIGNAL_READABLE |
                                          MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(false, thread.waiter(), 0);
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(3u, context);
}

TEST(AwakableListTest, BasicAwakeUnsatisfiable) {
  MojoResult result;
  uint64_t context;

  // Awake (for unsatisfiability) immediately after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 1, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread.Start();
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_NONE,
                                      MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(false, thread.waiter(), 0);
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
  EXPECT_EQ(1u, context);

  // Awake (for unsatisfiability) before after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 2, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      old_state);
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_READABLE,
                                      MOJO_HANDLE_SIGNAL_READABLE));
    awakable_list.Remove(false, thread.waiter(), 0);
    thread.Start();
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
  EXPECT_EQ(2u, context);

  // Awake (for unsatisfiability) some time after thread start.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 3, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread.Start();
    ThreadSleep(2 * test::EpsilonTimeout());
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_NONE,
                                      MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(false, thread.waiter(), 0);
    // Double-remove okay:
    awakable_list.Remove(false, thread.waiter(), 0);
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
  EXPECT_EQ(3u, context);
}

TEST(AwakableListTest, MultipleAwakables) {
  MojoResult result1;
  MojoResult result2;
  MojoResult result3;
  MojoResult result4;
  uint64_t context1;
  uint64_t context2;
  uint64_t context3;
  uint64_t context4;

  // Cancel two awakables.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread1(&result1, &context1);
    awakable_list.Add(thread1.waiter(), 1, false, MOJO_HANDLE_SIGNAL_READABLE,
                      HandleSignalsState());
    thread1.Start();
    test::SimpleWaiterThread thread2(&result2, &context2);
    awakable_list.Add(thread2.waiter(), 2, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      HandleSignalsState());
    thread2.Start();
    ThreadSleep(2 * test::EpsilonTimeout());
    awakable_list.CancelAndRemoveAll();
  }  // Join threads.
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result1);
  EXPECT_EQ(1u, context1);
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result2);
  EXPECT_EQ(2u, context2);

  // Awake one awakable, cancel other.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread1(&result1, &context1);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread1.waiter(), 3, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread1.Start();
    test::SimpleWaiterThread thread2(&result2, &context2);
    awakable_list.Add(thread2.waiter(), 4, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      old_state);
    thread2.Start();
    ThreadSleep(2 * test::EpsilonTimeout());
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_READABLE,
                                      MOJO_HANDLE_SIGNAL_READABLE |
                                          MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(false, thread1.waiter(), 0);
    awakable_list.CancelAndRemoveAll();
  }  // Join threads.
  EXPECT_EQ(MOJO_RESULT_OK, result1);
  EXPECT_EQ(3u, context1);
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result2);
  EXPECT_EQ(4u, context2);

  // Cancel one awakable, awake other for unsatisfiability.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread1(&result1, &context1);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread1.waiter(), 5, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread1.Start();
    test::SimpleWaiterThread thread2(&result2, &context2);
    awakable_list.Add(thread2.waiter(), 6, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      old_state);
    thread2.Start();
    ThreadSleep(2 * test::EpsilonTimeout());
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_NONE,
                                      MOJO_HANDLE_SIGNAL_READABLE));
    awakable_list.Remove(false, thread2.waiter(), 0);
    awakable_list.CancelAndRemoveAll();
  }  // Join threads.
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result1);
  EXPECT_EQ(5u, context1);
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result2);
  EXPECT_EQ(6u, context2);

  // Cancel one awakable, awake other for unsatisfiability.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread1(&result1, &context1);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread1.waiter(), 7, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread1.Start();

    ThreadSleep(1 * test::EpsilonTimeout());

    // Should do nothing.
    HandleSignalsState new_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.OnStateChange(old_state, new_state);
    old_state = new_state;

    test::SimpleWaiterThread thread2(&result2, &context2);
    awakable_list.Add(thread2.waiter(), 8, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      old_state);
    thread2.Start();

    ThreadSleep(1 * test::EpsilonTimeout());

    // Awake #1.
    new_state = HandleSignalsState(
        MOJO_HANDLE_SIGNAL_READABLE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.OnStateChange(old_state, new_state);
    old_state = new_state;
    awakable_list.Remove(false, thread1.waiter(), 0);

    ThreadSleep(1 * test::EpsilonTimeout());

    test::SimpleWaiterThread thread3(&result3, &context3);
    awakable_list.Add(thread3.waiter(), 9, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                      old_state);
    thread3.Start();

    test::SimpleWaiterThread thread4(&result4, &context4);
    awakable_list.Add(thread4.waiter(), 10, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread4.Start();

    ThreadSleep(1 * test::EpsilonTimeout());

    // Awake #2 and #3 for unsatisfiability.
    new_state = HandleSignalsState(MOJO_HANDLE_SIGNAL_NONE,
                                   MOJO_HANDLE_SIGNAL_READABLE);
    awakable_list.OnStateChange(old_state, new_state);
    awakable_list.Remove(false, thread2.waiter(), 0);
    awakable_list.Remove(false, thread3.waiter(), 0);

    // Cancel #4.
    awakable_list.CancelAndRemoveAll();
  }  // Join threads.
  EXPECT_EQ(MOJO_RESULT_OK, result1);
  EXPECT_EQ(7u, context1);
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result2);
  EXPECT_EQ(8u, context2);
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result3);
  EXPECT_EQ(9u, context3);
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result4);
  EXPECT_EQ(10u, context4);
}

TEST(AwakableListTest, RemoveMatchContext1) {
  MojoResult result;
  uint64_t context;

  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 1, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    awakable_list.Add(thread.waiter(), 2, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread.Start();
    awakable_list.Remove(true, thread.waiter(), 2);
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_READABLE,
                                      MOJO_HANDLE_SIGNAL_READABLE |
                                          MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(true, thread.waiter(), 1);
    // Double-remove okay:
    awakable_list.Remove(true, thread.waiter(), 1);
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(1u, context);

  // Try the same thing, but remove "1" before the awake instead.
  {
    AwakableList awakable_list;
    test::SimpleWaiterThread thread(&result, &context);
    HandleSignalsState old_state(
        MOJO_HANDLE_SIGNAL_NONE,
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
    awakable_list.Add(thread.waiter(), 1, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    awakable_list.Add(thread.waiter(), 2, false, MOJO_HANDLE_SIGNAL_READABLE,
                      old_state);
    thread.Start();
    awakable_list.Remove(true, thread.waiter(), 1);
    awakable_list.OnStateChange(
        old_state, HandleSignalsState(MOJO_HANDLE_SIGNAL_READABLE,
                                      MOJO_HANDLE_SIGNAL_READABLE |
                                          MOJO_HANDLE_SIGNAL_WRITABLE));
    awakable_list.Remove(true, thread.waiter(), 2);
  }  // Join |thread|.
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(2u, context);
}

class TestAwakable : public Awakable {
 public:
  TestAwakable() {}

  void Awake(uint64_t context,
             AwakeReason reason,
             const HandleSignalsState& signals_state) override {
    awake_count++;
    last_context = context;
    last_reason = reason;
    last_state = signals_state;
  }

  unsigned awake_count = 0;
  uint64_t last_context = static_cast<uint64_t>(-1);
  AwakeReason last_reason = AwakeReason::CANCELLED;
  HandleSignalsState last_state;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestAwakable);
};

TEST(AwakableListTest, PersistentVsOneShot1) {
  AwakableList awakable_list;
  TestAwakable persistent0;
  TestAwakable persistent1;
  TestAwakable oneshot0;
  TestAwakable oneshot1;

  HandleSignalsState old_state(MOJO_HANDLE_SIGNAL_NONE,
                               MOJO_HANDLE_SIGNAL_WRITABLE);
  awakable_list.Add(&persistent0, 100, true, MOJO_HANDLE_SIGNAL_WRITABLE,
                    old_state);
  EXPECT_EQ(persistent0.awake_count, 1u);
  EXPECT_EQ(persistent0.last_context, 100u);
  EXPECT_EQ(persistent0.last_reason, Awakable::AwakeReason::INITIALIZE);
  EXPECT_TRUE(persistent0.last_state.equals(old_state));
  awakable_list.Add(&persistent1, 101, true, MOJO_HANDLE_SIGNAL_WRITABLE,
                    old_state);
  EXPECT_EQ(persistent1.awake_count, 1u);
  EXPECT_EQ(persistent1.last_context, 101u);
  EXPECT_EQ(persistent1.last_reason, Awakable::AwakeReason::INITIALIZE);
  EXPECT_TRUE(persistent1.last_state.equals(old_state));
  awakable_list.Add(&oneshot0, 200, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                    old_state);
  EXPECT_EQ(oneshot0.awake_count, 0u);
  awakable_list.Add(&oneshot1, 201, false, MOJO_HANDLE_SIGNAL_WRITABLE,
                    old_state);
  EXPECT_EQ(oneshot1.awake_count, 0u);

  HandleSignalsState new_state(MOJO_HANDLE_SIGNAL_WRITABLE,
                               MOJO_HANDLE_SIGNAL_WRITABLE);
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent0.awake_count, 2u);
  EXPECT_EQ(persistent0.last_context, 100u);
  EXPECT_EQ(persistent0.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_TRUE(persistent0.last_state.equals(old_state));
  EXPECT_EQ(persistent1.awake_count, 2u);
  EXPECT_EQ(persistent1.last_context, 101u);
  EXPECT_EQ(persistent1.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_TRUE(persistent1.last_state.equals(old_state));
  EXPECT_EQ(oneshot0.awake_count, 1u);
  EXPECT_EQ(oneshot0.last_context, 200u);
  EXPECT_EQ(oneshot0.last_reason, Awakable::AwakeReason::SATISFIED);
  EXPECT_TRUE(oneshot0.last_state.equals(old_state));
  EXPECT_EQ(oneshot1.awake_count, 1u);
  EXPECT_EQ(oneshot1.last_context, 201u);
  EXPECT_EQ(oneshot1.last_reason, Awakable::AwakeReason::SATISFIED);
  EXPECT_TRUE(oneshot1.last_state.equals(old_state));

  new_state =
      HandleSignalsState(MOJO_HANDLE_SIGNAL_NONE, MOJO_HANDLE_SIGNAL_WRITABLE);
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent0.awake_count, 3u);
  EXPECT_EQ(persistent0.last_context, 100u);
  EXPECT_EQ(persistent0.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_TRUE(persistent0.last_state.equals(HandleSignalsState(
      MOJO_HANDLE_SIGNAL_NONE, MOJO_HANDLE_SIGNAL_WRITABLE)));
  EXPECT_EQ(persistent1.awake_count, 3u);
  EXPECT_EQ(persistent1.last_context, 101u);
  EXPECT_EQ(persistent1.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_TRUE(persistent1.last_state.equals(HandleSignalsState(
      MOJO_HANDLE_SIGNAL_NONE, MOJO_HANDLE_SIGNAL_WRITABLE)));
  EXPECT_EQ(oneshot0.awake_count, 1u);
  EXPECT_EQ(oneshot1.awake_count, 1u);

  new_state = HandleSignalsState(MOJO_HANDLE_SIGNAL_WRITABLE,
                                 MOJO_HANDLE_SIGNAL_WRITABLE);
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent0.last_context, 100u);
  EXPECT_EQ(persistent0.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_TRUE(persistent0.last_state.equals(HandleSignalsState(
      MOJO_HANDLE_SIGNAL_WRITABLE, MOJO_HANDLE_SIGNAL_WRITABLE)));
  EXPECT_EQ(persistent1.awake_count, 4u);
  EXPECT_EQ(persistent1.last_context, 101u);
  EXPECT_EQ(persistent1.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_TRUE(persistent1.last_state.equals(HandleSignalsState(
      MOJO_HANDLE_SIGNAL_WRITABLE, MOJO_HANDLE_SIGNAL_WRITABLE)));
  EXPECT_EQ(oneshot0.awake_count, 1u);
  EXPECT_EQ(oneshot1.awake_count, 1u);

  awakable_list.Remove(false, &persistent0, 0);
  awakable_list.Remove(false, &persistent1, 0);
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 4u);
  EXPECT_EQ(oneshot0.awake_count, 1u);
  EXPECT_EQ(oneshot1.awake_count, 1u);

  new_state =
      HandleSignalsState(MOJO_HANDLE_SIGNAL_NONE, MOJO_HANDLE_SIGNAL_WRITABLE);
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 4u);
  EXPECT_EQ(oneshot0.awake_count, 1u);
  EXPECT_EQ(oneshot1.awake_count, 1u);
}

// Checks carefully that persistent awakables see all changes whereas one-shot
// awakables see only "leading edges".
TEST(AwakableListTest, PersistentVsOneShot2) {
  static constexpr MojoHandleSignals kNone = MOJO_HANDLE_SIGNAL_NONE;
  static constexpr MojoHandleSignals kR = MOJO_HANDLE_SIGNAL_READABLE;
  static constexpr MojoHandleSignals kW = MOJO_HANDLE_SIGNAL_WRITABLE;
  static constexpr MojoHandleSignals kPC = MOJO_HANDLE_SIGNAL_PEER_CLOSED;

  AwakableList awakable_list;
  TestAwakable persistent;
  TestAwakable oneshot;

  // Starting state: Satisfied: None. Satisfiable: R | W | PC.
  HandleSignalsState old_state(kNone, kR | kW | kPC);
  HandleSignalsState new_state = old_state;

  // Watch R and PC; we'll do the same for |oneshot|, but add/remove each time.
  awakable_list.Add(&persistent, 123, true, kR | kPC, old_state);
  EXPECT_EQ(persistent.awake_count, 1u);
  EXPECT_EQ(persistent.last_reason, Awakable::AwakeReason::INITIALIZE);

  // Satisfied: +R.
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfied_signals |= kR;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 2u);
  EXPECT_EQ(persistent.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_EQ(oneshot.awake_count, 1u);
  EXPECT_EQ(oneshot.last_reason, Awakable::AwakeReason::SATISFIED);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfied: -R.
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfied_signals &= ~kR;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 3u);
  EXPECT_EQ(persistent.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_EQ(oneshot.awake_count, 0u);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfied: +W.
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfied_signals |= kW;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 3u);
  EXPECT_EQ(oneshot.awake_count, 0u);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfied: +PC -W.
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfied_signals |= kPC;
  new_state.satisfied_signals &= ~kW;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 4u);
  EXPECT_EQ(oneshot.awake_count, 1u);
  EXPECT_EQ(oneshot.last_reason, Awakable::AwakeReason::SATISFIED);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfied: +R -PC.
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfied_signals |= kR;
  new_state.satisfied_signals &= ~kPC;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 5u);
  EXPECT_EQ(persistent.last_reason, Awakable::AwakeReason::CHANGED);
  // It was previously satisfied and remains satisfied (for different reasons),
  // so the one-shot does not observe this change.
  EXPECT_EQ(oneshot.awake_count, 0u);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfiable: -PC.
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfiable_signals &= ~kPC;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 6u);
  EXPECT_EQ(persistent.last_reason, Awakable::AwakeReason::CHANGED);
  EXPECT_EQ(oneshot.awake_count, 0u);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfiable: -W.
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfiable_signals &= ~kW;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 6u);
  EXPECT_EQ(oneshot.awake_count, 0u);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfied: -R. Satisfiable: -R.
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfied_signals &= ~kR;
  new_state.satisfiable_signals &= ~kR;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 7u);
  EXPECT_EQ(persistent.last_reason, Awakable::AwakeReason::CHANGED);
  // "Leading edge" for one-shot is "rising" for (overall) satisfied-ness and
  // "falling" for (overall) satisfiability, so it's really picking up the -R in
  // satisfiability here.
  EXPECT_EQ(oneshot.awake_count, 1u);
  EXPECT_EQ(oneshot.last_reason, Awakable::AwakeReason::UNSATISFIABLE);
  awakable_list.Remove(true, &oneshot, 456);

  // Satisfiable: +R:
  oneshot.awake_count = 0;
  awakable_list.Add(&oneshot, 456, false, kR | kPC, old_state);
  new_state.satisfiable_signals |= kR;
  awakable_list.OnStateChange(old_state, new_state);
  old_state = new_state;
  EXPECT_EQ(persistent.awake_count, 8u);
  EXPECT_EQ(persistent.last_reason, Awakable::AwakeReason::CHANGED);
  // And the one-shot doesn't pick up the +R in satisfiability here.
  EXPECT_EQ(oneshot.awake_count, 0u);
  awakable_list.Remove(true, &oneshot, 456);

  awakable_list.Remove(true, &persistent, 123);
  EXPECT_EQ(persistent.awake_count, 8u);
}

TEST(AwakableListTest, RemoveNoMatchContext) {
  static constexpr MojoHandleSignals kNone = MOJO_HANDLE_SIGNAL_NONE;
  static constexpr MojoHandleSignals kR = MOJO_HANDLE_SIGNAL_READABLE;

  AwakableList awakable_list;
  TestAwakable persistent0;
  TestAwakable persistent1;

  // Add |persistent0| twice, with different contexts.
  awakable_list.Add(&persistent0, 12, true, kR, HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 1u);
  awakable_list.Add(&persistent0, 34, true, kR, HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 2u);
  awakable_list.Add(&persistent1, 56, true, kR, HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent1.awake_count, 1u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kR, kR));
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 2u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 2u);

  awakable_list.Remove(false, &persistent0, 0);
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 2u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kR, kR));
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 3u);

  awakable_list.Remove(false, &persistent1, 0);
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 3u);
}

TEST(AwakableListTest, RemoveMatchContext2) {
  static constexpr MojoHandleSignals kNone = MOJO_HANDLE_SIGNAL_NONE;
  static constexpr MojoHandleSignals kR = MOJO_HANDLE_SIGNAL_READABLE;

  AwakableList awakable_list;
  TestAwakable persistent0;
  TestAwakable persistent1;

  // Add |persistent0| twice, with different contexts.
  awakable_list.Add(&persistent0, 12, true, kR, HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 1u);
  awakable_list.Add(&persistent0, 34, true, kR, HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 2u);
  awakable_list.Add(&persistent1, 56, true, kR, HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent1.awake_count, 1u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kR, kR));
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 2u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 2u);

  awakable_list.Remove(true, &persistent0, 34);
  EXPECT_EQ(persistent0.awake_count, 4u);
  EXPECT_EQ(persistent1.awake_count, 2u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kR, kR));
  EXPECT_EQ(persistent0.awake_count, 5u);
  EXPECT_EQ(persistent0.last_context, 12u);
  EXPECT_EQ(persistent1.awake_count, 3u);

  // No-op: non-existent context.
  awakable_list.Remove(true, &persistent1, 0);
  EXPECT_EQ(persistent0.awake_count, 5u);
  EXPECT_EQ(persistent1.awake_count, 3u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 5u);
  EXPECT_EQ(persistent1.awake_count, 3u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kR, kR));
  EXPECT_EQ(persistent0.awake_count, 6u);
  EXPECT_EQ(persistent0.last_context, 12u);
  EXPECT_EQ(persistent1.awake_count, 4u);

  awakable_list.Remove(true, &persistent0, 12);
  awakable_list.Remove(true, &persistent1, 56);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kNone, kR));
  EXPECT_EQ(persistent0.awake_count, 6u);
  EXPECT_EQ(persistent1.awake_count, 4u);

  awakable_list.OnStateChange(HandleSignalsState(kNone, kR),
                              HandleSignalsState(kR, kR));
  EXPECT_EQ(persistent0.awake_count, 6u);
  EXPECT_EQ(persistent1.awake_count, 4u);
}

}  // namespace
}  // namespace system
}  // namespace mojo
