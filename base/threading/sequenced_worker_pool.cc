// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/sequenced_worker_pool.h"

#include <list>
#include <map>
#include <set>
#include <utility>
#include <vector>

#include "base/atomic_sequence_num.h"
#include "base/callback.h"
#include "base/compiler_specific.h"
#include "base/critical_closure.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/linked_ptr.h"
#include "base/stl_util.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/platform_thread.h"
#include "base/threading/simple_thread.h"
#include "base/threading/thread_local.h"
#include "base/threading/thread_restrictions.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "base/tracked_objects.h"

#if defined(OS_MACOSX)
#include "base/mac/scoped_nsautorelease_pool.h"
#elif defined(OS_WIN)
#include "base/win/scoped_com_initializer.h"
#endif

#if !defined(OS_NACL)
#include "base/metrics/histogram.h"
#endif

namespace base {

namespace {

struct SequencedTask : public TrackingInfo  {
  SequencedTask()
      : sequence_token_id(0),
        trace_id(0),
        sequence_task_number(0),
        shutdown_behavior(SequencedWorkerPool::BLOCK_SHUTDOWN) {}

  explicit SequencedTask(const tracked_objects::Location& from_here)
      : base::TrackingInfo(from_here, TimeTicks()),
        sequence_token_id(0),
        trace_id(0),
        sequence_task_number(0),
        shutdown_behavior(SequencedWorkerPool::BLOCK_SHUTDOWN) {}

  ~SequencedTask() {}

  int sequence_token_id;
  int trace_id;
  int64 sequence_task_number;
  SequencedWorkerPool::WorkerShutdown shutdown_behavior;
  tracked_objects::Location posted_from;
  Closure task;

  // Non-delayed tasks and delayed tasks are managed together by time-to-run
  // order. We calculate the time by adding the posted time and the given delay.
  TimeTicks time_to_run;
};

struct SequencedTaskLessThan {
 public:
  bool operator()(const SequencedTask& lhs, const SequencedTask& rhs) const {
    if (lhs.time_to_run < rhs.time_to_run)
      return true;

    if (lhs.time_to_run > rhs.time_to_run)
      return false;

    // If the time happen to match, then we use the sequence number to decide.
    return lhs.sequence_task_number < rhs.sequence_task_number;
  }
};

// SequencedWorkerPoolTaskRunner ---------------------------------------------
// A TaskRunner which posts tasks to a SequencedWorkerPool with a
// fixed ShutdownBehavior.
//
// Note that this class is RefCountedThreadSafe (inherited from TaskRunner).
class SequencedWorkerPoolTaskRunner : public TaskRunner {
 public:
  SequencedWorkerPoolTaskRunner(
      const scoped_refptr<SequencedWorkerPool>& pool,
      SequencedWorkerPool::WorkerShutdown shutdown_behavior);

  // TaskRunner implementation
  bool PostDelayedTask(const tracked_objects::Location& from_here,
                       const Closure& task,
                       TimeDelta delay) override;
  bool RunsTasksOnCurrentThread() const override;

 private:
  ~SequencedWorkerPoolTaskRunner() override;

  const scoped_refptr<SequencedWorkerPool> pool_;

  const SequencedWorkerPool::WorkerShutdown shutdown_behavior_;

  DISALLOW_COPY_AND_ASSIGN(SequencedWorkerPoolTaskRunner);
};

SequencedWorkerPoolTaskRunner::SequencedWorkerPoolTaskRunner(
    const scoped_refptr<SequencedWorkerPool>& pool,
    SequencedWorkerPool::WorkerShutdown shutdown_behavior)
    : pool_(pool),
      shutdown_behavior_(shutdown_behavior) {
}

SequencedWorkerPoolTaskRunner::~SequencedWorkerPoolTaskRunner() {
}

bool SequencedWorkerPoolTaskRunner::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  if (delay == TimeDelta()) {
    return pool_->PostWorkerTaskWithShutdownBehavior(
        from_here, task, shutdown_behavior_);
  }
  return pool_->PostDelayedWorkerTask(from_here, task, delay);
}

bool SequencedWorkerPoolTaskRunner::RunsTasksOnCurrentThread() const {
  return pool_->RunsTasksOnCurrentThread();
}

// SequencedWorkerPoolSequencedTaskRunner ------------------------------------
// A SequencedTaskRunner which posts tasks to a SequencedWorkerPool with a
// fixed sequence token.
//
// Note that this class is RefCountedThreadSafe (inherited from TaskRunner).
class SequencedWorkerPoolSequencedTaskRunner : public SequencedTaskRunner {
 public:
  SequencedWorkerPoolSequencedTaskRunner(
      const scoped_refptr<SequencedWorkerPool>& pool,
      SequencedWorkerPool::SequenceToken token,
      SequencedWorkerPool::WorkerShutdown shutdown_behavior);

  // TaskRunner implementation
  bool PostDelayedTask(const tracked_objects::Location& from_here,
                       const Closure& task,
                       TimeDelta delay) override;
  bool RunsTasksOnCurrentThread() const override;

  // SequencedTaskRunner implementation
  bool PostNonNestableDelayedTask(const tracked_objects::Location& from_here,
                                  const Closure& task,
                                  TimeDelta delay) override;

 private:
  ~SequencedWorkerPoolSequencedTaskRunner() override;

  const scoped_refptr<SequencedWorkerPool> pool_;

  const SequencedWorkerPool::SequenceToken token_;

  const SequencedWorkerPool::WorkerShutdown shutdown_behavior_;

