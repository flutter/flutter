// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/task/cancelable_task_tracker.h"

#include <cstddef>
#include <deque>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "base/run_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/test/test_simple_task_runner.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

class CancelableTaskTrackerTest : public testing::Test {
 protected:
  ~CancelableTaskTrackerTest() override { RunCurrentLoopUntilIdle(); }

  void RunCurrentLoopUntilIdle() {
    RunLoop run_loop;
    run_loop.RunUntilIdle();
  }

  CancelableTaskTracker task_tracker_;

 private:
  // Needed by CancelableTaskTracker methods.
  MessageLoop message_loop_;
};

void AddFailureAt(const tracked_objects::Location& location) {
  ADD_FAILURE_AT(location.file_name(), location.line_number());
}

// Returns a closure that fails if run.
Closure MakeExpectedNotRunClosure(const tracked_objects::Location& location) {
  return Bind(&AddFailureAt, location);
}

// A helper class for MakeExpectedRunClosure() that fails if it is
// destroyed without Run() having been called.  This class may be used
// from multiple threads as long as Run() is called at most once
// before destruction.
class RunChecker {
 public:
  explicit RunChecker(const tracked_objects::Location& location)
      : location_(location), called_(false) {}

  ~RunChecker() {
    if (!called_) {
      ADD_FAILURE_AT(location_.file_name(), location_.line_number());
    }
  }

  void Run() { called_ = true; }

 private:
  tracked_objects::Location location_;
  bool called_;
};

// Returns a closure that fails on destruction if it hasn't been run.
Closure MakeExpectedRunClosure(const tracked_objects::Location& location) {
  return Bind(&RunChecker::Run, Owned(new RunChecker(location)));
}

}  // namespace

// With the task tracker, post a task, a task with a reply, and get a
// new task id without canceling any of them.  The tasks and the reply
// should run and the "is canceled" callback should return false.
TEST_F(CancelableTaskTrackerTest, NoCancel) {
  Thread worker_thread("worker thread");
  ASSERT_TRUE(worker_thread.Start());

  ignore_result(task_tracker_.PostTask(worker_thread.task_runner().get(),
                                       FROM_HERE,
                                       MakeExpectedRunClosure(FROM_HERE)));

  ignore_result(task_tracker_.PostTaskAndReply(
      worker_thread.task_runner().get(), FROM_HERE,
      MakeExpectedRunClosure(FROM_HERE), MakeExpectedRunClosure(FROM_HERE)));

  CancelableTaskTracker::IsCanceledCallback is_canceled;
  ignore_result(task_tracker_.NewTrackedTaskId(&is_canceled));

  worker_thread.Stop();

  RunCurrentLoopUntilIdle();

  EXPECT_FALSE(is_canceled.Run());
}

// Post a task with the task tracker but cancel it before running the
// task runner.  The task should not run.
TEST_F(CancelableTaskTrackerTest, CancelPostedTask) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  CancelableTaskTracker::TaskId task_id = task_tracker_.PostTask(
      test_task_runner.get(), FROM_HERE, MakeExpectedNotRunClosure(FROM_HERE));
  EXPECT_NE(CancelableTaskTracker::kBadTaskId, task_id);

  EXPECT_EQ(1U, test_task_runner->GetPendingTasks().size());

  task_tracker_.TryCancel(task_id);

  test_task_runner->RunUntilIdle();
}

// Post a task with reply with the task tracker and cancel it before
// running the task runner.  Neither the task nor the reply should
// run.
TEST_F(CancelableTaskTrackerTest, CancelPostedTaskAndReply) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  CancelableTaskTracker::TaskId task_id =
      task_tracker_.PostTaskAndReply(test_task_runner.get(),
                                     FROM_HERE,
                                     MakeExpectedNotRunClosure(FROM_HERE),
                                     MakeExpectedNotRunClosure(FROM_HERE));
  EXPECT_NE(CancelableTaskTracker::kBadTaskId, task_id);

  task_tracker_.TryCancel(task_id);

  test_task_runner->RunUntilIdle();
}

// Post a task with reply with the task tracker and cancel it after
// running the task runner but before running the current message
// loop.  The task should run but the reply should not.
TEST_F(CancelableTaskTrackerTest, CancelReply) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  CancelableTaskTracker::TaskId task_id =
      task_tracker_.PostTaskAndReply(test_task_runner.get(),
                                     FROM_HERE,
                                     MakeExpectedRunClosure(FROM_HERE),
                                     MakeExpectedNotRunClosure(FROM_HERE));
  EXPECT_NE(CancelableTaskTracker::kBadTaskId, task_id);

  test_task_runner->RunUntilIdle();

  task_tracker_.TryCancel(task_id);
}

