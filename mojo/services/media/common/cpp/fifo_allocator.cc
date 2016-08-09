// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/logging.h"
#include "mojo/services/media/common/cpp/fifo_allocator.h"

namespace mojo {
namespace media {

FifoAllocator::FifoAllocator(uint64_t size) : front_(nullptr), free_(nullptr) {
  // front_ and free_ need to be set to nullptr before calling reset.
  Reset(size);
}

FifoAllocator::~FifoAllocator() {
  DeleteFrontToBack(front_);
  DeleteFrontToBack(free_);
}

void FifoAllocator::Reset(uint64_t size) {
  MOJO_DCHECK(size < kNullOffset);
  DeleteFrontToBack(front_);
  DeleteFrontToBack(free_);
  size_ = size;
  free_ = nullptr;
  front_ = back_ = active_ = get_free(false, size, 0);
  active_->prev = nullptr;
  active_->next = nullptr;
}

uint64_t FifoAllocator::AllocateRegion(uint64_t size) {
  MOJO_DCHECK(size != 0);

  if (active_->size < size) {
    // The active region is too small. Look for one that's large enough.
    if (!AdvanceActive(size)) {
      // No unallocated regions are large enough. Can't do the allocation.
      return kNullOffset;
    }
  }

  if (active_->size == size) {
    // The active region is exactly the right size. Use it for the allocation.
    uint64_t result = active_->offset;
    active_->allocated = true;
    if (active_ == back_ && !front_->allocated) {
      // active_ was the back region and the front region isn't allocated. Make
      // the front region the new active region.
      active_ = front_;
    } else {
      // The region after active_ is allocated, so make a zero-sized
      // placeholder.
      MakeActivePlaceholder();
    }
    return result;
  }

  // The active region can accommodate this allocation with room left over.
  // Create a new region (allocated) of the requested size at the front of the
  // active region, and adjust the active region to reflect the deficit.
  MOJO_DCHECK(active_->size > size);
  Region* allocated = get_free(true, size, active_->offset);
  active_->size -= size;
  active_->offset += size;
  insert_before(allocated, active_);
  return allocated->offset;
}

void FifoAllocator::ReleaseRegion(uint64_t offset) {
  // Start at active_->next. That's usually the region we're looking for.
  bool released = Release(offset, active_->next, nullptr) ||
                  Release(offset, front_, active_);
  MOJO_DCHECK(released);
}

bool FifoAllocator::AnyCurrentAllocatedRegions() const {
  return front_ != back_ || front_ != active_;
}

bool FifoAllocator::Release(uint64_t offset, Region* begin, Region* end) {
  MOJO_DCHECK(begin != nullptr || end == nullptr);
  for (Region* region = begin; region != end; region = region->next) {
    if (region->offset == offset) {
      MOJO_DCHECK(region->allocated);
      region->allocated = false;

      Region* prev = region->prev;
      if (prev != nullptr && !prev->allocated) {
        // Coalesce wtih the previous region.
        prev->size += region->size;
        remove(region);
        put_free(region);
        region = prev;
      }

      Region* next = region->next;
      if (next != nullptr && !next->allocated) {
        // Coalesce wtih the next region.
        next->offset = region->offset;
        next->size += region->size;
        if (active_ == region) {
          // This can happen if we coalesced the previous region.
          active_ = next;
        }
        remove(region);
        put_free(region);
      }

      return true;
    }
  }

  return false;
}

bool FifoAllocator::AdvanceActive(uint64_t size) {
  MOJO_DCHECK(size != 0);
  return AdvanceActive(size, active_->next, nullptr) ||
         AdvanceActive(size, front_, active_);
}

bool FifoAllocator::AdvanceActive(uint64_t size, Region* begin, Region* end) {
  for (Region* region = begin; region != end; region = region->next) {
    if (!region->allocated && region->size >= size) {
      if (active_->size == 0) {
        // The old active region is zero-sized. Get rid of it.
        MOJO_DCHECK(!active_->allocated);
        remove(active_);
        put_free(active_);
      }
      active_ = region;
      return true;
    }
  }
  return false;
}

void FifoAllocator::MakeActivePlaceholder() {
  // If the old active region was at the back of the list, we'll be inserting
  // at the front, so make the offset zero. We insert at the front, because it's
  // a bit more efficient and because we don't need to implement insert_after.
  Region* new_active = get_free(
      false, 0, active_ == back_ ? 0 : active_->offset + active_->size);

  MOJO_DCHECK((active_ == back_) == (active_->next == nullptr));
  insert_before(new_active, active_ == back_ ? front_ : active_->next);
  active_ = new_active;
}

void FifoAllocator::remove(Region* region) {
  MOJO_DCHECK(region);

  if (front_ == region) {
    MOJO_DCHECK(region->prev == nullptr);
    front_ = region->next;
  } else {
    MOJO_DCHECK(region->prev);
    MOJO_DCHECK(region->prev->next == region);
    region->prev->next = region->next;
  }

  if (back_ == region) {
    MOJO_DCHECK(region->next == nullptr);
    back_ = region->prev;
  } else {
    MOJO_DCHECK(region->next);
    MOJO_DCHECK(region->next->prev == region);
    region->next->prev = region->prev;
  }
}

void FifoAllocator::insert_before(Region* region, Region* before_this) {
  MOJO_DCHECK(region);
  MOJO_DCHECK(before_this);

  region->prev = before_this->prev;
  before_this->prev = region;
  region->next = before_this;
  if (front_ == before_this) {
    MOJO_DCHECK(region->prev == nullptr);
    front_ = region;
  } else {
    MOJO_DCHECK(region->prev);
    region->prev->next = region;
  }
}

FifoAllocator::Region* FifoAllocator::get_free(bool allocated,
                                               uint64_t size,
                                               uint64_t offset) {
  MOJO_DCHECK(size <= size_);
  MOJO_DCHECK(offset <= size_ - size);

  Region* result = free_;
  if (result == nullptr) {
    result = new Region();
  } else {
    free_ = free_->next;
  }

  result->allocated = allocated;
  result->size = size;
  result->offset = offset;

  return result;
}

void FifoAllocator::DeleteFrontToBack(Region* region) {
  while (region != nullptr) {
    Region* to_delete = region;
    region = region->next;
    delete to_delete;
  }
}

}  // namespace media
}  // namespace mojo
