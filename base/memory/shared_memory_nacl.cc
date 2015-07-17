// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/shared_memory.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <limits>

#include "base/logging.h"

namespace base {

SharedMemory::SharedMemory()
    : mapped_file_(-1),
      mapped_size_(0),
      memory_(NULL),
      read_only_(false),
      requested_size_(0) {
}

SharedMemory::SharedMemory(const SharedMemoryHandle& handle, bool read_only)
    : mapped_file_(handle.fd),
      mapped_size_(0),
      memory_(NULL),
      read_only_(read_only),
      requested_size_(0) {
}

SharedMemory::SharedMemory(const SharedMemoryHandle& handle,
                           bool read_only,
                           ProcessHandle process)
    : mapped_file_(handle.fd),
      mapped_size_(0),
      memory_(NULL),
      read_only_(read_only),
      requested_size_(0) {
  NOTREACHED();
}

SharedMemory::~SharedMemory() {
  Unmap();
  Close();
}

// static
bool SharedMemory::IsHandleValid(const SharedMemoryHandle& handle) {
  return handle.fd >= 0;
}

// static
SharedMemoryHandle SharedMemory::NULLHandle() {
  return SharedMemoryHandle();
}

// static
void SharedMemory::CloseHandle(const SharedMemoryHandle& handle) {
  DCHECK_GE(handle.fd, 0);
  if (close(handle.fd) < 0)
    DPLOG(ERROR) << "close";
}

// static
SharedMemoryHandle SharedMemory::DuplicateHandle(
    const SharedMemoryHandle& handle) {
  int duped_handle = HANDLE_EINTR(dup(handle.fd));
  if (duped_handle < 0)
    return base::SharedMemory::NULLHandle();
  return base::FileDescriptor(duped_handle, true);
}

bool SharedMemory::CreateAndMapAnonymous(size_t size) {
  // Untrusted code can't create descriptors or handles.
  return false;
}

bool SharedMemory::Create(const SharedMemoryCreateOptions& options) {
  // Untrusted code can't create descriptors or handles.
  return false;
}

bool SharedMemory::Delete(const std::string& name) {
  return false;
}

bool SharedMemory::Open(const std::string& name, bool read_only) {
  return false;
}

bool SharedMemory::MapAt(off_t offset, size_t bytes) {
  if (mapped_file_ == -1)
    return false;

  if (bytes > static_cast<size_t>(std::numeric_limits<int>::max()))
    return false;

  if (memory_)
    return false;

  memory_ = mmap(NULL, bytes, PROT_READ | (read_only_ ? 0 : PROT_WRITE),
                 MAP_SHARED, mapped_file_, offset);

  bool mmap_succeeded = memory_ != MAP_FAILED && memory_ != NULL;
  if (mmap_succeeded) {
    mapped_size_ = bytes;
    DCHECK_EQ(0U, reinterpret_cast<uintptr_t>(memory_) &
        (SharedMemory::MAP_MINIMUM_ALIGNMENT - 1));
  } else {
    memory_ = NULL;
  }

  return mmap_succeeded;
}

bool SharedMemory::Unmap() {
  if (memory_ == NULL)
    return false;

  if (munmap(memory_, mapped_size_) < 0)
    DPLOG(ERROR) << "munmap";
  memory_ = NULL;
  mapped_size_ = 0;
  return true;
}

SharedMemoryHandle SharedMemory::handle() const {
  return FileDescriptor(mapped_file_, false);
}

void SharedMemory::Close() {
  if (mapped_file_ > 0) {
    if (close(mapped_file_) < 0)
      DPLOG(ERROR) << "close";
    mapped_file_ = -1;
  }
}

bool SharedMemory::ShareToProcessCommon(ProcessHandle process,
                                        SharedMemoryHandle *new_handle,
                                        bool close_self,
                                        ShareMode share_mode) {
  if (share_mode == SHARE_READONLY) {
    // Untrusted code can't create descriptors or handles, which is needed to
    // drop permissions.
    return false;
  }
  const int new_fd = dup(mapped_file_);
  if (new_fd < 0) {
    DPLOG(ERROR) << "dup() failed.";
    return false;
  }

  new_handle->fd = new_fd;
  new_handle->auto_close = true;

  if (close_self) {
    Unmap();
    Close();
  }
  return true;
}

}  // namespace base