  DISALLOW_COPY_AND_ASSIGN(SequencedWorkerPoolSequencedTaskRunner);
};

SequencedWorkerPoolSequencedTaskRunner::SequencedWorkerPoolSequencedTaskRunner(
    const scoped_refptr<SequencedWorkerPool>& pool,
    SequencedWorkerPool::SequenceToken token,
    SequencedWorkerPool::WorkerShutdown shutdown_behavior)
    : pool_(pool),
      token_(token),
      shutdown_behavior_(shutdown_behavior) {
}

SequencedWorkerPoolSequencedTaskRunner::
~SequencedWorkerPoolSequencedTaskRunner() {
}

bool SequencedWorkerPoolSequencedTaskRunner::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  if (delay == TimeDelta()) {
    return pool_->PostSequencedWorkerTaskWithShutdownBehavior(
        token_, from_here, task, shutdown_behavior_);
  }
  return pool_->PostDelayedSequencedWorkerTask(token_, from_here, task, delay);
}

bool SequencedWorkerPoolSequencedTaskRunner::RunsTasksOnCurrentThread() const {
  return pool_->IsRunningSequenceOnCurrentThread(token_);
}

bool SequencedWorkerPoolSequencedTaskRunner::PostNonNestableDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  // There's no way to run nested tasks, so simply forward to
  // PostDelayedTask.
  return PostDelayedTask(from_here, task, delay);
}

// Create a process-wide unique ID to represent this task in trace events. This
// will be mangled with a Process ID hash to reduce the likelyhood of colliding
// with MessageLoop pointers on other processes.
uint64 GetTaskTraceID(const SequencedTask& task,
                      void* pool) {
  return (static_cast<uint64>(task.trace_id) << 32) |
         static_cast<uint64>(reinterpret_cast<intptr_t>(pool));
}

base::LazyInstance<base::ThreadLocalPointer<
    SequencedWorkerPool::SequenceToken> >::Leaky g_lazy_tls_ptr =
        LAZY_INSTANCE_INITIALIZER;

}  // namespace

// Worker ---------------------------------------------------------------------

class SequencedWorkerPool::Worker : public SimpleThread {
 public:
  // Hold a (cyclic) ref to |worker_pool|, since we want to keep it
  // around as long as we are running.
  Worker(const scoped_refptr<SequencedWorkerPool>& worker_pool,
         int thread_number,
         const std::string& thread_name_prefix);
  ~Worker() override;

  // SimpleThread implementation. This actually runs the background thread.
  void Run() override;

  // Indicates that a task is about to be run. The parameters provide
  // additional metainformation about the task being run.
  void set_running_task_info(SequenceToken token,
                             WorkerShutdown shutdown_behavior) {
    is_processing_task_ = true;
    task_sequence_token_ = token;
    task_shutdown_behavior_ = shutdown_behavior;
  }

  // Indicates that the task has finished running.
  void reset_running_task_info() { is_processing_task_ = false; }

  // Whether the worker is processing a task.
  bool is_processing_task() { return is_processing_task_; }

  SequenceToken task_sequence_token() const {
    DCHECK(is_processing_task_);
    return task_sequence_token_;
  }

  WorkerShutdown task_shutdown_behavior() const {
    DCHECK(is_processing_task_);
    return task_shutdown_behavior_;
  }

 private:
  scoped_refptr<SequencedWorkerPool> worker_pool_;
  // The sequence token of the task being processed. Only valid when
  // is_processing_task_ is true.
  SequenceToken task_sequence_token_;
  // The shutdown behavior of the task being processed. Only valid when
  // is_processing_task_ is true.
  WorkerShutdown task_shutdown_behavior_;
  // Whether the Worker is processing a task.
  bool is_processing_task_;

  DISALLOW_COPY_AND_ASSIGN(Worker);
};

// Inner ----------------------------------------------------------------------

class SequencedWorkerPool::Inner {
 public:
  // Take a raw pointer to |worker| to avoid cycles (since we're owned
  // by it).
  Inner(SequencedWorkerPool* worker_pool, size_t max_threads,
        const std::string& thread_name_prefix,
        TestingObserver* observer);

  ~Inner();

  SequenceToken GetSequenceToken();

  SequenceToken GetNamedSequenceToken(const std::string& name);

  // This function accepts a name and an ID. If the name is null, the
  // token ID is used. This allows us to implement the optional name lookup
  // from a single function without having to enter the lock a separate time.
  bool PostTask(const std::string* optional_token_name,
                SequenceToken sequence_token,
                WorkerShutdown shutdown_behavior,
                const tracked_objects::Location& from_here,
                const Closure& task,
                TimeDelta delay);

  bool RunsTasksOnCurrentThread() const;

  bool IsRunningSequenceOnCurrentThread(SequenceToken sequence_token) const;

  void CleanupForTesting();

  void SignalHasWorkForTesting();

  int GetWorkSignalCountForTesting() const;

  void Shutdown(int max_blocking_tasks_after_shutdown);

  bool IsShutdownInProgress();

  // Runs the worker loop on the background thread.
  void ThreadLoop(Worker* this_worker);

 private:
  enum GetWorkStatus {
    GET_WORK_FOUND,
    GET_WORK_NOT_FOUND,
    GET_WORK_WAIT,
  };

  enum CleanupState {
    CLEANUP_REQUESTED,
    CLEANUP_STARTING,
    CLEANUP_RUNNING,
    CLEANUP_FINISHING,
    CLEANUP_DONE,
  };

  // Called from within the lock, this converts the given token name into a
  // token ID, creating a new one if necessary.
  int LockedGetNamedTokenID(const std::string& name);

  // Called from within the lock, this returns the next sequence task number.
  int64 LockedGetNextSequenceTaskNumber();

  // Gets new task. There are 3 cases depending on the return value:
  //
  // 1) If the return value is |GET_WORK_FOUND|, |task| is filled in and should
  //    be run immediately.
  // 2) If the return value is |GET_WORK_NOT_FOUND|, there are no tasks to run,
  //    and |task| is not filled in. In this case, the caller should wait until
  //    a task is posted.
  // 3) If the return value is |GET_WORK_WAIT|, there are no tasks to run
  //    immediately, and |task| is not filled in. Likewise, |wait_time| is
  //    filled in the time to wait until the next task to run. In this case, the
  //    caller should wait the time.
  //
  // In any case, the calling code should clear the given
  // delete_these_outside_lock vector the next time the lock is released.
  // See the implementation for a more detailed description.
  GetWorkStatus GetWork(SequencedTask* task,
                        TimeDelta* wait_time,
                        std::vector<Closure>* delete_these_outside_lock);

