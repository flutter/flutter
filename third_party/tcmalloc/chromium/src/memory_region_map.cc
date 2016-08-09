/* Copyright (c) 2006, Google Inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ---
 * Author: Maxim Lifantsev
 */

//
// Background and key design points of MemoryRegionMap.
//
// MemoryRegionMap is a low-level module with quite atypical requirements that
// result in some degree of non-triviality of the implementation and design.
//
// MemoryRegionMap collects info about *all* memory regions created with
// mmap, munmap, mremap, sbrk.
// They key word above is 'all': all that are happening in a process
// during its lifetime frequently starting even before global object
// constructor execution.
//
// This is needed by the primary client of MemoryRegionMap:
// HeapLeakChecker uses the regions and the associated stack traces
// to figure out what part of the memory is the heap:
// if MemoryRegionMap were to miss some (early) regions, leak checking would
// stop working correctly.
//
// To accomplish the goal of functioning before/during global object
// constructor execution MemoryRegionMap is done as a singleton service
// that relies on own on-demand initialized static constructor-less data,
// and only relies on other low-level modules that can also function properly
// even before global object constructors run.
//
// Accomplishing the goal of collecting data about all mmap, munmap, mremap,
// sbrk occurrences is a more involved: conceptually to do this one needs to
// record some bits of data in particular about any mmap or sbrk call,
// but to do that one needs to allocate memory for that data at some point,
// but all memory allocations in the end themselves come from an mmap
// or sbrk call (that's how the address space of the process grows).
//
// Also note that we need to do all the above recording from
// within an mmap/sbrk hook which is sometimes/frequently is made by a memory
// allocator, including the allocator MemoryRegionMap itself must rely on.
// In the case of heap-checker usage this includes even the very first
// mmap/sbrk call happening in the program: heap-checker gets activated due to
// a link-time installed mmap/sbrk hook and it initializes MemoryRegionMap
// and asks it to record info about this very first call right from that
// very first hook invocation.
//
// MemoryRegionMap is doing its memory allocations via LowLevelAlloc:
// unlike more complex standard memory allocator, LowLevelAlloc cooperates with
// MemoryRegionMap by not holding any of its own locks while it calls mmap
// to get memory, thus we are able to call LowLevelAlloc from
// our mmap/sbrk hooks without causing a deadlock in it.
// For the same reason of deadlock prevention the locking in MemoryRegionMap
// itself is write-recursive which is an exception to Google's mutex usage.
//
// We still need to break the infinite cycle of mmap calling our hook,
// which asks LowLevelAlloc for memory to record this mmap,
// which (sometimes) causes mmap, which calls our hook, and so on.
// We do this as follows: on a recursive call of MemoryRegionMap's
// mmap/sbrk/mremap hook we record the data about the allocation in a
// static fixed-sized stack (saved_regions and saved_buckets), when the
// recursion unwinds but before returning from the outer hook call we unwind
// this stack and move the data from saved_regions and saved_buckets to its
// permanent place in the RegionSet and "bucket_table" respectively,
// which can cause more allocations and mmap-s and recursion and unwinding,
// but the whole process ends eventually due to the fact that for the small
// allocations we are doing LowLevelAlloc reuses one mmap call and parcels out
// the memory it created to satisfy several of our allocation requests.
//

// ========================================================================= //

#include <config.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif
#ifdef HAVE_MMAP
#include <sys/mman.h>
#elif !defined(MAP_FAILED)
#define MAP_FAILED -1  // the only thing we need from mman.h
#endif
#ifdef HAVE_PTHREAD
#include <pthread.h>   // for pthread_t, pthread_self()
#endif
#include <stddef.h>

#include <algorithm>
#include <set>

#include "memory_region_map.h"

#include "base/logging.h"
#include "base/low_level_alloc.h"
#include "malloc_hook-inl.h"

#include <gperftools/stacktrace.h>
#include <gperftools/malloc_hook.h>

// MREMAP_FIXED is a linux extension.  How it's used in this file,
// setting it to 0 is equivalent to saying, "This feature isn't
// supported", which is right.
#ifndef MREMAP_FIXED
# define MREMAP_FIXED  0
#endif

using std::max;

