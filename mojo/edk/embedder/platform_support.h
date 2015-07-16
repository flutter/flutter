// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_SUPPORT_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_SUPPORT_H_

#include <stddef.h>

#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace embedder {

class PlatformSharedBuffer;

// This class is provided by the embedder to implement (typically
// platform-dependent) things needed by the Mojo system implementation.
// Implementations must be thread-safe.
class MOJO_SYSTEM_IMPL_EXPORT PlatformSupport {
 public:
  virtual ~PlatformSupport() {}

  virtual void GetCryptoRandomBytes(void* bytes, size_t num_bytes) = 0;

  virtual PlatformSharedBuffer* CreateSharedBuffer(size_t num_bytes) = 0;
  virtual PlatformSharedBuffer* CreateSharedBufferFromHandle(
      size_t num_bytes,
      ScopedPlatformHandle platform_handle) = 0;

 protected:
  PlatformSupport() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(PlatformSupport);
};

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_PLATFORM_SUPPORT_H_
