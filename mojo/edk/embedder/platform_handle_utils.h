// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_HANDLE_UTILS_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_HANDLE_UTILS_H_

#include "mojo/edk/embedder/platform_handle.h"
#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/system/system_impl_export.h"

namespace mojo {
namespace embedder {

// Closes all the |PlatformHandle|s in the given container.
template <typename PlatformHandleContainer>
MOJO_SYSTEM_IMPL_EXPORT inline void CloseAllPlatformHandles(
    PlatformHandleContainer* platform_handles) {
  for (typename PlatformHandleContainer::iterator it =
           platform_handles->begin();
       it != platform_handles->end(); ++it)
    it->CloseIfNecessary();
}

// Duplicates the given |PlatformHandle| (which must be valid). (Returns an
// invalid |ScopedPlatformHandle| on failure.)
MOJO_SYSTEM_IMPL_EXPORT ScopedPlatformHandle
DuplicatePlatformHandle(PlatformHandle platform_handle);

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_PLATFORM_HANDLE_UTILS_H_
