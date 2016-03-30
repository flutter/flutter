// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_MAPPED_SHARED_MEDIA_BUFFER_ALLOCATOR_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_MAPPED_SHARED_MEDIA_BUFFER_ALLOCATOR_H_

#include <memory>
#include <mutex>  // NOLINT(build/c++11)

#include "mojo/services/media/common/cpp/fifo_allocator.h"
#include "mojo/services/media/common/cpp/mapped_shared_buffer.h"

namespace mojo {
namespace media {

// SharedMediaBufferAllocator enhances MappedSharedBuffer by adding allocation
// semantics (allocate and release) using FifoAllocator. This is useful in media
// applications in which media buffers are typically allocated and released in
// a first-allocated, first-released manner. SharedMediaBufferAllocator is
// thread-safe.
class SharedMediaBufferAllocator : public MappedSharedBuffer {
 public:
  static const uint64_t kNullOffset = FifoAllocator::kNullOffset;

  SharedMediaBufferAllocator() : fifo_allocator_(0) {}

  ~SharedMediaBufferAllocator() override;

  // Allocates a region of the buffer returning an offset. If the requested
  // region could not be allocated, returns kNullOffset.
  uint64_t AllocateRegionByOffset(uint64_t size) {
    std::lock_guard<std::mutex> lock(lock_);
    return fifo_allocator_.AllocateRegion(size);
  }

  // Releases a region of the buffer previously allocated by calling
  // AllocateRegionByOffset.
  void ReleaseRegionByOffset(uint64_t size, uint64_t offset) {
    std::lock_guard<std::mutex> lock(lock_);
    fifo_allocator_.ReleaseRegion(size, offset);
  }

  // Allocates a region of the buffer returning a pointer. If the requested
  // region could not be allocated, returns nullptr.
  void* AllocateRegion(uint64_t size) {
    return PtrFromOffset(AllocateRegionByOffset(size));
  }

  // Releases a region of the buffer previously allocated by calling
  // AllocateRegion.
  void ReleaseRegion(uint64_t size, void* ptr) {
    ReleaseRegionByOffset(size, OffsetFromPtr(ptr));
  }

 protected:
  void OnInit() override;

 private:
  mutable std::mutex lock_;
  FifoAllocator fifo_allocator_;
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_MAPPED_SHARED_MEDIA_BUFFER_ALLOCATOR_H_
