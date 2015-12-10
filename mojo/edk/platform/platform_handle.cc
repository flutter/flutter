// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/platform_handle.h"

#include <assert.h>
#include <errno.h>
#include <unistd.h>

#include "mojo/edk/platform/scoped_platform_handle.h"

namespace mojo {
namespace platform {

void PlatformHandle::CloseIfNecessary() {
  if (!is_valid())
    return;

  if (close(fd) != 0) {
    // The possible errors are EBADF (which is very bad -- it indicates a bug in
    // our code), EINTR, or EIO. On EINTR, don't retry |close()| (this is the
    // correct behavior on Linux, and the only safe thing to do on Mac: see,
    // e.g., http://crbug.com/269623). EIO is sad (it indicates potential data
    // loss), but again there's nothing more to do.
    assert(errno == EINTR || errno == EIO);
  }
  fd = -1;
}

ScopedPlatformHandle PlatformHandle::Duplicate() const {
  // This is slightly redundant, but it's good to be safe (and avoid the system
  // call and resulting EBADF).
  if (!is_valid())
    return ScopedPlatformHandle();
  // Note that |dup()| returns -1 on error (which is exactly the value we use
  // for invalid |PlatformHandle| FDs).
  return ScopedPlatformHandle(PlatformHandle(dup(fd)));
}

}  // namespace embedder
}  // namespace mojo
