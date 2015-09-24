// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/simple_platform_shared_buffer.h"

#include <stdint.h>
#include <sys/mman.h>   // For |PROT_...|.
#include <sys/types.h>  // For |off_t|.

#include <limits>

#include "base/logging.h"
#include "third_party/ashmem/ashmem.h"

namespace mojo {
namespace embedder {

// SimplePlatformSharedBuffer --------------------------------------------------

bool SimplePlatformSharedBuffer::Init() {
  DCHECK(!handle_.is_valid());

  if (static_cast<uint64_t>(num_bytes_) >
      static_cast<uint64_t>(std::numeric_limits<off_t>::max())) {
    return false;
  }

  ScopedPlatformHandle handle(
      PlatformHandle(ashmem_create_region(nullptr, num_bytes_)));
  if (!handle.is_valid()) {
    DPLOG(ERROR) << "ashmem_create_region()";
    return false;
  }

  if (ashmem_set_prot_region(handle.get().fd, PROT_READ | PROT_WRITE) < 0) {
    DPLOG(ERROR) << "ashmem_set_prot_region()";
    return false;
  }

  handle_ = handle.Pass();
  return true;
}

bool SimplePlatformSharedBuffer::InitFromPlatformHandle(
    ScopedPlatformHandle platform_handle) {
  DCHECK(!handle_.is_valid());

  if (static_cast<uint64_t>(num_bytes_) >
      static_cast<uint64_t>(std::numeric_limits<off_t>::max())) {
    return false;
  }

  int size = ashmem_get_size_region(platform_handle.get().fd);

  if (size < 0) {
    DPLOG(ERROR) << "ashmem_get_size_region()";
    return false;
  }

  if (static_cast<size_t>(size) != num_bytes_) {
    LOG(ERROR) << "Shared memory region has the wrong size";
    return false;
  }

  handle_ = platform_handle.Pass();
  return true;
}

}  // namespace embedder
}  // namespace mojo
