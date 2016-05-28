// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/environment.h"

#include "base/message_loop/message_loop.h"
#include "mojo/environment/default_async_waiter.h"
#include "mojo/environment/default_logger.h"

namespace mojo {

// TODO(vtl): Probably we should share the following async waiter and logger
// code with the "standalone" implementation. (The only difference is what the
// |internal::kDefault...| are.)

const MojoAsyncWaiter* g_default_async_waiter = &internal::kDefaultAsyncWaiter;
const MojoLogger* g_default_logger = &internal::kDefaultLogger;

// static
const MojoAsyncWaiter* Environment::GetDefaultAsyncWaiter() {
  return g_default_async_waiter;
}

// static
void Environment::SetDefaultAsyncWaiter(const MojoAsyncWaiter* async_waiter) {
  g_default_async_waiter =
      async_waiter ? async_waiter : &internal::kDefaultAsyncWaiter;
}

// static
const MojoLogger* Environment::GetDefaultLogger() {
  return g_default_logger;
}

// static
void Environment::SetDefaultLogger(const MojoLogger* logger) {
  g_default_logger = logger ? logger : &internal::kDefaultLogger;
}

// static
void Environment::InstantiateDefaultRunLoop() {
  CHECK(!base::MessageLoop::current());
  // Not leaked: accessible from |base::MessageLoop::current()|.
  base::MessageLoop* message_loop = new base::MessageLoop();
  CHECK_EQ(message_loop, base::MessageLoop::current());
}

// static
void Environment::DestroyDefaultRunLoop() {
  CHECK(base::MessageLoop::current());
  delete base::MessageLoop::current();
  CHECK(!base::MessageLoop::current());
}

}  // namespace mojo
