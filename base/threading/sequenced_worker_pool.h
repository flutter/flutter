// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_THREADING_SEQUENCED_WORKER_POOL_H_
#define BASE_THREADING_SEQUENCED_WORKER_POOL_H_

#include <cstddef>
#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/callback_forward.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/single_thread_task_runner.h"
#include "base/task_runner.h"

namespace tracked_objects {
class Location;
}  // namespace tracked_objects

namespace base {

class SingleThreadTaskRunner;

template <class T> class DeleteHelper;

class SequencedTaskRunner;

// A worker thread pool that enforces ordering between sets of tasks. It also
// allows you to specify what should happen to your tasks on shutdown.
//
// To enforce ordering, get a unique sequence token from the pool and post all
// tasks you want to order with the token. All tasks with the same token are
// guaranteed to execute serially, though not necessarily on the same thread.
// This means that:
//
//   - No two tasks with the same token will run at the same time.
//
//   - Given two tasks T1 and T2 with the same token such that T2 will
//     run after T1, then T2 will start after T1 is destroyed.
//
//   - If T2 will run after T1, then all memory changes in T1 and T1's
//     destruction will be visible to T2.
//
// Example:
//   SequencedWorkerPool::SequenceToken token = pool.GetSequenceToken();
//   pool.PostSequencedWorkerTask(token, SequencedWorkerPool::SKIP_ON_SHUTDOWN,
//                                FROM_HERE, base::Bind(...));
//   pool.PostSequencedWorkerTask(token, SequencedWorkerPool::SKIP_ON_SHUTDOWN,
//                                FROM_HERE, base::Bind(...));
//
// You can make named sequence tokens to make it easier to share a token
// across different components.
//
// You can also post tasks to the pool without ordering using PostWorkerTask.
// These will be executed in an unspecified order. The order of execution
// between tasks with different sequence tokens is also unspecified.
//
// This class may be leaked on shutdown to facilitate fast shutdown. The
// expected usage, however, is to call Shutdown(), which correctly accounts
// for CONTINUE_ON_SHUTDOWN behavior and is required for BLOCK_SHUTDOWN
// behavior.
//
// Implementation note: This does not use a base::WorkerPool since that does
// not enforce shutdown semantics or allow us to specify how many worker
// threads to run. For the typical use case of random background work, we don't
// necessarily want to be super aggressive about creating threads.
//
// Note that SequencedWorkerPool is RefCountedThreadSafe (inherited
// from TaskRunner).
//
// Test-only code should wrap this in a base::SequencedWorkerPoolOwner to avoid
// memory leaks. See http://crbug.com/273800
class BASE_EXPORT SequencedWorkerPool : public TaskRunner {
 public:
  // Defines what should happen to a task posted to the worker pool on
  // shutdown.
  enum WorkerShutdown {
    // Tasks posted with this mode which have not run at shutdown will be
    // deleted rather than run, and any tasks with this mode running at
    // shutdown will be ignored (the worker thread will not be joined).
    //
    // This option provides a nice way to post stuff you don't want blocking
    // shutdown. For example, you might be doing a slow DNS lookup and if it's
    // blocked on the OS, you may not want to stop shutdown, since the result
    // doesn't really matter at that point.
    //
    // However, you need to be very careful what you do in your callback when
    // you use this option. Since the thread will continue to run until the OS
    // terminates the process, the app can be in the process of tearing down
    // when you're running. This means any singletons or global objects you
    // use may suddenly become invalid out from under you. For this reason,
    // it's best to use this only for slow but simple operations like the DNS
    // example.
    CONTINUE_ON_SHUTDOWN,

    // Tasks posted with this mode that have not started executing at
    // shutdown will be deleted rather than executed. However, any tasks that
    // have already begun executing when shutdown is called will be allowed
    // to continue, and will block shutdown until completion.
    //
    // Note: Because Shutdown() may block while these tasks are executing,
    // care must be taken to ensure that they do not block on the thread that
    // called Shutdown(), as this may lead to deadlock.
    SKIP_ON_SHUTDOWN,

    // Tasks posted with this mode will block shutdown until they're
    // executed. Since this can have significant performance implications,
    // use sparingly.
    //
    // Generally, this should be used only for user data, for example, a task
    // writing a preference file.
    //
    // If a task is posted during shutdown, it will not get run since the
    // workers may already be stopped. In this case, the post operation will
    // fail (return false) and the task will be deleted.
    BLOCK_SHUTDOWN,
  };

  // Opaque identifier that defines sequencing of tasks posted to the worker
  // pool.
  class SequenceToken {
   public:
    SequenceToken() : id_(0) {}
    ~SequenceToken() {}

    bool Equals(const SequenceToken& other) const {
      return id_ == other.id_;
    }

