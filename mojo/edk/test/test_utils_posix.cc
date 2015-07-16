// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/test/test_utils.h"

#include <fcntl.h>
#include <unistd.h>

#include "base/posix/eintr_wrapper.h"

namespace mojo {
namespace test {

bool BlockingWrite(const embedder::PlatformHandle& handle,
                   const void* buffer,
                   size_t bytes_to_write,
                   size_t* bytes_written) {
  int original_flags = fcntl(handle.fd, F_GETFL);
  if (original_flags == -1 ||
      fcntl(handle.fd, F_SETFL, original_flags & (~O_NONBLOCK)) != 0) {
    return false;
  }

  ssize_t result = HANDLE_EINTR(write(handle.fd, buffer, bytes_to_write));

  fcntl(handle.fd, F_SETFL, original_flags);

  if (result < 0)
    return false;

  *bytes_written = result;
  return true;
}

bool BlockingRead(const embedder::PlatformHandle& handle,
                  void* buffer,
                  size_t buffer_size,
                  size_t* bytes_read) {
  int original_flags = fcntl(handle.fd, F_GETFL);
  if (original_flags == -1 ||
      fcntl(handle.fd, F_SETFL, original_flags & (~O_NONBLOCK)) != 0) {
    return false;
  }

  ssize_t result = HANDLE_EINTR(read(handle.fd, buffer, buffer_size));

  fcntl(handle.fd, F_SETFL, original_flags);

  if (result < 0)
    return false;

  *bytes_read = result;
  return true;
}

bool NonBlockingRead(const embedder::PlatformHandle& handle,
                     void* buffer,
                     size_t buffer_size,
                     size_t* bytes_read) {
  ssize_t result = HANDLE_EINTR(read(handle.fd, buffer, buffer_size));

  if (result < 0) {
    if (errno != EAGAIN && errno != EWOULDBLOCK)
      return false;

    *bytes_read = 0;
  } else {
    *bytes_read = result;
  }

  return true;
}

embedder::ScopedPlatformHandle PlatformHandleFromFILE(base::ScopedFILE fp) {
  CHECK(fp);
  int rv = dup(fileno(fp.get()));
  PCHECK(rv != -1) << "dup";
  return embedder::ScopedPlatformHandle(embedder::PlatformHandle(rv));
}

base::ScopedFILE FILEFromPlatformHandle(embedder::ScopedPlatformHandle h,
                                        const char* mode) {
  CHECK(h.is_valid());
  base::ScopedFILE rv(fdopen(h.release().fd, mode));
  PCHECK(rv) << "fdopen";
  return rv.Pass();
}

}  // namespace test
}  // namespace mojo