// Post a task with reply with the task tracker on a worker thread and
// cancel it before running the current message loop.  The task should
// run but the reply should not.
TEST_F(CancelableTaskTrackerTest, CancelReplyDifferentThread) {
  Thread worker_thread("worker thread");
  ASSERT_TRUE(worker_thread.Start());

  CancelableTaskTracker::TaskId task_id = task_tracker_.PostTaskAndReply(
      worker_thread.task_runner().get(), FROM_HERE, Bind(&DoNothing),
      MakeExpectedNotRunClosure(FROM_HERE));
  EXPECT_NE(CancelableTaskTracker::kBadTaskId, task_id);

  task_tracker_.TryCancel(task_id);

  worker_thread.Stop();
}

void ExpectIsCanceled(
    const CancelableTaskTracker::IsCanceledCallback& is_canceled,
    bool expected_is_canceled) {
  EXPECT_EQ(expected_is_canceled, is_canceled.Run());
}

// Create a new task ID and check its status on a separate thread
// before and after canceling.  The is-canceled callback should be
// thread-safe (i.e., nothing should blow up).
TEST_F(CancelableTaskTrackerTest, NewTrackedTaskIdDifferentThread) {
  CancelableTaskTracker::IsCanceledCallback is_canceled;
  CancelableTaskTracker::TaskId task_id =
      task_tracker_.NewTrackedTaskId(&is_canceled);

  EXPECT_FALSE(is_canceled.Run());

  Thread other_thread("other thread");
  ASSERT_TRUE(other_thread.Start());
  other_thread.task_runner()->PostTask(
      FROM_HERE, Bind(&ExpectIsCanceled, is_canceled, false));
  other_thread.Stop();

  task_tracker_.TryCancel(task_id);

  ASSERT_TRUE(other_thread.Start());
  other_thread.task_runner()->PostTask(
      FROM_HERE, Bind(&ExpectIsCanceled, is_canceled, true));
  other_thread.Stop();
}

// With the task tracker, post a task, a task with a reply, get a new
// task id, and then cancel all of them.  None of the tasks nor the
// reply should run and the "is canceled" callback should return
// true.
TEST_F(CancelableTaskTrackerTest, CancelAll) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  ignore_result(task_tracker_.PostTask(
      test_task_runner.get(), FROM_HERE, MakeExpectedNotRunClosure(FROM_HERE)));

  ignore_result(
      task_tracker_.PostTaskAndReply(test_task_runner.get(),
                                     FROM_HERE,
                                     MakeExpectedNotRunClosure(FROM_HERE),
                                     MakeExpectedNotRunClosure(FROM_HERE)));

  CancelableTaskTracker::IsCanceledCallback is_canceled;
  ignore_result(task_tracker_.NewTrackedTaskId(&is_canceled));

  task_tracker_.TryCancelAll();

  test_task_runner->RunUntilIdle();

  RunCurrentLoopUntilIdle();

  EXPECT_TRUE(is_canceled.Run());
}

// With the task tracker, post a task, a task with a reply, get a new
// task id, and then cancel all of them.  None of the tasks nor the
// reply should run and the "is canceled" callback should return
// true.
TEST_F(CancelableTaskTrackerTest, DestructionCancelsAll) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  CancelableTaskTracker::IsCanceledCallback is_canceled;

  {
    // Create another task tracker with a smaller scope.
    CancelableTaskTracker task_tracker;

    ignore_result(task_tracker.PostTask(test_task_runner.get(),
                                        FROM_HERE,
                                        MakeExpectedNotRunClosure(FROM_HERE)));

    ignore_result(
        task_tracker.PostTaskAndReply(test_task_runner.get(),
                                      FROM_HERE,
                                      MakeExpectedNotRunClosure(FROM_HERE),
                                      MakeExpectedNotRunClosure(FROM_HERE)));

    ignore_result(task_tracker_.NewTrackedTaskId(&is_canceled));
  }

  test_task_runner->RunUntilIdle();

  RunCurrentLoopUntilIdle();

  EXPECT_FALSE(is_canceled.Run());
}

// Post a task and cancel it.  HasTrackedTasks() should return true
// from when the task is posted until the (do-nothing) reply task is
// flushed.
TEST_F(CancelableTaskTrackerTest, HasTrackedTasksPost) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  EXPECT_FALSE(task_tracker_.HasTrackedTasks());

  ignore_result(task_tracker_.PostTask(
      test_task_runner.get(), FROM_HERE, MakeExpectedNotRunClosure(FROM_HERE)));

  task_tracker_.TryCancelAll();

  test_task_runner->RunUntilIdle();

  EXPECT_TRUE(task_tracker_.HasTrackedTasks());

  RunCurrentLoopUntilIdle();

  EXPECT_FALSE(task_tracker_.HasTrackedTasks());
}

