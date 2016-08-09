// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a OS-independent* module which purpose is tracking allocations and
// their call sites (stack traces). It is able to deal with hole punching
// (read: munmap). Also, it has low overhead and its presence in the system its
// barely noticeable, even if tracing *all* the processes.
// This module does NOT know how to deal with stack unwinding. The caller must
// do that and pass the addresses of the unwound stack.
// * (Modulo three lines for mutexes.)
//
// Exposed API:
//   void heap_profiler_init(HeapStats*);
//   void heap_profiler_alloc(addr, size, stack_frames, depth, flags);
//   void heap_profiler_free(addr, size);  (size == 0 means free entire region).
//
// The profiling information is tracked into two data structures:
// 1) A RB-Tree of non-overlapping VM regions (allocs) sorted by their start
//    addr. Each entry tracks the start-end addresses and points to the stack
//    trace which created that allocation (see below).
// 2) A (hash) table of stack traces. In general the #allocations >> #call sites
//    which create those allocations. In order to avoid duplicating the latter,
//    they are stored distinctly in this hash table and used by reference.
//
//   /  Process virtual address space  \
//   +------+      +------+      +------+
//   |Alloc1|      |Alloc2|      |Alloc3|    <- Allocs (a RB-Tree underneath)
//   +------+      +------+      +------+
//    Len: 12       Len: 4        Len: 4
//       |            |             |                     stack_traces
//       |            |             |              +-----------+--------------+
//       |            |             |              | Alloc tot | stack frames +
//       |            |             |              +-----------+--------------+
//       +------------|-------------+------------> |    16     | 0x1234 ....  |
//                    |                            +-----------+--------------+
//                    +--------------------------> |     4     | 0x5678 ....  |
//                                                 +-----------+--------------+
//                                                   (A hash-table underneath)
//
// Final note: the memory for both 1) and 2) entries is carved out from two
// static pools (i.e. stack_traces and allocs). The pools are treated as
// a sbrk essentially, and are kept compact by reusing freed elements (hence
// having a freelist for each of them).
//
// All the internal (static) functions here assume that the |lock| is held.

#include <assert.h>
#include <string.h>

// Platform-dependent mutex boilerplate.
#if defined(__linux__) || defined(__ANDROID__)
#include <pthread.h>
#define DEFINE_MUTEX(x) pthread_mutex_t x = PTHREAD_MUTEX_INITIALIZER
#define LOCK_MUTEX(x) pthread_mutex_lock(&x)
#define UNLOCK_MUTEX(x) pthread_mutex_unlock(&x)
#else
#error OS not supported.
#endif

#include "tools/android/heap_profiler/heap_profiler.h"


static DEFINE_MUTEX(lock);

// |stats| contains the global tracking metadata and is the entry point which
// is read by the heap_dump tool.
static HeapStats* stats;

// +---------------------------------------------------------------------------+
// + Stack traces hash-table                                                   +
// +---------------------------------------------------------------------------+
#define ST_ENTRIES_MAX (64 * 1024)
#define ST_HASHTABLE_BUCKETS (64 * 1024) /* Must be a power of 2. */

static StacktraceEntry stack_traces[ST_ENTRIES_MAX];
static StacktraceEntry* stack_traces_freelist;
static StacktraceEntry* stack_traces_ht[ST_HASHTABLE_BUCKETS];

