// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_MESSAGE_PUMP_HANDLE_WATCHER_H_
#define MOJO_MESSAGE_PUMP_HANDLE_WATCHER_H_

#include <memory>

#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/run_loop.h"
#include "mojo/public/c/system/time.h"
#include "mojo/public/cpp/system/handle.h"

namespace base {
class Thread;
}

namespace mojo {
namespace common {
namespace test {
class HandleWatcherTest;
}

// HandleWatcher is used to asynchronously wait on a handle and notify a Closure
// when the handle is ready, or the deadline has expired.
class HandleWatcher {
 public:
  HandleWatcher();

  // The destructor implicitly stops listening. See Stop() for details.
  ~HandleWatcher();

  // Starts listening for |handle|. This implicitly invokes Stop(). In other
  // words, Start() performs one asynchronous watch at a time. It is ok to call
  // Start() multiple times, but it cancels any existing watches. |callback| is
  // notified when the handle is ready, invalid or deadline has passed and is
  // notified on the thread Start() was invoked on. If the current thread exits
  // before the handle is ready, then |callback| is invoked with a result of
  // MOJO_RESULT_ABORTED.
  void Start(const Handle& handle,
             MojoHandleSignals handle_signals,
             MojoDeadline deadline,
             const base::Callback<void(MojoResult)>& callback);

  // Stops listening. Does nothing if not in the process of listening. Blocks
  // until no longer listening on the handle.
  void Stop();

 private:
  class StateBase;
  class SameThreadWatchingState;
  class SecondaryThreadWatchingState;

  // If non-null, Start() has been invoked.
  std::unique_ptr<StateBase> state_;

  DISALLOW_COPY_AND_ASSIGN(HandleWatcher);
};

}  // namespace common
}  // namespace mojo

#endif  // MOJO_MESSAGE_PUMP_HANDLE_WATCHER_H_
