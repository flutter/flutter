// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TASK_RUNNER_H_
#define BASE_TASK_RUNNER_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/callback_forward.h"
#include "base/memory/ref_counted.h"
#include "base/time/time.h"

namespace tracked_objects {
class Location;
} // namespace tracked_objects

namespace base {

struct TaskRunnerTraits;

// A TaskRunner is an object that runs posted tasks (in the form of
// Closure objects).  The TaskRunner interface provides a way of
// decoupling task posting from the mechanics of how each task will be
// run.  TaskRunner provides very weak guarantees as to how posted
// tasks are run (or if they're run at all).  In particular, it only
// guarantees:
//
//   - Posting a task will not run it synchronously.  That is, no
//     Post*Task method will call task.Run() directly.
//
//   - Increasing the delay can only delay when the task gets run.
//     That is, increasing the delay may not affect when the task gets
//     run, or it could make it run later than it normally would, but
//     it won't make it run earlier than it normally would.
//
// TaskRunner does not guarantee the order in which posted tasks are
// run, whether tasks overlap, or whether they're run on a particular
// thread.  Also it does not guarantee a memory model for shared data
// between tasks.  (In other words, you should use your own
// synchronization/locking primitives if you need to share data
// between tasks.)
//
// Implementations of TaskRunner should be thread-safe in that all
// methods must be safe to call on any thread.  Ownership semantics
// for TaskRunners are in general not clear, which is why the
// interface itself is RefCountedThreadSafe.
//
// Some theoretical implementations of TaskRunner:
//
//   - A TaskRunner that uses a thread pool to run posted tasks.
//
//   - A TaskRunner that, for each task, spawns a non-joinable thread
//     to run that task and immediately quit.
//
//   - A TaskRunner that stores the list of posted tasks and has a
//     method Run() that runs each runnable task in random order.
class BASE_EXPORT TaskRunner
    : public RefCountedThreadSafe<TaskRunner, TaskRunnerTraits> {
 public:
  // Posts the given task to be run.  Returns true if the task may be
  // run at some point in the future, and false if the task definitely
  // will not be run.
  //
  // Equivalent to PostDelayedTask(from_here, task, 0).
  bool PostTask(const tracked_objects::Location& from_here,
                const Closure& task);

  // Like PostTask, but tries to run the posted task only after
  // |delay_ms| has passed.
  //
  // It is valid for an implementation to ignore |delay_ms|; that is,
  // to have PostDelayedTask behave the same as PostTask.
  virtual bool PostDelayedTask(const tracked_objects::Location& from_here,
                               const Closure& task,
                               base::TimeDelta delay) = 0;

  // Returns true if the current thread is a thread on which a task
  // may be run, and false if no task will be run on the current
  // thread.
  //
  // It is valid for an implementation to always return true, or in
  // general to use 'true' as a default value.
  virtual bool RunsTasksOnCurrentThread() const = 0;

  // Posts |task| on the current TaskRunner.  On completion, |reply|
  // is posted to the thread that called PostTaskAndReply().  Both
  // |task| and |reply| are guaranteed to be deleted on the thread
  // from which PostTaskAndReply() is invoked.  This allows objects
  // that must be deleted on the originating thread to be bound into
  // the |task| and |reply| Closures.  In particular, it can be useful
  // to use WeakPtr<> in the |reply| Closure so that the reply
  // operation can be canceled. See the following pseudo-code:
  //
  // class DataBuffer : public RefCountedThreadSafe<DataBuffer> {
  //  public:
  //   // Called to add data into a buffer.
  //   void AddData(void* buf, size_t length);
  //   ...
  // };
  //
  //
  // class DataLoader : public SupportsWeakPtr<DataLoader> {
  //  public:
  //    void GetData() {
  //      scoped_refptr<DataBuffer> buffer = new DataBuffer();
  //      target_thread_.task_runner()->PostTaskAndReply(
  //          FROM_HERE,
  //          base::Bind(&DataBuffer::AddData, buffer),
  //          base::Bind(&DataLoader::OnDataReceived, AsWeakPtr(), buffer));
  //    }
  //
  //  private:
  //    void OnDataReceived(scoped_refptr<DataBuffer> buffer) {
  //      // Do something with buffer.
  //    }
  // };
  //
  //
  // Things to notice:
  //   * Results of |task| are shared with |reply| by binding a shared argument
  //     (a DataBuffer instance).
  //   * The DataLoader object has no special thread safety.
  //   * The DataLoader object can be deleted while |task| is still running,
  //     and the reply will cancel itself safely because it is bound to a
  //     WeakPtr<>.
  bool PostTaskAndReply(const tracked_objects::Location& from_here,
                        const Closure& task,
                        const Closure& reply);

 protected:
  friend struct TaskRunnerTraits;

  // Only the Windows debug build seems to need this: see
  // http://crbug.com/112250.
  friend class RefCountedThreadSafe<TaskRunner, TaskRunnerTraits>;

  TaskRunner();
  virtual ~TaskRunner();

  // Called when this object should be destroyed.  By default simply
  // deletes |this|, but can be overridden to do something else, like
  // delete on a certain thread.
  virtual void OnDestruct() const;
};

struct BASE_EXPORT TaskRunnerTraits {
  static void Destruct(const TaskRunner* task_runner);
};

}  // namespace base

#endif  // BASE_TASK_RUNNER_H_