// ========================================================================= //

int MemoryRegionMap::client_count_ = 0;
int MemoryRegionMap::max_stack_depth_ = 0;
MemoryRegionMap::RegionSet* MemoryRegionMap::regions_ = NULL;
LowLevelAlloc::Arena* MemoryRegionMap::arena_ = NULL;
SpinLock MemoryRegionMap::lock_(SpinLock::LINKER_INITIALIZED);
SpinLock MemoryRegionMap::owner_lock_(  // ACQUIRED_AFTER(lock_)
    SpinLock::LINKER_INITIALIZED);
int MemoryRegionMap::recursion_count_ = 0;  // GUARDED_BY(owner_lock_)
pthread_t MemoryRegionMap::lock_owner_tid_;  // GUARDED_BY(owner_lock_)
int64 MemoryRegionMap::map_size_ = 0;
int64 MemoryRegionMap::unmap_size_ = 0;
HeapProfileBucket** MemoryRegionMap::bucket_table_ = NULL;  // GUARDED_BY(lock_)
int MemoryRegionMap::num_buckets_ = 0;  // GUARDED_BY(lock_)
int MemoryRegionMap::saved_buckets_count_ = 0;  // GUARDED_BY(lock_)
HeapProfileBucket MemoryRegionMap::saved_buckets_[20];  // GUARDED_BY(lock_)

// GUARDED_BY(lock_)
const void* MemoryRegionMap::saved_buckets_keys_[20][kMaxStackDepth];

// ========================================================================= //

// Simple hook into execution of global object constructors,
// so that we do not call pthread_self() when it does not yet work.
static bool libpthread_initialized = false;
static bool initializer = (libpthread_initialized = true, true);

static inline bool current_thread_is(pthread_t should_be) {
  // Before main() runs, there's only one thread, so we're always that thread
  if (!libpthread_initialized) return true;
  // this starts working only sometime well into global constructor execution:
  return pthread_equal(pthread_self(), should_be);
}

// ========================================================================= //

// Constructor-less place-holder to store a RegionSet in.
union MemoryRegionMap::RegionSetRep {
  char rep[sizeof(RegionSet)];
  void* align_it;  // do not need a better alignment for 'rep' than this
  RegionSet* region_set() { return reinterpret_cast<RegionSet*>(rep); }
};

// The bytes where MemoryRegionMap::regions_ will point to.
// We use RegionSetRep with noop c-tor so that global construction
// does not interfere.
static MemoryRegionMap::RegionSetRep regions_rep;

// ========================================================================= //

// Has InsertRegionLocked been called recursively
// (or rather should we *not* use regions_ to record a hooked mmap).
static bool recursive_insert = false;

void MemoryRegionMap::Init(int max_stack_depth, bool use_buckets) {
  RAW_VLOG(10, "MemoryRegionMap Init");
  RAW_CHECK(max_stack_depth >= 0, "");
  // Make sure we don't overflow the memory in region stacks:
  RAW_CHECK(max_stack_depth <= kMaxStackDepth,
            "need to increase kMaxStackDepth?");
  Lock();
  client_count_ += 1;
  max_stack_depth_ = max(max_stack_depth_, max_stack_depth);
  if (client_count_ > 1) {
    // not first client: already did initialization-proper
    Unlock();
    RAW_VLOG(10, "MemoryRegionMap Init increment done");
    return;
  }
  // Set our hooks and make sure they were installed:
  RAW_CHECK(MallocHook::AddMmapHook(&MmapHook), "");
  RAW_CHECK(MallocHook::AddMremapHook(&MremapHook), "");
  RAW_CHECK(MallocHook::AddSbrkHook(&SbrkHook), "");
  RAW_CHECK(MallocHook::AddMunmapHook(&MunmapHook), "");
  // We need to set recursive_insert since the NewArena call itself
  // will already do some allocations with mmap which our hooks will catch
  // recursive_insert allows us to buffer info about these mmap calls.
  // Note that Init() can be (and is) sometimes called
  // already from within an mmap/sbrk hook.
  recursive_insert = true;
  arena_ = LowLevelAlloc::NewArena(0, LowLevelAlloc::DefaultArena());
  recursive_insert = false;
  HandleSavedRegionsLocked(&InsertRegionLocked);  // flush the buffered ones
    // Can't instead use HandleSavedRegionsLocked(&DoInsertRegionLocked) before
    // recursive_insert = false; as InsertRegionLocked will also construct
    // regions_ on demand for us.
  if (use_buckets) {
    const int table_bytes = kHashTableSize * sizeof(*bucket_table_);
    recursive_insert = true;
    bucket_table_ = static_cast<HeapProfileBucket**>(
        MyAllocator::Allocate(table_bytes));
    recursive_insert = false;
    memset(bucket_table_, 0, table_bytes);
    num_buckets_ = 0;
  }
  if (regions_ == NULL)  // init regions_
    InitRegionSetLocked();
  Unlock();
  RAW_VLOG(10, "MemoryRegionMap Init done");
}

