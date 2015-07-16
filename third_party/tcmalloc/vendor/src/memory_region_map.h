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

#ifndef BASE_MEMORY_REGION_MAP_H_
#define BASE_MEMORY_REGION_MAP_H_

#include <config.h>

#ifdef HAVE_PTHREAD
#include <pthread.h>
#endif
#include <stddef.h>
#include <set>
#include "base/stl_allocator.h"
#include "base/spinlock.h"
#include "base/thread_annotations.h"
#include "base/low_level_alloc.h"

// TODO(maxim): add a unittest:
//  execute a bunch of mmaps and compare memory map what strace logs
//  execute a bunch of mmap/munmup and compare memory map with
//  own accounting of what those mmaps generated

// Thread-safe class to collect and query the map of all memory regions
// in a process that have been created with mmap, munmap, mremap, sbrk.
// For each memory region, we keep track of (and provide to users)
// the stack trace that allocated that memory region.
// The recorded stack trace depth is bounded by
// a user-supplied max_stack_depth parameter of Init().
// After initialization with Init()
// (which can happened even before global object constructor execution)
// we collect the map by installing and monitoring MallocHook-s
// to mmap, munmap, mremap, sbrk.
// At any time one can query this map via provided interface.
// For more details on the design of MemoryRegionMap
// see the comment at the top of our .cc file.
class MemoryRegionMap {
 private:
  // Max call stack recording depth supported by Init().  Set it to be
  // high enough for all our clients.  Note: we do not define storage
  // for this (doing that requires special handling in windows), so
  // don't take the address of it!
  static const int kMaxStackDepth = 32;

 public:
  // interface ================================================================

  // Every client of MemoryRegionMap must call Init() before first use,
  // and Shutdown() after last use.  This allows us to reference count
  // this (singleton) class properly.  MemoryRegionMap assumes it's the
  // only client of MallocHooks, so a client can only register other
  // MallocHooks after calling Init() and must unregister them before
  // calling Shutdown().

  // Initialize this module to record memory allocation stack traces.
  // Stack traces that have more than "max_stack_depth" frames
  // are automatically shrunk to "max_stack_depth" when they are recorded.
  // Init() can be called more than once w/o harm, largest max_stack_depth
  // will be the effective one.
  // It will install mmap, munmap, mremap, sbrk hooks
  // and initialize arena_ and our hook and locks, hence one can use
  // MemoryRegionMap::Lock()/Unlock() to manage the locks.
  // Uses Lock/Unlock inside.
  static void Init(int max_stack_depth);

  // Try to shutdown this module undoing what Init() did.
  // Returns true iff could do full shutdown (or it was not attempted).
  // Full shutdown is attempted when the number of Shutdown() calls equals
  // the number of Init() calls.
  static bool Shutdown();

  // Locks to protect our internal data structures.
  // These also protect use of arena_ if our Init() has been done.
  // The lock is recursive.
  static void Lock() EXCLUSIVE_LOCK_FUNCTION(lock_);
  static void Unlock() UNLOCK_FUNCTION(lock_);

  // Returns true when the lock is held by this thread (for use in RAW_CHECK-s).
  static bool LockIsHeld();

  // Locker object that acquires the MemoryRegionMap::Lock
  // for the duration of its lifetime (a C++ scope).
  class LockHolder {
   public:
    LockHolder() { Lock(); }
    ~LockHolder() { Unlock(); }
   private:
    DISALLOW_COPY_AND_ASSIGN(LockHolder);
  };

  // A memory region that we know about through malloc_hook-s.
  // This is essentially an interface through which MemoryRegionMap
  // exports the collected data to its clients.  Thread-compatible.
  struct Region {
    uintptr_t start_addr;  // region start address
    uintptr_t end_addr;  // region end address
    int call_stack_depth;  // number of caller stack frames that we saved
    const void* call_stack[kMaxStackDepth];  // caller address stack array
                                             // filled to call_stack_depth size
    bool is_stack;  // does this region contain a thread's stack:
                    // a user of MemoryRegionMap supplies this info