  void HandleCleanup();

  // Peforms init and cleanup around running the given task. WillRun...
  // returns the value from PrepareToStartAdditionalThreadIfNecessary.
  // The calling code should call FinishStartingAdditionalThread once the
  // lock is released if the return values is nonzero.
  int WillRunWorkerTask(const SequencedTask& task);
  void DidRunWorkerTask(const SequencedTask& task);

  // Returns true if there are no threads currently running the given
  // sequence token.
  bool IsSequenceTokenRunnable(int sequence_token_id) const;

  // Checks if all threads are busy and the addition of one more could run an
  // additional task waiting in the queue. This must be called from within
  // the lock.
  //
  // If another thread is helpful, this will mark the thread as being in the
  // process of starting and returns the index of the new thread which will be
  // 0 or more. The caller should then call FinishStartingAdditionalThread to
  // complete initialization once the lock is released.
  //
  // If another thread is not necessary, returne 0;
  //
  // See the implementedion for more.
  int PrepareToStartAdditionalThreadIfHelpful();

  // The second part of thread creation after
  // PrepareToStartAdditionalThreadIfHelpful with the thread number it
  // generated. This actually creates the thread and should be called outside
  // the lock to avoid blocking important work starting a thread in the lock.
  void FinishStartingAdditionalThread(int thread_number);

  // Signal |has_work_| and increment |has_work_signal_count_|.
  void SignalHasWork();

  // Checks whether there is work left that's blocking shutdown. Must be
  // called inside the lock.
  bool CanShutdown() const;

  SequencedWorkerPool* const worker_pool_;

  // The last sequence number used. Managed by GetSequenceToken, since this
  // only does threadsafe increment operations, you do not need to hold the
  // lock. This is class-static to make SequenceTokens issued by
  // GetSequenceToken unique across SequencedWorkerPool instances.
  static base::StaticAtomicSequenceNumber g_last_sequence_number_;

  // This lock protects |everything in this class|. Do not read or modify
  // anything without holding this lock. Do not block while holding this
  // lock.
  mutable Lock lock_;

  // Condition variable that is waited on by worker threads until new
  // tasks are posted or shutdown starts.
  ConditionVariable has_work_cv_;

  // Condition variable that is waited on by non-worker threads (in
  // Shutdown()) until CanShutdown() goes to true.
  ConditionVariable can_shutdown_cv_;

  // The maximum number of worker threads we'll create.
  const size_t max_threads_;

  const std::string thread_name_prefix_;

  // Associates all known sequence token names with their IDs.
  std::map<std::string, int> named_sequence_tokens_;

  // Owning pointers to all threads we've created so far, indexed by
  // ID. Since we lazily create threads, this may be less than
  // max_threads_ and will be initially empty.
  typedef std::map<PlatformThreadId, linked_ptr<Worker> > ThreadMap;
  ThreadMap threads_;

  // Set to true when we're in the process of creating another thread.
  // See PrepareToStartAdditionalThreadIfHelpful for more.
  bool thread_being_created_;

  // Number of threads currently waiting for work.
  size_t waiting_thread_count_;

  // Number of threads currently running tasks that have the BLOCK_SHUTDOWN
  // or SKIP_ON_SHUTDOWN flag set.
  size_t blocking_shutdown_thread_count_;

  // A set of all pending tasks in time-to-run order. These are tasks that are
  // either waiting for a thread to run on, waiting for their time to run,
  // or blocked on a previous task in their sequence. We have to iterate over
  // the tasks by time-to-run order, so we use the set instead of the
  // traditional priority_queue.
  typedef std::set<SequencedTask, SequencedTaskLessThan> PendingTaskSet;
  PendingTaskSet pending_tasks_;

  // The next sequence number for a new sequenced task.
  int64 next_sequence_task_number_;

  // Number of tasks in the pending_tasks_ list that are marked as blocking
  // shutdown.
  size_t blocking_shutdown_pending_task_count_;

  // Lists all sequence tokens currently executing.
  std::set<int> current_sequences_;

  // An ID for each posted task to distinguish the task from others in traces.
  int trace_id_;

  // Set when Shutdown is called and no further tasks should be
  // allowed, though we may still be running existing tasks.
  bool shutdown_called_;

  // The number of new BLOCK_SHUTDOWN tasks that may be posted after Shudown()
  // has been called.
  int max_blocking_tasks_after_shutdown_;

  // State used to cleanup for testing, all guarded by lock_.
  CleanupState cleanup_state_;
  size_t cleanup_idlers_;
  ConditionVariable cleanup_cv_;

  TestingObserver* const testing_observer_;

  DISALLOW_COPY_AND_ASSIGN(Inner);
};

// Worker definitions ---------------------------------------------------------

SequencedWorkerPool::Worker::Worker(
    const scoped_refptr<SequencedWorkerPool>& worker_pool,
    int thread_number,
    const std::string& prefix)
    : SimpleThread(prefix + StringPrintf("Worker%d", thread_number)),
      worker_pool_(worker_pool),
      task_shutdown_behavior_(BLOCK_SHUTDOWN),
      is_processing_task_(false) {
  Start();
}

SequencedWorkerPool::Worker::~Worker() {
}

void SequencedWorkerPool::Worker::Run() {
#if defined(OS_WIN)
  win::ScopedCOMInitializer com_initializer;
#endif

  // Store a pointer to the running sequence in thread local storage for
  // static function access.
  g_lazy_tls_ptr.Get().Set(&task_sequence_token_);

  // Just jump back to the Inner object to run the thread, since it has all the
  // tracking information and queues. It might be more natural to implement
  // using DelegateSimpleThread and have Inner implement the Delegate to avoid
  // having these worker objects at all, but that method lacks the ability to
  // send thread-specific information easily to the thread loop.
  worker_pool_->inner_->ThreadLoop(this);
  // Release our cyclic reference once we're done.
  worker_pool_ = NULL;
}

