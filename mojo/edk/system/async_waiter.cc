// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/async_waiter.h"

namespace mojo {
namespace system {

AsyncWaiter::AsyncWaiter(const AwakeCallback& callback) : callback_(callback) {}

AsyncWaiter::~AsyncWaiter() {}

void AsyncWaiter::Awake(uint64_t /*context*/,
                        AwakeReason reason,
                        const HandleSignalsState& /*signals_state*/) {
  callback_(MojoResultForAwakeReason(reason));
  delete this;
}

}  // namespace system
}  // namespace mojo
