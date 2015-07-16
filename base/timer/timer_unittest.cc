// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/test/test_simple_task_runner.h"
#include "base/timer/timer.h"
#include "testing/gtest/include/gtest/gtest.h"

using base::TimeDelta;
using base::SingleThreadTaskRunner;

namespace {

// The message loops on which each timer should be tested.
const base::MessageLoop::Type testing_message_loops[] = {
  base::MessageLoop::TYPE_DEFAULT,
  base::MessageLoop::TYPE_IO,
#if !defined(OS_IOS)  // iOS does not allow direct running of the UI loop.
  base::MessageLoop::TYPE_UI,
#endif
};

const int kNumTestingMessageLoops = arraysize(testing_message_loops);

class OneShotTimerTester {
 public:
  explicit OneShotTimerTester(bool* did_run, unsigned milliseconds = 10)
      : did_run_(did_run),
        delay_ms_(milliseconds),
        quit_message_loop_(true) {
  }

  void Start() {
    timer_.Start(FROM_HERE, TimeDelta::FromMilliseconds(delay_ms_), this,
                 &OneShotTimerTester::Run);
  }

  void SetTaskRunner(scoped_refptr<SingleThreadTaskRunner> task_runner) {
    quit_message_loop_ = false;
    timer_.SetTaskRunner(task_runner);
  }

 private:
  void Run() {
    *did_run_ = true;
    if (quit_message_loop_) {
      base::MessageLoop::current()->QuitWhenIdle();
    }
  }

  bool* did_run_;
  base::OneShotTimer<OneShotTimerTester> timer_;
  const unsigned delay_ms_;
  bool quit_message_loop_;
};

class OneShotSelfDeletingTimerTester {
 public:
  explicit OneShotSelfDeletingTimerTester(bool* did_run) :
      did_run_(did_run),
      timer_(new base::OneShotTimer<OneShotSelfDeletingTimerTester>()) {
  }

  void Start() {
    timer_->Start(FROM_HERE, TimeDelta::FromMilliseconds(10), this,
                  &OneShotSelfDeletingTimerTester::Run);
  }

 private:
  void Run() {
    *did_run_ = true;
    timer_.reset();
    base::MessageLoop::current()->QuitWhenIdle();
  }

  bool* did_run_;
  scoped_ptr<base::OneShotTimer<OneShotSelfDeletingTimerTester> > timer_;
};

class RepeatingTimerTester {
 public:
  explicit RepeatingTimerTester(bool* did_run, const TimeDelta& delay)
      : did_run_(did_run), counter_(10), delay_(delay) {
  }

  void Start() {
    timer_.Start(FROM_HERE, delay_, this, &RepeatingTimerTester::Run);
  }

 private:
  void Run() {
    if (--counter_ == 0) {
      *did_run_ = true;
      timer_.Stop();
      base::MessageLoop::current()->QuitWhenIdle();
    }
  }

