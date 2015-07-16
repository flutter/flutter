// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_LOOP_PROXY_IMPL_H_
#define BASE_MESSAGE_LOOP_MESSAGE_LOOP_PROXY_IMPL_H_

#include "base/base_export.h"
#include "base/memory/ref_counted.h"
#include "base/message_loop/message_loop_proxy.h"
#include "base/pending_task.h"
#include "base/synchronization/lock.h"
#include "base/threading/platform_thread.h"

namespace base {
namespace internal {

class IncomingTaskQueue;

// A stock implementation of MessageLoopProxy that is created and managed by a
// MessageLoop. For now a MessageLoopProxyImpl can only be created as part of a
// MessageLoop.
class BASE_EXPORT MessageLoopProxyImpl : public MessageLoopProxy {
 public:
  explicit MessageLoopProxyImpl(
      scoped_refptr<IncomingTaskQueue> incoming_queue);

  // Initialize this message loop proxy on the current thread.
  void BindToCurrentThread();

  // MessageLoopProxy implementation
  bool PostDelayedTask(const tracked_objects::Location& from_here,
                       const base::Closure& task,
                       base::TimeDelta delay) override;
  bool PostNonNestableDelayedTask(const tracked_objects::Location& from_here,
                                  const base::Closure& task,
                                  base::TimeDelta delay) override;
  bool RunsTasksOnCurrentThread() const override;

 private:
  friend class RefCountedThreadSafe<MessageLoopProxyImpl>;
  ~MessageLoopProxyImpl() override;

  // THe incoming queue receiving all posted tasks.
  scoped_refptr<IncomingTaskQueue> incoming_queue_;

  // ID of the thread |this| was created on.  Could be accessed on multiple
  // threads, protected by |valid_thread_id_lock_|.
  PlatformThreadId valid_thread_id_;
  mutable Lock valid_thread_id_lock_;

  DISALLOW_COPY_AND_ASSIGN(MessageLoopProxyImpl);
};

}  // namespace internal
}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_LOOP_PROXY_IMPL_H_