// Post a task with a reply and cancel it.  HasTrackedTasks() should
// return true from when the task is posted until it is canceled.
TEST_F(CancelableTaskTrackerTest, HasTrackedTasksPostWithReply) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  EXPECT_FALSE(task_tracker_.HasTrackedTasks());

  ignore_result(
      task_tracker_.PostTaskAndReply(test_task_runner.get(),
                                     FROM_HERE,
                                     MakeExpectedNotRunClosure(FROM_HERE),
                                     MakeExpectedNotRunClosure(FROM_HERE)));

  task_tracker_.TryCancelAll();

  test_task_runner->RunUntilIdle();

  EXPECT_TRUE(task_tracker_.HasTrackedTasks());

  RunCurrentLoopUntilIdle();

  EXPECT_FALSE(task_tracker_.HasTrackedTasks());
}

// Create a new tracked task ID.  HasTrackedTasks() should return true
// until the IsCanceledCallback is destroyed.
TEST_F(CancelableTaskTrackerTest, HasTrackedTasksIsCancelled) {
  EXPECT_FALSE(task_tracker_.HasTrackedTasks());

  CancelableTaskTracker::IsCanceledCallback is_canceled;
  ignore_result(task_tracker_.NewTrackedTaskId(&is_canceled));

  task_tracker_.TryCancelAll();

  EXPECT_TRUE(task_tracker_.HasTrackedTasks());

  is_canceled.Reset();

  EXPECT_FALSE(task_tracker_.HasTrackedTasks());
}

// The death tests below make sure that calling task tracker member
// functions from a thread different from its owner thread DCHECKs in
// debug mode.

class CancelableTaskTrackerDeathTest : public CancelableTaskTrackerTest {
 protected:
  CancelableTaskTrackerDeathTest() {
    // The default style "fast" does not support multi-threaded tests.
    ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  }
};

// Duplicated from base/threading/thread_checker.h so that we can be
// good citizens there and undef the macro.
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
#define ENABLE_THREAD_CHECKER 1
#else
#define ENABLE_THREAD_CHECKER 0
#endif

// Runs |fn| with |task_tracker|, expecting it to crash in debug mode.
void MaybeRunDeadlyTaskTrackerMemberFunction(
    CancelableTaskTracker* task_tracker,
    const Callback<void(CancelableTaskTracker*)>& fn) {
// CancelableTask uses DCHECKs with its ThreadChecker (itself only
// enabled in debug mode).
#if ENABLE_THREAD_CHECKER
  EXPECT_DEATH_IF_SUPPORTED(fn.Run(task_tracker), "");
#endif
}

void PostDoNothingTask(CancelableTaskTracker* task_tracker) {
  ignore_result(task_tracker->PostTask(
      scoped_refptr<TestSimpleTaskRunner>(new TestSimpleTaskRunner()).get(),
      FROM_HERE,
      Bind(&DoNothing)));
}

TEST_F(CancelableTaskTrackerDeathTest, PostFromDifferentThread) {
  Thread bad_thread("bad thread");
  ASSERT_TRUE(bad_thread.Start());

  bad_thread.task_runner()->PostTask(
      FROM_HERE, Bind(&MaybeRunDeadlyTaskTrackerMemberFunction,
                      Unretained(&task_tracker_), Bind(&PostDoNothingTask)));
}

void TryCancel(CancelableTaskTracker::TaskId task_id,
               CancelableTaskTracker* task_tracker) {
  task_tracker->TryCancel(task_id);
}

TEST_F(CancelableTaskTrackerDeathTest, CancelOnDifferentThread) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  Thread bad_thread("bad thread");
  ASSERT_TRUE(bad_thread.Start());

  CancelableTaskTracker::TaskId task_id = task_tracker_.PostTask(
      test_task_runner.get(), FROM_HERE, Bind(&DoNothing));
  EXPECT_NE(CancelableTaskTracker::kBadTaskId, task_id);

  bad_thread.task_runner()->PostTask(
      FROM_HERE, Bind(&MaybeRunDeadlyTaskTrackerMemberFunction,
                      Unretained(&task_tracker_), Bind(&TryCancel, task_id)));

  test_task_runner->RunUntilIdle();
}

TEST_F(CancelableTaskTrackerDeathTest, CancelAllOnDifferentThread) {
  scoped_refptr<TestSimpleTaskRunner> test_task_runner(
      new TestSimpleTaskRunner());

  Thread bad_thread("bad thread");
  ASSERT_TRUE(bad_thread.Start());

  CancelableTaskTracker::TaskId task_id = task_tracker_.PostTask(
      test_task_runner.get(), FROM_HERE, Bind(&DoNothing));
  EXPECT_NE(CancelableTaskTracker::kBadTaskId, task_id);

  bad_thread.task_runner()->PostTask(
      FROM_HERE,
      Bind(&MaybeRunDeadlyTaskTrackerMemberFunction, Unretained(&task_tracker_),
           Bind(&CancelableTaskTracker::TryCancelAll)));

  test_task_runner->RunUntilIdle();
}

}  // namespace base