bool MemoryRegionMap::Shutdown() {
  RAW_VLOG(10, "MemoryRegionMap Shutdown");
  Lock();
  RAW_CHECK(client_count_ > 0, "");
  client_count_ -= 1;
  if (client_count_ != 0) {  // not last client; need not really shutdown
    Unlock();
    RAW_VLOG(10, "MemoryRegionMap Shutdown decrement done");
    return true;
  }
  if (bucket_table_ != NULL) {
    for (int i = 0; i < kHashTableSize; i++) {
      for (HeapProfileBucket* curr = bucket_table_[i]; curr != 0; /**/) {
        HeapProfileBucket* bucket = curr;
        curr = curr->next;
        MyAllocator::Free(bucket->stack, 0);
        MyAllocator::Free(bucket, 0);
      }
    }
    MyAllocator::Free(bucket_table_, 0);
    num_buckets_ = 0;
    bucket_table_ = NULL;
  }
  RAW_CHECK(MallocHook::RemoveMmapHook(&MmapHook), "");
  RAW_CHECK(MallocHook::RemoveMremapHook(&MremapHook), "");
  RAW_CHECK(MallocHook::RemoveSbrkHook(&SbrkHook), "");
  RAW_CHECK(MallocHook::RemoveMunmapHook(&MunmapHook), "");
  if (regions_) regions_->~RegionSet();
  regions_ = NULL;
  bool deleted_arena = LowLevelAlloc::DeleteArena(arena_);
  if (deleted_arena) {
    arena_ = 0;
  } else {
    RAW_LOG(WARNING, "Can't delete LowLevelAlloc arena: it's being used");
  }
  Unlock();
  RAW_VLOG(10, "MemoryRegionMap Shutdown done");
  return deleted_arena;
}

bool MemoryRegionMap::IsRecordingLocked() {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  return client_count_ > 0;
}

// Invariants (once libpthread_initialized is true):
//   * While lock_ is not held, recursion_count_ is 0 (and
//     lock_owner_tid_ is the previous owner, but we don't rely on
//     that).
//   * recursion_count_ and lock_owner_tid_ are only written while
//     both lock_ and owner_lock_ are held. They may be read under
//     just owner_lock_.
//   * At entry and exit of Lock() and Unlock(), the current thread
//     owns lock_ iff pthread_equal(lock_owner_tid_, pthread_self())
//     && recursion_count_ > 0.
void MemoryRegionMap::Lock() {
  {
    SpinLockHolder l(&owner_lock_);
    if (recursion_count_ > 0 && current_thread_is(lock_owner_tid_)) {
      RAW_CHECK(lock_.IsHeld(), "Invariants violated");
      recursion_count_++;
      RAW_CHECK(recursion_count_ <= 5,
                "recursive lock nesting unexpectedly deep");
      return;
    }
  }
  lock_.Lock();
  {
    SpinLockHolder l(&owner_lock_);
    RAW_CHECK(recursion_count_ == 0,
              "Last Unlock didn't reset recursion_count_");
    if (libpthread_initialized)
      lock_owner_tid_ = pthread_self();
    recursion_count_ = 1;
  }
}

