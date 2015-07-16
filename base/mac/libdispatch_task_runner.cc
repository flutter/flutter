// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/libdispatch_task_runner.h"

#include "base/callback.h"

namespace base {
namespace mac {

LibDispatchTaskRunner::LibDispatchTaskRunner(const char* name)
    : queue_(dispatch_queue_create(name, NULL)),
      queue_finalized_(false, false) {
  dispatch_set_context(queue_, this);
  dispatch_set_finalizer_f(queue_, &LibDispatchTaskRunner::Finalizer);
}

bool LibDispatchTaskRunner::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    base::TimeDelta delay) {
  if (!queue_)
    return false;

  // The block runtime would implicitly copy the reference, not the object
  // it's referencing. Copy the closure into block storage so it's available
  // to run.
  __block const Closure task_copy = task;
  void(^run_task)(void) = ^{
      task_copy.Run();
  };

  int64 delay_nano =
      delay.InMicroseconds() * base::Time::kNanosecondsPerMicrosecond;
  if (delay_nano > 0) {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay_nano);
    dispatch_after(time, queue_, run_task);
  } else {
    dispatch_async(queue_, run_task);
  }
  return true;
}

bool LibDispatchTaskRunner::RunsTasksOnCurrentThread() const {
  return queue_ == dispatch_get_current_queue();
}

bool LibDispatchTaskRunner::PostNonNestableDelayedTask(
    const tracked_objects::Location& from_here,
    const Closure& task,
    base::TimeDelta delay) {
  return PostDelayedTask(from_here, task, delay);
}

void LibDispatchTaskRunner::Shutdown() {
  dispatch_release(queue_);
  queue_ = NULL;
  queue_finalized_.Wait();
}

dispatch_queue_t LibDispatchTaskRunner::GetDispatchQueue() const {
  return queue_;
}

LibDispatchTaskRunner::~LibDispatchTaskRunner() {
  if (queue_) {
    dispatch_set_context(queue_, NULL);
    dispatch_set_finalizer_f(queue_, NULL);
    dispatch_release(queue_);
  }
}

void LibDispatchTaskRunner::Finalizer(void* context) {
  LibDispatchTaskRunner* self = static_cast<LibDispatchTaskRunner*>(context);
  self->queue_finalized_.Signal();
}

}  // namespace mac
}  // namespace base
