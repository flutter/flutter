// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/deferred_sequenced_task_runner.h"

#include "base/bind.h"
#include "base/logging.h"

namespace base {

DeferredSequencedTaskRunner::DeferredTask::DeferredTask()
    : is_non_nestable(false) {
}

DeferredSequencedTaskRunner::DeferredTask::~DeferredTask() {
}

DeferredSequencedTaskRunner::DeferredSequencedTaskRunner(
    const scoped_refptr<SequencedTaskRunner>& target_task_runner)
    : started_(false),
      target_task_runner_(target_task_runner) {
}

DeferredSequencedTaskRunner::~DeferredSequencedTaskRunner() {
}

bool DeferredSequencedTaskRunner::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  AutoLock lock(lock_);
  if (started_) {
    DCHECK(deferred_tasks_queue_.empty());
    return target_task_runner_->PostDelayedTask(from_here, task, delay);
  }

  QueueDeferredTask(from_here, task, delay, false /* is_non_nestable */);
  return true;
}

bool DeferredSequencedTaskRunner::RunsTasksOnCurrentThread() const {
  return target_task_runner_->RunsTasksOnCurrentThread();
}

bool DeferredSequencedTaskRunner::PostNonNestableDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  AutoLock lock(lock_);
  if (started_) {
    DCHECK(deferred_tasks_queue_.empty());
    return target_task_runner_->PostNonNestableDelayedTask(from_here,
                                                           task,
                                                           delay);
  }
  QueueDeferredTask(from_here, task, delay, true /* is_non_nestable */);
  return true;
}

void DeferredSequencedTaskRunner::QueueDeferredTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay,
    bool is_non_nestable) {
  DeferredTask deferred_task;
  deferred_task.posted_from = from_here;
  deferred_task.task = task;
  deferred_task.delay = delay;
  deferred_task.is_non_nestable = is_non_nestable;
  deferred_tasks_queue_.push_back(deferred_task);
}


void DeferredSequencedTaskRunner::Start() {
  AutoLock lock(lock_);
  DCHECK(!started_);
  started_ = true;
  for (std::vector<DeferredTask>::iterator i = deferred_tasks_queue_.begin();
      i != deferred_tasks_queue_.end();
      ++i) {
    const DeferredTask& task = *i;
    if (task.is_non_nestable) {
      target_task_runner_->PostNonNestableDelayedTask(task.posted_from,
                                                      task.task,
                                                      task.delay);
    } else {
      target_task_runner_->PostDelayedTask(task.posted_from,
                                           task.task,
                                           task.delay);
    }
    // Replace the i-th element in the |deferred_tasks_queue_| with an empty
    // |DelayedTask| to ensure that |task| is destroyed before the next task
    // is posted.
    *i = DeferredTask();
  }
  deferred_tasks_queue_.clear();
}

}  // namespace base