// Looks up a stack trace from the stack frames. Creates a new one if necessary.
static StacktraceEntry* record_stacktrace(uintptr_t* frames, uint32_t depth) {
  if (depth == 0)
    return NULL;

  if (depth > HEAP_PROFILER_MAX_DEPTH)
    depth = HEAP_PROFILER_MAX_DEPTH;

  uint32_t i;
  uintptr_t hash = 0;
  for (i = 0; i < depth; ++i)
    hash = (hash << 1) ^ (frames[i]);
  const uint32_t slot = hash & (ST_HASHTABLE_BUCKETS - 1);
  StacktraceEntry* st = stack_traces_ht[slot];

  // Look for an existing entry in the hash-table.
  const size_t frames_length = depth * sizeof(uintptr_t);
  while (st != NULL && st->hash != hash &&
         memcmp(frames, st->frames, frames_length) != 0) {
    st = st->next;
  }

  // If not found, create a new one from the stack_traces array and add it to
  // the hash-table.
  if (st == NULL) {
    // Get a free element either from the freelist or from the pool.
    if (stack_traces_freelist != NULL) {
      st = stack_traces_freelist;
      stack_traces_freelist = stack_traces_freelist->next;
    } else if (stats->max_stack_traces < ST_ENTRIES_MAX) {
      st = &stack_traces[stats->max_stack_traces];
      ++stats->max_stack_traces;
    } else {
      return NULL;
    }

    memset(st, 0, sizeof(*st));
    memcpy(st->frames, frames, frames_length);
    st->hash = hash;
    st->next = stack_traces_ht[slot];
    stack_traces_ht[slot] = st;
    ++stats->num_stack_traces;
  }

  return st;
}

// Frees up a stack trace and appends it to the corresponding freelist.
static void free_stacktrace(StacktraceEntry* st) {
  assert(st->alloc_bytes == 0);
  const uint32_t slot = st->hash & (ST_HASHTABLE_BUCKETS - 1);

  // The expected load factor of the hash-table is very low. Frees should be
  // pretty rare. Hence don't bother with a doubly linked list, might cost more.
  StacktraceEntry** prev = &stack_traces_ht[slot];
  while (*prev != st)
    prev = &((*prev)->next);

  // Remove from the hash-table bucket.
  assert(*prev == st);
  *prev = st->next;

  // Add to the freelist.
  st->next = stack_traces_freelist;
  stack_traces_freelist = st;
  --stats->num_stack_traces;
}

// +---------------------------------------------------------------------------+
// + Allocs RB-tree                                                            +
// +---------------------------------------------------------------------------+
#define ALLOCS_ENTRIES_MAX (256 * 1024)

static Alloc allocs[ALLOCS_ENTRIES_MAX];
static Alloc* allocs_freelist;
static RB_HEAD(HeapEntriesTree, Alloc) allocs_tree =
    RB_INITIALIZER(&allocs_tree);

// Comparator used by the RB-Tree (mind the overflow, avoid arith on addresses).
static int allocs_tree_cmp(Alloc *alloc_1, Alloc *alloc_2) {
  if (alloc_1->start < alloc_2->start)
    return -1;
  if (alloc_1->start > alloc_2->start)
    return 1;
  return 0;
}

RB_PROTOTYPE(HeapEntriesTree, Alloc, rb_node, allocs_tree_cmp);
RB_GENERATE(HeapEntriesTree, Alloc, rb_node, allocs_tree_cmp);

// Allocates a new Alloc and inserts it in the tree.
static Alloc* insert_alloc(
    uintptr_t start, uintptr_t end, StacktraceEntry* st, uint32_t flags) {
  Alloc* alloc = NULL;

  // First of all, get a free element either from the freelist or from the pool.
  if (allocs_freelist != NULL) {
    alloc = allocs_freelist;
    allocs_freelist = alloc->next_free;
  } else if (stats->max_allocs < ALLOCS_ENTRIES_MAX) {
    alloc = &allocs[stats->max_allocs];
    ++stats->max_allocs;
  } else {
    return NULL;  // OOM.
  }

  alloc->start = start;
  alloc->end = end;
  alloc->st = st;
  alloc->flags = flags;
  alloc->next_free = NULL;
  RB_INSERT(HeapEntriesTree, &allocs_tree, alloc);
  ++stats->num_allocs;
  return alloc;
}

