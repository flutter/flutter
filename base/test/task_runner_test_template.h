// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This class defines tests that implementations of TaskRunner should
// pass in order to be conformant.  Here's how you use it to test your
// implementation.
//
// Say your class is called MyTaskRunner.  Then you need to define a
// class called MyTaskRunnerTestDelegate in my_task_runner_unittest.cc
// like this:
//
//   class MyTaskRunnerTestDelegate {
//    public:
//     // Tasks posted to the task runner after this and before
//     // StopTaskRunner() is called is called should run successfully.
//     void StartTaskRunner() {
//       ...
//     }
//
//     // Should return the task runner implementation.  Only called
//     // after StartTaskRunner and before StopTaskRunner.
//     scoped_refptr<MyTaskRunner> GetTaskRunner() {
//       ...
//     }
//
//     // Stop the task runner and make sure all tasks posted before
//     // this is called are run. Caveat: delayed tasks are not run,
       // they're simply deleted.
//     void StopTaskRunner() {
//       ...
//     }
//   };
//
// The TaskRunnerTest test harness will have a member variable of
// this delegate type and will call its functions in the various
// tests.
//
// Then you simply #include this file as well as gtest.h and add the
// following statement to my_task_runner_unittest.cc:
//
//   INSTANTIATE_TYPED_TEST_CASE_P(
//       MyTaskRunner, TaskRunnerTest, MyTaskRunnerTestDelegate);
//
// Easy!

#ifndef BASE_TEST_TASK_RUNNER_TEST_TEMPLATE_H_
#define BASE_TEST_TASK_RUNNER_TEST_TEMPLATE_H_

#include <cstddef>
#include <map>

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/callback.h"
#include "base/location.h"
#include "base/memory/ref_counted.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "base/task_runner.h"
#include "base/threading/thread.h"
#include "base/tracked_objects.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace internal {

// Utility class that keeps track of how many times particular tasks
// are run.
class TaskTracker : public RefCountedThreadSafe<TaskTracker> {
 public:
  TaskTracker();

  // Returns a closure that runs the given task and increments the run
  // count of |i| by one.  |task| may be null.  It is guaranteed that
  // only one task wrapped by a given tracker will be run at a time.
  Closure WrapTask(const Closure& task, int i);

  std::map<int, int> GetTaskRunCounts() const;

  // Returns after the tracker observes a total of |count| task completions.
  void WaitForCompletedTasks(int count);

 private:
  friend class RefCountedThreadSafe<TaskTracker>;

  ~TaskTracker();

  void RunTask(const Closure& task, int i);

  mutable Lock lock_;
  std::map<int, int> task_run_counts_;
  int task_runs_;
  ConditionVariable task_runs_cv_;

  DISALLOW_COPY_AND_ASSIGN(TaskTracker);
};

}  // namespace internal

template <typename TaskRunnerTestDelegate>
class TaskRunnerTest : public testing::Test {
 protected:
  TaskRunnerTest() : task_tracker_(new internal::TaskTracker()) {}

  const scoped_refptr<internal::TaskTracker> task_tracker_;
  TaskRunnerTestDelegate delegate_;
};

TYPED_TEST_CASE_P(TaskRunnerTest);

// We can't really test much, since TaskRunner provides very few
// guarantees.

// Post a bunch of tasks to the task runner.  They should all
// complete.
TYPED_TEST_P(TaskRunnerTest, Basic) {
  std::map<int, int> expected_task_run_counts;

  this->delegate_.StartTaskRunner();
  scoped_refptr<TaskRunner> task_runner = this->delegate_.GetTaskRunner();
  // Post each ith task i+1 times.
  for (int i = 0; i < 20; ++i) {
    const Closure& ith_task = this->task_tracker_->WrapTask(Closure(), i);
    for (int j = 0; j < i + 1; ++j) {
      task_runner->PostTask(FROM_HERE, ith_task);
      ++expected_task_run_counts[i];
    }
  }
  this->delegate_.StopTaskRunner();

  EXPECT_EQ(expected_task_run_counts,
            this->task_tracker_->GetTaskRunCounts());
}

// Post a bunch of delayed tasks to the task runner.  They should all
// complete.
TYPED_TEST_P(TaskRunnerTest, Delayed) {
  std::map<int, int> expected_task_run_counts;
  int expected_total_tasks = 0;

  this->delegate_.StartTaskRunner();
  scoped_refptr<TaskRunner> task_runner = this->delegate_.GetTaskRunner();
  // Post each ith task i+1 times with delays from 0-i.
  for (int i = 0; i < 20; ++i) {
    const Closure& ith_task = this->task_tracker_->WrapTask(Closure(), i);
    for (int j = 0; j < i + 1; ++j) {
      task_runner->PostDelayedTask(
          FROM_HERE, ith_task, base::TimeDelta::FromMilliseconds(j));
      ++expected_task_run_counts[i];
      ++expected_total_tasks;
    }
  }
  this->task_tracker_->WaitForCompletedTasks(expected_total_tasks);
  this->delegate_.StopTaskRunner();

  EXPECT_EQ(expected_task_run_counts,
            this->task_tracker_->GetTaskRunCounts());
}

namespace internal {

// Calls RunsTasksOnCurrentThread() on |task_runner| and expects it to
// equal |expected_value|.
void ExpectRunsTasksOnCurrentThread(
    bool expected_value,
    const scoped_refptr<TaskRunner>& task_runner);

}  // namespace internal

// Post a bunch of tasks to the task runner as well as to a separate
// thread, each checking the value of RunsTasksOnCurrentThread(),
// which should return true for the tasks posted on the task runner
// and false for the tasks posted on the separate thread.
TYPED_TEST_P(TaskRunnerTest, RunsTasksOnCurrentThread) {
  std::map<int, int> expected_task_run_counts;

  Thread thread("Non-task-runner thread");
  ASSERT_TRUE(thread.Start());
  this->delegate_.StartTaskRunner();

  scoped_refptr<TaskRunner> task_runner = this->delegate_.GetTaskRunner();
  // Post each ith task i+1 times on the task runner and i+1 times on
  // the non-task-runner thread.
  for (int i = 0; i < 20; ++i) {
    const Closure& ith_task_runner_task =
        this->task_tracker_->WrapTask(
            Bind(&internal::ExpectRunsTasksOnCurrentThread,
                 true, task_runner),
            i);
    const Closure& ith_non_task_runner_task =
        this->task_tracker_->WrapTask(
            Bind(&internal::ExpectRunsTasksOnCurrentThread,
                 false, task_runner),
            i);
    for (int j = 0; j < i + 1; ++j) {
      task_runner->PostTask(FROM_HERE, ith_task_runner_task);
      thread.task_runner()->PostTask(FROM_HERE, ith_non_task_runner_task);
      expected_task_run_counts[i] += 2;
    }
  }

  this->delegate_.StopTaskRunner();
  thread.Stop();

  EXPECT_EQ(expected_task_run_counts,
            this->task_tracker_->GetTaskRunCounts());
}

REGISTER_TYPED_TEST_CASE_P(
    TaskRunnerTest, Basic, Delayed, RunsTasksOnCurrentThread);

}  // namespace base

#endif  // BASE_TEST_TASK_RUNNER_TEST_TEMPLATE_H_