void MemoryRegionMap::Unlock() {
  SpinLockHolder l(&owner_lock_);
  RAW_CHECK(recursion_count_ >  0, "unlock when not held");
  RAW_CHECK(lock_.IsHeld(),
            "unlock when not held, and recursion_count_ is wrong");
  RAW_CHECK(current_thread_is(lock_owner_tid_), "unlock by non-holder");
  recursion_count_--;
  if (recursion_count_ == 0) {
    lock_.Unlock();
  }
}

bool MemoryRegionMap::LockIsHeld() {
  SpinLockHolder l(&owner_lock_);
  return lock_.IsHeld()  &&  current_thread_is(lock_owner_tid_);
}

const MemoryRegionMap::Region*
MemoryRegionMap::DoFindRegionLocked(uintptr_t addr) {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  if (regions_ != NULL) {
    Region sample;
    sample.SetRegionSetKey(addr);
    RegionSet::iterator region = regions_->lower_bound(sample);
    if (region != regions_->end()) {
      RAW_CHECK(addr <= region->end_addr, "");
      if (region->start_addr <= addr  &&  addr < region->end_addr) {
        return &(*region);
      }
    }
  }
  return NULL;
}

bool MemoryRegionMap::FindRegion(uintptr_t addr, Region* result) {
  Lock();
  const Region* region = DoFindRegionLocked(addr);
  if (region != NULL) *result = *region;  // create it as an independent copy
  Unlock();
  return region != NULL;
}

bool MemoryRegionMap::FindAndMarkStackRegion(uintptr_t stack_top,
                                             Region* result) {
  Lock();
  const Region* region = DoFindRegionLocked(stack_top);
  if (region != NULL) {
    RAW_VLOG(10, "Stack at %p is inside region %p..%p",
                reinterpret_cast<void*>(stack_top),
                reinterpret_cast<void*>(region->start_addr),
                reinterpret_cast<void*>(region->end_addr));
    const_cast<Region*>(region)->set_is_stack();  // now we know
      // cast is safe (set_is_stack does not change the set ordering key)
    *result = *region;  // create *result as an independent copy
  }
  Unlock();
  return region != NULL;
}

HeapProfileBucket* MemoryRegionMap::GetBucket(int depth,
                                              const void* const key[]) {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  // Make hash-value
  uintptr_t hash = 0;
  for (int i = 0; i < depth; i++) {
    hash += reinterpret_cast<uintptr_t>(key[i]);
    hash += hash << 10;
    hash ^= hash >> 6;
  }
  hash += hash << 3;
  hash ^= hash >> 11;

  // Lookup stack trace in table
  unsigned int hash_index = (static_cast<unsigned int>(hash)) % kHashTableSize;
  for (HeapProfileBucket* bucket = bucket_table_[hash_index];
       bucket != 0;
       bucket = bucket->next) {
    if ((bucket->hash == hash) && (bucket->depth == depth) &&
        std::equal(key, key + depth, bucket->stack)) {
      return bucket;
    }
  }

  // Create new bucket
  const size_t key_size = sizeof(key[0]) * depth;
  HeapProfileBucket* bucket;
  if (recursive_insert) {  // recursion: save in saved_buckets_
    const void** key_copy = saved_buckets_keys_[saved_buckets_count_];
    std::copy(key, key + depth, key_copy);
    bucket = &saved_buckets_[saved_buckets_count_];
    memset(bucket, 0, sizeof(*bucket));
    ++saved_buckets_count_;
    bucket->stack = key_copy;
    bucket->next  = NULL;
  } else {
    recursive_insert = true;
    const void** key_copy = static_cast<const void**>(
        MyAllocator::Allocate(key_size));
    recursive_insert = false;
    std::copy(key, key + depth, key_copy);
    recursive_insert = true;
    bucket = static_cast<HeapProfileBucket*>(
        MyAllocator::Allocate(sizeof(HeapProfileBucket)));
    recursive_insert = false;
    memset(bucket, 0, sizeof(*bucket));
    bucket->stack = key_copy;
    bucket->next  = bucket_table_[hash_index];
  }
  bucket->hash = hash;
  bucket->depth = depth;
  bucket_table_[hash_index] = bucket;
  ++num_buckets_;
  return bucket;
}

MemoryRegionMap::RegionIterator MemoryRegionMap::BeginRegionLocked() {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  RAW_CHECK(regions_ != NULL, "");
  return regions_->begin();
}

