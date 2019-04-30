// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/file_descriptor.h>

#include <lib/zx/handle.h>
#include <lib/fdio/fd.h>
#include <zircon/processargs.h>

namespace sys {

fuchsia::sys::FileDescriptorPtr CloneFileDescriptor(int fd) {
  zx::handle handle;
  zx_status_t status = fdio_fd_clone(fd, handle.reset_and_get_address());
  if (status != ZX_OK)
    return nullptr;
  fuchsia::sys::FileDescriptorPtr result = fuchsia::sys::FileDescriptor::New();
  result->type0 = PA_HND(PA_FD, fd);
  result->handle0 = std::move(handle);
  return result;
}

}  // namespace sys
