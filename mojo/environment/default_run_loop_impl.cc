// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/environment/default_run_loop_impl.h"

#include "base/logging.h"
#include "base/message_loop/message_loop.h"

namespace mojo {
namespace internal {

void InstantiateDefaultRunLoopImpl() {
  CHECK(!base::MessageLoop::current());
  // Not leaked: accessible from |base::MessageLoop::current()|.
  base::MessageLoop* message_loop = new base::MessageLoop();
  CHECK_EQ(message_loop, base::MessageLoop::current());
}

void DestroyDefaultRunLoopImpl() {
  CHECK(base::MessageLoop::current());
  delete base::MessageLoop::current();
  CHECK(!base::MessageLoop::current());
}

}  // namespace internal
}  // namespace mojo
