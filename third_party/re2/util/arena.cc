// Copyright 2000 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/util.h"

namespace re2 {

// ----------------------------------------------------------------------
// UnsafeArena::UnsafeArena()
// UnsafeArena::~UnsafeArena()
//    Destroying the arena automatically calls Reset()
// ----------------------------------------------------------------------


UnsafeArena::UnsafeArena(const size_t block_size)
  : block_size_(block_size),
    freestart_(NULL),                   // set for real in Reset()
    last_alloc_(NULL),
    remaining_(0),
    blocks_alloced_(1),
    overflow_blocks_(NULL) {
  assert(block_size > kDefaultAlignment);

  first_blocks_[0].mem = reinterpret_cast<char*>(malloc(block_size_));
  first_blocks_[0].size = block_size_;

  Reset();
}

UnsafeArena::~UnsafeArena() {
  FreeBlocks();
  assert(overflow_blocks_ == NULL);    // FreeBlocks() should do that
  // The first X blocks stay allocated always by default.  Delete them now.
  for (int i = 0; i < blocks_alloced_; i++)
    free(first_blocks_[i].mem);
}

// ----------------------------------------------------------------------
// UnsafeArena::Reset()
//    Clears all the memory an arena is using.
// ----------------------------------------------------------------------

void UnsafeArena::Reset() {
  FreeBlocks();
  freestart_ = first_blocks_[0].mem;
  remaining_ = first_blocks_[0].size;
  last_alloc_ = NULL;

  // We do not know for sure whether or not the first block is aligned,
  // so we fix that right now.
  const int overage = reinterpret_cast<uintptr_t>(freestart_) &
                      (kDefaultAlignment-1);
  if (overage > 0) {
    const int waste = kDefaultAlignment - overage;
    freestart_ += waste;
    remaining_ -= waste;
  }
  freestart_when_empty_ = freestart_;
  assert(!(reinterpret_cast<uintptr_t>(freestart_)&(kDefaultAlignment-1)));
}

// -------------------------------------------------------------
// UnsafeArena::AllocNewBlock()
//    Adds and returns an AllocatedBlock.
//    The returned AllocatedBlock* is valid until the next call
//    to AllocNewBlock or Reset.  (i.e. anything that might
//    affect overflow_blocks_).
// -------------------------------------------------------------

UnsafeArena::AllocatedBlock* UnsafeArena::AllocNewBlock(const size_t block_size) {
  AllocatedBlock *block;
  // Find the next block.
  if ( blocks_alloced_ < arraysize(first_blocks_) ) {
    // Use one of the pre-allocated blocks
    block = &first_blocks_[blocks_alloced_++];
  } else {                   // oops, out of space, move to the vector
    if (overflow_blocks_ == NULL) overflow_blocks_ = new vector<AllocatedBlock>;
    // Adds another block to the vector.
    overflow_blocks_->resize(overflow_blocks_->size()+1);
    // block points to the last block of the vector.
    block = &overflow_blocks_->back();
  }

  block->mem = reinterpret_cast<char*>(malloc(block_size));
  block->size = block_size;

  return block;
}

// ----------------------------------------------------------------------
// UnsafeArena::GetMemoryFallback()
//    We take memory out of our pool, aligned on the byte boundary
//    requested.  If we don't have space in our current pool, we
//    allocate a new block (wasting the remaining space in the
//    current block) and give you that.  If your memory needs are
//    too big for a single block, we make a special your-memory-only
//    allocation -- this is equivalent to not using the arena at all.
// ----------------------------------------------------------------------

void* UnsafeArena::GetMemoryFallback(const size_t size, const int align) {
  if (size == 0)
    return NULL;             // stl/stl_alloc.h says this is okay

  assert(align > 0 && 0 == (align & (align - 1)));  // must be power of 2

  // If the object is more than a quarter of the block size, allocate
  // it separately to avoid wasting too much space in leftover bytes
  if (block_size_ == 0 || size > block_size_/4) {
    // then it gets its own block in the arena
    assert(align <= kDefaultAlignment);   // because that's what new gives us
    // This block stays separate from the rest of the world; in particular
    // we don't update last_alloc_ so you can't reclaim space on this block.
    return AllocNewBlock(size)->mem;
  }

  const int overage =
    (reinterpret_cast<uintptr_t>(freestart_) & (align-1));
  if (overage) {
    const int waste = align - overage;
    freestart_ += waste;
    if (waste < remaining_) {
      remaining_ -= waste;
    } else {
      remaining_ = 0;
    }
  }
  if (size > remaining_) {
    AllocatedBlock *block = AllocNewBlock(block_size_);
    freestart_ = block->mem;
    remaining_ = block->size;
  }
  remaining_ -= size;
  last_alloc_ = freestart_;
  freestart_ += size;
  assert((reinterpret_cast<uintptr_t>(last_alloc_) & (align-1)) == 0);
  return reinterpret_cast<void*>(last_alloc_);
}

// ----------------------------------------------------------------------
// UnsafeArena::FreeBlocks()
//    Unlike GetMemory(), which does actual work, ReturnMemory() is a
//    no-op: we don't "free" memory until Reset() is called.  We do
//    update some stats, though.  Note we do no checking that the
//    pointer you pass in was actually allocated by us, or that it
//    was allocated for the size you say, so be careful here!
//       FreeBlocks() does the work for Reset(), actually freeing all
//    memory allocated in one fell swoop.
// ----------------------------------------------------------------------

void UnsafeArena::FreeBlocks() {
  for ( int i = 1; i < blocks_alloced_; ++i ) {  // keep first block alloced
    free(first_blocks_[i].mem);
    first_blocks_[i].mem = NULL;
    first_blocks_[i].size = 0;
  }
  blocks_alloced_ = 1;
  if (overflow_blocks_ != NULL) {
    vector<AllocatedBlock>::iterator it;
    for (it = overflow_blocks_->begin(); it != overflow_blocks_->end(); ++it) {
      free(it->mem);
    }
    delete overflow_blocks_;             // These should be used very rarely
    overflow_blocks_ = NULL;
  }
}

}  // namespace re2
