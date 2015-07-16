// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_LOOP_PROXY_H_
#define BASE_MESSAGE_LOOP_MESSAGE_LOOP_PROXY_H_

#include "base/base_export.h"
#include "base/compiler_specific.h"
#include "base/memory/ref_counted.h"
#include "base/single_thread_task_runner.h"

// MessageLoopProxy is deprecated. Code should prefer to depend on TaskRunner
// (or the various specializations) for passing task runners around, and should
// use ThreadTaskRunnerHandle::Get() to get the thread's associated task runner.
//
// See http://crbug.com/391045 for more details.
// Example for these changes:
//
// base::MessageLoopProxy::current() -> base::ThreadTaskRunnerHandle::Get()
// scoped_refptr<base::MessageLoopProxy> ->
//     scoped_refptr<base::SingleThreadTaskRunner>
// base::MessageLoopProxy -> base::SingleThreadTaskRunner

namespace base {

// This class provides a thread-safe refcounted interface to the Post* methods
// of a message loop. This class can outlive the target message loop.
// MessageLoopProxy objects are constructed automatically for all MessageLoops.
// So, to access them, you can use any of the following:
//   Thread::message_loop_proxy()
//   MessageLoop::current()->message_loop_proxy()
//   MessageLoopProxy::current()
//
// TODO(akalin): Now that we have the *TaskRunner interfaces, we can
// merge this with MessageLoopProxyImpl.
class BASE_EXPORT MessageLoopProxy : public SingleThreadTaskRunner {
 public:
  // Gets the MessageLoopProxy for the current message loop, creating one if
  // needed.
  static scoped_refptr<MessageLoopProxy> current();

 protected:
  MessageLoopProxy();
  ~MessageLoopProxy() override;
};

}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_LOOP_PROXY_H_