  bool* did_run_;
  int counter_;
  TimeDelta delay_;
  base::RepeatingTimer<RepeatingTimerTester> timer_;
};

void RunTest_OneShotTimer(base::MessageLoop::Type message_loop_type) {
  base::MessageLoop loop(message_loop_type);

  bool did_run = false;
  OneShotTimerTester f(&did_run);
  f.Start();

  base::MessageLoop::current()->Run();

  EXPECT_TRUE(did_run);
}

void RunTest_OneShotTimer_Cancel(base::MessageLoop::Type message_loop_type) {
  base::MessageLoop loop(message_loop_type);

  bool did_run_a = false;
  OneShotTimerTester* a = new OneShotTimerTester(&did_run_a);

  // This should run before the timer expires.
  base::MessageLoop::current()->DeleteSoon(FROM_HERE, a);

  // Now start the timer.
  a->Start();

  bool did_run_b = false;
  OneShotTimerTester b(&did_run_b);
  b.Start();

  base::MessageLoop::current()->Run();

  EXPECT_FALSE(did_run_a);
  EXPECT_TRUE(did_run_b);
}

void RunTest_OneShotSelfDeletingTimer(
    base::MessageLoop::Type message_loop_type) {
  base::MessageLoop loop(message_loop_type);

  bool did_run = false;
  OneShotSelfDeletingTimerTester f(&did_run);
  f.Start();

  base::MessageLoop::current()->Run();

  EXPECT_TRUE(did_run);
}

void RunTest_RepeatingTimer(base::MessageLoop::Type message_loop_type,
                            const TimeDelta& delay) {
  base::MessageLoop loop(message_loop_type);

  bool did_run = false;
  RepeatingTimerTester f(&did_run, delay);
  f.Start();

  base::MessageLoop::current()->Run();

  EXPECT_TRUE(did_run);
}

void RunTest_RepeatingTimer_Cancel(base::MessageLoop::Type message_loop_type,
                                   const TimeDelta& delay) {
  base::MessageLoop loop(message_loop_type);

  bool did_run_a = false;
  RepeatingTimerTester* a = new RepeatingTimerTester(&did_run_a, delay);

  // This should run before the timer expires.
  base::MessageLoop::current()->DeleteSoon(FROM_HERE, a);

  // Now start the timer.
  a->Start();

  bool did_run_b = false;
  RepeatingTimerTester b(&did_run_b, delay);
  b.Start();

  base::MessageLoop::current()->Run();

  EXPECT_FALSE(did_run_a);
  EXPECT_TRUE(did_run_b);
}

class DelayTimerTarget {
 public:
  bool signaled() const { return signaled_; }

  void Signal() {
    ASSERT_FALSE(signaled_);
    signaled_ = true;
  }

 private:
  bool signaled_ = false;
};

void RunTest_DelayTimer_NoCall(base::MessageLoop::Type message_loop_type) {
  base::MessageLoop loop(message_loop_type);

  // If Delay is never called, the timer shouldn't go off.
  DelayTimerTarget target;
  base::DelayTimer<DelayTimerTarget> timer(FROM_HERE,
      TimeDelta::FromMilliseconds(1), &target, &DelayTimerTarget::Signal);

  bool did_run = false;
  OneShotTimerTester tester(&did_run);
  tester.Start();
  base::MessageLoop::current()->Run();

  ASSERT_FALSE(target.signaled());
}

void RunTest_DelayTimer_OneCall(base::MessageLoop::Type message_loop_type) {
  base::MessageLoop loop(message_loop_type);

  DelayTimerTarget target;
  base::DelayTimer<DelayTimerTarget> timer(FROM_HERE,
      TimeDelta::FromMilliseconds(1), &target, &DelayTimerTarget::Signal);
  timer.Reset();

  bool did_run = false;
  OneShotTimerTester tester(&did_run, 100 /* milliseconds */);
  tester.Start();
  base::MessageLoop::current()->Run();

  ASSERT_TRUE(target.signaled());
}

struct ResetHelper {
  ResetHelper(base::DelayTimer<DelayTimerTarget>* timer,
              DelayTimerTarget* target)
      : timer_(timer),
        target_(target) {
  }

  void Reset() {
    ASSERT_FALSE(target_->signaled());
    timer_->Reset();
  }

 private:
  base::DelayTimer<DelayTimerTarget> *const timer_;
  DelayTimerTarget *const target_;
};

void RunTest_DelayTimer_Reset(base::MessageLoop::Type message_loop_type) {
  base::MessageLoop loop(message_loop_type);

  // If Delay is never called, the timer shouldn't go off.
  DelayTimerTarget target;
  base::DelayTimer<DelayTimerTarget> timer(FROM_HERE,
      TimeDelta::FromMilliseconds(50), &target, &DelayTimerTarget::Signal);
  timer.Reset();

  ResetHelper reset_helper(&timer, &target);

  base::OneShotTimer<ResetHelper> timers[20];
  for (size_t i = 0; i < arraysize(timers); ++i) {
    timers[i].Start(FROM_HERE, TimeDelta::FromMilliseconds(i * 10),
                    &reset_helper, &ResetHelper::Reset);
  }

  bool did_run = false;
  OneShotTimerTester tester(&did_run, 300);
  tester.Start();
  base::MessageLoop::current()->Run();

  ASSERT_TRUE(target.signaled());
}

class DelayTimerFatalTarget {
 public:
  void Signal() {
    ASSERT_TRUE(false);
  }
};


void RunTest_DelayTimer_Deleted(base::MessageLoop::Type message_loop_type) {
  base::MessageLoop loop(message_loop_type);

  DelayTimerFatalTarget target;

  {
    base::DelayTimer<DelayTimerFatalTarget> timer(
        FROM_HERE, TimeDelta::FromMilliseconds(50), &target,
        &DelayTimerFatalTarget::Signal);
    timer.Reset();
  }

  // When the timer is deleted, the DelayTimerFatalTarget should never be
  // called.
  base::PlatformThread::Sleep(base::TimeDelta::FromMilliseconds(100));
}

}  // namespace

