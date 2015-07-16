// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_SIMPLE_TASK_RUNNER_H_
#define BASE_TEST_TEST_SIMPLE_TASK_RUNNER_H_

#include <deque>

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/single_thread_task_runner.h"
#include "base/test/test_pending_task.h"
#include "base/threading/thread_checker.h"

namespace base {

class TimeDelta;

// TestSimpleTaskRunner is a simple TaskRunner implementation that can
// be used for testing.  It implements SingleThreadTaskRunner as that
// interface implements SequencedTaskRunner, which in turn implements
// TaskRunner, so TestSimpleTaskRunner can be passed in to a function
// that accepts any *TaskRunner object.
//
// TestSimpleTaskRunner has the following properties which make it simple:
//
//   - It is non-thread safe; all member functions must be called on
//     the same thread.
//   - Tasks are simply stored in a queue in FIFO order, ignoring delay
//     and nestability.
//   - Tasks aren't guaranteed to be destroyed immediately after
//     they're run.
//
// However, TestSimpleTaskRunner allows for reentrancy, in that it
// handles the running of tasks that in turn call back into itself
// (e.g., to post more tasks).
//
// If you need more complicated properties, consider using this class
// as a template for writing a test TaskRunner implementation using
// TestPendingTask.
//
// Note that, like any TaskRunner, TestSimpleTaskRunner is
// ref-counted.
class TestSimpleTaskRunner : public SingleThreadTaskRunner {
 public:
  TestSimpleTaskRunner();

  // SingleThreadTaskRunner implementation.
  bool PostDelayedTask(const tracked_objects::Location& from_here,
                       const Closure& task,
                       TimeDelta delay) override;
  bool PostNonNestableDelayedTask(const tracked_objects::Location& from_here,
                                  const Closure& task,
                                  TimeDelta delay) override;

  bool RunsTasksOnCurrentThread() const override;

  const std::deque<TestPendingTask>& GetPendingTasks() const;
  bool HasPendingTask() const;
  base::TimeDelta NextPendingTaskDelay() const;

  // Clears the queue of pending tasks without running them.
  void ClearPendingTasks();

  // Runs each current pending task in order and clears the queue.
  // Any tasks posted by the tasks are not run.
  virtual void RunPendingTasks();

  // Runs pending tasks until the queue is empty.
  void RunUntilIdle();

 protected:
  ~TestSimpleTaskRunner() override;

  std::deque<TestPendingTask> pending_tasks_;
  ThreadChecker thread_checker_;

 private:
  DISALLOW_COPY_AND_ASSIGN(TestSimpleTaskRunner);
};

}  // namespace base

#endif  // BASE_TEST_TEST_SIMPLE_TASK_RUNNER_H_