// Inner definitions ---------------------------------------------------------

SequencedWorkerPool::Inner::Inner(
    SequencedWorkerPool* worker_pool,
    size_t max_threads,
    const std::string& thread_name_prefix,
    TestingObserver* observer)
    : worker_pool_(worker_pool),
      lock_(),
      has_work_cv_(&lock_),
      can_shutdown_cv_(&lock_),
      max_threads_(max_threads),
      thread_name_prefix_(thread_name_prefix),
      thread_being_created_(false),
      waiting_thread_count_(0),
      blocking_shutdown_thread_count_(0),
      next_sequence_task_number_(0),
      blocking_shutdown_pending_task_count_(0),
      trace_id_(0),
      shutdown_called_(false),
      max_blocking_tasks_after_shutdown_(0),
      cleanup_state_(CLEANUP_DONE),
      cleanup_idlers_(0),
      cleanup_cv_(&lock_),
      testing_observer_(observer) {}

SequencedWorkerPool::Inner::~Inner() {
  // You must call Shutdown() before destroying the pool.
  DCHECK(shutdown_called_);

  // Need to explicitly join with the threads before they're destroyed or else
  // they will be running when our object is half torn down.
  for (ThreadMap::iterator it = threads_.begin(); it != threads_.end(); ++it)
    it->second->Join();
  threads_.clear();

  if (testing_observer_)
    testing_observer_->OnDestruct();
}

SequencedWorkerPool::SequenceToken
SequencedWorkerPool::Inner::GetSequenceToken() {
  // Need to add one because StaticAtomicSequenceNumber starts at zero, which
  // is used as a sentinel value in SequenceTokens.
  return SequenceToken(g_last_sequence_number_.GetNext() + 1);
}

SequencedWorkerPool::SequenceToken
SequencedWorkerPool::Inner::GetNamedSequenceToken(const std::string& name) {
  AutoLock lock(lock_);
  return SequenceToken(LockedGetNamedTokenID(name));
}

bool SequencedWorkerPool::Inner::PostTask(
    const std::string* optional_token_name,
    SequenceToken sequence_token,
    WorkerShutdown shutdown_behavior,
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  DCHECK(delay == TimeDelta() || shutdown_behavior == SKIP_ON_SHUTDOWN);
  SequencedTask sequenced(from_here);
  sequenced.sequence_token_id = sequence_token.id_;
  sequenced.shutdown_behavior = shutdown_behavior;
  sequenced.posted_from = from_here;
  sequenced.task =
      shutdown_behavior == BLOCK_SHUTDOWN ?
      base::MakeCriticalClosure(task) : task;
  sequenced.time_to_run = TimeTicks::Now() + delay;

  int create_thread_id = 0;
  {
    AutoLock lock(lock_);
    if (shutdown_called_) {
      // Don't allow a new task to be posted if it doesn't block shutdown.
      if (shutdown_behavior != BLOCK_SHUTDOWN)
        return false;

      // If the current thread is running a task, and that task doesn't block
      // shutdown, then it shouldn't be allowed to post any more tasks.
      ThreadMap::const_iterator found =
          threads_.find(PlatformThread::CurrentId());
      if (found != threads_.end() && found->second->is_processing_task() &&
          found->second->task_shutdown_behavior() != BLOCK_SHUTDOWN) {
        return false;
      }

      if (max_blocking_tasks_after_shutdown_ <= 0) {
        DLOG(WARNING) << "BLOCK_SHUTDOWN task disallowed";
        return false;
      }
      max_blocking_tasks_after_shutdown_ -= 1;
    }

    // The trace_id is used for identifying the task in about:tracing.
    sequenced.trace_id = trace_id_++;

    TRACE_EVENT_FLOW_BEGIN0(TRACE_DISABLED_BY_DEFAULT("toplevel.flow"),
        "SequencedWorkerPool::PostTask",
        TRACE_ID_MANGLE(GetTaskTraceID(sequenced, static_cast<void*>(this))));

    sequenced.sequence_task_number = LockedGetNextSequenceTaskNumber();

    // Now that we have the lock, apply the named token rules.
    if (optional_token_name)
      sequenced.sequence_token_id = LockedGetNamedTokenID(*optional_token_name);

    pending_tasks_.insert(sequenced);
    if (shutdown_behavior == BLOCK_SHUTDOWN)
      blocking_shutdown_pending_task_count_++;

    create_thread_id = PrepareToStartAdditionalThreadIfHelpful();
  }

  // Actually start the additional thread or signal an existing one now that
  // we're outside the lock.
  if (create_thread_id)
    FinishStartingAdditionalThread(create_thread_id);
  else
    SignalHasWork();

  return true;
}

bool SequencedWorkerPool::Inner::RunsTasksOnCurrentThread() const {
  AutoLock lock(lock_);
  return ContainsKey(threads_, PlatformThread::CurrentId());
}

bool SequencedWorkerPool::Inner::IsRunningSequenceOnCurrentThread(
    SequenceToken sequence_token) const {
  AutoLock lock(lock_);
  ThreadMap::const_iterator found = threads_.find(PlatformThread::CurrentId());
  if (found == threads_.end())
    return false;
  return found->second->is_processing_task() &&
         sequence_token.Equals(found->second->task_sequence_token());
}