    // Returns false if current thread is executing an unsequenced task.
    bool IsValid() const {
      return id_ != 0;
    }

   private:
    friend class SequencedWorkerPool;

    explicit SequenceToken(int id) : id_(id) {}

    int id_;
  };

  // Allows tests to perform certain actions.
  class TestingObserver {
   public:
    virtual ~TestingObserver() {}
    virtual void OnHasWork() = 0;
    virtual void WillWaitForShutdown() = 0;
    virtual void OnDestruct() = 0;
  };

  // Gets the SequencedToken of the current thread.
  // If current thread is not a SequencedWorkerPool worker thread or is running
  // an unsequenced task, returns an invalid SequenceToken.
  static SequenceToken GetSequenceTokenForCurrentThread();

  // When constructing a SequencedWorkerPool, there must be a
  // MessageLoop on the current thread unless you plan to deliberately
  // leak it.

  // Pass the maximum number of threads (they will be lazily created as needed)
  // and a prefix for the thread name to aid in debugging.
  SequencedWorkerPool(size_t max_threads,
                      const std::string& thread_name_prefix);

  // Like above, but with |observer| for testing.  Does not take
  // ownership of |observer|.
  SequencedWorkerPool(size_t max_threads,
                      const std::string& thread_name_prefix,
                      TestingObserver* observer);

  // Returns a unique token that can be used to sequence tasks posted to
  // PostSequencedWorkerTask(). Valid tokens are always nonzero.
  SequenceToken GetSequenceToken();

  // Returns the sequence token associated with the given name. Calling this
  // function multiple times with the same string will always produce the
  // same sequence token. If the name has not been used before, a new token
  // will be created.
  SequenceToken GetNamedSequenceToken(const std::string& name);

  // Returns a SequencedTaskRunner wrapper which posts to this
  // SequencedWorkerPool using the given sequence token. Tasks with nonzero
  // delay are posted with SKIP_ON_SHUTDOWN behavior and tasks with zero delay
  // are posted with BLOCK_SHUTDOWN behavior.
  scoped_refptr<SequencedTaskRunner> GetSequencedTaskRunner(
      SequenceToken token);

  // Returns a SequencedTaskRunner wrapper which posts to this
  // SequencedWorkerPool using the given sequence token. Tasks with nonzero
  // delay are posted with SKIP_ON_SHUTDOWN behavior and tasks with zero delay
  // are posted with the given shutdown behavior.
  scoped_refptr<SequencedTaskRunner> GetSequencedTaskRunnerWithShutdownBehavior(
      SequenceToken token,
      WorkerShutdown shutdown_behavior);

  // Returns a TaskRunner wrapper which posts to this SequencedWorkerPool using
  // the given shutdown behavior. Tasks with nonzero delay are posted with
  // SKIP_ON_SHUTDOWN behavior and tasks with zero delay are posted with the
  // given shutdown behavior.
  scoped_refptr<TaskRunner> GetTaskRunnerWithShutdownBehavior(
      WorkerShutdown shutdown_behavior);

  // Posts the given task for execution in the worker pool. Tasks posted with
  // this function will execute in an unspecified order on a background thread.
  // Returns true if the task was posted. If your tasks have ordering
  // requirements, see PostSequencedWorkerTask().
  //
  // This class will attempt to delete tasks that aren't run
  // (non-block-shutdown semantics) but can't guarantee that this happens. If
  // all worker threads are busy running CONTINUE_ON_SHUTDOWN tasks, there
  // will be no workers available to delete these tasks. And there may be
  // tasks with the same sequence token behind those CONTINUE_ON_SHUTDOWN
  // tasks. Deleting those tasks before the previous one has completed could
  // cause nondeterministic crashes because the task could be keeping some
  // objects alive which do work in their destructor, which could voilate the
  // assumptions of the running task.
  //
  // The task will be guaranteed to run to completion before shutdown
  // (BLOCK_SHUTDOWN semantics).
  //
  // Returns true if the task was posted successfully. This may fail during
  // shutdown regardless of the specified ShutdownBehavior.
  bool PostWorkerTask(const tracked_objects::Location& from_here,
                      const Closure& task);

  // Same as PostWorkerTask but allows a delay to be specified (although doing
  // so changes the shutdown behavior). The task will be run after the given
  // delay has elapsed.
  //
  // If the delay is nonzero, the task won't be guaranteed to run to completion
  // before shutdown (SKIP_ON_SHUTDOWN semantics) to avoid shutdown hangs.
  // If the delay is zero, this behaves exactly like PostWorkerTask, i.e. the
  // task will be guaranteed to run to completion before shutdown
  // (BLOCK_SHUTDOWN semantics).
  bool PostDelayedWorkerTask(const tracked_objects::Location& from_here,
                             const Closure& task,
                             TimeDelta delay);