//-----------------------------------------------------------------------------
// Each test is run against each type of MessageLoop.  That way we are sure
// that timers work properly in all configurations.

TEST(TimerTest, OneShotTimer) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_OneShotTimer(testing_message_loops[i]);
  }
}

TEST(TimerTest, OneShotTimer_Cancel) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_OneShotTimer_Cancel(testing_message_loops[i]);
  }
}

// If underline timer does not handle properly, we will crash or fail
// in full page heap environment.
TEST(TimerTest, OneShotSelfDeletingTimer) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_OneShotSelfDeletingTimer(testing_message_loops[i]);
  }
}

TEST(TimerTest, OneShotTimer_CustomTaskRunner) {
  scoped_refptr<base::TestSimpleTaskRunner> task_runner =
      new base::TestSimpleTaskRunner();

  bool did_run = false;
  OneShotTimerTester f(&did_run);
  f.SetTaskRunner(task_runner);
  f.Start();

  EXPECT_FALSE(did_run);
  task_runner->RunUntilIdle();
  EXPECT_TRUE(did_run);
}

TEST(TimerTest, RepeatingTimer) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_RepeatingTimer(testing_message_loops[i],
                           TimeDelta::FromMilliseconds(10));
  }
}

TEST(TimerTest, RepeatingTimer_Cancel) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_RepeatingTimer_Cancel(testing_message_loops[i],
                                  TimeDelta::FromMilliseconds(10));
  }
}

TEST(TimerTest, RepeatingTimerZeroDelay) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_RepeatingTimer(testing_message_loops[i],
                           TimeDelta::FromMilliseconds(0));
  }
}

TEST(TimerTest, RepeatingTimerZeroDelay_Cancel) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_RepeatingTimer_Cancel(testing_message_loops[i],
                                  TimeDelta::FromMilliseconds(0));
  }
}

TEST(TimerTest, DelayTimer_NoCall) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_DelayTimer_NoCall(testing_message_loops[i]);
  }
}

TEST(TimerTest, DelayTimer_OneCall) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_DelayTimer_OneCall(testing_message_loops[i]);
  }
}

// It's flaky on the buildbot, http://crbug.com/25038.
TEST(TimerTest, DISABLED_DelayTimer_Reset) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_DelayTimer_Reset(testing_message_loops[i]);
  }
}

TEST(TimerTest, DelayTimer_Deleted) {
  for (int i = 0; i < kNumTestingMessageLoops; i++) {
    RunTest_DelayTimer_Deleted(testing_message_loops[i]);
  }
}

TEST(TimerTest, MessageLoopShutdown) {
  // This test is designed to verify that shutdown of the
  // message loop does not cause crashes if there were pending
  // timers not yet fired.  It may only trigger exceptions
  // if debug heap checking is enabled.
  bool did_run = false;
  {
    OneShotTimerTester a(&did_run);
    OneShotTimerTester b(&did_run);
    OneShotTimerTester c(&did_run);
    OneShotTimerTester d(&did_run);
    {
      base::MessageLoop loop;
      a.Start();
      b.Start();
    }  // MessageLoop destructs by falling out of scope.
  }  // OneShotTimers destruct.  SHOULD NOT CRASH, of course.

  EXPECT_FALSE(did_run);
}

void TimerTestCallback() {
}