// Deletes all the allocs in the range [addr, addr+size[ dealing with partial
// frees and hole punching. Note that in the general case this function might
// need to deal with very unfortunate cases, as below:
//
// Alloc tree begin: [Alloc 1]----[Alloc 2]-------[Alloc 3][Alloc 4]---[Alloc 5]
// Deletion range:                      [xxxxxxxxxxxxxxxxxxxx]
// Alloc tree end:   [Alloc 1]----[Al.2]----------------------[Al.4]---[Alloc 5]
//                   Alloc3 has to be deleted and Alloc 2,4 shrunk.
static uint32_t delete_allocs_in_range(void* addr, size_t size) {
  uintptr_t del_start = (uintptr_t) addr;
  uintptr_t del_end = del_start + size - 1;
  uint32_t flags = 0;

  Alloc* alloc = NULL;
  Alloc* next_alloc = RB_ROOT(&allocs_tree);

  // Lookup the first (by address) relevant Alloc to initiate the deletion walk.
  // At the end of the loop next_alloc is either:
  // - the closest alloc starting before (or exactly at) the start of the
  //   deletion range (i.e. addr == del_start).
  // - the first alloc inside the deletion range.
  // - the first alloc after the deletion range iff the range was already empty
  //   (in this case the next loop will just bail out doing nothing).
  // - NULL: iff the entire tree is empty (as above).
  while (next_alloc != NULL) {
    alloc = next_alloc;
    if (alloc->start > del_start) {
      next_alloc = RB_LEFT(alloc, rb_node);
    } else if (alloc->end < del_start) {
      next_alloc = RB_RIGHT(alloc, rb_node);
    } else {  // alloc->start <= del_start && alloc->end >= del_start
      break;
    }
  }

  // Now scan the allocs linearly deleting chunks (or eventually whole allocs)
  // until passing the end of the deleting region.
  next_alloc = alloc;
  while (next_alloc != NULL) {
    alloc = next_alloc;
    next_alloc = RB_NEXT(HeapEntriesTree, &allocs_tree, alloc);

    if (size != 0) {
      // In the general case we stop passed the end of the deletion range.
      if (alloc->start > del_end)
        break;

      // This deals with the case of the first Alloc laying before the range.
      if (alloc->end < del_start)
        continue;
    } else {
      // size == 0 is a special case. It means deleting only the alloc which
      // starts exactly at |del_start| if any (for dealing with free(ptr)).
      if (alloc->start > del_start)
        break;
      if (alloc->start < del_start)
        continue;
      del_end = alloc->end;
    }

    // Reached this point the Alloc must overlap (partially or completely) with
    // the deletion range.
    assert(!(alloc->start > del_end || alloc->end < del_start));

    StacktraceEntry* st = alloc->st;
    flags |= alloc->flags;
    uintptr_t freed_bytes = 0;  // Bytes freed in this cycle.

    if (del_start <= alloc->start) {
      if (del_end >= alloc->end) {
        // Complete overlap. Delete full Alloc. Note: the range might might
        // still overlap with the next allocs.
        // Begin:      ------[alloc.start    alloc.end]-[next alloc]
        // Del range:      [xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx]
        // Result:     ---------------------------------[next alloc]
        //             [next alloc] will be shrinked on the next iteration.
        freed_bytes = alloc->end - alloc->start + 1;
        RB_REMOVE(HeapEntriesTree, &allocs_tree, alloc);

        // Clean-up, so heap_dump can tell this is a free entry and skip it.
        alloc->start = alloc->end = 0;
        alloc->st = NULL;

        // Put in the freelist.
        alloc->next_free = allocs_freelist;
        allocs_freelist = alloc;
        --stats->num_allocs;
      } else {
        // Partial overlap at beginning. Cut first part and shrink the alloc.
        // Begin:      ------[alloc.start  alloc.end]-[next alloc]
        // Del range:      [xxxxxx]
        // Result:     ------------[start  alloc.end]-[next alloc]
        freed_bytes = del_end - alloc->start + 1;
        alloc->start = del_end + 1;
        // No need to update the tree even if we changed the key. The keys are
        // still monotonic (because the ranges are guaranteed to not overlap).
      }
    } else {
      if (del_end >= alloc->end) {
        // Partial overlap at end. Cut last part and shrink the alloc left.
        // Begin:      ------[alloc.start     alloc.end]-[next alloc]
        // Del range:                               [xxxxxxxx]
        // Result:     ------[alloc.start alloc.end]-----[next alloc]
        //             [next alloc] will be shrinked on the next iteration.
        freed_bytes = alloc->end - del_start + 1;
        alloc->end = del_start - 1;
      } else {
        // Hole punching. Requires creating an extra alloc.
        // Begin:      ------[alloc.start     alloc.end]-[next alloc]
        // Del range:                   [xxx]
        // Result:     ------[ alloc 1 ]-----[ alloc 2 ]-[next alloc]
        freed_bytes = del_end - del_start + 1;
        const uintptr_t old_end = alloc->end;
        alloc->end = del_start - 1;

        // In case of OOM, don't count the 2nd alloc we failed to allocate.
        if (insert_alloc(del_end + 1, old_end, st, alloc->flags) == NULL)
          freed_bytes += (old_end - del_end);
      }
    }
    // Now update the StackTraceEntry the Alloc was pointing to, eventually
    // freeing it up.
    assert(st->alloc_bytes >= freed_bytes);
    st->alloc_bytes -= freed_bytes;
    if (st->alloc_bytes == 0)
      free_stacktrace(st);
    stats->total_alloc_bytes -= freed_bytes;
  }
  return flags;
}