// See https://code.google.com/p/chromium/issues/detail?id=168415
void SequencedWorkerPool::Inner::CleanupForTesting() {
  DCHECK(!RunsTasksOnCurrentThread());
  base::ThreadRestrictions::ScopedAllowWait allow_wait;
  AutoLock lock(lock_);
  CHECK_EQ(CLEANUP_DONE, cleanup_state_);
  if (shutdown_called_)
    return;
  if (pending_tasks_.empty() && waiting_thread_count_ == threads_.size())
    return;
  cleanup_state_ = CLEANUP_REQUESTED;
  cleanup_idlers_ = 0;
  has_work_cv_.Signal();
  while (cleanup_state_ != CLEANUP_DONE)
    cleanup_cv_.Wait();
}

void SequencedWorkerPool::Inner::SignalHasWorkForTesting() {
  SignalHasWork();
}

void SequencedWorkerPool::Inner::Shutdown(
    int max_new_blocking_tasks_after_shutdown) {
  DCHECK_GE(max_new_blocking_tasks_after_shutdown, 0);
  {
    AutoLock lock(lock_);
    // Cleanup and Shutdown should not be called concurrently.
    CHECK_EQ(CLEANUP_DONE, cleanup_state_);
    if (shutdown_called_)
      return;
    shutdown_called_ = true;
    max_blocking_tasks_after_shutdown_ = max_new_blocking_tasks_after_shutdown;

    // Tickle the threads. This will wake up a waiting one so it will know that
    // it can exit, which in turn will wake up any other waiting ones.
    SignalHasWork();

    // There are no pending or running tasks blocking shutdown, we're done.
    if (CanShutdown())
      return;
  }

  // If we're here, then something is blocking shutdown.  So wait for
  // CanShutdown() to go to true.

  if (testing_observer_)
    testing_observer_->WillWaitForShutdown();

#if !defined(OS_NACL)
  TimeTicks shutdown_wait_begin = TimeTicks::Now();
#endif

  {
    base::ThreadRestrictions::ScopedAllowWait allow_wait;
    AutoLock lock(lock_);
    while (!CanShutdown())
      can_shutdown_cv_.Wait();
  }
#if !defined(OS_NACL)
  UMA_HISTOGRAM_TIMES("SequencedWorkerPool.ShutdownDelayTime",
                      TimeTicks::Now() - shutdown_wait_begin);
#endif
}

bool SequencedWorkerPool::Inner::IsShutdownInProgress() {
    AutoLock lock(lock_);
    return shutdown_called_;
}

void SequencedWorkerPool::Inner::ThreadLoop(Worker* this_worker) {
  {
    AutoLock lock(lock_);
    DCHECK(thread_being_created_);
    thread_being_created_ = false;
    std::pair<ThreadMap::iterator, bool> result =
        threads_.insert(
            std::make_pair(this_worker->tid(), make_linked_ptr(this_worker)));
    DCHECK(result.second);

    while (true) {
#if defined(OS_MACOSX)
      base::mac::ScopedNSAutoreleasePool autorelease_pool;
#endif

      HandleCleanup();

      // See GetWork for what delete_these_outside_lock is doing.
      SequencedTask task;
      TimeDelta wait_time;
      std::vector<Closure> delete_these_outside_lock;
      GetWorkStatus status =
          GetWork(&task, &wait_time, &delete_these_outside_lock);
      if (status == GET_WORK_FOUND) {
        TRACE_EVENT_FLOW_END0(TRACE_DISABLED_BY_DEFAULT("toplevel.flow"),
            "SequencedWorkerPool::PostTask",
            TRACE_ID_MANGLE(GetTaskTraceID(task, static_cast<void*>(this))));
        TRACE_EVENT2("toplevel", "SequencedWorkerPool::ThreadLoop",
                     "src_file", task.posted_from.file_name(),
                     "src_func", task.posted_from.function_name());
        int new_thread_id = WillRunWorkerTask(task);
        {
          AutoUnlock unlock(lock_);
          // There may be more work available, so wake up another
          // worker thread. (Technically not required, since we
          // already get a signal for each new task, but it doesn't
          // hurt.)
          SignalHasWork();
          delete_these_outside_lock.clear();

          // Complete thread creation outside the lock if necessary.
          if (new_thread_id)
            FinishStartingAdditionalThread(new_thread_id);

          this_worker->set_running_task_info(
              SequenceToken(task.sequence_token_id), task.shutdown_behavior);

          tracked_objects::TaskStopwatch stopwatch;
          stopwatch.Start();
          task.task.Run();
          stopwatch.Stop();

          tracked_objects::ThreadData::TallyRunOnNamedThreadIfTracking(
              task, stopwatch);

          // Make sure our task is erased outside the lock for the
          // same reason we do this with delete_these_oustide_lock.
          // Also, do it before calling reset_running_task_info() so
          // that sequence-checking from within the task's destructor
          // still works.
          task.task = Closure();

          this_worker->reset_running_task_info();
        }
        DidRunWorkerTask(task);  // Must be done inside the lock.
      } else if (cleanup_state_ == CLEANUP_RUNNING) {
        switch (status) {
          case GET_WORK_WAIT: {
              AutoUnlock unlock(lock_);
              delete_these_outside_lock.clear();
            }
            break;
          case GET_WORK_NOT_FOUND:
            CHECK(delete_these_outside_lock.empty());
            cleanup_state_ = CLEANUP_FINISHING;
            cleanup_cv_.Broadcast();
            break;
          default:
            NOTREACHED();
        }
      } else {
        // When we're terminating and there's no more work, we can
        // shut down, other workers can complete any pending or new tasks.
        // We can get additional tasks posted after shutdown_called_ is set
        // but only worker threads are allowed to post tasks at that time, and
        // the workers responsible for posting those tasks will be available
        // to run them. Also, there may be some tasks stuck behind running
        // ones with the same sequence token, but additional threads won't
        // help this case.
        if (shutdown_called_ && blocking_shutdown_pending_task_count_ == 0) {
          AutoUnlock unlock(lock_);
          delete_these_outside_lock.clear();
          break;
        }

        // No work was found, but there are tasks that need deletion. The
        // deletion must happen outside of the lock.
        if (delete_these_outside_lock.size()) {
          AutoUnlock unlock(lock_);
          delete_these_outside_lock.clear();

          // Since the lock has been released, |status| may no longer be
          // accurate. It might read GET_WORK_WAIT even if there are tasks
          // ready to perform work. Jump to the top of the loop to recalculate
          // |status|.
          continue;
        }

        waiting_thread_count_++;

        switch (status) {
          case GET_WORK_NOT_FOUND:
            has_work_cv_.Wait();
            break;
          case GET_WORK_WAIT:
            has_work_cv_.TimedWait(wait_time);
            break;
          default:
            NOTREACHED();
        }
        waiting_thread_count_--;
      }
    }
  }  // Release lock_.

  // We noticed we should exit. Wake up the next worker so it knows it should
  // exit as well (because the Shutdown() code only signals once).
  SignalHasWork();

  // Possibly unblock shutdown.
  can_shutdown_cv_.Signal();
}

