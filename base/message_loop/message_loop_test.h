// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_LOOP_TEST_H_
#define BASE_MESSAGE_LOOP_MESSAGE_LOOP_TEST_H_

#include "base/message_loop/message_loop.h"
#include "testing/gtest/include/gtest/gtest.h"

// This file consists of tests meant to exercise the combination of MessageLoop
// and MessagePump. To use these define the macro RUN_MESSAGE_LOOP_TESTS using
// an ID appropriate for your MessagePump, eg
// RUN_MESSAGE_LOOP_TESTS(UI, factory). Factory is a function called to create
// the MessagePump.
namespace base {
namespace test {

typedef MessageLoop::MessagePumpFactory MessagePumpFactory;

void RunTest_PostTask(MessagePumpFactory factory);
void RunTest_PostDelayedTask_Basic(MessagePumpFactory factory);
void RunTest_PostDelayedTask_InDelayOrder(MessagePumpFactory factory);
void RunTest_PostDelayedTask_InPostOrder(MessagePumpFactory factory);
void RunTest_PostDelayedTask_InPostOrder_2(MessagePumpFactory factory);
void RunTest_PostDelayedTask_InPostOrder_3(MessagePumpFactory factory);
void RunTest_PostDelayedTask_SharedTimer(MessagePumpFactory factory);
void RunTest_EnsureDeletion(MessagePumpFactory factory);
void RunTest_EnsureDeletion_Chain(MessagePumpFactory factory);
void RunTest_Nesting(MessagePumpFactory factory);
void RunTest_RecursiveDenial1(MessagePumpFactory factory);
void RunTest_RecursiveDenial3(MessagePumpFactory factory);
void RunTest_RecursiveSupport1(MessagePumpFactory factory);
void RunTest_NonNestableWithNoNesting(MessagePumpFactory factory);
void RunTest_NonNestableInNestedLoop(MessagePumpFactory factory,
                                     bool use_delayed);
void RunTest_QuitNow(MessagePumpFactory factory);
void RunTest_RunLoopQuitTop(MessagePumpFactory factory);
void RunTest_RunLoopQuitNested(MessagePumpFactory factory);
void RunTest_RunLoopQuitBogus(MessagePumpFactory factory);
void RunTest_RunLoopQuitDeep(MessagePumpFactory factory);
void RunTest_RunLoopQuitOrderBefore(MessagePumpFactory factory);
void RunTest_RunLoopQuitOrderDuring(MessagePumpFactory factory);
void RunTest_RunLoopQuitOrderAfter(MessagePumpFactory factory);
void RunTest_RecursivePosts(MessagePumpFactory factory);

}  // namespace test
}  // namespace base

#define RUN_MESSAGE_LOOP_TESTS(id, factory) \
  TEST(MessageLoopTestType##id, PostTask) { \
    base::test::RunTest_PostTask(factory); \
  } \
  TEST(MessageLoopTestType##id, PostDelayedTask_Basic) { \
    base::test::RunTest_PostDelayedTask_Basic(factory); \
  } \
  TEST(MessageLoopTestType##id, PostDelayedTask_InDelayOrder) { \
    base::test::RunTest_PostDelayedTask_InDelayOrder(factory); \
  } \
  TEST(MessageLoopTestType##id, PostDelayedTask_InPostOrder) { \
    base::test::RunTest_PostDelayedTask_InPostOrder(factory); \
  } \
  TEST(MessageLoopTestType##id, PostDelayedTask_InPostOrder_2) { \
    base::test::RunTest_PostDelayedTask_InPostOrder_2(factory); \
  } \
  TEST(MessageLoopTestType##id, PostDelayedTask_InPostOrder_3) { \
    base::test::RunTest_PostDelayedTask_InPostOrder_3(factory); \
  } \
  TEST(MessageLoopTestType##id, PostDelayedTask_SharedTimer) { \
    base::test::RunTest_PostDelayedTask_SharedTimer(factory); \
  } \
  /* TODO(darin): MessageLoop does not support deleting all tasks in the */ \
  /* destructor. */ \
  /* Fails, http://crbug.com/50272. */ \
  TEST(MessageLoopTestType##id, DISABLED_EnsureDeletion) { \
    base::test::RunTest_EnsureDeletion(factory); \
  } \
  /* TODO(darin): MessageLoop does not support deleting all tasks in the */ \
  /* destructor. */ \
  /* Fails, http://crbug.com/50272. */ \
  TEST(MessageLoopTestType##id, DISABLED_EnsureDeletion_Chain) { \
    base::test::RunTest_EnsureDeletion_Chain(factory); \
  } \
  TEST(MessageLoopTestType##id, Nesting) { \
    base::test::RunTest_Nesting(factory); \
  } \
  TEST(MessageLoopTestType##id, RecursiveDenial1) { \
    base::test::RunTest_RecursiveDenial1(factory); \
  } \
  TEST(MessageLoopTestType##id, RecursiveDenial3) { \
    base::test::RunTest_RecursiveDenial3(factory); \
  } \
  TEST(MessageLoopTestType##id, RecursiveSupport1) { \
    base::test::RunTest_RecursiveSupport1(factory); \
  } \
  TEST(MessageLoopTestType##id, NonNestableWithNoNesting) { \
    base::test::RunTest_NonNestableWithNoNesting(factory); \
  } \
  TEST(MessageLoopTestType##id, NonNestableInNestedLoop) { \
    base::test::RunTest_NonNestableInNestedLoop(factory, false); \
  } \
  TEST(MessageLoopTestType##id, NonNestableDelayedInNestedLoop) { \
    base::test::RunTest_NonNestableInNestedLoop(factory, true); \
  } \
  TEST(MessageLoopTestType##id, QuitNow) { \
    base::test::RunTest_QuitNow(factory); \
  } \
  TEST(MessageLoopTestType##id, RunLoopQuitTop) { \
    base::test::RunTest_RunLoopQuitTop(factory); \
  } \
  TEST(MessageLoopTestType##id, RunLoopQuitNested) { \
    base::test::RunTest_RunLoopQuitNested(factory); \
  } \
  TEST(MessageLoopTestType##id, RunLoopQuitBogus) { \
    base::test::RunTest_RunLoopQuitBogus(factory); \
  } \
  TEST(MessageLoopTestType##id, RunLoopQuitDeep) { \
    base::test::RunTest_RunLoopQuitDeep(factory); \
  } \
  TEST(MessageLoopTestType##id, RunLoopQuitOrderBefore) { \
    base::test::RunTest_RunLoopQuitOrderBefore(factory); \
  } \
  TEST(MessageLoopTestType##id, RunLoopQuitOrderDuring) { \
    base::test::RunTest_RunLoopQuitOrderDuring(factory); \
  } \
  TEST(MessageLoopTestType##id, RunLoopQuitOrderAfter) { \
    base::test::RunTest_RunLoopQuitOrderAfter(factory); \
  } \
  TEST(MessageLoopTestType##id, RecursivePosts) { \
    base::test::RunTest_RecursivePosts(factory); \
  } \

#endif  // BASE_MESSAGE_LOOP_MESSAGE_LOOP_TEST_H_
