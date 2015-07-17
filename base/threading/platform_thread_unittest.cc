// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/compiler_specific.h"
#include "base/macros.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/platform_thread.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_POSIX)
#include <sys/types.h>
#include <unistd.h>
#elif defined(OS_WIN)
#include <windows.h>
#endif

namespace base {

// Trivial tests that thread runs and doesn't crash on create and join ---------

namespace {

class TrivialThread : public PlatformThread::Delegate {
 public:
  TrivialThread() : did_run_(false) {}

  void ThreadMain() override { did_run_ = true; }

  bool did_run() const { return did_run_; }

 private:
  bool did_run_;

  DISALLOW_COPY_AND_ASSIGN(TrivialThread);
};

}  // namespace

TEST(PlatformThreadTest, Trivial) {
  TrivialThread thread;
  PlatformThreadHandle handle;

  ASSERT_FALSE(thread.did_run());
  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));
  PlatformThread::Join(handle);
  ASSERT_TRUE(thread.did_run());
}

TEST(PlatformThreadTest, TrivialTimesTen) {
  TrivialThread thread[10];
  PlatformThreadHandle handle[arraysize(thread)];

  for (size_t n = 0; n < arraysize(thread); n++)
    ASSERT_FALSE(thread[n].did_run());
  for (size_t n = 0; n < arraysize(thread); n++)
    ASSERT_TRUE(PlatformThread::Create(0, &thread[n], &handle[n]));
  for (size_t n = 0; n < arraysize(thread); n++)
    PlatformThread::Join(handle[n]);
  for (size_t n = 0; n < arraysize(thread); n++)
    ASSERT_TRUE(thread[n].did_run());
}

// Tests of basic thread functions ---------------------------------------------

namespace {

class FunctionTestThread : public PlatformThread::Delegate {
 public:
  FunctionTestThread()
      : thread_id_(kInvalidThreadId),
        termination_ready_(true, false),
        terminate_thread_(true, false),
        done_(false) {}
  ~FunctionTestThread() override {
    EXPECT_TRUE(terminate_thread_.IsSignaled())
        << "Need to mark thread for termination and join the underlying thread "
        << "before destroying a FunctionTestThread as it owns the "
        << "WaitableEvent blocking the underlying thread's main.";
  }

  // Grabs |thread_id_|, runs an optional test on that thread, signals
  // |termination_ready_|, and then waits for |terminate_thread_| to be
  // signaled before exiting.
  void ThreadMain() override {
    thread_id_ = PlatformThread::CurrentId();
    EXPECT_NE(thread_id_, kInvalidThreadId);

    // Make sure that the thread ID is the same across calls.
    EXPECT_EQ(thread_id_, PlatformThread::CurrentId());

    // Run extra tests.
    RunTest();

    termination_ready_.Signal();
    terminate_thread_.Wait();

    done_ = true;
  }

  PlatformThreadId thread_id() const {
    EXPECT_TRUE(termination_ready_.IsSignaled()) << "Thread ID still unknown";
    return thread_id_;
  }

  bool IsRunning() const {
    return termination_ready_.IsSignaled() && !done_;
  }

  // Blocks until this thread is started and ready to be terminated.
  void WaitForTerminationReady() { termination_ready_.Wait(); }

  // Marks this thread for termination (callers must then join this thread to be
  // guaranteed of termination).
  void MarkForTermination() { terminate_thread_.Signal(); }

 private:
  // Runs an optional test on the newly created thread.
  virtual void RunTest() {}

  PlatformThreadId thread_id_;

  mutable WaitableEvent termination_ready_;
  WaitableEvent terminate_thread_;
  bool done_;

  DISALLOW_COPY_AND_ASSIGN(FunctionTestThread);
};

}  // namespace

TEST(PlatformThreadTest, Function) {
  PlatformThreadId main_thread_id = PlatformThread::CurrentId();

  FunctionTestThread thread;
  PlatformThreadHandle handle;

  ASSERT_FALSE(thread.IsRunning());
  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));
  thread.WaitForTerminationReady();
  ASSERT_TRUE(thread.IsRunning());
  EXPECT_NE(thread.thread_id(), main_thread_id);

  thread.MarkForTermination();
  PlatformThread::Join(handle);
  ASSERT_FALSE(thread.IsRunning());

  // Make sure that the thread ID is the same across calls.
  EXPECT_EQ(main_thread_id, PlatformThread::CurrentId());
}

