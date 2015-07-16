// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_MOCK_TIME_TASK_RUNNER_H_
#define BASE_TEST_TEST_MOCK_TIME_TASK_RUNNER_H_

#include <queue>
#include <vector>

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/lock.h"
#include "base/test/test_pending_task.h"
#include "base/threading/thread_checker.h"
#include "base/time/time.h"

namespace base {

class Clock;
class TickClock;

// Runs pending tasks in the order of the tasks' post time + delay, and keeps
// track of a mock (virtual) tick clock time that can be fast-forwarded.
//
// TestMockTimeTaskRunner has the following properties:
//
//   - Methods RunsTasksOnCurrentThread() and Post[Delayed]Task() can be called
//     from any thread, but the rest of the methods must be called on the same
//     thread the TaskRunner was created on.
//   - It allows for reentrancy, in that it handles the running of tasks that in
//     turn call back into it (e.g., to post more tasks).
//   - Tasks are stored in a priority queue, and executed in the increasing
//     order of post time + delay, but ignoring nestability.
//   - It does not check for overflow when doing time arithmetic. A sufficient
//     condition for preventing overflows is to make sure that the sum of all
//     posted task delays and fast-forward increments is still representable by
//     a TimeDelta, and that adding this delta to the starting values of Time
//     and TickTime is still within their respective range.
//   - Tasks aren't guaranteed to be destroyed immediately after they're run.
//
// This is a slightly more sophisticated version of TestSimpleTaskRunner, in
// that it supports running delayed tasks in the correct temporal order.
class TestMockTimeTaskRunner : public SingleThreadTaskRunner {
 public:
  // Constructs an instance whose virtual time will start at the Unix epoch, and
  // whose time ticks will start at zero.
  TestMockTimeTaskRunner();

  // Fast-forwards virtual time by |delta|, causing all tasks with a remaining
  // delay less than or equal to |delta| to be executed. |delta| must be
  // non-negative.
  void FastForwardBy(TimeDelta delta);

  // Fast-forwards virtual time just until all tasks are executed.
  void FastForwardUntilNoTasksRemain();

  // Executes all tasks that have no remaining delay. Tasks with a remaining
  // delay greater than zero will remain enqueued, and no virtual time will
  // elapse.
  void RunUntilIdle();

  // Clears the queue of pending tasks without running them.
  void ClearPendingTasks();

  // Returns the current virtual time (initially starting at the Unix epoch).
  Time Now() const;

  // Returns the current virtual tick time (initially starting at 0).
  TimeTicks NowTicks() const;

  // Returns a Clock that uses the virtual time of |this| as its time source.
  // The returned Clock will hold a reference to |this|.
  scoped_ptr<Clock> GetMockClock() const;

  // Returns a TickClock that uses the virtual time ticks of |this| as its tick
  // source. The returned TickClock will hold a reference to |this|.
  scoped_ptr<TickClock> GetMockTickClock() const;

  bool HasPendingTask() const;
  size_t GetPendingTaskCount() const;
  TimeDelta NextPendingTaskDelay() const;

  // SingleThreadTaskRunner:
  bool RunsTasksOnCurrentThread() const override;
  bool PostDelayedTask(const tracked_objects::Location& from_here,
                       const Closure& task,
                       TimeDelta delay) override;
  bool PostNonNestableDelayedTask(const tracked_objects::Location& from_here,
                                  const Closure& task,
                                  TimeDelta delay) override;

 protected:
  ~TestMockTimeTaskRunner() override;

  // Whether the elapsing of virtual time is stopped or not. Subclasses can
  // override this method to perform early exits from a running task runner.
  // Defaults to always return false.
  virtual bool IsElapsingStopped();

  // Called before the next task to run is selected, so that subclasses have a
  // last chance to make sure all tasks are posted.
  virtual void OnBeforeSelectingTask();

  // Called after the current mock time has been incremented so that subclasses
  // can react to the passing of time.
  virtual void OnAfterTimePassed();

  // Called after each task is run so that subclasses may perform additional
  // activities, e.g., pump additional task runners.
  virtual void OnAfterTaskRun();

 private:
  struct TestOrderedPendingTask;

  // Predicate that defines a strict weak temporal ordering of tasks.
  class TemporalOrder {
   public:
    bool operator()(const TestOrderedPendingTask& first_task,
                    const TestOrderedPendingTask& second_task) const;
  };

  typedef std::priority_queue<TestOrderedPendingTask,
                              std::vector<TestOrderedPendingTask>,
                              TemporalOrder> TaskPriorityQueue;

  // Core of the implementation for all flavors of fast-forward methods. Given a
  // non-negative |max_delta|, runs all tasks with a remaining delay less than
  // or equal to |max_delta|, and moves virtual time forward as needed for each
  // processed task. Pass in TimeDelta::Max() as |max_delta| to run all tasks.
  void ProcessAllTasksNoLaterThan(TimeDelta max_delta);

  // Forwards |now_ticks_| until it equals |later_ticks|, and forwards |now_| by
  // the same amount. Calls OnAfterTimePassed() if |later_ticks| > |now_ticks_|.
  // Does nothing if |later_ticks| <= |now_ticks_|.
  void ForwardClocksUntilTickTime(TimeTicks later_ticks);

  // Returns the |next_task| to run if there is any with a running time that is
  // at most |reference| + |max_delta|. This additional complexity is required
  // so that |max_delta| == TimeDelta::Max() can be supported.
  bool DequeueNextTask(const TimeTicks& reference,
                       const TimeDelta& max_delta,
                       TestPendingTask* next_task);

  ThreadChecker thread_checker_;
  Time now_;
  TimeTicks now_ticks_;

  // Temporally ordered heap of pending tasks. Must only be accessed while the
  // |tasks_lock_| is held.
  TaskPriorityQueue tasks_;

  // The ordinal to use for the next task. Must only be accessed while the
  // |tasks_lock_| is held.
  size_t next_task_ordinal_;

  Lock tasks_lock_;

  DISALLOW_COPY_AND_ASSIGN(TestMockTimeTaskRunner);
};

}  // namespace base

#endif  // BASE_TEST_TEST_MOCK_TIME_TASK_RUNNER_H_
