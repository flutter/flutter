// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/handle_transport.h"

#include "base/logging.h"

namespace mojo {
namespace system {

void HandleTransport::End() {
  DCHECK(dispatcher_);
  dispatcher_->mutex_.Unlock();
  dispatcher_ = nullptr;
}

}  // namespace system
}  // namespace mojo
