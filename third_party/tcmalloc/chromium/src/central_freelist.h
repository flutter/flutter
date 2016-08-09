// Copyright (c) 2008, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Sanjay Ghemawat <opensource@google.com>

#ifndef TCMALLOC_CENTRAL_FREELIST_H_
#define TCMALLOC_CENTRAL_FREELIST_H_

#include "config.h"
#include <stddef.h>                     // for size_t
#ifdef HAVE_STDINT_H
#include <stdint.h>                     // for int32_t
#endif
#include "base/spinlock.h"
#include "base/thread_annotations.h"
#include "common.h"
#include "span.h"

namespace tcmalloc {

// Data kept per size-class in central cache.
class CentralFreeList {
 public:
  // A CentralFreeList may be used before its constructor runs.
  // So we prevent lock_'s constructor from doing anything to the
  // lock_ state.
  CentralFreeList() : lock_(base::LINKER_INITIALIZED) { }

  void Init(size_t cl);

  // These methods all do internal locking.

  // Insert the specified range into the central freelist.  N is the number of
  // elements in the range.  RemoveRange() is the opposite operation.
  void InsertRange(void *start, void *end, int N);

  // Returns the actual number of fetched elements and sets *start and *end.
  int RemoveRange(void **start, void **end, int N);

  // Returns the number of free objects in cache.
  int length() {
    SpinLockHolder h(&lock_);
    return counter_;
  }

  // Returns the number of free objects in the transfer cache.
  int tc_length();

  // Returns the memory overhead (internal fragmentation) attributable
  // to the freelist.  This is memory lost when the size of elements
  // in a freelist doesn't exactly divide the page-size (an 8192-byte
  // page full of 5-byte objects would have 2 bytes memory overhead).
  size_t OverheadBytes();

 private:
  // TransferCache is used to cache transfers of
  // sizemap.num_objects_to_move(size_class) back and forth between
  // thread caches and the central cache for a given size class.
  struct TCEntry {
    void *head;  // Head of chain of objects.
    void *tail;  // Tail of chain of objects.
  };

  // A central cache freelist can have anywhere from 0 to kMaxNumTransferEntries
  // slots to put link list chains into.
#ifdef TCMALLOC_SMALL_BUT_SLOW
  // For the small memory model, the transfer cache is not used.
  static const int kMaxNumTransferEntries = 0;
#else
  // Starting point for the the maximum number of entries in the transfer cache.
  // This actual maximum for a given size class may be lower than this
  // maximum value.
  static const int kMaxNumTransferEntries = 64;
#endif

  // REQUIRES: lock_ is held
  // Remove object from cache and return.
  // Return NULL if no free entries in cache.
  void* FetchFromSpans() EXCLUSIVE_LOCKS_REQUIRED(lock_);

  // REQUIRES: lock_ is held
  // Remove object from cache and return.  Fetches
  // from pageheap if cache is empty.  Only returns
  // NULL on allocation failure.
  void* FetchFromSpansSafe() EXCLUSIVE_LOCKS_REQUIRED(lock_);

  // REQUIRES: lock_ is held
  // Release a linked list of objects to spans.
  // May temporarily release lock_.
  void ReleaseListToSpans(void *start) EXCLUSIVE_LOCKS_REQUIRED(lock_);

  // REQUIRES: lock_ is held
  // Release an object to spans.
  // May temporarily release lock_.
  void ReleaseToSpans(void* object) EXCLUSIVE_LOCKS_REQUIRED(lock_);

  // REQUIRES: lock_ is held
  // Populate cache by fetching from the page heap.
  // May temporarily release lock_.
  void Populate() EXCLUSIVE_LOCKS_REQUIRED(lock_);

  // REQUIRES: lock is held.
  // Tries to make room for a TCEntry.  If the cache is full it will try to
  // expand it at the cost of some other cache size.  Return false if there is
  // no space.
  bool MakeCacheSpace() EXCLUSIVE_LOCKS_REQUIRED(lock_);

  // REQUIRES: lock_ for locked_size_class is held.
  // Picks a "random" size class to steal TCEntry slot from.  In reality it
  // just iterates over the sizeclasses but does so without taking a lock.
  // Returns true on success.
  // May temporarily lock a "random" size class.
  static bool EvictRandomSizeClass(int locked_size_class, bool force);

  // REQUIRES: lock_ is *not* held.
  // Tries to shrink the Cache.  If force is true it will relase objects to
  // spans if it allows it to shrink the cache.  Return false if it failed to
  // shrink the cache.  Decrements cache_size_ on succeess.
  // May temporarily take lock_.  If it takes lock_, the locked_size_class
  // lock is released to keep the thread from holding two size class locks
  // concurrently which could lead to a deadlock.
  bool ShrinkCache(int locked_size_class, bool force) LOCKS_EXCLUDED(lock_);

  // This lock protects all the data members.  cached_entries and cache_size_
  // may be looked at without holding the lock.
  SpinLock lock_;

  // We keep linked lists of empty and non-empty spans.
  size_t   size_class_;     // My size class
  Span     empty_;          // Dummy header for list of empty spans
  Span     nonempty_;       // Dummy header for list of non-empty spans
  size_t   num_spans_;      // Number of spans in empty_ plus nonempty_
  size_t   counter_;        // Number of free objects in cache entry

  // Here we reserve space for TCEntry cache slots.  Space is preallocated
  // for the largest possible number of entries than any one size class may
  // accumulate.  Not all size classes are allowed to accumulate
  // kMaxNumTransferEntries, so there is some wasted space for those size
  // classes.
  TCEntry tc_slots_[kMaxNumTransferEntries];

  // Number of currently used cached entries in tc_slots_.  This variable is
  // updated under a lock but can be read without one.
  int32_t used_slots_;
  // The current number of slots for this size class.  This is an
  // adaptive value that is increased if there is lots of traffic
  // on a given size class.
  int32_t cache_size_;
  // Maximum size of the cache for a given size class.
  int32_t max_cache_size_;
};

// Pads each CentralCache object to multiple of 64 bytes.  Since some
// compilers (such as MSVC) don't like it when the padding is 0, I use
// template specialization to remove the padding entirely when
// sizeof(CentralFreeList) is a multiple of 64.
template<int kFreeListSizeMod64>
class CentralFreeListPaddedTo : public CentralFreeList {
 private:
  char pad_[64 - kFreeListSizeMod64];
};

template<>
class CentralFreeListPaddedTo<0> : public CentralFreeList {
};

class CentralFreeListPadded : public CentralFreeListPaddedTo<
  sizeof(CentralFreeList) % 64> {
};

}  // namespace tcmalloc

#endif  // TCMALLOC_CENTRAL_FREELIST_H_