void SequencedWorkerPool::Inner::HandleCleanup() {
  lock_.AssertAcquired();
  if (cleanup_state_ == CLEANUP_DONE)
    return;
  if (cleanup_state_ == CLEANUP_REQUESTED) {
    // We win, we get to do the cleanup as soon as the others wise up and idle.
    cleanup_state_ = CLEANUP_STARTING;
    while (thread_being_created_ ||
           cleanup_idlers_ != threads_.size() - 1) {
      has_work_cv_.Signal();
      cleanup_cv_.Wait();
    }
    cleanup_state_ = CLEANUP_RUNNING;
    return;
  }
  if (cleanup_state_ == CLEANUP_STARTING) {
    // Another worker thread is cleaning up, we idle here until thats done.
    ++cleanup_idlers_;
    cleanup_cv_.Broadcast();
    while (cleanup_state_ != CLEANUP_FINISHING) {
      cleanup_cv_.Wait();
    }
    --cleanup_idlers_;
    cleanup_cv_.Broadcast();
    return;
  }
  if (cleanup_state_ == CLEANUP_FINISHING) {
    // We wait for all idlers to wake up prior to being DONE.
    while (cleanup_idlers_ != 0) {
      cleanup_cv_.Broadcast();
      cleanup_cv_.Wait();
    }
    if (cleanup_state_ == CLEANUP_FINISHING) {
      cleanup_state_ = CLEANUP_DONE;
      cleanup_cv_.Signal();
    }
    return;
  }
}

int SequencedWorkerPool::Inner::LockedGetNamedTokenID(
    const std::string& name) {
  lock_.AssertAcquired();
  DCHECK(!name.empty());

  std::map<std::string, int>::const_iterator found =
      named_sequence_tokens_.find(name);
  if (found != named_sequence_tokens_.end())
    return found->second;  // Got an existing one.

  // Create a new one for this name.
  SequenceToken result = GetSequenceToken();
  named_sequence_tokens_.insert(std::make_pair(name, result.id_));
  return result.id_;
}

int64 SequencedWorkerPool::Inner::LockedGetNextSequenceTaskNumber() {
  lock_.AssertAcquired();
  // We assume that we never create enough tasks to wrap around.
  return next_sequence_task_number_++;
}

SequencedWorkerPool::Inner::GetWorkStatus SequencedWorkerPool::Inner::GetWork(
    SequencedTask* task,
    TimeDelta* wait_time,
    std::vector<Closure>* delete_these_outside_lock) {
  lock_.AssertAcquired();

  // Find the next task with a sequence token that's not currently in use.
  // If the token is in use, that means another thread is running something
  // in that sequence, and we can't run it without going out-of-order.
  //
  // This algorithm is simple and fair, but inefficient in some cases. For
  // example, say somebody schedules 1000 slow tasks with the same sequence
  // number. We'll have to go through all those tasks each time we feel like
  // there might be work to schedule. If this proves to be a problem, we
  // should make this more efficient.
  //
  // One possible enhancement would be to keep a map from sequence ID to a
  // list of pending but currently blocked SequencedTasks for that ID.
  // When a worker finishes a task of one sequence token, it can pick up the
  // next one from that token right away.
  //
  // This may lead to starvation if there are sufficient numbers of sequences
  // in use. To alleviate this, we could add an incrementing priority counter
  // to each SequencedTask. Then maintain a priority_queue of all runnable
  // tasks, sorted by priority counter. When a sequenced task is completed
  // we would pop the head element off of that tasks pending list and add it
  // to the priority queue. Then we would run the first item in the priority
  // queue.

  GetWorkStatus status = GET_WORK_NOT_FOUND;
  int unrunnable_tasks = 0;
  PendingTaskSet::iterator i = pending_tasks_.begin();
  // We assume that the loop below doesn't take too long and so we can just do
  // a single call to TimeTicks::Now().
  const TimeTicks current_time = TimeTicks::Now();
  while (i != pending_tasks_.end()) {
    if (!IsSequenceTokenRunnable(i->sequence_token_id)) {
      unrunnable_tasks++;
      ++i;
      continue;
    }

    if (shutdown_called_ && i->shutdown_behavior != BLOCK_SHUTDOWN) {
      // We're shutting down and the task we just found isn't blocking
      // shutdown. Delete it and get more work.
      //
      // Note that we do not want to delete unrunnable tasks. Deleting a task
      // can have side effects (like freeing some objects) and deleting a
      // task that's supposed to run after one that's currently running could
      // cause an obscure crash.
      //
      // We really want to delete these tasks outside the lock in case the
      // closures are holding refs to objects that want to post work from
      // their destructorss (which would deadlock). The closures are
      // internally refcounted, so we just need to keep a copy of them alive
      // until the lock is exited. The calling code can just clear() the
      // vector they passed to us once the lock is exited to make this
      // happen.
      delete_these_outside_lock->push_back(i->task);
      pending_tasks_.erase(i++);
      continue;
    }

    if (i->time_to_run > current_time) {
      // The time to run has not come yet.
      *wait_time = i->time_to_run - current_time;
      status = GET_WORK_WAIT;
      if (cleanup_state_ == CLEANUP_RUNNING) {
        // Deferred tasks are deleted when cleaning up, see Inner::ThreadLoop.
        delete_these_outside_lock->push_back(i->task);
        pending_tasks_.erase(i);
      }
      break;
    }

    // Found a runnable task.
    *task = *i;
    pending_tasks_.erase(i);
    if (task->shutdown_behavior == BLOCK_SHUTDOWN) {
      blocking_shutdown_pending_task_count_--;
    }

    status = GET_WORK_FOUND;
    break;
  }

  return status;
}

