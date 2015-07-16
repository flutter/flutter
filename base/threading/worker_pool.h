// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_THREADING_WORKER_POOL_H_
#define BASE_THREADING_WORKER_POOL_H_

#include "base/base_export.h"
#include "base/callback_forward.h"
#include "base/memory/ref_counted.h"

class Task;

namespace tracked_objects {
class Location;
}  // namespace tracked_objects

namespace base {

class TaskRunner;

// This is a facility that runs tasks that don't require a specific thread or
// a message loop.
//
// WARNING: This shouldn't be used unless absolutely necessary. We don't wait
// for the worker pool threads to finish on shutdown, so the tasks running
// inside the pool must be extremely careful about other objects they access
// (MessageLoops, Singletons, etc). During shutdown these object may no longer
// exist.
class BASE_EXPORT WorkerPool {
 public:
  // This function posts |task| to run on a worker thread.  |task_is_slow|
  // should be used for tasks that will take a long time to execute.  Returns
  // false if |task| could not be posted to a worker thread.  Regardless of
  // return value, ownership of |task| is transferred to the worker pool.
  static bool PostTask(const tracked_objects::Location& from_here,
                       const base::Closure& task, bool task_is_slow);

  // Just like TaskRunner::PostTaskAndReply, except the destination
  // for |task| is a worker thread and you can specify |task_is_slow| just
  // like you can for PostTask above.
  static bool PostTaskAndReply(const tracked_objects::Location& from_here,
                               const Closure& task,
                               const Closure& reply,
                               bool task_is_slow);

  // Return true if the current thread is one that this WorkerPool runs tasks
  // on.  (Note that if the Windows worker pool is used without going through
  // this WorkerPool interface, RunsTasksOnCurrentThread would return false on
  // those threads.)
  static bool RunsTasksOnCurrentThread();

  // Get a TaskRunner wrapper which posts to the WorkerPool using the given
  // |task_is_slow| behavior.
  static const scoped_refptr<TaskRunner>& GetTaskRunner(bool task_is_slow);
};

}  // namespace base

#endif  // BASE_THREADING_WORKER_POOL_H_
