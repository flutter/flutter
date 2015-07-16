// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/timer/timer.h"

#include <stddef.h>

#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/single_thread_task_runner.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/platform_thread.h"

namespace base {

// BaseTimerTaskInternal is a simple delegate for scheduling a callback to
// Timer in the thread's default task runner. It also handles the following
// edge cases:
// - deleted by the task runner.
// - abandoned (orphaned) by Timer.
class BaseTimerTaskInternal {
 public:
  explicit BaseTimerTaskInternal(Timer* timer)
      : timer_(timer) {
  }

  ~BaseTimerTaskInternal() {
    // This task may be getting cleared because the task runner has been
    // destructed.  If so, don't leave Timer with a dangling pointer
    // to this.
    if (timer_)
      timer_->StopAndAbandon();
  }

  void Run() {
    // timer_ is NULL if we were abandoned.
    if (!timer_)
      return;

    // *this will be deleted by the task runner, so Timer needs to
    // forget us:
    timer_->scheduled_task_ = NULL;

    // Although Timer should not call back into *this, let's clear
    // the timer_ member first to be pedantic.
    Timer* timer = timer_;
    timer_ = NULL;
    timer->RunScheduledTask();
  }

  // The task remains in the MessageLoop queue, but nothing will happen when it
  // runs.
  void Abandon() {
    timer_ = NULL;
  }

 private:
  Timer* timer_;
};

Timer::Timer(bool retain_user_task, bool is_repeating)
    : scheduled_task_(NULL),
      thread_id_(0),
      is_repeating_(is_repeating),
      retain_user_task_(retain_user_task),
      is_running_(false) {
}

Timer::Timer(const tracked_objects::Location& posted_from,
             TimeDelta delay,
             const base::Closure& user_task,
             bool is_repeating)
    : scheduled_task_(NULL),
      posted_from_(posted_from),
      delay_(delay),
      user_task_(user_task),
      thread_id_(0),
      is_repeating_(is_repeating),
      retain_user_task_(true),
      is_running_(false) {
}

Timer::~Timer() {
  StopAndAbandon();
}

bool Timer::IsRunning() const {
  return is_running_;
}

TimeDelta Timer::GetCurrentDelay() const {
  return delay_;
}

void Timer::SetTaskRunner(scoped_refptr<SingleThreadTaskRunner> task_runner) {
  // Do not allow changing the task runner once something has been scheduled.
  DCHECK_EQ(thread_id_, 0);
  task_runner_.swap(task_runner);
}

void Timer::Start(const tracked_objects::Location& posted_from,
                  TimeDelta delay,
                  const base::Closure& user_task) {
  SetTaskInfo(posted_from, delay, user_task);
  Reset();
}

void Timer::Stop() {
  is_running_ = false;
  if (!retain_user_task_)
    user_task_.Reset();
}

void Timer::Reset() {
  DCHECK(!user_task_.is_null());

  // If there's no pending task, start one up and return.
  if (!scheduled_task_) {
    PostNewScheduledTask(delay_);
    return;
  }

  // Set the new desired_run_time_.
  if (delay_ > TimeDelta::FromMicroseconds(0))
    desired_run_time_ = TimeTicks::Now() + delay_;
  else
    desired_run_time_ = TimeTicks();

  // We can use the existing scheduled task if it arrives before the new
  // desired_run_time_.
  if (desired_run_time_ >= scheduled_run_time_) {
    is_running_ = true;
    return;
  }

  // We can't reuse the scheduled_task_, so abandon it and post a new one.
  AbandonScheduledTask();
  PostNewScheduledTask(delay_);
}

void Timer::SetTaskInfo(const tracked_objects::Location& posted_from,
                        TimeDelta delay,
                        const base::Closure& user_task) {
  posted_from_ = posted_from;
  delay_ = delay;
  user_task_ = user_task;
}

void Timer::PostNewScheduledTask(TimeDelta delay) {
  DCHECK(scheduled_task_ == NULL);
  is_running_ = true;
  scheduled_task_ = new BaseTimerTaskInternal(this);
  if (delay > TimeDelta::FromMicroseconds(0)) {
    GetTaskRunner()->PostDelayedTask(posted_from_,
        base::Bind(&BaseTimerTaskInternal::Run, base::Owned(scheduled_task_)),
        delay);
    scheduled_run_time_ = desired_run_time_ = TimeTicks::Now() + delay;
  } else {
    GetTaskRunner()->PostTask(posted_from_,
        base::Bind(&BaseTimerTaskInternal::Run, base::Owned(scheduled_task_)));
    scheduled_run_time_ = desired_run_time_ = TimeTicks();
  }
  // Remember the thread ID that posts the first task -- this will be verified
  // later when the task is abandoned to detect misuse from multiple threads.
  if (!thread_id_) {
    DCHECK(GetTaskRunner()->BelongsToCurrentThread());
    thread_id_ = static_cast<int>(PlatformThread::CurrentId());
  }
}

scoped_refptr<SingleThreadTaskRunner> Timer::GetTaskRunner() {
  return task_runner_.get() ? task_runner_ : ThreadTaskRunnerHandle::Get();
}

void Timer::AbandonScheduledTask() {
  DCHECK(thread_id_ == 0 ||
         thread_id_ == static_cast<int>(PlatformThread::CurrentId()));
  if (scheduled_task_) {
    scheduled_task_->Abandon();
    scheduled_task_ = NULL;
  }
}

void Timer::RunScheduledTask() {
  // Task may have been disabled.
  if (!is_running_)
    return;

  // First check if we need to delay the task because of a new target time.
  if (desired_run_time_ > scheduled_run_time_) {
    // TimeTicks::Now() can be expensive, so only call it if we know the user
    // has changed the desired_run_time_.
    TimeTicks now = TimeTicks::Now();
    // Task runner may have called us late anyway, so only post a continuation
    // task if the desired_run_time_ is in the future.
    if (desired_run_time_ > now) {
      // Post a new task to span the remaining time.
      PostNewScheduledTask(desired_run_time_ - now);
      return;
    }
  }

  // Make a local copy of the task to run. The Stop method will reset the
  // user_task_ member if retain_user_task_ is false.
  base::Closure task = user_task_;

  if (is_repeating_)
    PostNewScheduledTask(delay_);
  else
    Stop();

  task.Run();

  // No more member accesses here: *this could be deleted at this point.
}

}  // namespace base
