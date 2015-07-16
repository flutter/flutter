// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process.h"

#include "base/process/kill.h"
#include "base/test/multiprocess_test.h"
#include "base/test/test_timeouts.h"
#include "base/threading/platform_thread.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/multiprocess_func_list.h"

#if defined(OS_MACOSX)
#include <mach/mach.h>
#endif  // OS_MACOSX

namespace {

#if defined(OS_WIN)
const int kExpectedStillRunningExitCode = 0x102;
#else
const int kExpectedStillRunningExitCode = 0;
#endif

}  // namespace

namespace base {

class ProcessTest : public MultiProcessTest {
};

TEST_F(ProcessTest, Create) {
  Process process(SpawnChild("SimpleChildProcess"));
  ASSERT_TRUE(process.IsValid());
  ASSERT_FALSE(process.is_current());
  process.Close();
  ASSERT_FALSE(process.IsValid());
}

TEST_F(ProcessTest, CreateCurrent) {
  Process process = Process::Current();
  ASSERT_TRUE(process.IsValid());
  ASSERT_TRUE(process.is_current());
  process.Close();
  ASSERT_FALSE(process.IsValid());
}

TEST_F(ProcessTest, Move) {
  Process process1(SpawnChild("SimpleChildProcess"));
  EXPECT_TRUE(process1.IsValid());

  Process process2;
  EXPECT_FALSE(process2.IsValid());

  process2 = process1.Pass();
  EXPECT_TRUE(process2.IsValid());
  EXPECT_FALSE(process1.IsValid());
  EXPECT_FALSE(process2.is_current());

  Process process3 = Process::Current();
  process2 = process3.Pass();
  EXPECT_TRUE(process2.is_current());
  EXPECT_TRUE(process2.IsValid());
  EXPECT_FALSE(process3.IsValid());
}

TEST_F(ProcessTest, Duplicate) {
  Process process1(SpawnChild("SimpleChildProcess"));
  ASSERT_TRUE(process1.IsValid());

  Process process2 = process1.Duplicate();
  ASSERT_TRUE(process1.IsValid());
  ASSERT_TRUE(process2.IsValid());
  EXPECT_EQ(process1.Pid(), process2.Pid());
  EXPECT_FALSE(process1.is_current());
  EXPECT_FALSE(process2.is_current());

  process1.Close();
  ASSERT_TRUE(process2.IsValid());
}

TEST_F(ProcessTest, DuplicateCurrent) {
  Process process1 = Process::Current();
  ASSERT_TRUE(process1.IsValid());

  Process process2 = process1.Duplicate();
  ASSERT_TRUE(process1.IsValid());
  ASSERT_TRUE(process2.IsValid());
  EXPECT_EQ(process1.Pid(), process2.Pid());
  EXPECT_TRUE(process1.is_current());
  EXPECT_TRUE(process2.is_current());

  process1.Close();
  ASSERT_TRUE(process2.IsValid());
}

TEST_F(ProcessTest, DeprecatedGetProcessFromHandle) {
  Process process1(SpawnChild("SimpleChildProcess"));
  ASSERT_TRUE(process1.IsValid());

  Process process2 = Process::DeprecatedGetProcessFromHandle(process1.Handle());
  ASSERT_TRUE(process1.IsValid());
  ASSERT_TRUE(process2.IsValid());
  EXPECT_EQ(process1.Pid(), process2.Pid());
  EXPECT_FALSE(process1.is_current());
  EXPECT_FALSE(process2.is_current());

  process1.Close();
  ASSERT_TRUE(process2.IsValid());
}

MULTIPROCESS_TEST_MAIN(SleepyChildProcess) {
  PlatformThread::Sleep(TestTimeouts::action_max_timeout());
  return 0;
}

TEST_F(ProcessTest, Terminate) {
  Process process(SpawnChild("SleepyChildProcess"));
  ASSERT_TRUE(process.IsValid());

  const int kDummyExitCode = 42;
  int exit_code = kDummyExitCode;
  EXPECT_EQ(TERMINATION_STATUS_STILL_RUNNING,
            GetTerminationStatus(process.Handle(), &exit_code));
  EXPECT_EQ(kExpectedStillRunningExitCode, exit_code);

  exit_code = kDummyExitCode;
  int kExpectedExitCode = 250;
  process.Terminate(kExpectedExitCode, false);
  process.WaitForExitWithTimeout(TestTimeouts::action_max_timeout(),
                                 &exit_code);

  EXPECT_NE(TERMINATION_STATUS_STILL_RUNNING,
            GetTerminationStatus(process.Handle(), &exit_code));
#if !defined(OS_POSIX)
  // The POSIX implementation actually ignores the exit_code.
  EXPECT_EQ(kExpectedExitCode, exit_code);
#endif
}

MULTIPROCESS_TEST_MAIN(FastSleepyChildProcess) {
  PlatformThread::Sleep(TestTimeouts::tiny_timeout() * 10);
  return 0;
}

TEST_F(ProcessTest, WaitForExit) {
  Process process(SpawnChild("FastSleepyChildProcess"));
  ASSERT_TRUE(process.IsValid());

  const int kDummyExitCode = 42;
  int exit_code = kDummyExitCode;
  EXPECT_TRUE(process.WaitForExit(&exit_code));
  EXPECT_EQ(0, exit_code);
}

TEST_F(ProcessTest, WaitForExitWithTimeout) {
  Process process(SpawnChild("SleepyChildProcess"));
  ASSERT_TRUE(process.IsValid());

  const int kDummyExitCode = 42;
  int exit_code = kDummyExitCode;
  TimeDelta timeout = TestTimeouts::tiny_timeout();
  EXPECT_FALSE(process.WaitForExitWithTimeout(timeout, &exit_code));
  EXPECT_EQ(kDummyExitCode, exit_code);

  process.Terminate(kDummyExitCode, false);
}

// Ensure that the priority of a process is restored correctly after
// backgrounding and restoring.
// Note: a platform may not be willing or able to lower the priority of
// a process. The calls to SetProcessBackground should be noops then.
TEST_F(ProcessTest, SetProcessBackgrounded) {
  Process process(SpawnChild("SimpleChildProcess"));
  int old_priority = process.GetPriority();
#if defined(OS_MACOSX)
  // On the Mac, backgrounding a process requires a port to that process.
  // In the browser it's available through the MachBroker class, which is not
  // part of base. Additionally, there is an indefinite amount of time between
  // spawning a process and receiving its port. Because this test just checks
  // the ability to background/foreground a process, we can use the current
  // process's port instead.
  mach_port_t process_port = mach_task_self();
  EXPECT_TRUE(process.SetProcessBackgrounded(process_port, true));
  EXPECT_TRUE(process.IsProcessBackgrounded(process_port));
  EXPECT_TRUE(process.SetProcessBackgrounded(process_port, false));
  EXPECT_FALSE(process.IsProcessBackgrounded(process_port));
#elif defined(OS_WIN)
  EXPECT_TRUE(process.SetProcessBackgrounded(true));
  EXPECT_TRUE(process.IsProcessBackgrounded());
  EXPECT_TRUE(process.SetProcessBackgrounded(false));
  EXPECT_FALSE(process.IsProcessBackgrounded());
#else
  process.SetProcessBackgrounded(true);
  process.SetProcessBackgrounded(false);
#endif
  int new_priority = process.GetPriority();
  EXPECT_EQ(old_priority, new_priority);
}

// Same as SetProcessBackgrounded but to this very process. It uses
// a different code path at least for Windows.
TEST_F(ProcessTest, SetProcessBackgroundedSelf) {
  Process process = Process::Current();
  int old_priority = process.GetPriority();
#if defined(OS_MACOSX)
  mach_port_t process_port = mach_task_self();
  EXPECT_TRUE(process.SetProcessBackgrounded(process_port, true));
  EXPECT_TRUE(process.IsProcessBackgrounded(process_port));
  EXPECT_TRUE(process.SetProcessBackgrounded(process_port, false));
  EXPECT_FALSE(process.IsProcessBackgrounded(process_port));
#elif defined(OS_WIN)
  EXPECT_TRUE(process.SetProcessBackgrounded(true));
  EXPECT_TRUE(process.IsProcessBackgrounded());
  EXPECT_TRUE(process.SetProcessBackgrounded(false));
  EXPECT_FALSE(process.IsProcessBackgrounded());
#else
  process.SetProcessBackgrounded(true);
  process.SetProcessBackgrounded(false);
#endif
  int new_priority = process.GetPriority();
  EXPECT_EQ(old_priority, new_priority);
}

}  // namespace base
