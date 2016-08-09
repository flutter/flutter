// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This header contains internal details for the *implementation* of the
// embedder API. It should not be included by any public header (nor by users of
// the embedder API).

#ifndef MOJO_EDK_EMBEDDER_EMBEDDER_INTERNAL_H_
#define MOJO_EDK_EMBEDDER_EMBEDDER_INTERNAL_H_

#include <stdint.h>

#include "mojo/edk/system/channel_id.h"

namespace base {
class TaskRunner;
}

namespace mojo {

namespace system {

class ChannelManager;
class Core;
class IPCSupport;

}  // namespace system

namespace embedder {

class PlatformSupport;
class ProcessDelegate;

// This is a type that's opaque to users of the embedder API (which only
// gives/takes |ChannelInfo*|s). We make it a struct to make it
// template-friendly.
struct ChannelInfo {
  explicit ChannelInfo(system::ChannelId channel_id = 0)
      : channel_id(channel_id) {}

  system::ChannelId channel_id;
};

namespace internal {

// Instance of |PlatformSupport| to use.
extern PlatformSupport* g_platform_support;

// Instance of |Core| used by the system functions (|Mojo...()|).
extern system::Core* g_core;

// Instance of |IPCSupport|, initialized by |InitIPCSupport()| and reset by
// |ShutdownIPCSupport()|. This is declared here so that
// |mojo::embedder::test::Shutdown()| can check that it's only called after
// |ShutdownIPCSupport()|.
extern system::IPCSupport* g_ipc_support;

}  // namespace internal

}  // namepace embedder

}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_EMBEDDER_INTERNAL_H_
