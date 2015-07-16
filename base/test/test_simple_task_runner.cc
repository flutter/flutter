// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_simple_task_runner.h"

#include "base/logging.h"

namespace base {

TestSimpleTaskRunner::TestSimpleTaskRunner() {}

TestSimpleTaskRunner::~TestSimpleTaskRunner() {
  DCHECK(thread_checker_.CalledOnValidThread());
}

bool TestSimpleTaskRunner::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  DCHECK(thread_checker_.CalledOnValidThread());
  pending_tasks_.push_back(
      TestPendingTask(from_here, task, TimeTicks(), delay,
                      TestPendingTask::NESTABLE));
  return true;
}

bool TestSimpleTaskRunner::PostNonNestableDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  DCHECK(thread_checker_.CalledOnValidThread());
  pending_tasks_.push_back(
      TestPendingTask(from_here, task, TimeTicks(), delay,
                      TestPendingTask::NON_NESTABLE));
  return true;
}

bool TestSimpleTaskRunner::RunsTasksOnCurrentThread() const {
  DCHECK(thread_checker_.CalledOnValidThread());
  return true;
}

const std::deque<TestPendingTask>&
TestSimpleTaskRunner::GetPendingTasks() const {
  DCHECK(thread_checker_.CalledOnValidThread());
  return pending_tasks_;
}

bool TestSimpleTaskRunner::HasPendingTask() const {
  DCHECK(thread_checker_.CalledOnValidThread());
  return !pending_tasks_.empty();
}

base::TimeDelta TestSimpleTaskRunner::NextPendingTaskDelay() const {
  DCHECK(thread_checker_.CalledOnValidThread());
  return pending_tasks_.front().GetTimeToRun() - base::TimeTicks();
}

void TestSimpleTaskRunner::ClearPendingTasks() {
  DCHECK(thread_checker_.CalledOnValidThread());
  pending_tasks_.clear();
}

void TestSimpleTaskRunner::RunPendingTasks() {
  DCHECK(thread_checker_.CalledOnValidThread());
  // Swap with a local variable to avoid re-entrancy problems.
  std::deque<TestPendingTask> tasks_to_run;
  tasks_to_run.swap(pending_tasks_);
  for (std::deque<TestPendingTask>::iterator it = tasks_to_run.begin();
       it != tasks_to_run.end(); ++it) {
    it->task.Run();
  }
}

void TestSimpleTaskRunner::RunUntilIdle() {
  while (!pending_tasks_.empty()) {
    RunPendingTasks();
  }
}

}  // namespace base