  // Same as PostWorkerTask but allows specification of the shutdown behavior.
  bool PostWorkerTaskWithShutdownBehavior(
      const tracked_objects::Location& from_here,
      const Closure& task,
      WorkerShutdown shutdown_behavior);

  // Like PostWorkerTask above, but provides sequencing semantics. This means
  // that tasks posted with the same sequence token (see GetSequenceToken())
  // are guaranteed to execute in order. This is useful in cases where you're
  // doing operations that may depend on previous ones, like appending to a
  // file.
  //
  // The task will be guaranteed to run to completion before shutdown
  // (BLOCK_SHUTDOWN semantics).
  //
  // Returns true if the task was posted successfully. This may fail during
  // shutdown regardless of the specified ShutdownBehavior.
  bool PostSequencedWorkerTask(SequenceToken sequence_token,
                               const tracked_objects::Location& from_here,
                               const Closure& task);

  // Like PostSequencedWorkerTask above, but allows you to specify a named
  // token, which saves an extra call to GetNamedSequenceToken.
  bool PostNamedSequencedWorkerTask(const std::string& token_name,
                                    const tracked_objects::Location& from_here,
                                    const Closure& task);

  // Same as PostSequencedWorkerTask but allows a delay to be specified
  // (although doing so changes the shutdown behavior). The task will be run
  // after the given delay has elapsed.
  //
  // If the delay is nonzero, the task won't be guaranteed to run to completion
  // before shutdown (SKIP_ON_SHUTDOWN semantics) to avoid shutdown hangs.
  // If the delay is zero, this behaves exactly like PostSequencedWorkerTask,
  // i.e. the task will be guaranteed to run to completion before shutdown
  // (BLOCK_SHUTDOWN semantics).
  bool PostDelayedSequencedWorkerTask(
      SequenceToken sequence_token,
      const tracked_objects::Location& from_here,
      const Closure& task,
      TimeDelta delay);

  // Same as PostSequencedWorkerTask but allows specification of the shutdown
  // behavior.
  bool PostSequencedWorkerTaskWithShutdownBehavior(
      SequenceToken sequence_token,
      const tracked_objects::Location& from_here,
      const Closure& task,
      WorkerShutdown shutdown_behavior);

  // TaskRunner implementation. Forwards to PostDelayedWorkerTask().
  bool PostDelayedTask(const tracked_objects::Location& from_here,
                       const Closure& task,
                       TimeDelta delay) override;
  bool RunsTasksOnCurrentThread() const override;

  // Returns true if the current thread is processing a task with the given
  // sequence_token.
  bool IsRunningSequenceOnCurrentThread(SequenceToken sequence_token) const;

  // Blocks until all pending tasks are complete. This should only be called in
  // unit tests when you want to validate something that should have happened.
  // This will not flush delayed tasks; delayed tasks get deleted.
  //
  // Note that calling this will not prevent other threads from posting work to
  // the queue while the calling thread is waiting on Flush(). In this case,
  // Flush will return only when there's no more work in the queue. Normally,
  // this doesn't come up since in a test, all the work is being posted from
  // the main thread.
  void FlushForTesting();

  // Spuriously signal that there is work to be done.
  void SignalHasWorkForTesting();

  // Implements the worker pool shutdown. This should be called during app
  // shutdown, and will discard/join with appropriate tasks before returning.
  // After this call, subsequent calls to post tasks will fail.
  //
  // Must be called from the same thread this object was constructed on.
  void Shutdown() { Shutdown(0); }

  // A variant that allows an arbitrary number of new blocking tasks to be
  // posted during shutdown. The tasks cannot be posted within the execution
  // context of tasks whose shutdown behavior is not BLOCKING_SHUTDOWN. Once
  // the limit is reached, subsequent calls to post task fail in all cases.
  // Must be called from the same thread this object was constructed on.
  void Shutdown(int max_new_blocking_tasks_after_shutdown);

  // Check if Shutdown was called for given threading pool. This method is used
  // for aborting time consuming operation to avoid blocking shutdown.
  //
  // Can be called from any thread.
  bool IsShutdownInProgress();

 protected:
  ~SequencedWorkerPool() override;

  void OnDestruct() const override;

 private:
  friend class RefCountedThreadSafe<SequencedWorkerPool>;
  friend class DeleteHelper<SequencedWorkerPool>;

  class Inner;
  class Worker;

  const scoped_refptr<SingleThreadTaskRunner> constructor_task_runner_;

  // Avoid pulling in too many headers by putting (almost) everything
  // into |inner_|.
  const scoped_ptr<Inner> inner_;

  DISALLOW_COPY_AND_ASSIGN(SequencedWorkerPool);
};

}  // namespace base

#endif  // BASE_THREADING_SEQUENCED_WORKER_POOL_H_
