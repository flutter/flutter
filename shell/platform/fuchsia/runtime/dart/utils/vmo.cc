// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vmo.h"

#include <fcntl.h>
#include <sys/stat.h>

#include <fuchsia/io/cpp/fidl.h>
#include <fuchsia/mem/cpp/fidl.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/io.h>
#include <lib/syslog/global.h>
#include <zircon/status.h>

#include "logging.h"

namespace {

bool VmoFromFd(int fd, bool executable, fuchsia::mem::Buffer* buffer) {
  if (!buffer) {
    FX_LOG(FATAL, LOG_TAG, "Invalid buffer pointer");
  }

  struct stat stat_struct;
  if (fstat(fd, &stat_struct) == -1) {
    FX_LOGF(ERROR, LOG_TAG, "fstat failed: %s", strerror(errno));
    return false;
  }

  zx_handle_t result = ZX_HANDLE_INVALID;
  zx_status_t status;
  if (executable) {
    status = fdio_get_vmo_exec(fd, &result);
  } else {
    status = fdio_get_vmo_copy(fd, &result);
  }

  if (status != ZX_OK) {
    return false;
  }

  buffer->vmo = zx::vmo(result);
  buffer->size = stat_struct.st_size;

  return true;
}

}  // namespace

namespace dart_utils {

bool VmoFromFilename(const std::string& filename,
                     bool executable,
                     fuchsia::mem::Buffer* buffer) {
  // Note: the implementation here cannot be shared with VmoFromFilenameAt
  // because fdio_open_fd_at does not aim to provide POSIX compatibility, and
  // thus does not handle AT_FDCWD as dirfd.
  uint32_t flags = fuchsia::io::OPEN_RIGHT_READABLE |
                   (executable ? fuchsia::io::OPEN_RIGHT_EXECUTABLE : 0);
  zx_status_t status;
  int fd;

  status = fdio_open_fd(filename.c_str(), flags, &fd);
  if (status != ZX_OK) {
    FX_LOGF(ERROR, LOG_TAG, "fdio_open_fd(\"%s\", %08x) failed: %s",
            filename.c_str(), flags, zx_status_get_string(status));
    return false;
  }
  bool result = VmoFromFd(fd, executable, buffer);
  close(fd);
  return result;
}

bool VmoFromFilenameAt(int dirfd,
                       const std::string& filename,
                       bool executable,
                       fuchsia::mem::Buffer* buffer) {
  uint32_t flags = fuchsia::io::OPEN_RIGHT_READABLE |
                   (executable ? fuchsia::io::OPEN_RIGHT_EXECUTABLE : 0);
  zx_status_t status;
  int fd;
  status = fdio_open_fd_at(dirfd, filename.c_str(), flags, &fd);
  if (status != ZX_OK) {
    FX_LOGF(ERROR, LOG_TAG, "fdio_open_fd_at(%d, \"%s\", %08x) failed: %s",
            dirfd, filename.c_str(), flags, zx_status_get_string(status));
    return false;
  }
  bool result = VmoFromFd(fd, executable, buffer);
  close(fd);
  return result;
}

zx_status_t IsSizeValid(const fuchsia::mem::Buffer& buffer, bool* is_valid) {
  size_t vmo_size;
  zx_status_t status = buffer.vmo.get_size(&vmo_size);
  if (status == ZX_OK) {
    *is_valid = vmo_size >= buffer.size;
  } else {
    *is_valid = false;
  }
  return status;
}

}  // namespace dart_utils
