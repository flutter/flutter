// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Factory functions for creating "simple" |PlatformSharedBuffer|s. These are
// implemented in a simple/obvious way, and may not work in a sandbox.

#ifndef MOJO_EDK_PLATFORM_SIMPLE_PLATFORM_SHARED_BUFFER_H_
#define MOJO_EDK_PLATFORM_SIMPLE_PLATFORM_SHARED_BUFFER_H_

#include <stddef.h>

#include "mojo/edk/platform/platform_shared_buffer.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/util/ref_ptr.h"

namespace mojo {
namespace platform {

// Creates a shared buffer of size |num_bytes| bytes (initially zero-filled).
// |num_bytes| must be nonzero. Returns null on failure.
util::RefPtr<PlatformSharedBuffer> CreateSimplePlatformSharedBuffer(
    size_t num_bytes);

// Creates a shared buffer of size |num_bytes| bytes, "backed" by the given
// |PlatformHandle|. This should be used only with |platform_handle|s obtained
// (via |PassPlatformHandle()|) from |PlatformSharedBuffer|s created using
// |CreateSimplePlatformSharedBuffer()| (above); |num_bytes| must be the same as
// passed to |CreateSimplePlatformSharedBuffer()|.
util::RefPtr<PlatformSharedBuffer>
CreateSimplePlatformSharedBufferFromPlatformHandle(
    size_t num_bytes,
    ScopedPlatformHandle platform_handle);

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_SIMPLE_PLATFORM_SHARED_BUFFER_H_