    // Convenience accessor for call_stack[0],
    // i.e. (the program counter of) the immediate caller
    // of this region's allocation function,
    // but it also returns NULL when call_stack_depth is 0,
    // i.e whe we weren't able to get the call stack.
    // This usually happens in recursive calls, when the stack-unwinder
    // calls mmap() which in turn calls the stack-unwinder.
    uintptr_t caller() const {
      return reinterpret_cast<uintptr_t>(call_stack_depth >= 1
                                         ? call_stack[0] : NULL);
    }

    // Return true iff this region overlaps region x.
    bool Overlaps(const Region& x) const {
      return start_addr < x.end_addr  &&  end_addr > x.start_addr;
    }

   private:  // helpers for MemoryRegionMap
    friend class MemoryRegionMap;

    // The ways we create Region-s:
    void Create(const void* start, size_t size) {
      start_addr = reinterpret_cast<uintptr_t>(start);
      end_addr = start_addr + size;
      is_stack = false;  // not a stack till marked such
      call_stack_depth = 0;
      AssertIsConsistent();
    }
    void set_call_stack_depth(int depth) {
      RAW_DCHECK(call_stack_depth == 0, "");  // only one such set is allowed
      call_stack_depth = depth;
      AssertIsConsistent();
    }

    // The ways we modify Region-s:
    void set_is_stack() { is_stack = true; }
    void set_start_addr(uintptr_t addr) {
      start_addr = addr;
      AssertIsConsistent();
    }
    void set_end_addr(uintptr_t addr) {
      end_addr = addr;
      AssertIsConsistent();
    }

    // Verifies that *this contains consistent data, crashes if not the case.
    void AssertIsConsistent() const {
      RAW_DCHECK(start_addr < end_addr, "");
      RAW_DCHECK(call_stack_depth >= 0  &&
                 call_stack_depth <= kMaxStackDepth, "");
    }

    // Post-default construction helper to make a Region suitable
    // for searching in RegionSet regions_.
    void SetRegionSetKey(uintptr_t addr) {
      // make sure *this has no usable data:
      if (DEBUG_MODE) memset(this, 0xFF, sizeof(*this));
      end_addr = addr;
    }

    // Note: call_stack[kMaxStackDepth] as a member lets us make Region
    // a simple self-contained struct with correctly behaving bit-vise copying.
    // This simplifies the code of this module but wastes some memory:
    // in most-often use case of this module (leak checking)
    // only one call_stack element out of kMaxStackDepth is actually needed.
    // Making the storage for call_stack variable-sized,
    // substantially complicates memory management for the Region-s:
    // as they need to be created and manipulated for some time
    // w/o any memory allocations, yet are also given out to the users.
  };

  // Find the region that covers addr and write its data into *result if found,
  // in which case *result gets filled so that it stays fully functional
  // even when the underlying region gets removed from MemoryRegionMap.
  // Returns success. Uses Lock/Unlock inside.
  static bool FindRegion(uintptr_t addr, Region* result);

  // Find the region that contains stack_top, mark that region as
  // a stack region, and write its data into *result if found,
  // in which case *result gets filled so that it stays fully functional
  // even when the underlying region gets removed from MemoryRegionMap.
  // Returns success. Uses Lock/Unlock inside.
  static bool FindAndMarkStackRegion(uintptr_t stack_top, Region* result);

 private:  // our internal types ==============================================

  // Region comparator for sorting with STL
  struct RegionCmp {
    bool operator()(const Region& x, const Region& y) const {
      return x.end_addr < y.end_addr;
    }
  };

  // We allocate STL objects in our own arena.
  struct MyAllocator {
    static void *Allocate(size_t n) {
      return LowLevelAlloc::AllocWithArena(n, arena_);
    }
    static void Free(const void *p, size_t /* n */) {
      LowLevelAlloc::Free(const_cast<void*>(p));
    }
  };

