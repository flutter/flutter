// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "runtime/dart/utils/vmo.h"

#include <fcntl.h>
#include <sys/stat.h>

#include <fuchsia/mem/cpp/fidl.h>
#include <lib/fdio/io.h>
#include <lib/syslog/global.h>

#include "runtime/dart/utils/logging.h"

namespace {

bool VmoFromFd(int fd, fuchsia::mem::Buffer* buffer) {
  if (!buffer) {
    FX_LOG(FATAL, LOG_TAG, "Invalid buffer pointer");
  }

  struct stat stat_struct;
  if (fstat(fd, &stat_struct) == -1) {
    FX_LOGF(ERROR, LOG_TAG, "fstat failed: %s", strerror(errno));
    return false;
  }

  zx_handle_t result = ZX_HANDLE_INVALID;
  if (fdio_get_vmo_copy(fd, &result) != ZX_OK) {
    return false;
  }

  buffer->vmo = zx::vmo(result);
  buffer->size = stat_struct.st_size;

  return true;
}

}  // namespace

namespace dart_utils {

bool VmoFromFilename(const std::string& filename,
                     fuchsia::mem::Buffer* buffer) {
  return VmoFromFilenameAt(AT_FDCWD, filename, buffer);
}

bool VmoFromFilenameAt(int dirfd,
                       const std::string& filename,
                       fuchsia::mem::Buffer* buffer) {
  int fd = openat(dirfd, filename.c_str(), O_RDONLY);
  if (fd == -1) {
    FX_LOGF(ERROR, LOG_TAG, "openat(\"%s\") failed: %s", filename.c_str(),
            strerror(errno));
    return false;
  }
  bool result = VmoFromFd(fd, buffer);
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
