// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/worker_pool_posix.h"

#include "base/bind.h"
#include "base/callback.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/strings/stringprintf.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread_local.h"
#include "base/threading/worker_pool.h"
#include "base/trace_event/trace_event.h"
#include "base/tracked_objects.h"

using tracked_objects::TrackedTime;

namespace base {

namespace {

base::LazyInstance<ThreadLocalBoolean>::Leaky
    g_worker_pool_running_on_this_thread = LAZY_INSTANCE_INITIALIZER;

const int kIdleSecondsBeforeExit = 10 * 60;

class WorkerPoolImpl {
 public:
  WorkerPoolImpl();
  ~WorkerPoolImpl();

  void PostTask(const tracked_objects::Location& from_here,
                const base::Closure& task, bool task_is_slow);

 private:
  scoped_refptr<base::PosixDynamicThreadPool> pool_;
};

WorkerPoolImpl::WorkerPoolImpl()
    : pool_(new base::PosixDynamicThreadPool("WorkerPool",
                                             kIdleSecondsBeforeExit)) {
}

WorkerPoolImpl::~WorkerPoolImpl() {
  pool_->Terminate();
}

void WorkerPoolImpl::PostTask(const tracked_objects::Location& from_here,
                              const base::Closure& task, bool task_is_slow) {
  pool_->PostTask(from_here, task);
}

base::LazyInstance<WorkerPoolImpl> g_lazy_worker_pool =
    LAZY_INSTANCE_INITIALIZER;

class WorkerThread : public PlatformThread::Delegate {
 public:
  WorkerThread(const std::string& name_prefix,
               base::PosixDynamicThreadPool* pool)
      : name_prefix_(name_prefix),
        pool_(pool) {}

  void ThreadMain() override;

 private:
  const std::string name_prefix_;
  scoped_refptr<base::PosixDynamicThreadPool> pool_;

  DISALLOW_COPY_AND_ASSIGN(WorkerThread);
};

void WorkerThread::ThreadMain() {
  g_worker_pool_running_on_this_thread.Get().Set(true);
  const std::string name = base::StringPrintf(
      "%s/%d", name_prefix_.c_str(), PlatformThread::CurrentId());
  // Note |name.c_str()| must remain valid for for the whole life of the thread.
  PlatformThread::SetName(name);

  for (;;) {
    PendingTask pending_task = pool_->WaitForTask();
    if (pending_task.task.is_null())
      break;
    TRACE_EVENT2("toplevel", "WorkerThread::ThreadMain::Run",
        "src_file", pending_task.posted_from.file_name(),
        "src_func", pending_task.posted_from.function_name());

    tracked_objects::TaskStopwatch stopwatch;
    stopwatch.Start();
    pending_task.task.Run();
    stopwatch.Stop();

    tracked_objects::ThreadData::TallyRunOnWorkerThreadIfTracking(
        pending_task.birth_tally, pending_task.time_posted, stopwatch);
  }

  // The WorkerThread is non-joinable, so it deletes itself.
  delete this;
}

}  // namespace

// static
bool WorkerPool::PostTask(const tracked_objects::Location& from_here,
                          const base::Closure& task, bool task_is_slow) {
  g_lazy_worker_pool.Pointer()->PostTask(from_here, task, task_is_slow);
  return true;
}

// static
bool WorkerPool::RunsTasksOnCurrentThread() {
  return g_worker_pool_running_on_this_thread.Get().Get();
}

PosixDynamicThreadPool::PosixDynamicThreadPool(const std::string& name_prefix,
                                               int idle_seconds_before_exit)
    : name_prefix_(name_prefix),
      idle_seconds_before_exit_(idle_seconds_before_exit),
      pending_tasks_available_cv_(&lock_),
      num_idle_threads_(0),
      terminated_(false) {}

PosixDynamicThreadPool::~PosixDynamicThreadPool() {
  while (!pending_tasks_.empty())
    pending_tasks_.pop();
}

void PosixDynamicThreadPool::Terminate() {
  {
    AutoLock locked(lock_);
    DCHECK(!terminated_) << "Thread pool is already terminated.";
    terminated_ = true;
  }
  pending_tasks_available_cv_.Broadcast();
}

void PosixDynamicThreadPool::PostTask(
    const tracked_objects::Location& from_here,
    const base::Closure& task) {
  PendingTask pending_task(from_here, task);
  AddTask(&pending_task);
}

void PosixDynamicThreadPool::AddTask(PendingTask* pending_task) {
  AutoLock locked(lock_);
  DCHECK(!terminated_) <<
      "This thread pool is already terminated.  Do not post new tasks.";

  pending_tasks_.push(*pending_task);
  pending_task->task.Reset();

  // We have enough worker threads.
  if (static_cast<size_t>(num_idle_threads_) >= pending_tasks_.size()) {
    pending_tasks_available_cv_.Signal();
  } else {
    // The new PlatformThread will take ownership of the WorkerThread object,
    // which will delete itself on exit.
    WorkerThread* worker =
        new WorkerThread(name_prefix_, this);
    PlatformThread::CreateNonJoinable(0, worker);
  }
}

PendingTask PosixDynamicThreadPool::WaitForTask() {
  AutoLock locked(lock_);

  if (terminated_)
    return PendingTask(FROM_HERE, base::Closure());

  if (pending_tasks_.empty()) {  // No work available, wait for work.
    num_idle_threads_++;
    if (num_idle_threads_cv_.get())
      num_idle_threads_cv_->Signal();
    pending_tasks_available_cv_.TimedWait(
        TimeDelta::FromSeconds(idle_seconds_before_exit_));
    num_idle_threads_--;
    if (num_idle_threads_cv_.get())
      num_idle_threads_cv_->Signal();
    if (pending_tasks_.empty()) {
      // We waited for work, but there's still no work.  Return NULL to signal
      // the thread to terminate.
      return PendingTask(FROM_HERE, base::Closure());
    }
  }

  PendingTask pending_task = pending_tasks_.front();
  pending_tasks_.pop();
  return pending_task;
}

}  // namespace base
