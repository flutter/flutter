// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/shared_memory.h"

#include <sys/mman.h>

#include "base/logging.h"
#include "third_party/ashmem/ashmem.h"

namespace base {

// For Android, we use ashmem to implement SharedMemory. ashmem_create_region
// will automatically pin the region. We never explicitly call pin/unpin. When
// all the file descriptors from different processes associated with the region
// are closed, the memory buffer will go away.

bool SharedMemory::Create(const SharedMemoryCreateOptions& options) {
  DCHECK_EQ(-1, mapped_file_ );

  if (options.size > static_cast<size_t>(std::numeric_limits<int>::max()))
    return false;

  // "name" is just a label in ashmem. It is visible in /proc/pid/maps.
  mapped_file_ = ashmem_create_region(
      options.name_deprecated == NULL ? "" : options.name_deprecated->c_str(),
      options.size);
  if (-1 == mapped_file_) {
    DLOG(ERROR) << "Shared memory creation failed";
    return false;
  }

  int err = ashmem_set_prot_region(mapped_file_,
                                   PROT_READ | PROT_WRITE | PROT_EXEC);
  if (err < 0) {
    DLOG(ERROR) << "Error " << err << " when setting protection of ashmem";
    return false;
  }

  // Android doesn't appear to have a way to drop write access on an ashmem
  // segment for a single descriptor.  http://crbug.com/320865
  readonly_mapped_file_ = dup(mapped_file_);
  if (-1 == readonly_mapped_file_) {
    DPLOG(ERROR) << "dup() failed";
    return false;
  }

  requested_size_ = options.size;

  return true;
}

bool SharedMemory::Delete(const std::string& name) {
  // Like on Windows, this is intentionally returning true as ashmem will
  // automatically releases the resource when all FDs on it are closed.
  return true;
}

bool SharedMemory::Open(const std::string& name, bool read_only) {
  // ashmem doesn't support name mapping
  NOTIMPLEMENTED();
  return false;
}

}  // namespace base
