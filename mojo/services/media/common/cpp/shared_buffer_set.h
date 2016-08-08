// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_SHARED_BUFFER_SET_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_SHARED_BUFFER_SET_H_

#include <limits>
#include <map>
#include <memory>
#include <vector>

#include "mojo/public/cpp/system/buffer.h"
#include "mojo/services/media/common/cpp/mapped_shared_buffer.h"

namespace mojo {
namespace media {

// SharedBufferSet simplifies the use of multiple shared buffers by taking care
// of mapping/unmapping and by providing offset/pointer translation. It can be
// used directly when the caller needs to use shared buffers supplied by another
// party. Its subclass SharedBufferSetAllocator can be used by callers that want
// to allocate from a set of shared buffers.
//
// MediaPacketConsumer implementations such as MediaPacketConsumerBase and its
// subclasses should used SharedBufferSet, while producer implementation such
// as MediaPacketProducerBase should use SharedBufferSetAllocator.
class SharedBufferSet {
 public:
  // References an allocation by buffer id and offset into the buffer.
  class Locator {
   public:
    static Locator Null() { return Locator(); }

    Locator() : buffer_id_(0), offset_(kNullOffset) {}

    Locator(uint32_t buffer_id, uint64_t offset)
        : buffer_id_(buffer_id), offset_(offset) {}

    uint32_t buffer_id() const { return buffer_id_; }
    uint64_t offset() const { return offset_; }

    bool is_null() const { return offset_ == kNullOffset; }

    explicit operator bool() const { return !is_null(); }

    bool operator==(const Locator& other) const {
      return buffer_id_ == other.buffer_id() && offset_ == other.offset();
    }

   private:
    static const uint64_t kNullOffset = std::numeric_limits<uint64_t>::max();

    uint32_t buffer_id_;
    uint64_t offset_;
  };

  SharedBufferSet();

  virtual ~SharedBufferSet();

  // Adds the indicated buffer.
  MojoResult AddBuffer(uint32_t buffer_id, ScopedSharedBufferHandle handle);

  // Creates a new buffer of the indicated size. If successful, delivers the
  // buffer id assigned to the buffer and a handle to the buffer via
  // |buffer_id_out| and |handle_out|.
  MojoResult CreateNewBuffer(uint64_t size,
                             uint32_t* buffer_id_out,
                             ScopedSharedBufferHandle* handle_out);

  // Removes a buffer.
  void RemoveBuffer(uint32_t buffer_id);

  // Resets the object to its initial state.
  void Reset();

  // Validates a locator and size, verifying that the locator's buffer id
  // references an active buffer and that the locator's offset and size
  // describe a region within the bounds of that buffer.
  bool Validate(const Locator& locator, uint64_t size) const;

  // Translates a locator into a pointer.
  void* PtrFromLocator(const Locator& locator) const;

  // Translates a pointer into a locator.
  Locator LocatorFromPtr(void* ptr) const;

 private:
  // Allocates an unused buffer id.
  uint32_t AllocateBufferId();

  // Adds a buffer to |buffers_| and |buffer_ids_by_base_address_|.
  void AddBuffer(uint32_t buffer_id, MappedSharedBuffer* mapped_shared_buffer);

  std::vector<std::unique_ptr<MappedSharedBuffer>> buffers_;
  std::map<uint8_t*, uint32_t> buffer_ids_by_base_address_;
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_SHARED_BUFFER_SET_H_