TEST(TimerTest, NonRepeatIsRunning) {
  {
    base::MessageLoop loop;
    base::Timer timer(false, false);
    EXPECT_FALSE(timer.IsRunning());
    timer.Start(FROM_HERE, TimeDelta::FromDays(1),
                base::Bind(&TimerTestCallback));
    EXPECT_TRUE(timer.IsRunning());
    timer.Stop();
    EXPECT_FALSE(timer.IsRunning());
    EXPECT_TRUE(timer.user_task().is_null());
  }

  {
    base::Timer timer(true, false);
    base::MessageLoop loop;
    EXPECT_FALSE(timer.IsRunning());
    timer.Start(FROM_HERE, TimeDelta::FromDays(1),
                base::Bind(&TimerTestCallback));
    EXPECT_TRUE(timer.IsRunning());
    timer.Stop();
    EXPECT_FALSE(timer.IsRunning());
    ASSERT_FALSE(timer.user_task().is_null());
    timer.Reset();
    EXPECT_TRUE(timer.IsRunning());
  }
}

TEST(TimerTest, NonRepeatMessageLoopDeath) {
  base::Timer timer(false, false);
  {
    base::MessageLoop loop;
    EXPECT_FALSE(timer.IsRunning());
    timer.Start(FROM_HERE, TimeDelta::FromDays(1),
                base::Bind(&TimerTestCallback));
    EXPECT_TRUE(timer.IsRunning());
  }
  EXPECT_FALSE(timer.IsRunning());
  EXPECT_TRUE(timer.user_task().is_null());
}

TEST(TimerTest, RetainRepeatIsRunning) {
  base::MessageLoop loop;
  base::Timer timer(FROM_HERE, TimeDelta::FromDays(1),
                    base::Bind(&TimerTestCallback), true);
  EXPECT_FALSE(timer.IsRunning());
  timer.Reset();
  EXPECT_TRUE(timer.IsRunning());
  timer.Stop();
  EXPECT_FALSE(timer.IsRunning());
  timer.Reset();
  EXPECT_TRUE(timer.IsRunning());
}

TEST(TimerTest, RetainNonRepeatIsRunning) {
  base::MessageLoop loop;
  base::Timer timer(FROM_HERE, TimeDelta::FromDays(1),
                    base::Bind(&TimerTestCallback), false);
  EXPECT_FALSE(timer.IsRunning());
  timer.Reset();
  EXPECT_TRUE(timer.IsRunning());
  timer.Stop();
  EXPECT_FALSE(timer.IsRunning());
  timer.Reset();
  EXPECT_TRUE(timer.IsRunning());
}

namespace {

bool g_callback_happened1 = false;
bool g_callback_happened2 = false;

void ClearAllCallbackHappened() {
  g_callback_happened1 = false;
  g_callback_happened2 = false;
}

void SetCallbackHappened1() {
  g_callback_happened1 = true;
  base::MessageLoop::current()->QuitWhenIdle();
}

void SetCallbackHappened2() {
  g_callback_happened2 = true;
  base::MessageLoop::current()->QuitWhenIdle();
}

TEST(TimerTest, ContinuationStopStart) {
  {
    ClearAllCallbackHappened();
    base::MessageLoop loop;
    base::Timer timer(false, false);
    timer.Start(FROM_HERE, TimeDelta::FromMilliseconds(10),
                base::Bind(&SetCallbackHappened1));
    timer.Stop();
    timer.Start(FROM_HERE, TimeDelta::FromMilliseconds(40),
                base::Bind(&SetCallbackHappened2));
    base::MessageLoop::current()->Run();
    EXPECT_FALSE(g_callback_happened1);
    EXPECT_TRUE(g_callback_happened2);
  }
}

TEST(TimerTest, ContinuationReset) {
  {
    ClearAllCallbackHappened();
    base::MessageLoop loop;
    base::Timer timer(false, false);
    timer.Start(FROM_HERE, TimeDelta::FromMilliseconds(10),
                base::Bind(&SetCallbackHappened1));
    timer.Reset();
    // Since Reset happened before task ran, the user_task must not be cleared:
    ASSERT_FALSE(timer.user_task().is_null());
    base::MessageLoop::current()->Run();
    EXPECT_TRUE(g_callback_happened1);
  }
}

}  // namespace
