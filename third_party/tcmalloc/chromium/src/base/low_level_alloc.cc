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
 */

// A low-level allocator that can be used by other low-level
// modules without introducing dependency cycles.
// This allocator is slow and wasteful of memory;
// it should not be used when performance is key.

#include "base/low_level_alloc.h"
#include "base/dynamic_annotations.h"
#include "base/spinlock.h"
#include "base/logging.h"
#include "malloc_hook-inl.h"
#include <gperftools/malloc_hook.h>
#include <errno.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_MMAP
#include <sys/mman.h>
#endif
#include <new>                   // for placement-new

// On systems (like freebsd) that don't define MAP_ANONYMOUS, use the old
// form of the name instead.
#ifndef MAP_ANONYMOUS
# define MAP_ANONYMOUS MAP_ANON
#endif

// A first-fit allocator with amortized logarithmic free() time.

// ---------------------------------------------------------------------------
static const int kMaxLevel = 30;

// We put this class-only struct in a namespace to avoid polluting the
// global namespace with this struct name (thus risking an ODR violation).
namespace low_level_alloc_internal {
  // This struct describes one allocated block, or one free block.
  struct AllocList {
    struct Header {
      intptr_t size;  // size of entire region, including this field. Must be
                      // first.  Valid in both allocated and unallocated blocks
      intptr_t magic; // kMagicAllocated or kMagicUnallocated xor this
      LowLevelAlloc::Arena *arena; // pointer to parent arena
      void *dummy_for_alignment;   // aligns regions to 0 mod 2*sizeof(void*)
    } header;

    // Next two fields: in unallocated blocks: freelist skiplist data
    //                  in allocated blocks: overlaps with client data
    int levels;           // levels in skiplist used
    AllocList *next[kMaxLevel];   // actually has levels elements.
                                  // The AllocList node may not have room for
                                  // all kMaxLevel entries.  See max_fit in
                                  // LLA_SkiplistLevels()
  };
}
using low_level_alloc_internal::AllocList;


// ---------------------------------------------------------------------------
// A trivial skiplist implementation.  This is used to keep the freelist
// in address order while taking only logarithmic time per insert and delete.

// An integer approximation of log2(size/base)
// Requires size >= base.
static int IntLog2(size_t size, size_t base) {
  int result = 0;
  for (size_t i = size; i > base; i >>= 1) { // i == floor(size/2**result)
    result++;
  }
  //    floor(size / 2**result) <= base < floor(size / 2**(result-1))
  // =>     log2(size/(base+1)) <= result < 1+log2(size/base)
  // => result ~= log2(size/base)
  return result;
}

// Return a random integer n:  p(n)=1/(2**n) if 1 <= n; p(n)=0 if n < 1.
static int Random() {
  static int32 r = 1;         // no locking---it's not critical
  ANNOTATE_BENIGN_RACE(&r, "benign race, not critical.");
  int result = 1;
  while ((((r = r*1103515245 + 12345) >> 30) & 1) == 0) {
    result++;
  }
  return result;
}

// Return a number of skiplist levels for a node of size bytes, where
// base is the minimum node size.  Compute level=log2(size / base)+n
// where n is 1 if random is false and otherwise a random number generated with
// the standard distribution for a skiplist:  See Random() above.
// Bigger nodes tend to have more skiplist levels due to the log2(size / base)
// term, so first-fit searches touch fewer nodes.  "level" is clipped so
// level<kMaxLevel and next[level-1] will fit in the node.
// 0 < LLA_SkiplistLevels(x,y,false) <= LLA_SkiplistLevels(x,y,true) < kMaxLevel
static int LLA_SkiplistLevels(size_t size, size_t base, bool random) {
  // max_fit is the maximum number of levels that will fit in a node for the
  // given size.   We can't return more than max_fit, no matter what the
  // random number generator says.
  int max_fit = (size-OFFSETOF_MEMBER(AllocList, next)) / sizeof (AllocList *);
  int level = IntLog2(size, base) + (random? Random() : 1);
  if (level > max_fit)     level = max_fit;
  if (level > kMaxLevel-1) level = kMaxLevel - 1;
  RAW_CHECK(level >= 1, "block not big enough for even one level");
  return level;
}

