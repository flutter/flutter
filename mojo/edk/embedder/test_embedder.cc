// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/test_embedder.h"

#include "base/logging.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/embedder_internal.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/system/channel_manager.h"
#include "mojo/edk/system/core.h"
#include "mojo/edk/system/handle_table.h"

namespace mojo {

namespace system {
namespace internal {

bool ShutdownCheckNoLeaks(Core* core) {
  // No point in taking the lock.
  const HandleTable::HandleToEntryMap& handle_to_entry_map =
      core->handle_table_.handle_to_entry_map_;

  if (handle_to_entry_map.empty())
    return true;

  for (HandleTable::HandleToEntryMap::const_iterator it =
           handle_to_entry_map.begin();
       it != handle_to_entry_map.end(); ++it) {
    LOG(ERROR) << "Mojo embedder shutdown: Leaking handle " << (*it).first;
  }
  return false;
}

}  // namespace internal
}  // namespace system

namespace embedder {
namespace test {

void InitWithSimplePlatformSupport() {
  Init(CreateSimplePlatformSupport());
}

bool Shutdown() {
  // If |InitIPCSupport()| was called, then |ShutdownIPCSupport()| must have
  // been called first.
  CHECK(!internal::g_ipc_support);

  CHECK(internal::g_core);
  bool rv = system::internal::ShutdownCheckNoLeaks(internal::g_core);
  delete internal::g_core;
  internal::g_core = nullptr;

  CHECK(internal::g_platform_support);
  delete internal::g_platform_support;
  internal::g_platform_support = nullptr;

  return rv;
}

}  // namespace test
}  // namespace embedder

}  // namespace mojo
