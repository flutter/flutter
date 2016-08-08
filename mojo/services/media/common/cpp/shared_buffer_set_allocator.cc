// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/media/common/cpp/shared_buffer_set_allocator.h"

namespace mojo {
namespace media {

SharedBufferSetAllocator::SharedBufferSetAllocator() {}

SharedBufferSetAllocator::~SharedBufferSetAllocator() {}

void* SharedBufferSetAllocator::AllocateRegion(uint64_t size) {
  MOJO_DCHECK(size != 0);

  std::lock_guard<std::mutex> lock(lock_);

  Locator locator;

  if (size >= kWholeRegionMinimumSize) {
    locator = AllocateWholeRegion(size);
  } else {
    locator = AllocateSlicedRegion(size);
  }

  return PtrFromLocator(locator);
}

void SharedBufferSetAllocator::ReleaseRegion(void* ptr) {
  MOJO_DCHECK(ptr != nullptr);

  std::lock_guard<std::mutex> lock(lock_);

  Locator locator = LocatorFromPtr(ptr);
  MOJO_DCHECK(locator.buffer_id() < buffers_.size());

  if (buffers_[locator.buffer_id()].whole()) {
    ReleaseWholeRegion(locator);
  } else {
    ReleaseSlicedRegion(locator);
  }
}

bool SharedBufferSetAllocator::PollForBufferUpdate(
    uint32_t* buffer_id_out,
    ScopedSharedBufferHandle* handle_out) {
  MOJO_DCHECK(buffer_id_out != nullptr);
  MOJO_DCHECK(handle_out != nullptr);

  std::lock_guard<std::mutex> lock(lock_);

  if (buffer_updates_.empty()) {
    return false;
  }

  *buffer_id_out = buffer_updates_.front().buffer_id_;
  *handle_out = buffer_updates_.front().handle_.Pass();

  buffer_updates_.pop();

  return true;
}

SharedBufferSet::Locator SharedBufferSetAllocator::AllocateWholeRegion(
    uint64_t size) {
  auto lower_bound = free_whole_buffer_ids_by_size_.lower_bound(size);

  for (auto iter = free_whole_buffer_ids_by_size_.begin(); iter != lower_bound;
       ++iter) {
    DeleteBuffer(iter->second);
  }

  free_whole_buffer_ids_by_size_.erase(free_whole_buffer_ids_by_size_.begin(),
                                       lower_bound);

  MOJO_DCHECK(lower_bound == free_whole_buffer_ids_by_size_.begin());

  if (lower_bound != free_whole_buffer_ids_by_size_.end()) {
    // Found a free buffer that's large enough. Use it.
    uint32_t buffer_id = lower_bound->second;
    free_whole_buffer_ids_by_size_.erase(lower_bound);
    return Locator(buffer_id, 0);
  }

  // Didn't find a large enough buffer. Create one.
  uint32_t buffer_id = CreateBuffer(true, size);
  if (buffer_id == kNullBufferId) {
    return Locator::Null();
  }

  return Locator(buffer_id, 0);
}

void SharedBufferSetAllocator::ReleaseWholeRegion(const Locator& locator) {
  MOJO_DCHECK(locator);
  MOJO_DCHECK(locator.buffer_id() < buffers_.size());
  MOJO_DCHECK(!buffers_[locator.buffer_id()].allocator_);

  free_whole_buffer_ids_by_size_.insert(
      std::make_pair(buffers_[locator.buffer_id()].size_, locator.buffer_id()));
}

SharedBufferSet::Locator SharedBufferSetAllocator::AllocateSlicedRegion(
    uint64_t size) {
  if (active_sliced_buffer_id_ == kNullBufferId) {
    // No buffer has been established for allocating sliced buffers. Create one.
    active_sliced_buffer_id_ =
        CreateBuffer(false, size * kSlicedBufferInitialSizeMultiplier);
    if (active_sliced_buffer_id_ == kNullBufferId) {
      return Locator::Null();
    }
  }

  // Try allocating from the buffer.
  MOJO_DCHECK(buffers_[active_sliced_buffer_id_].allocator_);
  uint64_t offset =
      buffers_[active_sliced_buffer_id_].allocator_->AllocateRegion(size);

  if (offset != FifoAllocator::kNullOffset) {
    // Allocation succeeded.
    return Locator(active_sliced_buffer_id_, offset);
  }

  // Allocation failed - we need a bigger buffer. We either grow the buffer size
  // by a factor of kSlicedBufferGrowMultiplier or use the initial buffer size
  // calculation based on this allocation request, whichever produces the
  // larger buffer.
  //
  // The old buffer will be deleted once all the regions that were allocated
  // from it are released.

  uint64_t new_buffer_size = std::max(
      size * kSlicedBufferInitialSizeMultiplier,
      buffers_[active_sliced_buffer_id_].size_ * kSlicedBufferGrowMultiplier);

  uint32_t buffer_id = CreateBuffer(false, new_buffer_size);
  if (buffer_id == kNullBufferId) {
    return Locator::Null();
  }

  MaybeDeleteSlicedBuffer(active_sliced_buffer_id_);

  active_sliced_buffer_id_ = buffer_id;

  MOJO_DCHECK(buffers_[active_sliced_buffer_id_].allocator_);
  offset = buffers_[active_sliced_buffer_id_].allocator_->AllocateRegion(size);
  // The allocation must succeed since the new buffer is at least
  // kSlicedBufferInitialSizeMultiplier times larger than size.
  MOJO_DCHECK(offset != FifoAllocator::kNullOffset);

  return Locator(active_sliced_buffer_id_, offset);
}

void SharedBufferSetAllocator::ReleaseSlicedRegion(const Locator& locator) {
  MOJO_DCHECK(locator);
  MOJO_DCHECK(locator.buffer_id() < buffers_.size());
  MOJO_DCHECK(buffers_[locator.buffer_id()].allocator_);

  buffers_[locator.buffer_id()].allocator_->ReleaseRegion(locator.offset());

  // Delete the buffer if it's no longer the active one, and it's fully
  // released.
  if (locator.buffer_id() != active_sliced_buffer_id_) {
    MaybeDeleteSlicedBuffer(locator.buffer_id());
  }
}

uint32_t SharedBufferSetAllocator::CreateBuffer(bool whole, uint64_t size) {
  uint32_t buffer_id;
  ScopedSharedBufferHandle handle;
  MojoResult result = CreateNewBuffer(size * kSlicedBufferInitialSizeMultiplier,
                                      &buffer_id, &handle);
  if (result != MOJO_RESULT_OK) {
    return kNullBufferId;
  }

  if (buffers_.size() <= buffer_id) {
    buffers_.resize(buffer_id + 1);
  }

  Buffer& buffer = buffers_[buffer_id];
  buffer.size_ = size;
  if (!whole) {
    buffer.allocator_.reset(new FifoAllocator(size));
  }

  buffer_updates_.emplace(buffer_id, handle.Pass());

  return buffer_id;
}

void SharedBufferSetAllocator::DeleteBuffer(uint32_t id) {
  MOJO_DCHECK(buffers_.size() > id);
  RemoveBuffer(id);
  buffers_[id].size_ = 0;
  buffers_[id].allocator_.reset();

  buffer_updates_.emplace(id);
}

void SharedBufferSetAllocator::MaybeDeleteSlicedBuffer(uint32_t id) {
  MOJO_DCHECK(buffers_[id].allocator_);
  if (!buffers_[id].allocator_->AnyCurrentAllocatedRegions()) {
    DeleteBuffer(id);
  }
}

SharedBufferSetAllocator::Buffer::Buffer() {}

SharedBufferSetAllocator::Buffer::~Buffer() {}

SharedBufferSetAllocator::BufferUpdate::BufferUpdate(
    uint32_t buffer_id,
    ScopedSharedBufferHandle handle)
    : buffer_id_(buffer_id), handle_(handle.Pass()) {}

SharedBufferSetAllocator::BufferUpdate::BufferUpdate(uint32_t buffer_id)
    : buffer_id_(buffer_id) {}

SharedBufferSetAllocator::BufferUpdate::~BufferUpdate() {}

}  // namespace media
}  // namespace mojo
