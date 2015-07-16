// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/compiler_specific.h"
#include "base/macros.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/platform_thread.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_WIN)
#include <windows.h>
#endif

namespace base {

// Trivial tests that thread runs and doesn't crash on create and join ---------

class TrivialThread : public PlatformThread::Delegate {
 public:
  TrivialThread() : did_run_(false) {}

  void ThreadMain() override { did_run_ = true; }

  bool did_run() const { return did_run_; }

 private:
  bool did_run_;

  DISALLOW_COPY_AND_ASSIGN(TrivialThread);
};

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

class FunctionTestThread : public PlatformThread::Delegate {
 public:
  FunctionTestThread()
      : thread_id_(kInvalidThreadId),
        thread_started_(true, false),
        terminate_thread_(true, false),
        done_(false) {}
  ~FunctionTestThread() override {
    EXPECT_TRUE(terminate_thread_.IsSignaled())
        << "Need to mark thread for termination and join the underlying thread "
        << "before destroying a FunctionTestThread as it owns the "
        << "WaitableEvent blocking the underlying thread's main.";
  }

  // Grabs |thread_id_|, signals |thread_started_|, and then waits for
  // |terminate_thread_| to be signaled before exiting.
  void ThreadMain() override {
    thread_id_ = PlatformThread::CurrentId();
    EXPECT_NE(thread_id_, kInvalidThreadId);

    // Make sure that the thread ID is the same across calls.
    EXPECT_EQ(thread_id_, PlatformThread::CurrentId());

    thread_started_.Signal();

    terminate_thread_.Wait();

    done_ = true;
  }

  PlatformThreadId thread_id() const {
    EXPECT_TRUE(thread_started_.IsSignaled()) << "Thread ID still unknown";
    return thread_id_;
  }

  bool IsRunning() const {
    return thread_started_.IsSignaled() && !done_;
  }

  // Blocks until this thread is started.
  void WaitForThreadStart() { thread_started_.Wait(); }

  // Mark this thread for termination (callers must then join this thread to be
  // guaranteed of termination).
  void MarkForTermination() { terminate_thread_.Signal(); }

 private:
  PlatformThreadId thread_id_;

  mutable WaitableEvent thread_started_;
  WaitableEvent terminate_thread_;
  bool done_;

  DISALLOW_COPY_AND_ASSIGN(FunctionTestThread);
};

TEST(PlatformThreadTest, Function) {
  PlatformThreadId main_thread_id = PlatformThread::CurrentId();

  FunctionTestThread thread;
  PlatformThreadHandle handle;

  ASSERT_FALSE(thread.IsRunning());
  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));
  thread.WaitForThreadStart();
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
    thread[n].WaitForThreadStart();

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
// Disable non-normal priority toggling on POSIX as it appears to be broken
// (http://crbug.com/468793). This is prefered to disabling the tests altogether
// on POSIX as it at least provides coverage for running this code under
// "normal" priority.
#if !defined(OS_POSIX)
    ThreadPriority::DISPLAY,
    ThreadPriority::REALTIME_AUDIO,
    // Keep BACKGROUND second to last to test backgrounding from other
    // priorities.
    ThreadPriority::BACKGROUND,
#endif  // !defined(OS_POSIX)
    // Keep NORMAL last to test unbackgrounding.
    ThreadPriority::NORMAL
};

}  // namespace

// Test changing another thread's priority.
// NOTE: This test is partially disabled on POSIX, see note above and
// http://crbug.com/468793.
TEST(PlatformThreadTest, ThreadPriorityOtherThread) {
  PlatformThreadHandle current_handle(PlatformThread::CurrentHandle());

  // Confirm that the current thread's priority is as expected.
  EXPECT_EQ(ThreadPriority::NORMAL,
            PlatformThread::GetThreadPriority(current_handle));

  // Create a test thread.
  FunctionTestThread thread;
  PlatformThreadHandle handle;
  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));
  thread.WaitForThreadStart();
  EXPECT_NE(thread.thread_id(), kInvalidThreadId);
  EXPECT_NE(thread.thread_id(), PlatformThread::CurrentId());

  // New threads should get normal priority by default.
  EXPECT_EQ(ThreadPriority::NORMAL, PlatformThread::GetThreadPriority(handle));

  // Toggle each supported priority on the test thread and confirm it only
  // affects it (and not the current thread).
  for (size_t i = 0; i < arraysize(kThreadPriorityTestValues); ++i) {
    SCOPED_TRACE(i);

    // Alter and verify the test thread's priority.
    PlatformThread::SetThreadPriority(handle, kThreadPriorityTestValues[i]);
    EXPECT_EQ(kThreadPriorityTestValues[i],
              PlatformThread::GetThreadPriority(handle));

    // Make sure the current thread was otherwise unaffected.
    EXPECT_EQ(ThreadPriority::NORMAL,
              PlatformThread::GetThreadPriority(current_handle));
  }

  thread.MarkForTermination();
  PlatformThread::Join(handle);
}

// Test changing the current thread's priority (which has different semantics on
// some platforms).
// NOTE: This test is partially disabled on POSIX, see note above and
// http://crbug.com/468793.
TEST(PlatformThreadTest, ThreadPriorityCurrentThread) {
  PlatformThreadHandle current_handle(PlatformThread::CurrentHandle());

  // Confirm that the current thread's priority is as expected.
  EXPECT_EQ(ThreadPriority::NORMAL,
            PlatformThread::GetThreadPriority(current_handle));

  // Create a test thread for verification purposes only.
  FunctionTestThread thread;
  PlatformThreadHandle handle;
  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));
  thread.WaitForThreadStart();
  EXPECT_NE(thread.thread_id(), kInvalidThreadId);
  EXPECT_NE(thread.thread_id(), PlatformThread::CurrentId());

  // Confirm that the new thread's priority is as expected.
  EXPECT_EQ(ThreadPriority::NORMAL, PlatformThread::GetThreadPriority(handle));

  // Toggle each supported priority on the current thread and confirm it only
  // affects it (and not the test thread).
  for (size_t i = 0; i < arraysize(kThreadPriorityTestValues); ++i) {
    SCOPED_TRACE(i);

    // Alter and verify the current thread's priority.
    PlatformThread::SetThreadPriority(current_handle,
                                      kThreadPriorityTestValues[i]);
    EXPECT_EQ(kThreadPriorityTestValues[i],
              PlatformThread::GetThreadPriority(current_handle));

    // Make sure the test thread was otherwise unaffected.
    EXPECT_EQ(ThreadPriority::NORMAL,
              PlatformThread::GetThreadPriority(handle));
  }

  // Restore current thread priority for follow-up tests.
  PlatformThread::SetThreadPriority(current_handle, ThreadPriority::NORMAL);

  thread.MarkForTermination();
  PlatformThread::Join(handle);
}

}  // namespace base
