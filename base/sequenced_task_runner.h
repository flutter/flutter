// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SEQUENCED_TASK_RUNNER_H_
#define BASE_SEQUENCED_TASK_RUNNER_H_

#include "base/base_export.h"
#include "base/sequenced_task_runner_helpers.h"
#include "base/task_runner.h"

namespace base {

// A SequencedTaskRunner is a subclass of TaskRunner that provides
// additional guarantees on the order that tasks are started, as well
// as guarantees on when tasks are in sequence, i.e. one task finishes
// before the other one starts.
//
// Summary
// -------
// Non-nested tasks with the same delay will run one by one in FIFO
// order.
//
// Detailed guarantees
// -------------------
//
// SequencedTaskRunner also adds additional methods for posting
// non-nestable tasks.  In general, an implementation of TaskRunner
// may expose task-running methods which are themselves callable from
// within tasks.  A non-nestable task is one that is guaranteed to not
// be run from within an already-running task.  Conversely, a nestable
// task (the default) is a task that can be run from within an
// already-running task.
//
// The guarantees of SequencedTaskRunner are as follows:
//
//   - Given two tasks T2 and T1, T2 will start after T1 starts if:
//
//       * T2 is posted after T1; and
//       * T2 has equal or higher delay than T1; and
//       * T2 is non-nestable or T1 is nestable.
//
//   - If T2 will start after T1 starts by the above guarantee, then
//     T2 will start after T1 finishes and is destroyed if:
//
//       * T2 is non-nestable, or
//       * T1 doesn't call any task-running methods.
//
//   - If T2 will start after T1 finishes by the above guarantee, then
//     all memory changes in T1 and T1's destruction will be visible
//     to T2.
//
//   - If T2 runs nested within T1 via a call to the task-running
//     method M, then all memory changes in T1 up to the call to M
//     will be visible to T2, and all memory changes in T2 will be
//     visible to T1 from the return from M.
//
// Note that SequencedTaskRunner does not guarantee that tasks are run
// on a single dedicated thread, although the above guarantees provide
// most (but not all) of the same guarantees.  If you do need to
// guarantee that tasks are run on a single dedicated thread, see
// SingleThreadTaskRunner (in single_thread_task_runner.h).
//
// Some corollaries to the above guarantees, assuming the tasks in
// question don't call any task-running methods:
//
//   - Tasks posted via PostTask are run in FIFO order.
//
//   - Tasks posted via PostNonNestableTask are run in FIFO order.
//
//   - Tasks posted with the same delay and the same nestable state
//     are run in FIFO order.
//
//   - A list of tasks with the same nestable state posted in order of
//     non-decreasing delay is run in FIFO order.
//
//   - A list of tasks posted in order of non-decreasing delay with at
//     most a single change in nestable state from nestable to
//     non-nestable is run in FIFO order. (This is equivalent to the
//     statement of the first guarantee above.)
//
// Some theoretical implementations of SequencedTaskRunner:
//
//   - A SequencedTaskRunner that wraps a regular TaskRunner but makes
//     sure that only one task at a time is posted to the TaskRunner,
//     with appropriate memory barriers in between tasks.
//
//   - A SequencedTaskRunner that, for each task, spawns a joinable
//     thread to run that task and immediately quit, and then
//     immediately joins that thread.
//
//   - A SequencedTaskRunner that stores the list of posted tasks and
//     has a method Run() that runs each runnable task in FIFO order
//     that can be called from any thread, but only if another
//     (non-nested) Run() call isn't already happening.
class BASE_EXPORT SequencedTaskRunner : public TaskRunner {
 public:
  // The two PostNonNestable*Task methods below are like their
  // nestable equivalents in TaskRunner, but they guarantee that the
  // posted task will not run nested within an already-running task.
  //
  // A simple corollary is that posting a task as non-nestable can
  // only delay when the task gets run.  That is, posting a task as
  // non-nestable may not affect when the task gets run, or it could
  // make it run later than it normally would, but it won't make it
  // run earlier than it normally would.

  // TODO(akalin): Get rid of the boolean return value for the methods
  // below.

  bool PostNonNestableTask(const tracked_objects::Location& from_here,
                           const Closure& task);

  virtual bool PostNonNestableDelayedTask(
      const tracked_objects::Location& from_here,
      const Closure& task,
      base::TimeDelta delay) = 0;

  // Submits a non-nestable task to delete the given object.  Returns
  // true if the object may be deleted at some point in the future,
  // and false if the object definitely will not be deleted.
  template <class T>
  bool DeleteSoon(const tracked_objects::Location& from_here,
                  const T* object) {
    return
        subtle::DeleteHelperInternal<T, bool>::DeleteViaSequencedTaskRunner(
            this, from_here, object);
  }

  // Submits a non-nestable task to release the given object.  Returns
  // true if the object may be released at some point in the future,
  // and false if the object definitely will not be released.
  template <class T>
  bool ReleaseSoon(const tracked_objects::Location& from_here,
                   T* object) {
    return
        subtle::ReleaseHelperInternal<T, bool>::ReleaseViaSequencedTaskRunner(
            this, from_here, object);
  }

 protected:
  ~SequencedTaskRunner() override {}

 private:
  template <class T, class R> friend class subtle::DeleteHelperInternal;
  template <class T, class R> friend class subtle::ReleaseHelperInternal;

  bool DeleteSoonInternal(const tracked_objects::Location& from_here,
                          void(*deleter)(const void*),
                          const void* object);

  bool ReleaseSoonInternal(const tracked_objects::Location& from_here,
                           void(*releaser)(const void*),
                           const void* object);
};

}  // namespace base

#endif  // BASE_SEQUENCED_TASK_RUNNER_H_
