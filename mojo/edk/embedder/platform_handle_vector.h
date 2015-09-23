// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_HANDLE_VECTOR_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_HANDLE_VECTOR_H_

#include <memory>
#include <vector>

#include "mojo/edk/embedder/platform_handle.h"
#include "mojo/edk/embedder/platform_handle_utils.h"

namespace mojo {
namespace embedder {

// TODO(vtl): Can we switch to using std::vector<ScopedPlatformHandle> instead?
using PlatformHandleVector = std::vector<PlatformHandle>;

// A deleter (for use with |std::unique_ptr|) that closes all handles and then
// |delete|s the |PlatformHandleVector|.
struct PlatformHandleVectorDeleter {
  void operator()(PlatformHandleVector* platform_handles) const {
    CloseAllPlatformHandles(platform_handles);
    delete platform_handles;
  }
};

using ScopedPlatformHandleVectorPtr =
    std::unique_ptr<PlatformHandleVector, PlatformHandleVectorDeleter>;

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_PLATFORM_HANDLE_VECTOR_H_
