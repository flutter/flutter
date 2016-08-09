// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_FIFO_ALLOCATOR_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_FIFO_ALLOCATOR_H_

#include <cstdint>
#include <limits>

namespace mojo {
namespace media {

// FifoAllocator implements heap semantics on a single contiguous buffer using
// a strategy that is especially suited to streaming. Allocations can vary in
// size, but the expectation is that regions will be released in roughly the
// order they were allocated (hence 'Fifo'). It's important that FifoAllocator
// be used in this way. FifoAllocator can deal with regions that don't get
// released in the order they were allocated, but they can potentially fragment
// the buffer and impact performance.
//
// FifoAllocator doesn't actually deal with any particular region of memory. It
// simply does the bookkeeping regarding how a buffer of a given size is
// allocated into regions.
//
// DESIGN:
//
// FifoAllocator maintains an ordered list of regions that partition the buffer.
// Some regions are allocated and some are free. Free regions are always
// coalesced, so there are no two adjacent free regions. Allocated regions are
// not coalesced. There is always at least one free region.
//
// One free region is distinguished as the 'active' region. New allocations are
// taken from the front of the active region. If the active region is too small
// to accommodate a requested allocation, FifoAllocator walks the list looking
// for an unallocated region that's large enough. The old active region becomes
// an unused scrap that is recovered when the active region catches up to it
// again. In some cases, the active region has a length of zero.
//
// The allocation strategy that emerges from all this is well-suited to many
// streaming scenarios in which packets vary in size. If packets are of
// consistent size, this strategy will still work, but is overkill given that
// a fixed set of regions can be preallocated from the buffer.
//
// An internal region structure is employed to represent the list of regions.
// FifoAllocator keeps unused region structures in a lookaside and never deletes
// them until the FifoAllocator is deleted. This could cause a large number of
// region structures to sit unused if the number of regions ever gets large.
// This is generally not an issue for the streaming scenarios for which the
// class is intended.
//
// Deallocations (releases) employ a sequential search for a matching
// region. The search is done starting immediately after the active region, so
// it typically finds the desired region immediately. If the number of regions
// is very large and deallocation is frequently done out of order, the
// sequential searches may be a performance issue.
class FifoAllocator {
 public:
  // Returned by AllocatedRegion when the requested allocation cannot be
  // performed.
  static const uint64_t kNullOffset = std::numeric_limits<uint64_t>::max();

  FifoAllocator(uint64_t size);

  ~FifoAllocator();

  // Returns the size of the entire buffer as determined by the call to the
  // constructor or the most recent call to Reset.
  uint64_t size() const { return size_; }

  // Resets the buffer manager to its initial state (no regions allocated)
  // with a new buffer size. Also deletes all the regions in the lookaside.
  void Reset(uint64_t size);

  // Allocates a region and returns its offset or kNullOffset if the allocation
  // could not be performed.
  uint64_t AllocateRegion(uint64_t size);

  // Releases a previously-allocated region.
  void ReleaseRegion(uint64_t offset);

  // Determines if there are currently any allocated regions.
  bool AnyCurrentAllocatedRegions() const;

 private:
  // List element to track allocated and free regions.
  struct Region {
    bool allocated;
    uint64_t size;
    uint64_t offset;

    // Intrusive list pointers.
    Region* prev;
    Region* next;
  };

  // Releases the specified region if it's found between begin (inclusive) and
  // end (exclusive).
  bool Release(uint64_t offset, Region* begin, Region* end);

  // Advances the active region to one that's at least the specified size.
  // Returns false if none could be found.
  bool AdvanceActive(uint64_t size);

  // Does the above for the interval between begin (inclusive) and end
  // (exclusive).
  bool AdvanceActive(uint64_t size, Region* begin, Region* end);

  // Inserts a zero-sized region after active_ and makes that the active region.
  void MakeActivePlaceholder();

  // Deletes a list of regions by following their next pointers.
  void DeleteFrontToBack(Region* region);

  // Removes a region from the list.
  void remove(Region* region);

  // Inserts a region into the list before the specified region.
  void insert_before(Region* region, Region* before_this);

  // gets a free region structure, checking the lookaside first.
  Region* get_free(bool allocated, uint64_t size, uint64_t offset);

  // Saves a unused region structure to the lookaside.
  void put_free(Region* region) {
    region->next = free_;
    free_ = region;
  }

  // Total size of the buffer to be managed. The sum of the sizes of all the
  // regions in the list should equal size_.
  uint64_t size_;

  // Doubly-linked intrusive list of current regions in offset order.
  Region* front_;
  Region* back_;

  // Lookaside for free region objects.
  Region* free_;

  // Unallocated region from which allocations are currently being made.
  Region* active_;
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_FIFO_ALLOCATOR_H_
