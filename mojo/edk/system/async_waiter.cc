// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/async_waiter.h"

namespace mojo {
namespace system {

AsyncWaiter::AsyncWaiter(const AwakeCallback& callback) : callback_(callback) {
}

AsyncWaiter::~AsyncWaiter() {
}

bool AsyncWaiter::Awake(MojoResult result, uintptr_t context) {
  callback_.Run(result);
  delete this;
  return false;
}

}  // namespace system
}  // namespace mojo
