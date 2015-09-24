// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/platform_handle.h"

#include <unistd.h>

#include "base/logging.h"

namespace mojo {
namespace embedder {

void PlatformHandle::CloseIfNecessary() {
  if (!is_valid())
    return;

  bool success = (close(fd) == 0);
  DPCHECK(success);
  fd = -1;
}

}  // namespace embedder
}  // namespace mojo
