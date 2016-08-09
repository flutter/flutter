// Copyright (c) 2006, Google Inc.
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
// Author: Sanjay Ghemawat
//         Maxim Lifantsev (refactoring)
//

#ifndef BASE_HEAP_PROFILE_TABLE_H_
#define BASE_HEAP_PROFILE_TABLE_H_

#include "addressmap-inl.h"
#include "base/basictypes.h"
#include "base/logging.h"   // for RawFD

// Table to maintain a heap profile data inside,
// i.e. the set of currently active heap memory allocations.
// thread-unsafe and non-reentrant code:
// each instance object must be used by one thread
// at a time w/o self-recursion.
//
// TODO(maxim): add a unittest for this class.
class HeapProfileTable {
 public:

  // Extension to be used for heap pforile files.
  static const char kFileExt[];

  // Longest stack trace we record.
  static const int kMaxStackDepth = 32;

  // data types ----------------------------

  // Profile stats.
  struct Stats {
    int32 allocs;      // Number of allocation calls
    int32 frees;       // Number of free calls
    int64 alloc_size;  // Total size of all allocated objects so far
    int64 free_size;   // Total size of all freed objects so far

    // semantic equality
    bool Equivalent(const Stats& x) const {
      return allocs - frees == x.allocs - x.frees  &&
             alloc_size - free_size == x.alloc_size - x.free_size;
    }
  };

  // Info we can return about an allocation.
  struct AllocInfo {
    size_t object_size;  // size of the allocation
    const void* const* call_stack;  // call stack that made the allocation call
    int stack_depth;  // depth of call_stack
    bool live;
    bool ignored;
  };

  // Info we return about an allocation context.
  // An allocation context is a unique caller stack trace
  // of an allocation operation.
  struct AllocContextInfo : public Stats {
    int stack_depth;                // Depth of stack trace
    const void* const* call_stack;  // Stack trace
  };

  // Memory (de)allocator interface we'll use.
  typedef void* (*Allocator)(size_t size);
  typedef void  (*DeAllocator)(void* ptr);

  // interface ---------------------------

  HeapProfileTable(Allocator alloc, DeAllocator dealloc);
  ~HeapProfileTable();

  // Collect the stack trace for the function that asked to do the
  // allocation for passing to RecordAlloc() below.
  //
  // The stack trace is stored in 'stack'. The stack depth is returned.
  //
  // 'skip_count' gives the number of stack frames between this call
  // and the memory allocation function.
  static int GetCallerStackTrace(int skip_count, void* stack[kMaxStackDepth]);

  // Record an allocation at 'ptr' of 'bytes' bytes.  'stack_depth'
  // and 'call_stack' identifying the function that requested the
  // allocation. They can be generated using GetCallerStackTrace() above.
  void RecordAlloc(const void* ptr, size_t bytes,
                   int stack_depth, const void* const call_stack[]);

  // Record the deallocation of memory at 'ptr'.
  void RecordFree(const void* ptr);

  // Return true iff we have recorded an allocation at 'ptr'.
  // If yes, fill *object_size with the allocation byte size.
  bool FindAlloc(const void* ptr, size_t* object_size) const;
  // Same as FindAlloc, but fills all of *info.
  bool FindAllocDetails(const void* ptr, AllocInfo* info) const;

  // Return true iff "ptr" points into a recorded allocation
  // If yes, fill *object_ptr with the actual allocation address
  // and *object_size with the allocation byte size.
  // max_size specifies largest currently possible allocation size.
  bool FindInsideAlloc(const void* ptr, size_t max_size,
                       const void** object_ptr, size_t* object_size) const;

  // If "ptr" points to a recorded allocation and it's not marked as live
  // mark it as live and return true. Else return false.
  // All allocations start as non-live.
  bool MarkAsLive(const void* ptr);

  // If "ptr" points to a recorded allocation, mark it as "ignored".
  // Ignored objects are treated like other objects, except that they
  // are skipped in heap checking reports.
  void MarkAsIgnored(const void* ptr);

  // Return current total (de)allocation statistics.  It doesn't contain
  // mmap'ed regions.
  const Stats& total() const { return total_; }

  // Allocation data iteration callback: gets passed object pointer and
  // fully-filled AllocInfo.
  typedef void (*AllocIterator)(const void* ptr, const AllocInfo& info);

  // Iterate over the allocation profile data calling "callback"
  // for every allocation.
  void IterateAllocs(AllocIterator callback) const {
    alloc_address_map_->Iterate(MapArgsAllocIterator, callback);
  }

  // Allocation context profile data iteration callback
  typedef void (*AllocContextIterator)(const AllocContextInfo& info);

  // Iterate over the allocation context profile data calling "callback"
  // for every allocation context. Allocation contexts are ordered by the
  // size of allocated space.
  void IterateOrderedAllocContexts(AllocContextIterator callback) const;

