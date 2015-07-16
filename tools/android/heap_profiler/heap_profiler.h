// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_HEAP_PROFILER_HEAP_PROFILER_H_
#define TOOLS_ANDROID_HEAP_PROFILER_HEAP_PROFILER_H_

#include <stdint.h>
#include "third_party/bsdtrees/tree.h"

#define HEAP_PROFILER_MAGIC_MARKER 0x42beef42L
#define HEAP_PROFILER_MAX_DEPTH 12

// The allocation is a result of a system malloc() invocation.
#define HEAP_PROFILER_FLAGS_MALLOC 1

// The allocation is a result of a mmap() invocation.
#define HEAP_PROFILER_FLAGS_MMAP 2  // Allocation performed through mmap.

// Only in the case of FLAGS_MMAP: The mmap is not anonymous (i.e. file backed).
#define HEAP_PROFILER_FLAGS_MMAP_FILE 4

// Android only: allocation made by the Zygote (before forking).
#define HEAP_PROFILER_FLAGS_IN_ZYGOTE 8

#ifdef __cplusplus
extern "C" {
#endif

typedef struct StacktraceEntry {
  uintptr_t frames[HEAP_PROFILER_MAX_DEPTH];  // Absolute addrs of stack frames.
  uint32_t hash;  // H(frames), used to keep these entries in a hashtable.

  // Total number of bytes allocated through this code path. It is equal to the
  // sum of Alloc instances' length which .bt == this.
  size_t alloc_bytes;

  // |next| has a dual purpose. When the entry is used (hence in the hashtable),
  // this is a ptr to the next item in the same bucket. When the entry is free,
  // this is a ptr to the next entry in the freelist.
  struct StacktraceEntry* next;
} StacktraceEntry;

// Represents a contiguous range of virtual memory which has been allocated by
// a give code path (identified by the corresponding StacktraceEntry).
typedef struct Alloc {
  RB_ENTRY(Alloc) rb_node;  // Anchor for the RB-tree;
  uintptr_t start;
  uintptr_t end;
  uint32_t flags;       // See HEAP_PROFILER_FLAGS_*.
  StacktraceEntry* st;  // NULL == free entry.
  struct Alloc* next_free;
} Alloc;

typedef struct {
  uint32_t magic_start;       // The magic marker used to locate the stats mmap.
  uint32_t num_allocs;        // The total number of allocation entries present.
  uint32_t max_allocs;        // The max number of items in |allocs|.
  uint32_t num_stack_traces;  // The total number of stack traces present.
  uint32_t max_stack_traces;  // The max number of items in |stack_traces|.
  size_t total_alloc_bytes;   // Total allocation bytes tracked.
  Alloc* allocs;              // Start of the the Alloc pool.
  StacktraceEntry* stack_traces;  // Start of the StacktraceEntry pool.
} HeapStats;

// Initialize the heap_profiler. The caller has to allocate the HeapStats
// "superblock", since the way it is mapped is platform-specific.
void heap_profiler_init(HeapStats* heap_stats);

// Records and allocation. The caller must unwind the stack and pass the
// frames array. Flags are optionals and don't affect the behavior of the
// library (they're just kept along and dumped).
void heap_profiler_alloc(void* addr,
                         size_t size,
                         uintptr_t* frames,
                         uint32_t depth,
                         uint32_t flags);

// Frees any allocation (even partial) overlapping with the given range.
// If old_flags != NULL, it will be filled with the flags of the deleted allocs.
void heap_profiler_free(void* addr, size_t size, uint32_t* old_flags);

// Cleans up the HeapStats and all the internal data structures.
void heap_profiler_cleanup(void);

#ifdef __cplusplus
}
#endif

#endif  // TOOLS_ANDROID_HEAP_PROFILER_HEAP_PROFILER_H_