MemoryRegionMap::RegionIterator MemoryRegionMap::EndRegionLocked() {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  RAW_CHECK(regions_ != NULL, "");
  return regions_->end();
}

inline void MemoryRegionMap::DoInsertRegionLocked(const Region& region) {
  RAW_VLOG(12, "Inserting region %p..%p from %p",
              reinterpret_cast<void*>(region.start_addr),
              reinterpret_cast<void*>(region.end_addr),
              reinterpret_cast<void*>(region.caller()));
  RegionSet::const_iterator i = regions_->lower_bound(region);
  if (i != regions_->end() && i->start_addr <= region.start_addr) {
    RAW_DCHECK(region.end_addr <= i->end_addr, "");  // lower_bound ensures this
    return;  // 'region' is a subset of an already recorded region; do nothing
    // We can be stricter and allow this only when *i has been created via
    // an mmap with MAP_NORESERVE flag set.
  }
  if (DEBUG_MODE) {
    RAW_CHECK(i == regions_->end()  ||  !region.Overlaps(*i),
              "Wow, overlapping memory regions");
    Region sample;
    sample.SetRegionSetKey(region.start_addr);
    i = regions_->lower_bound(sample);
    RAW_CHECK(i == regions_->end()  ||  !region.Overlaps(*i),
              "Wow, overlapping memory regions");
  }
  region.AssertIsConsistent();  // just making sure
  // This inserts and allocates permanent storage for region
  // and its call stack data: it's safe to do it now:
  regions_->insert(region);
  RAW_VLOG(12, "Inserted region %p..%p :",
              reinterpret_cast<void*>(region.start_addr),
              reinterpret_cast<void*>(region.end_addr));
  if (VLOG_IS_ON(12))  LogAllLocked();
}

// These variables are local to MemoryRegionMap::InsertRegionLocked()
// and MemoryRegionMap::HandleSavedRegionsLocked()
// and are file-level to ensure that they are initialized at load time.

// Number of unprocessed region inserts.
static int saved_regions_count = 0;

// Unprocessed inserts (must be big enough to hold all allocations that can
// be caused by a InsertRegionLocked call).
// Region has no constructor, so that c-tor execution does not interfere
// with the any-time use of the static memory behind saved_regions.
static MemoryRegionMap::Region saved_regions[20];

inline void MemoryRegionMap::HandleSavedRegionsLocked(
              void (*insert_func)(const Region& region)) {
  while (saved_regions_count > 0) {
    // Making a local-var copy of the region argument to insert_func
    // including its stack (w/o doing any memory allocations) is important:
    // in many cases the memory in saved_regions
    // will get written-to during the (*insert_func)(r) call below.
    Region r = saved_regions[--saved_regions_count];
    (*insert_func)(r);
  }
}

void MemoryRegionMap::RestoreSavedBucketsLocked() {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  while (saved_buckets_count_ > 0) {
    HeapProfileBucket bucket = saved_buckets_[--saved_buckets_count_];
    unsigned int hash_index =
        static_cast<unsigned int>(bucket.hash) % kHashTableSize;
    bool is_found = false;
    for (HeapProfileBucket* curr = bucket_table_[hash_index];
         curr != 0;
         curr = curr->next) {
      if ((curr->hash == bucket.hash) && (curr->depth == bucket.depth) &&
          std::equal(bucket.stack, bucket.stack + bucket.depth, curr->stack)) {
        curr->allocs += bucket.allocs;
        curr->alloc_size += bucket.alloc_size;
        curr->frees += bucket.frees;
        curr->free_size += bucket.free_size;
        is_found = true;
        break;
      }
    }
    if (is_found) continue;

    const size_t key_size = sizeof(bucket.stack[0]) * bucket.depth;
    const void** key_copy = static_cast<const void**>(
        MyAllocator::Allocate(key_size));
    std::copy(bucket.stack, bucket.stack + bucket.depth, key_copy);
    HeapProfileBucket* new_bucket = static_cast<HeapProfileBucket*>(
        MyAllocator::Allocate(sizeof(HeapProfileBucket)));
    memset(new_bucket, 0, sizeof(*new_bucket));
    new_bucket->hash = bucket.hash;
    new_bucket->depth = bucket.depth;
    new_bucket->stack = key_copy;
    new_bucket->next = bucket_table_[hash_index];
    bucket_table_[hash_index] = new_bucket;
    ++num_buckets_;
  }
}

