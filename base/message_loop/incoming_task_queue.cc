// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/incoming_task_queue.h"

#include <limits>

#include "base/location.h"
#include "base/message_loop/message_loop.h"
#include "base/metrics/histogram.h"
#include "base/synchronization/waitable_event.h"
#include "base/time/time.h"

namespace base {
namespace internal {

namespace {

#ifndef NDEBUG
// Delays larger than this are often bogus, and a warning should be emitted in
// debug builds to warn developers.  http://crbug.com/450045
const int kTaskDelayWarningThresholdInSeconds =
    14 * 24 * 60 * 60;  // 14 days.
#endif

// Returns true if MessagePump::ScheduleWork() must be called one
// time for every task that is added to the MessageLoop incoming queue.
bool AlwaysNotifyPump(MessageLoop::Type type) {
#if defined(OS_ANDROID)
  // The Android UI message loop needs to get notified each time a task is
  // added
  // to the incoming queue.
  return type == MessageLoop::TYPE_UI || type == MessageLoop::TYPE_JAVA;
#else
  return false;
#endif
}

}  // namespace

IncomingTaskQueue::IncomingTaskQueue(MessageLoop* message_loop)
    : high_res_task_count_(0),
      message_loop_(message_loop),
      next_sequence_num_(0),
      message_loop_scheduled_(false),
      always_schedule_work_(AlwaysNotifyPump(message_loop_->type())),
      is_ready_for_scheduling_(false) {
}

bool IncomingTaskQueue::AddToIncomingQueue(
    const tracked_objects::Location& from_here,
    const Closure& task,
    TimeDelta delay,
    bool nestable) {
  DLOG_IF(WARNING,
          delay.InSeconds() > kTaskDelayWarningThresholdInSeconds)
      << "Requesting super-long task delay period of " << delay.InSeconds()
      << " seconds from here: " << from_here.ToString();

  AutoLock locked(incoming_queue_lock_);
  PendingTask pending_task(
      from_here, task, CalculateDelayedRuntime(delay), nestable);
#if defined(OS_WIN)
  // We consider the task needs a high resolution timer if the delay is
  // more than 0 and less than 32ms. This caps the relative error to
  // less than 50% : a 33ms wait can wake at 48ms since the default
  // resolution on Windows is between 10 and 15ms.
  if (delay > TimeDelta() &&
      delay.InMilliseconds() < (2 * Time::kMinLowResolutionThresholdMs)) {
    ++high_res_task_count_;
    pending_task.is_high_res = true;
  }
#endif
  return PostPendingTask(&pending_task);
}

bool IncomingTaskQueue::HasHighResolutionTasks() {
  AutoLock lock(incoming_queue_lock_);
  return high_res_task_count_ > 0;
}

bool IncomingTaskQueue::IsIdleForTesting() {
  AutoLock lock(incoming_queue_lock_);
  return incoming_queue_.empty();
}

int IncomingTaskQueue::ReloadWorkQueue(TaskQueue* work_queue) {
  // Make sure no tasks are lost.
  DCHECK(work_queue->empty());

  // Acquire all we can from the inter-thread queue with one lock acquisition.
  AutoLock lock(incoming_queue_lock_);
  if (incoming_queue_.empty()) {
    // If the loop attempts to reload but there are no tasks in the incoming
    // queue, that means it will go to sleep waiting for more work. If the
    // incoming queue becomes nonempty we need to schedule it again.
    message_loop_scheduled_ = false;
  } else {
    incoming_queue_.Swap(work_queue);
  }
  // Reset the count of high resolution tasks since our queue is now empty.
  int high_res_tasks = high_res_task_count_;
  high_res_task_count_ = 0;
  return high_res_tasks;
}

void IncomingTaskQueue::WillDestroyCurrentMessageLoop() {
  AutoLock lock(incoming_queue_lock_);
  message_loop_ = NULL;
}

void IncomingTaskQueue::StartScheduling() {
  AutoLock lock(incoming_queue_lock_);
  DCHECK(!is_ready_for_scheduling_);
  DCHECK(!message_loop_scheduled_);
  is_ready_for_scheduling_ = true;
  if (!incoming_queue_.empty())
    ScheduleWork();
}

IncomingTaskQueue::~IncomingTaskQueue() {
  // Verify that WillDestroyCurrentMessageLoop() has been called.
  DCHECK(!message_loop_);
}

TimeTicks IncomingTaskQueue::CalculateDelayedRuntime(TimeDelta delay) {
  TimeTicks delayed_run_time;
  if (delay > TimeDelta())
    delayed_run_time = TimeTicks::Now() + delay;
  else
    DCHECK_EQ(delay.InMilliseconds(), 0) << "delay should not be negative";
  return delayed_run_time;
}

bool IncomingTaskQueue::PostPendingTask(PendingTask* pending_task) {
  // Warning: Don't try to short-circuit, and handle this thread's tasks more
  // directly, as it could starve handling of foreign threads.  Put every task
  // into this queue.

  // This should only be called while the lock is taken.
  incoming_queue_lock_.AssertAcquired();

  if (!message_loop_) {
    pending_task->task.Reset();
    return false;
  }

  // Initialize the sequence number. The sequence number is used for delayed
  // tasks (to faciliate FIFO sorting when two tasks have the same
  // delayed_run_time value) and for identifying the task in about:tracing.
  pending_task->sequence_num = next_sequence_num_++;

  message_loop_->task_annotator()->DidQueueTask("MessageLoop::PostTask",
                                                *pending_task);

  bool was_empty = incoming_queue_.empty();
  incoming_queue_.push(*pending_task);
  pending_task->task.Reset();

  if (is_ready_for_scheduling_ &&
      (always_schedule_work_ || (!message_loop_scheduled_ && was_empty))) {
    ScheduleWork();
  }

  return true;
}

void IncomingTaskQueue::ScheduleWork() {
  DCHECK(is_ready_for_scheduling_);
  // Wake up the message loop.
  message_loop_->ScheduleWork();
  // After we've scheduled the message loop, we do not need to do so again
  // until we know it has processed all of the work in our queue and is
  // waiting for more work again. The message loop will always attempt to
  // reload from the incoming queue before waiting again so we clear this flag
  // in ReloadWorkQueue().
  message_loop_scheduled_ = true;
}

}  // namespace internal
}  // namespace base
