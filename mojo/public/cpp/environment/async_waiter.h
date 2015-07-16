// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_ENVIRONMENT_ASYNC_WAITER_H_
#define MOJO_PUBLIC_CPP_ENVIRONMENT_ASYNC_WAITER_H_

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/system/handle.h"

namespace mojo {

// A class that waits until a handle is ready and calls |callback| with the
// result. If the AsyncWaiter is deleted before the handle is ready, the wait is
// cancelled and the callback will not be called.
class AsyncWaiter {
 public:
  typedef mojo::Callback<void(MojoResult)> Callback;

  AsyncWaiter(Handle handle,
              MojoHandleSignals signals,
              const Callback& callback);
  ~AsyncWaiter();

 private:
  static void WaitComplete(void* waiter, MojoResult result);
  void WaitCompleteInternal(MojoResult result);

  const MojoAsyncWaiter* waiter_;
  MojoAsyncWaitID id_;
  const Callback callback_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(AsyncWaiter);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_ENVIRONMENT_ASYNC_WAITER_H_
