// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/platform_handle_utils.h"

#include <unistd.h>

#include "base/logging.h"

namespace mojo {
namespace embedder {

ScopedPlatformHandle DuplicatePlatformHandle(PlatformHandle platform_handle) {
  DCHECK(platform_handle.is_valid());
  // Note that |dup()| returns -1 on error (which is exactly the value we use
  // for invalid |PlatformHandle| FDs).
  return ScopedPlatformHandle(PlatformHandle(dup(platform_handle.fd)));
}

}  // namespace embedder
}  // namespace mojo
