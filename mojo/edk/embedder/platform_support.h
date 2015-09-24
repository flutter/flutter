// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_SUPPORT_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_SUPPORT_H_

#include <stddef.h>

#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace embedder {

class PlatformSharedBuffer;

// This class is provided by the embedder to implement (typically
// platform-dependent) things needed by the Mojo system implementation.
// Implementations must be thread-safe.
class PlatformSupport {
 public:
  virtual ~PlatformSupport() {}

  // Gets a "time-ticks" value:
  //   - The value should be nondecreasing with respect to time/causality.
  //   - The value should be in microseconds (i.e., if a caller runs
  //     continuously, getting the value twice, their difference should be
  //     approximately the real time elapsed between the samples, in
  //     microseconds).
  //   - The value should be nonnegative.
  //   - The behaviour of the value if execution is suspended (i.e., the
  //     computer "sleeps") is undefined (i.e., this is not a real-time clock),
  //     except that it must remain monotonic.
  //   - As observable, monotonicity should hold across threads.
  // If multiple |PlatformSupport| implementations/instances are used in a
  // single system, all implementations must agree (i.e., respect the above as
  // if there were only a single |PlatformSupport|).
  virtual MojoTimeTicks GetTimeTicksNow() = 0;

  // Gets cryptographically-secure (pseudo)random bytes.
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