// Return "atleast", the first element of AllocList *head s.t. *atleast >= *e.
// For 0 <= i < head->levels, set prev[i] to "no_greater", where no_greater
// points to the last element at level i in the AllocList less than *e, or is
// head if no such element exists.
static AllocList *LLA_SkiplistSearch(AllocList *head,
                                     AllocList *e, AllocList **prev) {
  AllocList *p = head;
  for (int level = head->levels - 1; level >= 0; level--) {
    for (AllocList *n; (n = p->next[level]) != 0 && n < e; p = n) {
    }
    prev[level] = p;
  }
  return (head->levels == 0) ?  0 : prev[0]->next[0];
}

// Insert element *e into AllocList *head.  Set prev[] as LLA_SkiplistSearch.
// Requires that e->levels be previously set by the caller (using
// LLA_SkiplistLevels())
static void LLA_SkiplistInsert(AllocList *head, AllocList *e,
                               AllocList **prev) {
  LLA_SkiplistSearch(head, e, prev);
  for (; head->levels < e->levels; head->levels++) { // extend prev pointers
    prev[head->levels] = head;                       // to all *e's levels
  }
  for (int i = 0; i != e->levels; i++) { // add element to list
    e->next[i] = prev[i]->next[i];
    prev[i]->next[i] = e;
  }
}

// Remove element *e from AllocList *head.  Set prev[] as LLA_SkiplistSearch().
// Requires that e->levels be previous set by the caller (using
// LLA_SkiplistLevels())
static void LLA_SkiplistDelete(AllocList *head, AllocList *e,
                               AllocList **prev) {
  AllocList *found = LLA_SkiplistSearch(head, e, prev);
  RAW_CHECK(e == found, "element not in freelist");
  for (int i = 0; i != e->levels && prev[i]->next[i] == e; i++) {
    prev[i]->next[i] = e->next[i];
  }
  while (head->levels > 0 && head->next[head->levels - 1] == 0) {
    head->levels--;   // reduce head->levels if level unused
  }
}

// ---------------------------------------------------------------------------
// Arena implementation

struct LowLevelAlloc::Arena {
  Arena() : mu(SpinLock::LINKER_INITIALIZED) {} // does nothing; for static init
  explicit Arena(int) : pagesize(0) {}  // set pagesize to zero explicitly
                                        // for non-static init

  SpinLock mu;            // protects freelist, allocation_count,
                          // pagesize, roundup, min_size
  AllocList freelist;     // head of free list; sorted by addr (under mu)
  int32 allocation_count; // count of allocated blocks (under mu)
  int32 flags;            // flags passed to NewArena (ro after init)
  size_t pagesize;        // ==getpagesize()  (init under mu, then ro)
  size_t roundup;         // lowest power of 2 >= max(16,sizeof (AllocList))
                          // (init under mu, then ro)
  size_t min_size;        // smallest allocation block size
                          // (init under mu, then ro)
};

// The default arena, which is used when 0 is passed instead of an Arena
// pointer.
static struct LowLevelAlloc::Arena default_arena;

// Non-malloc-hooked arenas: used only to allocate metadata for arenas that
// do not want malloc hook reporting, so that for them there's no malloc hook
// reporting even during arena creation.
static struct LowLevelAlloc::Arena unhooked_arena;
static struct LowLevelAlloc::Arena unhooked_async_sig_safe_arena;

// magic numbers to identify allocated and unallocated blocks
static const intptr_t kMagicAllocated = 0x4c833e95;
static const intptr_t kMagicUnallocated = ~kMagicAllocated;

