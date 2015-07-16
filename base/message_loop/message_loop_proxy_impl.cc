// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_loop_proxy_impl.h"

#include "base/location.h"
#include "base/logging.h"
#include "base/message_loop/incoming_task_queue.h"
#include "base/message_loop/message_loop.h"

namespace base {
namespace internal {

MessageLoopProxyImpl::MessageLoopProxyImpl(
    scoped_refptr<IncomingTaskQueue> incoming_queue)
    : incoming_queue_(incoming_queue),
      valid_thread_id_(kInvalidThreadId) {
}

void MessageLoopProxyImpl::BindToCurrentThread() {
  AutoLock lock(valid_thread_id_lock_);
  DCHECK_EQ(kInvalidThreadId, valid_thread_id_);
  valid_thread_id_ = PlatformThread::CurrentId();
}

bool MessageLoopProxyImpl::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const base::Closure& task,
    base::TimeDelta delay) {
  DCHECK(!task.is_null()) << from_here.ToString();
  return incoming_queue_->AddToIncomingQueue(from_here, task, delay, true);
}

bool MessageLoopProxyImpl::PostNonNestableDelayedTask(
    const tracked_objects::Location& from_here,
    const base::Closure& task,
    base::TimeDelta delay) {
  DCHECK(!task.is_null()) << from_here.ToString();
  return incoming_queue_->AddToIncomingQueue(from_here, task, delay, false);
}

bool MessageLoopProxyImpl::RunsTasksOnCurrentThread() const {
  AutoLock lock(valid_thread_id_lock_);
  return valid_thread_id_ == PlatformThread::CurrentId();
}

MessageLoopProxyImpl::~MessageLoopProxyImpl() {
}

}  // namespace internal

scoped_refptr<MessageLoopProxy>
MessageLoopProxy::current() {
  MessageLoop* cur_loop = MessageLoop::current();
  if (!cur_loop)
    return NULL;
  return cur_loop->message_loop_proxy();
}

}  // namespace base