// +---------------------------------------------------------------------------+
// + Library entry points (refer to heap_profiler.h for API doc).              +
// +---------------------------------------------------------------------------+
void heap_profiler_free(void* addr, size_t size, uint32_t* old_flags) {
  assert(size == 0 || ((uintptr_t) addr + (size - 1)) >= (uintptr_t) addr);

  LOCK_MUTEX(lock);
  uint32_t flags = delete_allocs_in_range(addr, size);
  UNLOCK_MUTEX(lock);

  if (old_flags != NULL)
    *old_flags = flags;
}

void heap_profiler_alloc(void* addr, size_t size, uintptr_t* frames,
                         uint32_t depth, uint32_t flags) {
  if (depth > HEAP_PROFILER_MAX_DEPTH)
    depth = HEAP_PROFILER_MAX_DEPTH;

  if (size == 0)  // Apps calling malloc(0), sometimes it happens.
    return;

  const uintptr_t start = (uintptr_t) addr;
  const uintptr_t end = start + (size - 1);
  assert(start <= end);

  LOCK_MUTEX(lock);

  delete_allocs_in_range(addr, size);

  StacktraceEntry* st = record_stacktrace(frames, depth);
  if (st != NULL) {
    Alloc* alloc = insert_alloc(start, end, st, flags);
    if (alloc != NULL) {
      st->alloc_bytes += size;
      stats->total_alloc_bytes += size;
    }
  }

  UNLOCK_MUTEX(lock);
}

void heap_profiler_init(HeapStats* heap_stats) {
  LOCK_MUTEX(lock);

  assert(stats == NULL);
  stats = heap_stats;
  memset(stats, 0, sizeof(HeapStats));
  stats->magic_start = HEAP_PROFILER_MAGIC_MARKER;
  stats->allocs = &allocs[0];
  stats->stack_traces = &stack_traces[0];

  UNLOCK_MUTEX(lock);
}

void heap_profiler_cleanup(void) {
  LOCK_MUTEX(lock);

  assert(stats != NULL);
  memset(stack_traces, 0, sizeof(StacktraceEntry) * stats->max_stack_traces);
  memset(stack_traces_ht, 0, sizeof(stack_traces_ht));
  stack_traces_freelist = NULL;

  memset(allocs, 0, sizeof(Alloc) * stats->max_allocs);
  allocs_freelist = NULL;
  RB_INIT(&allocs_tree);

  stats = NULL;

  UNLOCK_MUTEX(lock);
}