int SequencedWorkerPool::Inner::WillRunWorkerTask(const SequencedTask& task) {
  lock_.AssertAcquired();

  // Mark the task's sequence number as in use.
  if (task.sequence_token_id)
    current_sequences_.insert(task.sequence_token_id);

  // Ensure that threads running tasks posted with either SKIP_ON_SHUTDOWN
  // or BLOCK_SHUTDOWN will prevent shutdown until that task or thread
  // completes.
  if (task.shutdown_behavior != CONTINUE_ON_SHUTDOWN)
    blocking_shutdown_thread_count_++;

  // We just picked up a task. Since StartAdditionalThreadIfHelpful only
  // creates a new thread if there is no free one, there is a race when posting
  // tasks that many tasks could have been posted before a thread started
  // running them, so only one thread would have been created. So we also check
  // whether we should create more threads after removing our task from the
  // queue, which also has the nice side effect of creating the workers from
  // background threads rather than the main thread of the app.
  //
  // If another thread wasn't created, we want to wake up an existing thread
  // if there is one waiting to pick up the next task.
  //
  // Note that we really need to do this *before* running the task, not
  // after. Otherwise, if more than one task is posted, the creation of the
  // second thread (since we only create one at a time) will be blocked by
  // the execution of the first task, which could be arbitrarily long.
  return PrepareToStartAdditionalThreadIfHelpful();
}

void SequencedWorkerPool::Inner::DidRunWorkerTask(const SequencedTask& task) {
  lock_.AssertAcquired();

  if (task.shutdown_behavior != CONTINUE_ON_SHUTDOWN) {
    DCHECK_GT(blocking_shutdown_thread_count_, 0u);
    blocking_shutdown_thread_count_--;
  }

  if (task.sequence_token_id)
    current_sequences_.erase(task.sequence_token_id);
}

bool SequencedWorkerPool::Inner::IsSequenceTokenRunnable(
    int sequence_token_id) const {
  lock_.AssertAcquired();
  return !sequence_token_id ||
      current_sequences_.find(sequence_token_id) ==
          current_sequences_.end();
}

int SequencedWorkerPool::Inner::PrepareToStartAdditionalThreadIfHelpful() {
  lock_.AssertAcquired();
  // How thread creation works:
  //
  // We'de like to avoid creating threads with the lock held. However, we
  // need to be sure that we have an accurate accounting of the threads for
  // proper Joining and deltion on shutdown.
  //
  // We need to figure out if we need another thread with the lock held, which
  // is what this function does. It then marks us as in the process of creating
  // a thread. When we do shutdown, we wait until the thread_being_created_
  // flag is cleared, which ensures that the new thread is properly added to
  // all the data structures and we can't leak it. Once shutdown starts, we'll
  // refuse to create more threads or they would be leaked.
  //
  // Note that this creates a mostly benign race condition on shutdown that
  // will cause fewer workers to be created than one would expect. It isn't
  // much of an issue in real life, but affects some tests. Since we only spawn
  // one worker at a time, the following sequence of events can happen:
  //
  //  1. Main thread posts a bunch of unrelated tasks that would normally be
  //     run on separate threads.
  //  2. The first task post causes us to start a worker. Other tasks do not
  //     cause a worker to start since one is pending.
  //  3. Main thread initiates shutdown.
  //  4. No more threads are created since the shutdown_called_ flag is set.
  //
  // The result is that one may expect that max_threads_ workers to be created
  // given the workload, but in reality fewer may be created because the
  // sequence of thread creation on the background threads is racing with the
  // shutdown call.
  if (!shutdown_called_ &&
      !thread_being_created_ &&
      cleanup_state_ == CLEANUP_DONE &&
      threads_.size() < max_threads_ &&
      waiting_thread_count_ == 0) {
    // We could use an additional thread if there's work to be done.
    for (PendingTaskSet::const_iterator i = pending_tasks_.begin();
         i != pending_tasks_.end(); ++i) {
      if (IsSequenceTokenRunnable(i->sequence_token_id)) {
        // Found a runnable task, mark the thread as being started.
        thread_being_created_ = true;
        return static_cast<int>(threads_.size() + 1);
      }
    }
  }
  return 0;
}

void SequencedWorkerPool::Inner::FinishStartingAdditionalThread(
    int thread_number) {
  // Called outside of the lock.
  DCHECK_GT(thread_number, 0);

  // The worker is assigned to the list when the thread actually starts, which
  // will manage the memory of the pointer.
  new Worker(worker_pool_, thread_number, thread_name_prefix_);
}

void SequencedWorkerPool::Inner::SignalHasWork() {
  has_work_cv_.Signal();
  if (testing_observer_) {
    testing_observer_->OnHasWork();
  }
}

bool SequencedWorkerPool::Inner::CanShutdown() const {
  lock_.AssertAcquired();
  // See PrepareToStartAdditionalThreadIfHelpful for how thread creation works.
  return !thread_being_created_ &&
         blocking_shutdown_thread_count_ == 0 &&
         blocking_shutdown_pending_task_count_ == 0;
}

base::StaticAtomicSequenceNumber
SequencedWorkerPool::Inner::g_last_sequence_number_;

// SequencedWorkerPool --------------------------------------------------------

