// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/media/common/cpp/mapped_shared_buffer.h"

#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/system/handle.h"
#include "mojo/services/media/common/cpp/fifo_allocator.h"
#include "mojo/services/media/common/interfaces/media_transport.mojom.h"

namespace mojo {
namespace media {

MappedSharedBuffer::MappedSharedBuffer() {}

MappedSharedBuffer::~MappedSharedBuffer() {
  Reset();
}

MojoResult MappedSharedBuffer::InitNew(uint64_t size) {
  MOJO_DCHECK(size > 0);

  buffer_.reset(new SharedBuffer(size));
  handle_.reset();

  return InitInternal(buffer_->handle);
}

MojoResult MappedSharedBuffer::InitFromHandle(ScopedSharedBufferHandle handle) {
  MOJO_DCHECK(handle.is_valid());

  buffer_.reset();
  handle_ = handle.Pass();

  return InitInternal(handle_);
}

MojoResult MappedSharedBuffer::InitInternal(
    const ScopedSharedBufferHandle& handle) {
  MOJO_DCHECK(handle.is_valid());

  // Query the buffer for its size.
  MojoBufferInformation info;
  MojoResult result =
      MojoGetBufferInformation(handle.get().value(), &info, sizeof(info));
  uint64_t size = info.num_bytes;

  if (result != MOJO_RESULT_OK) {
    MOJO_DLOG(ERROR) << "MojoGetBufferInformation failed, result " << result;
    return result;
  }

  if (size == 0 || size > MediaPacketConsumer::kMaxBufferLen) {
    MOJO_DLOG(ERROR) << "MojoGetBufferInformation returned invalid size "
                     << size;
    return MOJO_RESULT_OUT_OF_RANGE;
  }

  size_ = size;
  buffer_ptr_.reset();

  void* ptr;
  result = MapBuffer(handle.get(),
                     0,  // offset
                     size, &ptr, MOJO_MAP_BUFFER_FLAG_NONE);

  if (result != MOJO_RESULT_OK) {
    MOJO_DLOG(ERROR) << "MapBuffer failed, result " << result;
    Reset();
    return result;
  }

  MOJO_DCHECK(ptr);

  buffer_ptr_.reset(reinterpret_cast<uint8_t*>(ptr));

  OnInit();

  return MOJO_RESULT_OK;
}

bool MappedSharedBuffer::initialized() const {
  return buffer_ptr_ != nullptr;
}

void MappedSharedBuffer::Reset() {
  size_ = 0;
  buffer_.reset();
  handle_.reset();
  buffer_ptr_.reset();
}

uint64_t MappedSharedBuffer::size() const {
  return size_;
}

ScopedSharedBufferHandle MappedSharedBuffer::GetDuplicateHandle() const {
  MOJO_DCHECK(initialized());
  ScopedSharedBufferHandle handle;
  if (buffer_) {
    handle = DuplicateHandle(buffer_->handle.get());
  } else {
    MOJO_DCHECK(handle_.is_valid());
    handle = DuplicateHandle(handle_.get());
  }
  MOJO_DCHECK(handle.is_valid());
  return handle;
}

bool MappedSharedBuffer::Validate(uint64_t offset, uint64_t size) {
  MOJO_DCHECK(buffer_ptr_);
  return offset < size_ && size <= size_ - offset;
}

void* MappedSharedBuffer::PtrFromOffset(uint64_t offset) const {
  MOJO_DCHECK(buffer_ptr_);

  if (offset == FifoAllocator::kNullOffset) {
    return nullptr;
  }

  MOJO_DCHECK(offset < size_);
  return buffer_ptr_.get() + offset;
}

uint64_t MappedSharedBuffer::OffsetFromPtr(void* ptr) const {
  MOJO_DCHECK(buffer_ptr_);
  if (ptr == nullptr) {
    return FifoAllocator::kNullOffset;
  }
  uint64_t offset = reinterpret_cast<uint8_t*>(ptr) - buffer_ptr_.get();
  MOJO_DCHECK(offset < size_);
  return offset;
}

void MappedSharedBuffer::OnInit() {}

}  // namespace media
}  // namespace mojo