TEST(PlatformThreadTest, FunctionTimesTen) {
  PlatformThreadId main_thread_id = PlatformThread::CurrentId();

  FunctionTestThread thread[10];
  PlatformThreadHandle handle[arraysize(thread)];

  for (size_t n = 0; n < arraysize(thread); n++)
    ASSERT_FALSE(thread[n].IsRunning());

  for (size_t n = 0; n < arraysize(thread); n++)
    ASSERT_TRUE(PlatformThread::Create(0, &thread[n], &handle[n]));
  for (size_t n = 0; n < arraysize(thread); n++)
    thread[n].WaitForTerminationReady();

  for (size_t n = 0; n < arraysize(thread); n++) {
    ASSERT_TRUE(thread[n].IsRunning());
    EXPECT_NE(thread[n].thread_id(), main_thread_id);

    // Make sure no two threads get the same ID.
    for (size_t i = 0; i < n; ++i) {
      EXPECT_NE(thread[i].thread_id(), thread[n].thread_id());
    }
  }

  for (size_t n = 0; n < arraysize(thread); n++)
    thread[n].MarkForTermination();
  for (size_t n = 0; n < arraysize(thread); n++)
    PlatformThread::Join(handle[n]);
  for (size_t n = 0; n < arraysize(thread); n++)
    ASSERT_FALSE(thread[n].IsRunning());

  // Make sure that the thread ID is the same across calls.
  EXPECT_EQ(main_thread_id, PlatformThread::CurrentId());
}

namespace {

const ThreadPriority kThreadPriorityTestValues[] = {
// The order should be higher to lower to cover as much cases as possible on
// Linux trybots running without CAP_SYS_NICE permission.
#if !defined(OS_ANDROID)
    // PlatformThread::GetCurrentThreadPriority() on Android does not support
    // REALTIME_AUDIO case. See http://crbug.com/505474.
    ThreadPriority::REALTIME_AUDIO,
#endif
    ThreadPriority::DISPLAY,
    // This redundant BACKGROUND priority is to test backgrounding from other
    // priorities, and unbackgrounding.
    ThreadPriority::BACKGROUND,
    ThreadPriority::NORMAL,
    ThreadPriority::BACKGROUND};

bool IsBumpingPriorityAllowed() {
#if defined(OS_POSIX)
  // Only root can raise thread priority on POSIX environment. On Linux, users
  // who have CAP_SYS_NICE permission also can raise the thread priority, but
  // libcap.so would be needed to check the capability.
  return geteuid() == 0;
#else
  return true;
#endif
}

class ThreadPriorityTestThread : public FunctionTestThread {
 public:
  ThreadPriorityTestThread() = default;
  ~ThreadPriorityTestThread() override = default;

 private:
  void RunTest() override {
    // Confirm that the current thread's priority is as expected.
    EXPECT_EQ(ThreadPriority::NORMAL,
              PlatformThread::GetCurrentThreadPriority());

    // Toggle each supported priority on the current thread and confirm it
    // affects it.
    const bool bumping_priority_allowed = IsBumpingPriorityAllowed();
    for (size_t i = 0; i < arraysize(kThreadPriorityTestValues); ++i) {
      SCOPED_TRACE(i);
      if (!bumping_priority_allowed &&
          kThreadPriorityTestValues[i] >
              PlatformThread::GetCurrentThreadPriority()) {
        continue;
      }

      // Alter and verify the current thread's priority.
      PlatformThread::SetCurrentThreadPriority(kThreadPriorityTestValues[i]);
      EXPECT_EQ(kThreadPriorityTestValues[i],
                PlatformThread::GetCurrentThreadPriority());
    }
  }

  DISALLOW_COPY_AND_ASSIGN(ThreadPriorityTestThread);
};

}  // namespace

#if defined(OS_MACOSX)
// PlatformThread::GetCurrentThreadPriority() is not implemented on OS X.
#define MAYBE_ThreadPriorityCurrentThread DISABLED_ThreadPriorityCurrentThread
#else
#define MAYBE_ThreadPriorityCurrentThread ThreadPriorityCurrentThread
#endif

// Test changing a created thread's priority (which has different semantics on
// some platforms).
TEST(PlatformThreadTest, MAYBE_ThreadPriorityCurrentThread) {
  ThreadPriorityTestThread thread;
  PlatformThreadHandle handle;

  ASSERT_FALSE(thread.IsRunning());
  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));
  thread.WaitForTerminationReady();
  ASSERT_TRUE(thread.IsRunning());

  thread.MarkForTermination();
  PlatformThread::Join(handle);
  ASSERT_FALSE(thread.IsRunning());
}

}  // namespace base