namespace {
  class SCOPED_LOCKABLE ArenaLock {
   public:
    explicit ArenaLock(LowLevelAlloc::Arena *arena)
        EXCLUSIVE_LOCK_FUNCTION(arena->mu)
        : left_(false), mask_valid_(false), arena_(arena) {
      if ((arena->flags & LowLevelAlloc::kAsyncSignalSafe) != 0) {
      // We've decided not to support async-signal-safe arena use until
      // there a demonstrated need.  Here's how one could do it though
      // (would need to be made more portable).
#if 0
        sigset_t all;
        sigfillset(&all);
        this->mask_valid_ =
            (pthread_sigmask(SIG_BLOCK, &all, &this->mask_) == 0);
#else
        RAW_CHECK(false, "We do not yet support async-signal-safe arena.");
#endif
      }
      this->arena_->mu.Lock();
    }
    ~ArenaLock() { RAW_CHECK(this->left_, "haven't left Arena region"); }
    void Leave() /*UNLOCK_FUNCTION()*/ {
      this->arena_->mu.Unlock();
#if 0
      if (this->mask_valid_) {
        pthread_sigmask(SIG_SETMASK, &this->mask_, 0);
      }
#endif
      this->left_ = true;
    }
   private:
    bool left_;       // whether left region
    bool mask_valid_;
#if 0
    sigset_t mask_;   // old mask of blocked signals
#endif
    LowLevelAlloc::Arena *arena_;
    DISALLOW_COPY_AND_ASSIGN(ArenaLock);
  };
} // anonymous namespace

// create an appropriate magic number for an object at "ptr"
// "magic" should be kMagicAllocated or kMagicUnallocated
inline static intptr_t Magic(intptr_t magic, AllocList::Header *ptr) {
  return magic ^ reinterpret_cast<intptr_t>(ptr);
}

// Initialize the fields of an Arena
static void ArenaInit(LowLevelAlloc::Arena *arena) {
  if (arena->pagesize == 0) {
    arena->pagesize = getpagesize();
    // Round up block sizes to a power of two close to the header size.
    arena->roundup = 16;
    while (arena->roundup < sizeof (arena->freelist.header)) {
      arena->roundup += arena->roundup;
    }
    // Don't allocate blocks less than twice the roundup size to avoid tiny
    // free blocks.
    arena->min_size = 2 * arena->roundup;
    arena->freelist.header.size = 0;
    arena->freelist.header.magic =
        Magic(kMagicUnallocated, &arena->freelist.header);
    arena->freelist.header.arena = arena;
    arena->freelist.levels = 0;
    memset(arena->freelist.next, 0, sizeof (arena->freelist.next));
    arena->allocation_count = 0;
    if (arena == &default_arena) {
      // Default arena should be hooked, e.g. for heap-checker to trace
      // pointer chains through objects in the default arena.
      arena->flags = LowLevelAlloc::kCallMallocHook;
    } else if (arena == &unhooked_async_sig_safe_arena) {
      arena->flags = LowLevelAlloc::kAsyncSignalSafe;
    } else {
      arena->flags = 0;   // other arenas' flags may be overridden by client,
                          // but unhooked_arena will have 0 in 'flags'.
    }
  }
}

// L < meta_data_arena->mu
LowLevelAlloc::Arena *LowLevelAlloc::NewArena(int32 flags,
                                              Arena *meta_data_arena) {
  RAW_CHECK(meta_data_arena != 0, "must pass a valid arena");
  if (meta_data_arena == &default_arena) {
    if ((flags & LowLevelAlloc::kAsyncSignalSafe) != 0) {
      meta_data_arena = &unhooked_async_sig_safe_arena;
    } else if ((flags & LowLevelAlloc::kCallMallocHook) == 0) {
      meta_data_arena = &unhooked_arena;
    }
  }
  // Arena(0) uses the constructor for non-static contexts
  Arena *result =
    new (AllocWithArena(sizeof (*result), meta_data_arena)) Arena(0);
  ArenaInit(result);
  result->flags = flags;
  return result;
}

// L < arena->mu, L < arena->arena->mu
bool LowLevelAlloc::DeleteArena(Arena *arena) {
  RAW_CHECK(arena != 0 && arena != &default_arena && arena != &unhooked_arena,
            "may not delete default arena");
  ArenaLock section(arena);
  bool empty = (arena->allocation_count == 0);
  section.Leave();
  if (empty) {
    while (arena->freelist.next[0] != 0) {
      AllocList *region = arena->freelist.next[0];
      size_t size = region->header.size;
      arena->freelist.next[0] = region->next[0];
      RAW_CHECK(region->header.magic ==
                Magic(kMagicUnallocated, &region->header),
                "bad magic number in DeleteArena()");
      RAW_CHECK(region->header.arena == arena,
                "bad arena pointer in DeleteArena()");
      RAW_CHECK(size % arena->pagesize == 0,
                "empty arena has non-page-aligned block size");
      RAW_CHECK(reinterpret_cast<intptr_t>(region) % arena->pagesize == 0,
                "empty arena has non-page-aligned block");
      int munmap_result;
      if ((arena->flags & LowLevelAlloc::kAsyncSignalSafe) == 0) {
        munmap_result = munmap(region, size);
      } else {
        munmap_result = MallocHook::UnhookedMUnmap(region, size);
      }
      RAW_CHECK(munmap_result == 0,
                "LowLevelAlloc::DeleteArena:  munmap failed address");
    }
    Free(arena);
  }
  return empty;
}

