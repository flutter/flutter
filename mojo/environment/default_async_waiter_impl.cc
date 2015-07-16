// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/environment/default_async_waiter_impl.h"

#include "base/bind.h"
#include "mojo/common/handle_watcher.h"

namespace mojo {
namespace internal {
namespace {

void OnHandleReady(common::HandleWatcher* watcher,
                   MojoAsyncWaitCallback callback,
                   void* closure,
                   MojoResult result) {
  delete watcher;
  callback(closure, result);
}

MojoAsyncWaitID AsyncWait(MojoHandle handle,
                          MojoHandleSignals signals,
                          MojoDeadline deadline,
                          MojoAsyncWaitCallback callback,
                          void* closure) {
  // This instance will be deleted when done or cancelled.
  common::HandleWatcher* watcher = new common::HandleWatcher();
  watcher->Start(Handle(handle), signals, deadline,
                 base::Bind(&OnHandleReady, watcher, callback, closure));
  return reinterpret_cast<MojoAsyncWaitID>(watcher);
}

void CancelWait(MojoAsyncWaitID wait_id) {
  delete reinterpret_cast<common::HandleWatcher*>(wait_id);
}

const MojoAsyncWaiter kDefaultAsyncWaiter = {
  AsyncWait,
  CancelWait
};

}  // namespace

const MojoAsyncWaiter* GetDefaultAsyncWaiterImpl() {
  return &kDefaultAsyncWaiter;
}

}  // namespace internal
}  // namespace mojo
