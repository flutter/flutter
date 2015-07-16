// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/sequenced_worker_pool_owner.h"

#include "base/location.h"
#include "base/message_loop/message_loop.h"
#include "base/single_thread_task_runner.h"

namespace base {

SequencedWorkerPoolOwner::SequencedWorkerPoolOwner(
    size_t max_threads,
    const std::string& thread_name_prefix)
    : constructor_message_loop_(MessageLoop::current()),
      pool_(new SequencedWorkerPool(max_threads, thread_name_prefix, this)),
      has_work_call_count_(0) {}

SequencedWorkerPoolOwner::~SequencedWorkerPoolOwner() {
  pool_ = NULL;
  MessageLoop::current()->Run();
}

const scoped_refptr<SequencedWorkerPool>& SequencedWorkerPoolOwner::pool() {
  return pool_;
}

void SequencedWorkerPoolOwner::SetWillWaitForShutdownCallback(
    const Closure& callback) {
  will_wait_for_shutdown_callback_ = callback;
}

int SequencedWorkerPoolOwner::has_work_call_count() const {
  AutoLock lock(has_work_lock_);
  return has_work_call_count_;
}

void SequencedWorkerPoolOwner::OnHasWork() {
  AutoLock lock(has_work_lock_);
  ++has_work_call_count_;
}

void SequencedWorkerPoolOwner::WillWaitForShutdown() {
  if (!will_wait_for_shutdown_callback_.is_null()) {
    will_wait_for_shutdown_callback_.Run();

    // Release the reference to the callback to prevent retain cycles.
    will_wait_for_shutdown_callback_ = Closure();
  }
}

void SequencedWorkerPoolOwner::OnDestruct() {
  constructor_message_loop_->task_runner()->PostTask(
      FROM_HERE, constructor_message_loop_->QuitWhenIdleClosure());
}

}  // namespace base