  // Fill profile data into buffer 'buf' of size 'size'
  // and return the actual size occupied by the dump in 'buf'.
  // The profile buckets are dumped in the decreasing order
  // of currently allocated bytes.
  // We do not provision for 0-terminating 'buf'.
  int FillOrderedProfile(char buf[], int size) const;

  // Cleanup any old profile files matching prefix + ".*" + kFileExt.
  static void CleanupOldProfiles(const char* prefix);

  // Return a snapshot of the current contents of *this.
  // Caller must call ReleaseSnapshot() on result when no longer needed.
  // The result is only valid while this exists and until
  // the snapshot is discarded by calling ReleaseSnapshot().
  class Snapshot;
  Snapshot* TakeSnapshot();

  // Release a previously taken snapshot.  snapshot must not
  // be used after this call.
  void ReleaseSnapshot(Snapshot* snapshot);

  // Return a snapshot of every non-live, non-ignored object in *this.
  // If "base" is non-NULL, skip any objects present in "base".
  // As a side-effect, clears the "live" bit on every live object in *this.
  // Caller must call ReleaseSnapshot() on result when no longer needed.
  Snapshot* NonLiveSnapshot(Snapshot* base);

  // Refresh the internal mmap information from MemoryRegionMap.  Results of
  // FillOrderedProfile and IterateOrderedAllocContexts will contain mmap'ed
  // memory regions as at calling RefreshMMapData.
  void RefreshMMapData();

  // Clear the internal mmap information.  Results of FillOrderedProfile and
  // IterateOrderedAllocContexts won't contain mmap'ed memory regions after
  // calling ClearMMapData.
  void ClearMMapData();

 private:

  // data types ----------------------------

  // Hash table bucket to hold (de)allocation stats
  // for a given allocation call stack trace.
  struct Bucket : public Stats {
    uintptr_t    hash;   // Hash value of the stack trace
    int          depth;  // Depth of stack trace
    const void** stack;  // Stack trace
    Bucket*      next;   // Next entry in hash-table
  };

  // Info stored in the address map
  struct AllocValue {
    // Access to the stack-trace bucket
    Bucket* bucket() const {
      return reinterpret_cast<Bucket*>(bucket_rep & ~uintptr_t(kMask));
    }
    // This also does set_live(false).
    void set_bucket(Bucket* b) { bucket_rep = reinterpret_cast<uintptr_t>(b); }
    size_t  bytes;   // Number of bytes in this allocation

    // Access to the allocation liveness flag (for leak checking)
    bool live() const { return bucket_rep & kLive; }
    void set_live(bool l) {
      bucket_rep = (bucket_rep & ~uintptr_t(kLive)) | (l ? kLive : 0);
    }

    // Should this allocation be ignored if it looks like a leak?
    bool ignore() const { return bucket_rep & kIgnore; }
    void set_ignore(bool r) {
      bucket_rep = (bucket_rep & ~uintptr_t(kIgnore)) | (r ? kIgnore : 0);
    }

   private:
    // We store a few bits in the bottom bits of bucket_rep.
    // (Alignment is at least four, so we have at least two bits.)
    static const int kLive = 1;
    static const int kIgnore = 2;
    static const int kMask = kLive | kIgnore;

    uintptr_t bucket_rep;
  };

  // helper for FindInsideAlloc
  static size_t AllocValueSize(const AllocValue& v) { return v.bytes; }

  typedef AddressMap<AllocValue> AllocationMap;

  // Arguments that need to be passed DumpNonLiveIterator callback below.
  struct DumpArgs {
    RawFD fd;  // file to write to
    Stats* profile_stats;  // stats to update (may be NULL)

    DumpArgs(RawFD a, Stats* d)
      : fd(a), profile_stats(d) { }
  };

  // helpers ----------------------------

  // Unparse bucket b and print its portion of profile dump into buf.
  // We return the amount of space in buf that we use.  We start printing
  // at buf + buflen, and promise not to go beyond buf + bufsize.
  // We do not provision for 0-terminating 'buf'.
  //
  // If profile_stats is non-NULL, we update *profile_stats by
  // counting bucket b.
  //
  // "extra" is appended to the unparsed bucket.  Typically it is empty,
  // but may be set to something like " heapprofile" for the total
  // bucket to indicate the type of the profile.
  static int UnparseBucket(const Bucket& b,
                           char* buf, int buflen, int bufsize,
                           const char* extra,
                           Stats* profile_stats);

  // Deallocate a given allocation map.
  void DeallocateAllocationMap(AllocationMap* allocation);

  // Deallocate a given bucket table.
  void DeallocateBucketTable(Bucket** table);

  // Get the bucket for the caller stack trace 'key' of depth 'depth' from a
  // bucket hash map 'table' creating the bucket if needed.  '*bucket_count'
  // is incremented both when 'bucket_count' is not NULL and when a new
  // bucket object is created.
  Bucket* GetBucket(int depth, const void* const key[], Bucket** table,
                    int* bucket_count);

