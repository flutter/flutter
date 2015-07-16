// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/task/cancelable_task_tracker.h"

#include <utility>

#include "base/bind.h"
#include "base/callback_helpers.h"
#include "base/compiler_specific.h"
#include "base/location.h"
#include "base/memory/ref_counted.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/cancellation_flag.h"
#include "base/task_runner.h"
#include "base/thread_task_runner_handle.h"

using base::Bind;
using base::CancellationFlag;
using base::Closure;
using base::hash_map;
using base::TaskRunner;

namespace {

void RunIfNotCanceled(const CancellationFlag* flag, const Closure& task) {
  if (!flag->IsSet())
    task.Run();
}

void RunIfNotCanceledThenUntrack(const CancellationFlag* flag,
                                 const Closure& task,
                                 const Closure& untrack) {
  RunIfNotCanceled(flag, task);
  untrack.Run();
}

bool IsCanceled(const CancellationFlag* flag,
                base::ScopedClosureRunner* cleanup_runner) {
  return flag->IsSet();
}

void RunAndDeleteFlag(const Closure& closure, const CancellationFlag* flag) {
  closure.Run();
  delete flag;
}

void RunOrPostToTaskRunner(TaskRunner* task_runner, const Closure& closure) {
  if (task_runner->RunsTasksOnCurrentThread())
    closure.Run();
  else
    task_runner->PostTask(FROM_HERE, closure);
}

}  // namespace

namespace base {

// static
const CancelableTaskTracker::TaskId CancelableTaskTracker::kBadTaskId = 0;

CancelableTaskTracker::CancelableTaskTracker()
    : next_id_(1),weak_factory_(this) {}

CancelableTaskTracker::~CancelableTaskTracker() {
  DCHECK(thread_checker_.CalledOnValidThread());

  TryCancelAll();
}

CancelableTaskTracker::TaskId CancelableTaskTracker::PostTask(
    TaskRunner* task_runner,
    const tracked_objects::Location& from_here,
    const Closure& task) {
  DCHECK(thread_checker_.CalledOnValidThread());

  return PostTaskAndReply(task_runner, from_here, task, Bind(&base::DoNothing));
}

CancelableTaskTracker::TaskId CancelableTaskTracker::PostTaskAndReply(
    TaskRunner* task_runner,
    const tracked_objects::Location& from_here,
    const Closure& task,
    const Closure& reply) {
  DCHECK(thread_checker_.CalledOnValidThread());

  // We need a MessageLoop to run reply.
  DCHECK(base::ThreadTaskRunnerHandle::IsSet());

  // Owned by reply callback below.
  CancellationFlag* flag = new CancellationFlag();

  TaskId id = next_id_;
  next_id_++;  // int64 is big enough that we ignore the potential overflow.

  const Closure& untrack_closure =
      Bind(&CancelableTaskTracker::Untrack, weak_factory_.GetWeakPtr(), id);
  bool success =
      task_runner->PostTaskAndReply(from_here,
                                    Bind(&RunIfNotCanceled, flag, task),
                                    Bind(&RunIfNotCanceledThenUntrack,
                                         base::Owned(flag),
                                         reply,
                                         untrack_closure));

  if (!success)
    return kBadTaskId;

  Track(id, flag);
  return id;
}

CancelableTaskTracker::TaskId CancelableTaskTracker::NewTrackedTaskId(
    IsCanceledCallback* is_canceled_cb) {
  DCHECK(thread_checker_.CalledOnValidThread());
  DCHECK(base::ThreadTaskRunnerHandle::IsSet());

  TaskId id = next_id_;
  next_id_++;  // int64 is big enough that we ignore the potential overflow.

  // Will be deleted by |untrack_and_delete_flag| after Untrack().
  CancellationFlag* flag = new CancellationFlag();

  Closure untrack_and_delete_flag = Bind(
      &RunAndDeleteFlag,
      Bind(&CancelableTaskTracker::Untrack, weak_factory_.GetWeakPtr(), id),
      flag);

  // Will always run |untrack_and_delete_flag| on current MessageLoop.
  base::ScopedClosureRunner* untrack_and_delete_flag_runner =
      new base::ScopedClosureRunner(Bind(&RunOrPostToTaskRunner,
                                         base::ThreadTaskRunnerHandle::Get(),
                                         untrack_and_delete_flag));

  *is_canceled_cb =
      Bind(&IsCanceled, flag, base::Owned(untrack_and_delete_flag_runner));

  Track(id, flag);
  return id;
}

void CancelableTaskTracker::TryCancel(TaskId id) {
  DCHECK(thread_checker_.CalledOnValidThread());

  hash_map<TaskId, CancellationFlag*>::const_iterator it = task_flags_.find(id);
  if (it == task_flags_.end()) {
    // Two possibilities:
    //
    //   1. The task has already been untracked.
    //   2. The TaskId is bad or unknown.
    //
    // Since this function is best-effort, it's OK to ignore these.
    return;
  }
  it->second->Set();
}

void CancelableTaskTracker::TryCancelAll() {
  DCHECK(thread_checker_.CalledOnValidThread());

  for (hash_map<TaskId, CancellationFlag*>::const_iterator it =
           task_flags_.begin();
       it != task_flags_.end();
       ++it) {
    it->second->Set();
  }
}

bool CancelableTaskTracker::HasTrackedTasks() const {
  DCHECK(thread_checker_.CalledOnValidThread());
  return !task_flags_.empty();
}

void CancelableTaskTracker::Track(TaskId id, CancellationFlag* flag) {
  DCHECK(thread_checker_.CalledOnValidThread());

  bool success = task_flags_.insert(std::make_pair(id, flag)).second;
  DCHECK(success);
}

void CancelableTaskTracker::Untrack(TaskId id) {
  DCHECK(thread_checker_.CalledOnValidThread());
  size_t num = task_flags_.erase(id);
  DCHECK_EQ(1u, num);
}

}  // namespace base
