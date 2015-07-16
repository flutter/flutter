// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_LIBDISPATCH_TASK_RUNNER_H_
#define BASE_MAC_LIBDISPATCH_TASK_RUNNER_H_

#include <dispatch/dispatch.h>

#include "base/single_thread_task_runner.h"
#include "base/synchronization/waitable_event.h"

namespace base {
namespace mac {

// This is an implementation of the TaskRunner interface that runs closures on
// a thread managed by Apple's libdispatch. This has the benefit of being able
// to PostTask() and friends to a dispatch queue, while being reusable as a
// dispatch_queue_t.
//
// One would use this class if an object lives exclusively on one thread but
// needs a dispatch_queue_t for use in a system API. This ensures all dispatch
// callbacks happen on the same thread as Closure tasks.
//
// A LibDispatchTaskRunner will continue to run until all references to the
// underlying dispatch queue are released.
//
// Important Notes:
//   - There is no MessageLoop running on this thread, and ::current() returns
//     NULL.
//   - No nested loops can be run, and all tasks are run non-nested.
//   - Work scheduled via libdispatch runs at the same priority as and is
//     interleaved with posted tasks, though FIFO order is guaranteed.
//
class BASE_EXPORT LibDispatchTaskRunner : public base::SingleThreadTaskRunner {
 public:
  // Starts a new serial dispatch queue with a given name.
  explicit LibDispatchTaskRunner(const char* name);

  // base::TaskRunner:
  bool PostDelayedTask(const tracked_objects::Location& from_here,
                       const Closure& task,
                       base::TimeDelta delay) override;
  bool RunsTasksOnCurrentThread() const override;

  // base::SequencedTaskRunner:
  bool PostNonNestableDelayedTask(const tracked_objects::Location& from_here,
                                  const Closure& task,
                                  base::TimeDelta delay) override;

  // This blocks the calling thread until all work on the dispatch queue has
  // been run and the queue has been destroyed. Destroying a queue requires
  // ALL retained references to it to be released. Any new tasks posted to
  // this thread after shutdown are dropped.
  void Shutdown();

  // Returns the dispatch queue associated with this task runner, for use with
  // system APIs that take dispatch queues. The caller is responsible for
  // retaining the result.
  //
  // All properties (context, finalizer, etc.) are managed by this class, and
  // clients should only use the result of this for dispatch_async().
  dispatch_queue_t GetDispatchQueue() const;

 protected:
  ~LibDispatchTaskRunner() override;

 private:
  static void Finalizer(void* context);

  dispatch_queue_t queue_;

  // The event on which Shutdown waits until Finalizer runs.
  base::WaitableEvent queue_finalized_;
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_LIBDISPATCH_TASK_RUNNER_H_