// ---------------------------------------------------------------------------

// Return value rounded up to next multiple of align.
// align must be a power of two.
static intptr_t RoundUp(intptr_t addr, intptr_t align) {
  return (addr + align - 1) & ~(align - 1);
}

// Equivalent to "return prev->next[i]" but with sanity checking
// that the freelist is in the correct order, that it
// consists of regions marked "unallocated", and that no two regions
// are adjacent in memory (they should have been coalesced).
// L < arena->mu
static AllocList *Next(int i, AllocList *prev, LowLevelAlloc::Arena *arena) {
  RAW_CHECK(i < prev->levels, "too few levels in Next()");
  AllocList *next = prev->next[i];
  if (next != 0) {
    RAW_CHECK(next->header.magic == Magic(kMagicUnallocated, &next->header),
              "bad magic number in Next()");
    RAW_CHECK(next->header.arena == arena,
              "bad arena pointer in Next()");
    if (prev != &arena->freelist) {
      RAW_CHECK(prev < next, "unordered freelist");
      RAW_CHECK(reinterpret_cast<char *>(prev) + prev->header.size <
                reinterpret_cast<char *>(next), "malformed freelist");
    }
  }
  return next;
}

// Coalesce list item "a" with its successor if they are adjacent.
static void Coalesce(AllocList *a) {
  AllocList *n = a->next[0];
  if (n != 0 && reinterpret_cast<char *>(a) + a->header.size ==
                    reinterpret_cast<char *>(n)) {
    LowLevelAlloc::Arena *arena = a->header.arena;
    a->header.size += n->header.size;
    n->header.magic = 0;
    n->header.arena = 0;
    AllocList *prev[kMaxLevel];
    LLA_SkiplistDelete(&arena->freelist, n, prev);
    LLA_SkiplistDelete(&arena->freelist, a, prev);
    a->levels = LLA_SkiplistLevels(a->header.size, arena->min_size, true);
    LLA_SkiplistInsert(&arena->freelist, a, prev);
  }
}

// Adds block at location "v" to the free list
// L >= arena->mu
static void AddToFreelist(void *v, LowLevelAlloc::Arena *arena) {
  AllocList *f = reinterpret_cast<AllocList *>(
                        reinterpret_cast<char *>(v) - sizeof (f->header));
  RAW_CHECK(f->header.magic == Magic(kMagicAllocated, &f->header),
            "bad magic number in AddToFreelist()");
  RAW_CHECK(f->header.arena == arena,
            "bad arena pointer in AddToFreelist()");
  f->levels = LLA_SkiplistLevels(f->header.size, arena->min_size, true);
  AllocList *prev[kMaxLevel];
  LLA_SkiplistInsert(&arena->freelist, f, prev);
  f->header.magic = Magic(kMagicUnallocated, &f->header);
  Coalesce(f);                  // maybe coalesce with successor
  Coalesce(prev[0]);            // maybe coalesce with predecessor
}

// Frees storage allocated by LowLevelAlloc::Alloc().
// L < arena->mu
void LowLevelAlloc::Free(void *v) {
  if (v != 0) {
    AllocList *f = reinterpret_cast<AllocList *>(
                        reinterpret_cast<char *>(v) - sizeof (f->header));
    RAW_CHECK(f->header.magic == Magic(kMagicAllocated, &f->header),
              "bad magic number in Free()");
    LowLevelAlloc::Arena *arena = f->header.arena;
    if ((arena->flags & kCallMallocHook) != 0) {
      MallocHook::InvokeDeleteHook(v);
    }
    ArenaLock section(arena);
    AddToFreelist(v, arena);
    RAW_CHECK(arena->allocation_count > 0, "nothing in arena to free");
    arena->allocation_count--;
    section.Leave();
  }
}

