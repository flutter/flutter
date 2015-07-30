// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/environment.h"

#include "base/message_loop/message_loop.h"
#include "mojo/environment/default_async_waiter.h"
#include "mojo/environment/default_logger.h"
#include "mojo/environment/default_task_tracker.h"

namespace mojo {

// These methods are intentionally not implemented so that there is a link
// error if someone uses them in a Chromium-environment.
#if 0
Environment::Environment() {
}

Environment::Environment(const MojoAsyncWaiter* default_async_waiter,
                         const MojoLogger* default_logger) {
}

Environment::~Environment() {
}
#endif

// static
const MojoAsyncWaiter* Environment::GetDefaultAsyncWaiter() {
  return &internal::kDefaultAsyncWaiter;
}

// static
const MojoLogger* Environment::GetDefaultLogger() {
  return &internal::kDefaultLogger;
}

// static
const TaskTracker* Environment::GetDefaultTaskTracker() {
  return &internal::kDefaultTaskTracker;
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
