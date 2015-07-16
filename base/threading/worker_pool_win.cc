// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/worker_pool.h"

#include "base/bind.h"
#include "base/callback.h"
#include "base/logging.h"
#include "base/pending_task.h"
#include "base/threading/thread_local.h"
#include "base/trace_event/trace_event.h"
#include "base/tracked_objects.h"

namespace base {

namespace {

base::LazyInstance<ThreadLocalBoolean>::Leaky
    g_worker_pool_running_on_this_thread = LAZY_INSTANCE_INITIALIZER;

DWORD CALLBACK WorkItemCallback(void* param) {
  PendingTask* pending_task = static_cast<PendingTask*>(param);
  TRACE_EVENT2("toplevel", "WorkItemCallback::Run",
               "src_file", pending_task->posted_from.file_name(),
               "src_func", pending_task->posted_from.function_name());

  g_worker_pool_running_on_this_thread.Get().Set(true);

  tracked_objects::TaskStopwatch stopwatch;
  stopwatch.Start();
  pending_task->task.Run();
  stopwatch.Stop();

  g_worker_pool_running_on_this_thread.Get().Set(false);

  tracked_objects::ThreadData::TallyRunOnWorkerThreadIfTracking(
      pending_task->birth_tally, pending_task->time_posted, stopwatch);

  delete pending_task;
  return 0;
}

// Takes ownership of |pending_task|
bool PostTaskInternal(PendingTask* pending_task, bool task_is_slow) {
  ULONG flags = 0;
  if (task_is_slow)
    flags |= WT_EXECUTELONGFUNCTION;

  if (!QueueUserWorkItem(WorkItemCallback, pending_task, flags)) {
    DPLOG(ERROR) << "QueueUserWorkItem failed";
    delete pending_task;
    return false;
  }

  return true;
}

}  // namespace

// static
bool WorkerPool::PostTask(const tracked_objects::Location& from_here,
                          const base::Closure& task, bool task_is_slow) {
  PendingTask* pending_task = new PendingTask(from_here, task);
  return PostTaskInternal(pending_task, task_is_slow);
}

// static
bool WorkerPool::RunsTasksOnCurrentThread() {
  return g_worker_pool_running_on_this_thread.Get().Get();
}

}  // namespace base