  // Set of the memory regions
  typedef std::set<Region, RegionCmp,
              STL_Allocator<Region, MyAllocator> > RegionSet;

 public:  // more in-depth interface ==========================================

  // STL iterator with values of Region
  typedef RegionSet::const_iterator RegionIterator;

  // Return the begin/end iterators to all the regions.
  // These need Lock/Unlock protection around their whole usage (loop).
  // Even when the same thread causes modifications during such a loop
  // (which are permitted due to recursive locking)
  // the loop iterator will still be valid as long as its region
  // has not been deleted, but EndRegionLocked should be
  // re-evaluated whenever the set of regions has changed.
  static RegionIterator BeginRegionLocked();
  static RegionIterator EndRegionLocked();

  // Return the accumulated sizes of mapped and unmapped regions.
  static int64 MapSize() { return map_size_; }
  static int64 UnmapSize() { return unmap_size_; }

  // Effectively private type from our .cc =================================
  // public to let us declare global objects:
  union RegionSetRep;

 private:
  // representation ===========================================================

  // Counter of clients of this module that have called Init().
  static int client_count_;

  // Maximal number of caller stack frames to save (>= 0).
  static int max_stack_depth_;

  // Arena used for our allocations in regions_.
  static LowLevelAlloc::Arena* arena_;

  // Set of the mmap/sbrk/mremap-ed memory regions
  // To be accessed *only* when Lock() is held.
  // Hence we protect the non-recursive lock used inside of arena_
  // with our recursive Lock(). This lets a user prevent deadlocks
  // when threads are stopped by ListAllProcessThreads at random spots
  // simply by acquiring our recursive Lock() before that.
  static RegionSet* regions_;

  // Lock to protect regions_ variable and the data behind.
  static SpinLock lock_;
  // Lock to protect the recursive lock itself.
  static SpinLock owner_lock_;

  // Recursion count for the recursive lock.
  static int recursion_count_;
  // The thread id of the thread that's inside the recursive lock.
  static pthread_t lock_owner_tid_;

  // Total size of all mapped pages so far
  static int64 map_size_;
  // Total size of all unmapped pages so far
  static int64 unmap_size_;

  // helpers ==================================================================

  // Helper for FindRegion and FindAndMarkStackRegion:
  // returns the region covering 'addr' or NULL; assumes our lock_ is held.
  static const Region* DoFindRegionLocked(uintptr_t addr);

  // Verifying wrapper around regions_->insert(region)
  // To be called to do InsertRegionLocked's work only!
  inline static void DoInsertRegionLocked(const Region& region);
  // Handle regions saved by InsertRegionLocked into a tmp static array
  // by calling insert_func on them.
  inline static void HandleSavedRegionsLocked(
                       void (*insert_func)(const Region& region));
  // Wrapper around DoInsertRegionLocked
  // that handles the case of recursive allocator calls.
  inline static void InsertRegionLocked(const Region& region);

  // Record addition of a memory region at address "start" of size "size"
  // (called from our mmap/mremap/sbrk hooks).
  static void RecordRegionAddition(const void* start, size_t size);
  // Record deletion of a memory region at address "start" of size "size"
  // (called from our munmap/mremap/sbrk hooks).
  static void RecordRegionRemoval(const void* start, size_t size);

  // Hooks for MallocHook
  static void MmapHook(const void* result,
                       const void* start, size_t size,
                       int prot, int flags,
                       int fd, off_t offset);
  static void MunmapHook(const void* ptr, size_t size);
  static void MremapHook(const void* result, const void* old_addr,
                         size_t old_size, size_t new_size, int flags,
                         const void* new_addr);
  static void SbrkHook(const void* result, ptrdiff_t increment);

  // Log all memory regions; Useful for debugging only.
  // Assumes Lock() is held
  static void LogAllLocked();

  DISALLOW_COPY_AND_ASSIGN(MemoryRegionMap);
};

#endif  // BASE_MEMORY_REGION_MAP_H_
