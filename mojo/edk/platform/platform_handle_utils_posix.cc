// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/platform_handle_utils_posix.h"

#include <assert.h>
#include <stdio.h>
#include <unistd.h>

#include "mojo/edk/platform/platform_handle.h"

namespace mojo {
namespace platform {

ScopedPlatformHandle PlatformHandleFromFILE(util::ScopedFILE fp) {
  assert(fp);
  int rv = dup(fileno(fp.get()));
  assert(rv != -1);
  return ScopedPlatformHandle(PlatformHandle(rv));
}

util::ScopedFILE FILEFromPlatformHandle(ScopedPlatformHandle h,
                                        const char* mode) {
  assert(h.is_valid());
  util::ScopedFILE rv(fdopen(h.release().fd, mode));
  assert(rv);
  return rv;
}

}  // namespace platform
}  // namespace mojo