inline void MemoryRegionMap::InitRegionSetLocked() {
  RAW_VLOG(12, "Initializing region set");
  regions_ = regions_rep.region_set();
  recursive_insert = true;
  new(regions_) RegionSet();
  HandleSavedRegionsLocked(&DoInsertRegionLocked);
  recursive_insert = false;
}

inline void MemoryRegionMap::InsertRegionLocked(const Region& region) {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  // We can be called recursively, because RegionSet constructor
  // and DoInsertRegionLocked() (called below) can call the allocator.
  // recursive_insert tells us if that's the case. When this happens,
  // region insertion information is recorded in saved_regions[],
  // and taken into account when the recursion unwinds.
  // Do the insert:
  if (recursive_insert) {  // recursion: save in saved_regions
    RAW_VLOG(12, "Saving recursive insert of region %p..%p from %p",
                reinterpret_cast<void*>(region.start_addr),
                reinterpret_cast<void*>(region.end_addr),
                reinterpret_cast<void*>(region.caller()));
    RAW_CHECK(saved_regions_count < arraysize(saved_regions), "");
    // Copy 'region' to saved_regions[saved_regions_count]
    // together with the contents of its call_stack,
    // then increment saved_regions_count.
    saved_regions[saved_regions_count++] = region;
  } else {  // not a recusrive call
    if (regions_ == NULL)  // init regions_
      InitRegionSetLocked();
    recursive_insert = true;
    // Do the actual insertion work to put new regions into regions_:
    DoInsertRegionLocked(region);
    HandleSavedRegionsLocked(&DoInsertRegionLocked);
    recursive_insert = false;
  }
}

// We strip out different number of stack frames in debug mode
// because less inlining happens in that case
#ifdef NDEBUG
static const int kStripFrames = 1;
#else
static const int kStripFrames = 3;
#endif

void MemoryRegionMap::RecordRegionAddition(const void* start, size_t size) {
  // Record start/end info about this memory acquisition call in a new region:
  Region region;
  region.Create(start, size);
  // First get the call stack info into the local varible 'region':
  const int depth =
    max_stack_depth_ > 0
    ? MallocHook::GetCallerStackTrace(const_cast<void**>(region.call_stack),
                                      max_stack_depth_, kStripFrames + 1)
    : 0;
  region.set_call_stack_depth(depth);  // record stack info fully
  RAW_VLOG(10, "New global region %p..%p from %p",
              reinterpret_cast<void*>(region.start_addr),
              reinterpret_cast<void*>(region.end_addr),
              reinterpret_cast<void*>(region.caller()));
  // Note: none of the above allocates memory.
  Lock();  // recursively lock
  map_size_ += size;
  InsertRegionLocked(region);
    // This will (eventually) allocate storage for and copy over the stack data
    // from region.call_stack_data_ that is pointed by region.call_stack().
  if (bucket_table_ != NULL) {
    HeapProfileBucket* b = GetBucket(depth, region.call_stack);
    ++b->allocs;
    b->alloc_size += size;
    if (!recursive_insert) {
      recursive_insert = true;
      RestoreSavedBucketsLocked();
      recursive_insert = false;
    }
  }
  Unlock();
}

