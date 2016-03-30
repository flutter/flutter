// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/logging.h"
#include "mojo/services/media/common/cpp/mapped_shared_buffer.h"

namespace mojo {
namespace media {

MappedSharedBuffer::MappedSharedBuffer() {}

MappedSharedBuffer::~MappedSharedBuffer() {}

void MappedSharedBuffer::InitNew(uint64_t size) {
  MOJO_DCHECK(size > 0);

  buffer_.reset(new SharedBuffer(size));
  handle_.reset();

  InitInternal(buffer_->handle);
}

void MappedSharedBuffer::InitFromHandle(ScopedSharedBufferHandle handle) {
  MOJO_DCHECK(handle.is_valid());

  buffer_.reset();
  handle_ = handle.Pass();

  InitInternal(handle_);
}

void MappedSharedBuffer::InitInternal(const ScopedSharedBufferHandle& handle) {
  MOJO_DCHECK(handle.is_valid());

  // Query the buffer for its size.
  // TODO(johngro) :  It would be nice if we could do something other than
  // DCHECK if things don't go exactly our way.
  MojoBufferInformation info;
  MojoResult res =
      MojoGetBufferInformation(handle.get().value(), &info, sizeof(info));
  uint64_t size = info.num_bytes;
  MOJO_DCHECK(res == MOJO_RESULT_OK);
  MOJO_DCHECK(size > 0);

  size_ = size;
  buffer_ptr_.reset();

  void* ptr;
  auto result = MapBuffer(handle.get(),
                          0,  // offset
                          size, &ptr, MOJO_MAP_BUFFER_FLAG_NONE);
  MOJO_DCHECK(result == MOJO_RESULT_OK);
  MOJO_DCHECK(ptr);

  buffer_ptr_.reset(reinterpret_cast<uint8_t*>(ptr));

  OnInit();
}

bool MappedSharedBuffer::initialized() const {
  return buffer_ptr_ != nullptr;
}

uint64_t MappedSharedBuffer::size() const {
  return size_;
}

ScopedSharedBufferHandle MappedSharedBuffer::GetDuplicateHandle() const {
  MOJO_DCHECK(initialized());
  ScopedSharedBufferHandle handle;
  if (buffer_) {
    DuplicateBuffer(buffer_->handle.get(), nullptr, &handle);
  } else {
    MOJO_DCHECK(handle_.is_valid());
    DuplicateBuffer(handle_.get(), nullptr, &handle);
  }
  return handle.Pass();
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
