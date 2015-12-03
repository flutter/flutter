// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/platform_handle.h"

#include <assert.h>
#include <errno.h>
#include <unistd.h>

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

}  // namespace embedder
}  // namespace mojo