// allocates and returns a block of size bytes, to be freed with Free()
// L < arena->mu
static void *DoAllocWithArena(size_t request, LowLevelAlloc::Arena *arena) {
  void *result = 0;
  if (request != 0) {
    AllocList *s;       // will point to region that satisfies request
    ArenaLock section(arena);
    ArenaInit(arena);
    // round up with header
    size_t req_rnd = RoundUp(request + sizeof (s->header), arena->roundup);
    for (;;) {      // loop until we find a suitable region
      // find the minimum levels that a block of this size must have
      int i = LLA_SkiplistLevels(req_rnd, arena->min_size, false) - 1;
      if (i < arena->freelist.levels) {   // potential blocks exist
        AllocList *before = &arena->freelist;  // predecessor of s
        while ((s = Next(i, before, arena)) != 0 && s->header.size < req_rnd) {
          before = s;
        }
        if (s != 0) {       // we found a region
          break;
        }
      }
      // we unlock before mmap() both because mmap() may call a callback hook,
      // and because it may be slow.
      arena->mu.Unlock();
      // mmap generous 64K chunks to decrease
      // the chances/impact of fragmentation:
      size_t new_pages_size = RoundUp(req_rnd, arena->pagesize * 16);
      void *new_pages;
      if ((arena->flags & LowLevelAlloc::kAsyncSignalSafe) != 0) {
        new_pages = MallocHook::UnhookedMMap(0, new_pages_size,
            PROT_WRITE|PROT_READ, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
      } else {
        new_pages = mmap(0, new_pages_size,
            PROT_WRITE|PROT_READ, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
      }
      RAW_CHECK(new_pages != MAP_FAILED, "mmap error");
      arena->mu.Lock();
      s = reinterpret_cast<AllocList *>(new_pages);
      s->header.size = new_pages_size;
      // Pretend the block is allocated; call AddToFreelist() to free it.
      s->header.magic = Magic(kMagicAllocated, &s->header);
      s->header.arena = arena;
      AddToFreelist(&s->levels, arena);  // insert new region into free list
    }
    AllocList *prev[kMaxLevel];
    LLA_SkiplistDelete(&arena->freelist, s, prev);    // remove from free list
    // s points to the first free region that's big enough
    if (req_rnd + arena->min_size <= s->header.size) {  // big enough to split
      AllocList *n = reinterpret_cast<AllocList *>
                        (req_rnd + reinterpret_cast<char *>(s));
      n->header.size = s->header.size - req_rnd;
      n->header.magic = Magic(kMagicAllocated, &n->header);
      n->header.arena = arena;
      s->header.size = req_rnd;
      AddToFreelist(&n->levels, arena);
    }
    s->header.magic = Magic(kMagicAllocated, &s->header);
    RAW_CHECK(s->header.arena == arena, "");
    arena->allocation_count++;
    section.Leave();
    result = &s->levels;
  }
  ANNOTATE_NEW_MEMORY(result, request);
  return result;
}

void *LowLevelAlloc::Alloc(size_t request) {
  void *result = DoAllocWithArena(request, &default_arena);
  if ((default_arena.flags & kCallMallocHook) != 0) {
    // this call must be directly in the user-called allocator function
    // for MallocHook::GetCallerStackTrace to work properly
    MallocHook::InvokeNewHook(result, request);
  }
  return result;
}

void *LowLevelAlloc::AllocWithArena(size_t request, Arena *arena) {
  RAW_CHECK(arena != 0, "must pass a valid arena");
  void *result = DoAllocWithArena(request, arena);
  if ((arena->flags & kCallMallocHook) != 0) {
    // this call must be directly in the user-called allocator function
    // for MallocHook::GetCallerStackTrace to work properly
    MallocHook::InvokeNewHook(result, request);
  }
  return result;
}

LowLevelAlloc::Arena *LowLevelAlloc::DefaultArena() {
  return &default_arena;
}
