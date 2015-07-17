// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/shared_memory_handle.h"

#include <unistd.h>

#include "base/posix/eintr_wrapper.h"

#if defined(OS_MACOSX) && !defined(OS_IOS)
namespace base {

static_assert(sizeof(SharedMemoryHandle::Type) <=
                  sizeof(SharedMemoryHandle::TypeWireFormat),
              "Size of enum SharedMemoryHandle::Type exceeds size of type "
              "transmitted over wire.");

SharedMemoryHandle::SharedMemoryHandle() : type_(POSIX), file_descriptor_() {
}

SharedMemoryHandle::SharedMemoryHandle(
    const base::FileDescriptor& file_descriptor)
    : type_(POSIX), file_descriptor_(file_descriptor) {
}

SharedMemoryHandle::SharedMemoryHandle(int fd, bool auto_close)
    : type_(POSIX), file_descriptor_(fd, auto_close) {
}

SharedMemoryHandle::SharedMemoryHandle(const SharedMemoryHandle& handle)
    : type_(handle.type_), file_descriptor_(handle.file_descriptor_) {
}

SharedMemoryHandle& SharedMemoryHandle::operator=(
    const SharedMemoryHandle& handle) {
  if (this == &handle)
    return *this;

  type_ = handle.type_;
  file_descriptor_ = handle.file_descriptor_;
  return *this;
}

bool SharedMemoryHandle::operator==(const SharedMemoryHandle& handle) const {
  // Invalid handles are always equal, even if they have different types.
  if (!IsValid() && !handle.IsValid())
    return true;

  return type_ == handle.type_ && file_descriptor_ == handle.file_descriptor_;
}

bool SharedMemoryHandle::operator!=(const SharedMemoryHandle& handle) const {
  return !(*this == handle);
}

SharedMemoryHandle::Type SharedMemoryHandle::GetType() const {
  return type_;
}

bool SharedMemoryHandle::IsValid() const {
  switch (type_) {
    case POSIX:
      return file_descriptor_.fd >= 0;
    case MACH:
      return false;
  }
}

void SharedMemoryHandle::SetFileHandle(int fd, bool auto_close) {
  DCHECK_EQ(type_, POSIX);
  file_descriptor_.fd = fd;
  file_descriptor_.auto_close = auto_close;
}

const FileDescriptor SharedMemoryHandle::GetFileDescriptor() const {
  DCHECK_EQ(type_, POSIX);
  return file_descriptor_;
}

SharedMemoryHandle SharedMemoryHandle::Duplicate() const {
  DCHECK_EQ(type_, POSIX);
  int duped_handle = HANDLE_EINTR(dup(file_descriptor_.fd));
  if (duped_handle < 0)
    return SharedMemoryHandle();
  return SharedMemoryHandle(duped_handle, true);
}

}  // namespace base
#endif  // defined(OS_MACOSX) && !defined(OS_IOS)