void MemoryRegionMap::RecordRegionRemoval(const void* start, size_t size) {
  Lock();
  if (recursive_insert) {
    // First remove the removed region from saved_regions, if it's
    // there, to prevent overrunning saved_regions in recursive
    // map/unmap call sequences, and also from later inserting regions
    // which have already been unmapped.
    uintptr_t start_addr = reinterpret_cast<uintptr_t>(start);
    uintptr_t end_addr = start_addr + size;
    int put_pos = 0;
    int old_count = saved_regions_count;
    for (int i = 0; i < old_count; ++i, ++put_pos) {
      Region& r = saved_regions[i];
      if (r.start_addr == start_addr && r.end_addr == end_addr) {
        // An exact match, so it's safe to remove.
        RecordRegionRemovalInBucket(r.call_stack_depth, r.call_stack, size);
        --saved_regions_count;
        --put_pos;
        RAW_VLOG(10, ("Insta-Removing saved region %p..%p; "
                     "now have %d saved regions"),
                 reinterpret_cast<void*>(start_addr),
                 reinterpret_cast<void*>(end_addr),
                 saved_regions_count);
      } else {
        if (put_pos < i) {
          saved_regions[put_pos] = saved_regions[i];
        }
      }
    }
  }
  if (regions_ == NULL) {  // We must have just unset the hooks,
                           // but this thread was already inside the hook.
    Unlock();
    return;
  }
  if (!recursive_insert) {
    HandleSavedRegionsLocked(&InsertRegionLocked);
  }
    // first handle adding saved regions if any
  uintptr_t start_addr = reinterpret_cast<uintptr_t>(start);
  uintptr_t end_addr = start_addr + size;
  // subtract start_addr, end_addr from all the regions
  RAW_VLOG(10, "Removing global region %p..%p; have %" PRIuS " regions",
              reinterpret_cast<void*>(start_addr),
              reinterpret_cast<void*>(end_addr),
              regions_->size());
  Region sample;
  sample.SetRegionSetKey(start_addr);
  // Only iterate over the regions that might overlap start_addr..end_addr:
  for (RegionSet::iterator region = regions_->lower_bound(sample);
       region != regions_->end()  &&  region->start_addr < end_addr;
       /*noop*/) {
    RAW_VLOG(13, "Looking at region %p..%p",
                reinterpret_cast<void*>(region->start_addr),
                reinterpret_cast<void*>(region->end_addr));
    if (start_addr <= region->start_addr  &&
        region->end_addr <= end_addr) {  // full deletion
      RAW_VLOG(12, "Deleting region %p..%p",
                  reinterpret_cast<void*>(region->start_addr),
                  reinterpret_cast<void*>(region->end_addr));
      RecordRegionRemovalInBucket(region->call_stack_depth, region->call_stack,
                                  region->end_addr - region->start_addr);
      RegionSet::iterator d = region;
      ++region;
      regions_->erase(d);
      continue;
    } else if (region->start_addr < start_addr  &&
               end_addr < region->end_addr) {  // cutting-out split
      RAW_VLOG(12, "Splitting region %p..%p in two",
                  reinterpret_cast<void*>(region->start_addr),
                  reinterpret_cast<void*>(region->end_addr));
      RecordRegionRemovalInBucket(region->call_stack_depth, region->call_stack,
                                  end_addr - start_addr);
      // Make another region for the start portion:
      // The new region has to be the start portion because we can't
      // just modify region->end_addr as it's the sorting key.
      Region r = *region;
      r.set_end_addr(start_addr);
      InsertRegionLocked(r);
      // cut *region from start:
      const_cast<Region&>(*region).set_start_addr(end_addr);
    } else if (end_addr > region->start_addr  &&
               start_addr <= region->start_addr) {  // cut from start
      RAW_VLOG(12, "Start-chopping region %p..%p",
                  reinterpret_cast<void*>(region->start_addr),
                  reinterpret_cast<void*>(region->end_addr));
      RecordRegionRemovalInBucket(region->call_stack_depth, region->call_stack,
                                  end_addr - region->start_addr);
      const_cast<Region&>(*region).set_start_addr(end_addr);
    } else if (start_addr > region->start_addr  &&
               start_addr < region->end_addr) {  // cut from end
      RAW_VLOG(12, "End-chopping region %p..%p",
                  reinterpret_cast<void*>(region->start_addr),
                  reinterpret_cast<void*>(region->end_addr));
      RecordRegionRemovalInBucket(region->call_stack_depth, region->call_stack,
                                  region->end_addr - start_addr);
      // Can't just modify region->end_addr (it's the sorting key):
      Region r = *region;
      r.set_end_addr(start_addr);
      RegionSet::iterator d = region;
      ++region;
      // It's safe to erase before inserting since r is independent of *d:
      // r contains an own copy of the call stack:
      regions_->erase(d);
      InsertRegionLocked(r);
      continue;
    }
    ++region;
  }
  RAW_VLOG(12, "Removed region %p..%p; have %" PRIuS " regions",
              reinterpret_cast<void*>(start_addr),
              reinterpret_cast<void*>(end_addr),
              regions_->size());
  if (VLOG_IS_ON(12))  LogAllLocked();
  unmap_size_ += size;
  Unlock();
}

