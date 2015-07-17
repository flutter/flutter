// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MEMORY_SHARED_MEMORY_HANDLE_H_
#define BASE_MEMORY_SHARED_MEMORY_HANDLE_H_

#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#elif defined(OS_MACOSX) && !defined(OS_IOS)
#include <sys/types.h>
#include "base/base_export.h"
#include "base/file_descriptor_posix.h"
#include "base/macros.h"
#elif defined(OS_POSIX)
#include <sys/types.h>
#include "base/file_descriptor_posix.h"
#endif

namespace base {

class Pickle;

// SharedMemoryHandle is a platform specific type which represents
// the underlying OS handle to a shared memory segment.
#if defined(OS_WIN)
typedef HANDLE SharedMemoryHandle;
#elif defined(OS_POSIX) && !(defined(OS_MACOSX) && !defined(OS_IOS))
typedef FileDescriptor SharedMemoryHandle;
#else
class BASE_EXPORT SharedMemoryHandle {
 public:
  enum Type {
    // Indicates that the SharedMemoryHandle is backed by a POSIX fd.
    POSIX,
    // Indicates that the SharedMemoryHandle is backed by the Mach primitive
    // "memory object".
    MACH,
  };

  // The format that should be used to transmit |Type| over the wire.
  typedef int TypeWireFormat;

  // The default constructor returns an invalid SharedMemoryHandle.
  SharedMemoryHandle();

  // Constructs a SharedMemoryHandle backed by the components of a
  // FileDescriptor. The newly created instance has the same ownership semantics
  // as base::FileDescriptor. This typically means that the SharedMemoryHandle
  // takes ownership of the |fd| if |auto_close| is true. Unfortunately, it's
  // common for existing code to make shallow copies of SharedMemoryHandle, and
  // the one that is finally passed into a base::SharedMemory is the one that
  // "consumes" the fd.
  explicit SharedMemoryHandle(const base::FileDescriptor& file_descriptor);
  SharedMemoryHandle(int fd, bool auto_close);

  // Standard copy constructor. The new instance shares the underlying OS
  // primitives.
  SharedMemoryHandle(const SharedMemoryHandle& handle);

  // Standard assignment operator. The updated instance shares the underlying
  // OS primitives.
  SharedMemoryHandle& operator=(const SharedMemoryHandle& handle);

  // Duplicates the underlying OS resources.
  SharedMemoryHandle Duplicate() const;

  // Comparison operators.
  bool operator==(const SharedMemoryHandle& handle) const;
  bool operator!=(const SharedMemoryHandle& handle) const;

  // Returns the type.
  Type GetType() const;

  // Whether the underlying OS primitive is valid.
  bool IsValid() const;

  // Sets the POSIX fd backing the SharedMemoryHandle. Requires that the
  // SharedMemoryHandle be backed by a POSIX fd.
  void SetFileHandle(int fd, bool auto_close);

  // This method assumes that the SharedMemoryHandle is backed by a POSIX fd.
  // This is eventually no longer going to be true, so please avoid adding new
  // uses of this method.
  const FileDescriptor GetFileDescriptor() const;

 private:
  Type type_;
  FileDescriptor file_descriptor_;
};
#endif

}  // namespace base

#endif  // BASE_MEMORY_SHARED_MEMORY_HANDLE_H_