// static
SequencedWorkerPool::SequenceToken
SequencedWorkerPool::GetSequenceTokenForCurrentThread() {
  // Don't construct lazy instance on check.
  if (g_lazy_tls_ptr == NULL)
    return SequenceToken();

  SequencedWorkerPool::SequenceToken* token = g_lazy_tls_ptr.Get().Get();
  if (!token)
    return SequenceToken();
  return *token;
}

SequencedWorkerPool::SequencedWorkerPool(size_t max_threads,
                                         const std::string& thread_name_prefix)
    : constructor_task_runner_(ThreadTaskRunnerHandle::Get()),
      inner_(new Inner(this, max_threads, thread_name_prefix, NULL)) {
}

SequencedWorkerPool::SequencedWorkerPool(size_t max_threads,
                                         const std::string& thread_name_prefix,
                                         TestingObserver* observer)
    : constructor_task_runner_(ThreadTaskRunnerHandle::Get()),
      inner_(new Inner(this, max_threads, thread_name_prefix, observer)) {
}

SequencedWorkerPool::~SequencedWorkerPool() {}

void SequencedWorkerPool::OnDestruct() const {
  // Avoid deleting ourselves on a worker thread (which would
  // deadlock).
  if (RunsTasksOnCurrentThread()) {
    constructor_task_runner_->DeleteSoon(FROM_HERE, this);
  } else {
    delete this;
  }
}

SequencedWorkerPool::SequenceToken SequencedWorkerPool::GetSequenceToken() {
  return inner_->GetSequenceToken();
}

SequencedWorkerPool::SequenceToken SequencedWorkerPool::GetNamedSequenceToken(
    const std::string& name) {
  return inner_->GetNamedSequenceToken(name);
}

scoped_refptr<SequencedTaskRunner> SequencedWorkerPool::GetSequencedTaskRunner(
    SequenceToken token) {
  return GetSequencedTaskRunnerWithShutdownBehavior(token, BLOCK_SHUTDOWN);
}

scoped_refptr<SequencedTaskRunner>
SequencedWorkerPool::GetSequencedTaskRunnerWithShutdownBehavior(
    SequenceToken token, WorkerShutdown shutdown_behavior) {
  return new SequencedWorkerPoolSequencedTaskRunner(
      this, token, shutdown_behavior);
}

scoped_refptr<TaskRunner>
SequencedWorkerPool::GetTaskRunnerWithShutdownBehavior(
    WorkerShutdown shutdown_behavior) {
  return new SequencedWorkerPoolTaskRunner(this, shutdown_behavior);
}

bool SequencedWorkerPool::PostWorkerTask(
    const tracked_objects::Location& from_here,
    const Closure& task) {
  return inner_->PostTask(NULL, SequenceToken(), BLOCK_SHUTDOWN,
                          from_here, task, TimeDelta());
}

bool SequencedWorkerPool::PostDelayedWorkerTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  WorkerShutdown shutdown_behavior =
      delay == TimeDelta() ? BLOCK_SHUTDOWN : SKIP_ON_SHUTDOWN;
  return inner_->PostTask(NULL, SequenceToken(), shutdown_behavior,
                          from_here, task, delay);
}

bool SequencedWorkerPool::PostWorkerTaskWithShutdownBehavior(
    const tracked_objects::Location& from_here,
    const Closure& task,
    WorkerShutdown shutdown_behavior) {
  return inner_->PostTask(NULL, SequenceToken(), shutdown_behavior,
                          from_here, task, TimeDelta());
}

bool SequencedWorkerPool::PostSequencedWorkerTask(
    SequenceToken sequence_token,
    const tracked_objects::Location& from_here,
    const Closure& task) {
  return inner_->PostTask(NULL, sequence_token, BLOCK_SHUTDOWN,
                          from_here, task, TimeDelta());
}

bool SequencedWorkerPool::PostDelayedSequencedWorkerTask(
    SequenceToken sequence_token,
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  WorkerShutdown shutdown_behavior =
      delay == TimeDelta() ? BLOCK_SHUTDOWN : SKIP_ON_SHUTDOWN;
  return inner_->PostTask(NULL, sequence_token, shutdown_behavior,
                          from_here, task, delay);
}

bool SequencedWorkerPool::PostNamedSequencedWorkerTask(
    const std::string& token_name,
    const tracked_objects::Location& from_here,
    const Closure& task) {
  DCHECK(!token_name.empty());
  return inner_->PostTask(&token_name, SequenceToken(), BLOCK_SHUTDOWN,
                          from_here, task, TimeDelta());
}

bool SequencedWorkerPool::PostSequencedWorkerTaskWithShutdownBehavior(
    SequenceToken sequence_token,
    const tracked_objects::Location& from_here,
    const Closure& task,
    WorkerShutdown shutdown_behavior) {
  return inner_->PostTask(NULL, sequence_token, shutdown_behavior,
                          from_here, task, TimeDelta());
}

bool SequencedWorkerPool::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay) {
  return PostDelayedWorkerTask(from_here, task, delay);
}

bool SequencedWorkerPool::RunsTasksOnCurrentThread() const {
  return inner_->RunsTasksOnCurrentThread();
}

bool SequencedWorkerPool::IsRunningSequenceOnCurrentThread(
    SequenceToken sequence_token) const {
  return inner_->IsRunningSequenceOnCurrentThread(sequence_token);
}

void SequencedWorkerPool::FlushForTesting() {
  inner_->CleanupForTesting();
}

void SequencedWorkerPool::SignalHasWorkForTesting() {
  inner_->SignalHasWorkForTesting();
}

void SequencedWorkerPool::Shutdown(int max_new_blocking_tasks_after_shutdown) {
  DCHECK(constructor_task_runner_->BelongsToCurrentThread());
  inner_->Shutdown(max_new_blocking_tasks_after_shutdown);
}

bool SequencedWorkerPool::IsShutdownInProgress() {
  return inner_->IsShutdownInProgress();
}

}  // namespace base