void MemoryRegionMap::RecordRegionRemovalInBucket(int depth,
                                                  const void* const stack[],
                                                  size_t size) {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  if (bucket_table_ == NULL) return;
  HeapProfileBucket* b = GetBucket(depth, stack);
  ++b->frees;
  b->free_size += size;
}

void MemoryRegionMap::MmapHook(const void* result,
                               const void* start, size_t size,
                               int prot, int flags,
                               int fd, off_t offset) {
  // TODO(maxim): replace all 0x%"PRIxS" by %p when RAW_VLOG uses a safe
  // snprintf reimplementation that does not malloc to pretty-print NULL
  RAW_VLOG(10, "MMap = 0x%" PRIxPTR " of %" PRIuS " at %" PRIu64 " "
              "prot %d flags %d fd %d offs %" PRId64,
              reinterpret_cast<uintptr_t>(result), size,
              reinterpret_cast<uint64>(start), prot, flags, fd,
              static_cast<int64>(offset));
  if (result != reinterpret_cast<void*>(MAP_FAILED)  &&  size != 0) {
    RecordRegionAddition(result, size);
  }
}

void MemoryRegionMap::MunmapHook(const void* ptr, size_t size) {
  RAW_VLOG(10, "MUnmap of %p %" PRIuS, ptr, size);
  if (size != 0) {
    RecordRegionRemoval(ptr, size);
  }
}

void MemoryRegionMap::MremapHook(const void* result,
                                 const void* old_addr, size_t old_size,
                                 size_t new_size, int flags,
                                 const void* new_addr) {
  RAW_VLOG(10, "MRemap = 0x%" PRIxPTR " of 0x%" PRIxPTR " %" PRIuS " "
              "to %" PRIuS " flags %d new_addr=0x%" PRIxPTR,
              (uintptr_t)result, (uintptr_t)old_addr,
               old_size, new_size, flags,
               flags & MREMAP_FIXED ? (uintptr_t)new_addr : 0);
  if (result != reinterpret_cast<void*>(-1)) {
    RecordRegionRemoval(old_addr, old_size);
    RecordRegionAddition(result, new_size);
  }
}

extern "C" void* __sbrk(ptrdiff_t increment);  // defined in libc

void MemoryRegionMap::SbrkHook(const void* result, ptrdiff_t increment) {
  RAW_VLOG(10, "Sbrk = 0x%" PRIxPTR " of %" PRIdS,
           (uintptr_t)result, increment);
  if (result != reinterpret_cast<void*>(-1)) {
    if (increment > 0) {
      void* new_end = sbrk(0);
      RecordRegionAddition(result, reinterpret_cast<uintptr_t>(new_end) -
                                   reinterpret_cast<uintptr_t>(result));
    } else if (increment < 0) {
      void* new_end = sbrk(0);
      RecordRegionRemoval(new_end, reinterpret_cast<uintptr_t>(result) -
                                   reinterpret_cast<uintptr_t>(new_end));
    }
  }
}

void MemoryRegionMap::LogAllLocked() {
  RAW_CHECK(LockIsHeld(), "should be held (by this thread)");
  RAW_LOG(INFO, "List of regions:");
  uintptr_t previous = 0;
  for (RegionSet::const_iterator r = regions_->begin();
       r != regions_->end(); ++r) {
    RAW_LOG(INFO, "Memory region 0x%" PRIxPTR "..0x%" PRIxPTR " "
                  "from 0x%" PRIxPTR " stack=%d",
                  r->start_addr, r->end_addr, r->caller(), r->is_stack);
    RAW_CHECK(previous < r->end_addr, "wow, we messed up the set order");
      // this must be caused by uncontrolled recursive operations on regions_
    previous = r->end_addr;
  }
  RAW_LOG(INFO, "End of regions list");
}
