// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_PLATFORM_SHARED_BUFFER_H_
#define MOJO_EDK_PLATFORM_PLATFORM_SHARED_BUFFER_H_

#include <stddef.h>

#include <memory>

#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/util/ref_counted.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace platform {

class PlatformSharedBufferMapping;

// |PlatformSharedBuffer| is an interface for a thread-safe, ref-counted wrapper
// around OS-specific shared memory. It has the following features:
//   - A |PlatformSharedBuffer| simply represents a piece of shared memory that
//     *may* be mapped and *may* be shared to another process.
//   - A single |PlatformSharedBuffer| may be mapped multiple times. The
//     lifetime of the mapping (owned by |PlatformSharedBufferMapping|) is
//     separate from the lifetime of the |PlatformSharedBuffer|.
//   - Sizes/offsets (of the shared memory and mappings) are arbitrary, and not
//     restricted by page size. However, more memory may actually be mapped than
//     requested.
//
// It currently does NOT support the following:
//   - Sharing read-only. (This will probably eventually be supported.)
//
// TODO(vtl): Rectify this with |base::SharedMemory|.
class PlatformSharedBuffer
    : public util::RefCountedThreadSafe<PlatformSharedBuffer> {
 public:
  // Gets the size of shared buffer (in number of bytes).
  virtual size_t GetNumBytes() const = 0;

  // Maps (some) of the shared buffer into memory; [|offset|, |offset + length|]
  // must be contained in [0, |num_bytes|], and |length| must be at least 1.
  // Returns null on failure.
  virtual std::unique_ptr<PlatformSharedBufferMapping> Map(size_t offset,
                                                           size_t length) = 0;

  // Checks if |offset| and |length| are valid arguments.
  virtual bool IsValidMap(size_t offset, size_t length) = 0;

  // Like |Map()|, but doesn't check its arguments (which should have been
  // preflighted using |IsValidMap()|).
  virtual std::unique_ptr<PlatformSharedBufferMapping> MapNoCheck(
      size_t offset,
      size_t length) = 0;

  // Duplicates the underlying platform handle and passes it to the caller.
  // TODO(vtl): On POSIX, we'll need two FDs to support sharing read-only.
  virtual ScopedPlatformHandle DuplicatePlatformHandle() = 0;

  // Passes the underlying platform handle to the caller. This should only be
  // called if there's a unique reference to this object (owned by the caller).
  // After calling this, this object should no longer be used, but should only
  // be disposed of.
  virtual ScopedPlatformHandle PassPlatformHandle() = 0;

 protected:
  friend class util::RefCountedThreadSafe<PlatformSharedBuffer>;

  PlatformSharedBuffer() {}
  virtual ~PlatformSharedBuffer() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(PlatformSharedBuffer);
};

// An interface for a mapping of a |PlatformSharedBuffer| (compararable to a
// "file view" in Windows); see above. Created by (implementations of)
// |PlatformSharedBuffer::Map()|. Automatically unmaps memory on destruction.
//
// Mappings are NOT thread-safe.
//
// Note: This is an entirely separate class (instead of
// |PlatformSharedBuffer::Mapping|) so that it can be forward-declared.
class PlatformSharedBufferMapping {
 public:
  // IMPORTANT: Implementations must implement a destructor that unmaps memory.
  virtual ~PlatformSharedBufferMapping() {}

  virtual void* GetBase() const = 0;
  virtual size_t GetLength() const = 0;

 protected:
  PlatformSharedBufferMapping() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(PlatformSharedBufferMapping);
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_PLATFORM_SHARED_BUFFER_H_
