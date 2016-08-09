// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_MAPPED_SHARED_BUFFER_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_MAPPED_SHARED_BUFFER_H_

#include <memory>

#include "mojo/public/cpp/system/buffer.h"

namespace mojo {
namespace media {

// MappedSharedBuffer simplifies the use of shared buffers by taking care of
// mapping/unmapping and by providing offset/pointer translation. It can be
// used when the caller wants to allocate its own buffer (InitNew) and when
// the caller needs to use a buffer supplied by another party (InitFromHandle).
// It can be used by itself when regions of the buffer are allocated by another
// party. If the caller needs to allocate regions, SharedMediaBufferAllocator,
// which is derived from MappedSharedBuffer, provides allocation semantics
// using FifoAllocator.
class MappedSharedBuffer {
 public:
  MappedSharedBuffer();

  virtual ~MappedSharedBuffer();

  // Initializes by creating a new shared buffer of the indicated size.
  MojoResult InitNew(uint64_t size);

  // Initializes from a handle to an existing shared buffer.
  MojoResult InitFromHandle(ScopedSharedBufferHandle handle);

  // Indicates whether the buffer is initialized.
  bool initialized() const;

  // Shuts down the buffer.
  void Reset();

  // Gets the size of the buffer.
  uint64_t size() const;

  // Gets a duplicate handle for the shared buffer.
  ScopedSharedBufferHandle GetDuplicateHandle() const;

  // Validates an offset and size.
  bool Validate(uint64_t offset, uint64_t size);

  // Translates an offset into a pointer.
  void* PtrFromOffset(uint64_t offset) const;

  // Translates a pointer into an offset.
  uint64_t OffsetFromPtr(void* payload_ptr) const;

 protected:
  MojoResult InitInternal(const ScopedSharedBufferHandle& handle);

  // Does nothing. Called when initialization is complete. Subclasses may
  // override.
  virtual void OnInit();

 private:
  struct MappedBufferDeleter {
    inline void operator()(uint8_t* ptr) const { UnmapBuffer(ptr); }
  };

  // Size of the shared buffer.
  uint64_t size_;

  // Shared buffer when initialized with InitNew.
  std::unique_ptr<SharedBuffer> buffer_;

  // Handle to shared buffer when initialized with InitFromHandle.
  ScopedSharedBufferHandle handle_;

  // Pointer to the mapped buffer.
  std::unique_ptr<uint8_t, MappedBufferDeleter> buffer_ptr_;
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_MAPPED_SHARED_BUFFER_H_
