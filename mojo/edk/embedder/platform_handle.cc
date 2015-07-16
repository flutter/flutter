// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/platform_handle.h"

#include "build/build_config.h"
#if defined(OS_POSIX)
#include <unistd.h>
#elif defined(OS_WIN)
#include <windows.h>
#else
#error "Platform not yet supported."
#endif

#include "base/logging.h"

namespace mojo {
namespace embedder {

void PlatformHandle::CloseIfNecessary() {
  if (!is_valid())
    return;

#if defined(OS_POSIX)
  bool success = (close(fd) == 0);
  DPCHECK(success);
  fd = -1;
#elif defined(OS_WIN)
  bool success = !!CloseHandle(handle);
  DPCHECK(success);
  handle = INVALID_HANDLE_VALUE;
#else
#error "Platform not yet supported."
#endif
}

}  // namespace embedder
}  // namespace mojo
