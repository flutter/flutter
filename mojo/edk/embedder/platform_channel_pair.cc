// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/platform_channel_pair.h"

#include "base/logging.h"

namespace mojo {
namespace embedder {

const char PlatformChannelPair::kMojoPlatformChannelHandleSwitch[] =
    "mojo-platform-channel-handle";

PlatformChannelPair::~PlatformChannelPair() {
}

ScopedPlatformHandle PlatformChannelPair::PassServerHandle() {
  return server_handle_.Pass();
}

ScopedPlatformHandle PlatformChannelPair::PassClientHandle() {
  return client_handle_.Pass();
}

void PlatformChannelPair::ChildProcessLaunched() {
  DCHECK(client_handle_.is_valid());
  client_handle_.reset();
}

}  // namespace embedder
}  // namespace mojo