  // Helper for IterateAllocs to do callback signature conversion
  // from AllocationMap::Iterate to AllocIterator.
  static void MapArgsAllocIterator(const void* ptr, AllocValue* v,
                                   AllocIterator callback) {
    AllocInfo info;
    info.object_size = v->bytes;
    info.call_stack = v->bucket()->stack;
    info.stack_depth = v->bucket()->depth;
    info.live = v->live();
    info.ignored = v->ignore();
    callback(ptr, info);
  }

  // Helper for DumpNonLiveProfile to do object-granularity
  // heap profile dumping. It gets passed to AllocationMap::Iterate.
  inline static void DumpNonLiveIterator(const void* ptr, AllocValue* v,
                                         const DumpArgs& args);

  // Helper for filling size variables in buckets by zero.
  inline static void ZeroBucketCountsIterator(
      const void* ptr, AllocValue* v, HeapProfileTable* heap_profile);

  // Helper for IterateOrderedAllocContexts and FillOrderedProfile.
  // Creates a sorted list of Buckets whose length is num_alloc_buckets_ +
  // num_avaliable_mmap_buckets_.
  // The caller is responsible for deallocating the returned list.
  Bucket** MakeSortedBucketList() const;

  // Helper for TakeSnapshot.  Saves object to snapshot.
  static void AddToSnapshot(const void* ptr, AllocValue* v, Snapshot* s);

  // Arguments passed to AddIfNonLive
  struct AddNonLiveArgs {
    Snapshot* dest;
    Snapshot* base;
  };

  // Helper for NonLiveSnapshot.  Adds the object to the destination
  // snapshot if it is non-live.
  static void AddIfNonLive(const void* ptr, AllocValue* v,
                           AddNonLiveArgs* arg);

  // Write contents of "*allocations" as a heap profile to
  // "file_name".  "total" must contain the total of all entries in
  // "*allocations".
  static bool WriteProfile(const char* file_name,
                           const Bucket& total,
                           AllocationMap* allocations);

  // data ----------------------------

  // Memory (de)allocator that we use.
  Allocator alloc_;
  DeAllocator dealloc_;

  // Overall profile stats; we use only the Stats part,
  // but make it a Bucket to pass to UnparseBucket.
  // It doesn't contain mmap'ed regions.
  Bucket total_;

  // Bucket hash table for malloc.
  // We hand-craft one instead of using one of the pre-written
  // ones because we do not want to use malloc when operating on the table.
  // It is only few lines of code, so no big deal.
  Bucket** alloc_table_;
  int num_alloc_buckets_;

  // Bucket hash table for mmap.
  // This table is filled with the information from MemoryRegionMap by calling
  // RefreshMMapData.
  Bucket** mmap_table_;
  int num_available_mmap_buckets_;

  // Map of all currently allocated objects and mapped regions we know about.
  AllocationMap* alloc_address_map_;
  AllocationMap* mmap_address_map_;

  DISALLOW_COPY_AND_ASSIGN(HeapProfileTable);
};

class HeapProfileTable::Snapshot {
 public:
  const Stats& total() const { return total_; }

  // Report anything in this snapshot as a leak.
  // May use new/delete for temporary storage.
  // If should_symbolize is true, will fork (which is not threadsafe)
  // to turn addresses into symbol names.  Set to false for maximum safety.
  // Also writes a heap profile to "filename" that contains
  // all of the objects in this snapshot.
  void ReportLeaks(const char* checker_name, const char* filename,
                   bool should_symbolize);

  // Report the addresses of all leaked objects.
  // May use new/delete for temporary storage.
  void ReportIndividualObjects();

  bool Empty() const {
    return (total_.allocs == 0) && (total_.alloc_size == 0);
  }

 private:
  friend class HeapProfileTable;

  // Total count/size are stored in a Bucket so we can reuse UnparseBucket
  Bucket total_;

  // We share the Buckets managed by the parent table, but have our
  // own object->bucket map.
  AllocationMap map_;

  Snapshot(Allocator alloc, DeAllocator dealloc) : map_(alloc, dealloc) {
    memset(&total_, 0, sizeof(total_));
  }

  // Callback used to populate a Snapshot object with entries found
  // in another allocation map.
  inline void Add(const void* ptr, const AllocValue& v) {
    map_.Insert(ptr, v);
    total_.allocs++;
    total_.alloc_size += v.bytes;
  }

  // Helpers for sorting and generating leak reports
  struct Entry;
  struct ReportState;
  static void ReportCallback(const void* ptr, AllocValue* v, ReportState*);
  static void ReportObject(const void* ptr, AllocValue* v, char*);

  DISALLOW_COPY_AND_ASSIGN(Snapshot);
};

#endif  // BASE_HEAP_PROFILE_TABLE_H_
