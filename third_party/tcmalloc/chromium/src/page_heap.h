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

#ifndef TCMALLOC_PAGE_HEAP_H_
#define TCMALLOC_PAGE_HEAP_H_

#include <config.h>
#include <stddef.h>                     // for size_t
#ifdef HAVE_STDINT_H
#include <stdint.h>                     // for uint64_t, int64_t, uint16_t
#endif
#include <gperftools/malloc_extension.h>
#include "base/basictypes.h"
#include "common.h"
#include "packed-cache-inl.h"
#include "pagemap.h"
#include "span.h"

// We need to dllexport PageHeap just for the unittest.  MSVC complains
// that we don't dllexport the PageHeap members, but we don't need to
// test those, so I just suppress this warning.
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable:4251)
#endif

// This #ifdef should almost never be set.  Set NO_TCMALLOC_SAMPLES if
// you're porting to a system where you really can't get a stacktrace.
// Because we control the definition of GetStackTrace, all clients of
// GetStackTrace should #include us rather than stacktrace.h.
#ifdef NO_TCMALLOC_SAMPLES
  // We use #define so code compiles even if you #include stacktrace.h somehow.
# define GetStackTrace(stack, depth, skip)  (0)
#else
# include <gperftools/stacktrace.h>
#endif

namespace base {
struct MallocRange;
}

namespace tcmalloc {

// -------------------------------------------------------------------------
// Map from page-id to per-page data
// -------------------------------------------------------------------------

// We use PageMap2<> for 32-bit and PageMap3<> for 64-bit machines.
// ...except...
// On Windows, we use TCMalloc_PageMap1_LazyCommit<> for 32-bit machines.
// We also use a simple one-level cache for hot PageID-to-sizeclass mappings,
// because sometimes the sizeclass is all the information we need.

// Selector class -- general selector uses 3-level map
template <int BITS> class MapSelector {
 public:
  typedef TCMalloc_PageMap3<BITS-kPageShift> Type;
  typedef PackedCache<BITS-kPageShift, uint64_t> CacheType;
};

// A two-level map for 32-bit machines
template <> class MapSelector<32> {
 public:
#ifdef WIN32
// A flat map for 32-bit machines (with lazy commit of memory).
  typedef TCMalloc_PageMap1_LazyCommit<32-kPageShift> Type;
#else
  // A two-level map for 32-bit machines
  typedef TCMalloc_PageMap2<32-kPageShift> Type;
#endif
  typedef PackedCache<32-kPageShift, uint16_t> CacheType;
};

// -------------------------------------------------------------------------
// Page-level allocator
//  * Eager coalescing
//
// Heap for page-level allocation.  We allow allocating and freeing a
// contiguous runs of pages (called a "span").
// -------------------------------------------------------------------------

class PERFTOOLS_DLL_DECL PageHeap {
 public:
  PageHeap();

  // Allocate a run of "n" pages.  Returns zero if out of memory.
  // Caller should not pass "n == 0" -- instead, n should have
  // been rounded up already.
  Span* New(Length n);

  // Delete the span "[p, p+n-1]".
  // REQUIRES: span was returned by earlier call to New() and
  //           has not yet been deleted.
  void Delete(Span* span);

  // Mark an allocated span as being used for small objects of the
  // specified size-class.
  // REQUIRES: span was returned by an earlier call to New()
  //           and has not yet been deleted.
  void RegisterSizeClass(Span* span, size_t sc);

  // Split an allocated span into two spans: one of length "n" pages
  // followed by another span of length "span->length - n" pages.
  // Modifies "*span" to point to the first span of length "n" pages.
  // Returns a pointer to the second span.
  //
  // REQUIRES: "0 < n < span->length"
  // REQUIRES: span->location == IN_USE
  // REQUIRES: span->sizeclass == 0
  Span* Split(Span* span, Length n);

  // Return the descriptor for the specified page.  Returns NULL if
  // this PageID was not allocated previously.
  inline Span* GetDescriptor(PageID p) const {
    return reinterpret_cast<Span*>(pagemap_.get(p));
  }

  // If this page heap is managing a range with starting page # >= start,
  // store info about the range in *r and return true.  Else return false.
  bool GetNextRange(PageID start, base::MallocRange* r);

  // Page heap statistics
  struct Stats {
    Stats() : system_bytes(0), free_bytes(0), unmapped_bytes(0) {}
    uint64_t system_bytes;    // Total bytes allocated from system
    uint64_t free_bytes;      // Total bytes on normal freelists
    uint64_t unmapped_bytes;  // Total bytes on returned freelists
    uint64_t committed_bytes;  // Bytes committed, always <= system_bytes_.

  };
  inline Stats stats() const { return stats_; }

  struct SmallSpanStats {
    // For each free list of small spans, the length (in spans) of the
    // normal and returned free lists for that size.
    int64 normal_length[kMaxPages];
    int64 returned_length[kMaxPages];
  };
  void GetSmallSpanStats(SmallSpanStats* result);

  // Stats for free large spans (i.e., spans with more than kMaxPages pages).
  struct LargeSpanStats {
    int64 spans;           // Number of such spans
    int64 normal_pages;    // Combined page length of normal large spans
    int64 returned_pages;  // Combined page length of unmapped spans
  };
  void GetLargeSpanStats(LargeSpanStats* result);

  bool Check();
  // Like Check() but does some more comprehensive checking.
  bool CheckExpensive();
  bool CheckList(Span* list, Length min_pages, Length max_pages,
                 int freelist);  // ON_NORMAL_FREELIST or ON_RETURNED_FREELIST

  // Try to release at least num_pages for reuse by the OS.  Returns
  // the actual number of pages released, which may be less than
  // num_pages if there weren't enough pages to release. The result
  // may also be larger than num_pages since page_heap might decide to
  // release one large range instead of fragmenting it into two
  // smaller released and unreleased ranges.
  Length ReleaseAtLeastNPages(Length num_pages);

  // Return 0 if we have no information, or else the correct sizeclass for p.
  // Reads and writes to pagemap_cache_ do not require locking.
  // The entries are 64 bits on 64-bit hardware and 16 bits on
  // 32-bit hardware, and we don't mind raciness as long as each read of
  // an entry yields a valid entry, not a partially updated entry.
  size_t GetSizeClassIfCached(PageID p) const {
    return pagemap_cache_.GetOrDefault(p, 0);
  }
  void CacheSizeClass(PageID p, size_t cl) const { pagemap_cache_.Put(p, cl); }

 private:
  // Allocates a big block of memory for the pagemap once we reach more than
  // 128MB
  static const size_t kPageMapBigAllocationThreshold = 128 << 20;

  // Minimum number of pages to fetch from system at a time.  Must be
  // significantly bigger than kBlockSize to amortize system-call
  // overhead, and also to reduce external fragementation.  Also, we
  // should keep this value big because various incarnations of Linux
  // have small limits on the number of mmap() regions per
  // address-space.
  // REQUIRED: kMinSystemAlloc <= kMaxPages;
  static const int kMinSystemAlloc = kMaxPages;

  // Never delay scavenging for more than the following number of
  // deallocated pages.  With 4K pages, this comes to 4GB of
  // deallocation.
  // Chrome:  Changed to 64MB
  static const int kMaxReleaseDelay = 1 << 14;

  // If there is nothing to release, wait for so many pages before
  // scavenging again.  With 4K pages, this comes to 1GB of memory.
  // Chrome:  Changed to 16MB
  static const int kDefaultReleaseDelay = 1 << 12;

  // Pick the appropriate map and cache types based on pointer size
  typedef MapSelector<kAddressBits>::Type PageMap;
  typedef MapSelector<kAddressBits>::CacheType PageMapCache;
  PageMap pagemap_;
  mutable PageMapCache pagemap_cache_;

  // We segregate spans of a given size into two circular linked
  // lists: one for normal spans, and one for spans whose memory
  // has been returned to the system.
  struct SpanList {
    Span        normal;
    Span        returned;
  };

  // List of free spans of length >= kMaxPages
  SpanList large_;

  // Array mapping from span length to a doubly linked list of free spans
  SpanList free_[kMaxPages];

  // Statistics on system, free, and unmapped bytes
  Stats stats_;
  Span* SearchFreeAndLargeLists(Length n);

  bool GrowHeap(Length n);

  // REQUIRES: span->length >= n
  // REQUIRES: span->location != IN_USE
  // Remove span from its free list, and move any leftover part of
  // span into appropriate free lists.  Also update "span" to have
  // length exactly "n" and mark it as non-free so it can be returned
  // to the client.  After all that, decrease free_pages_ by n and
  // return span.
  Span* Carve(Span* span, Length n);

  void RecordSpan(Span* span) {
    pagemap_.set(span->start, span);
    if (span->length > 1) {
      pagemap_.set(span->start + span->length - 1, span);
    }
  }

  // Allocate a large span of length == n.  If successful, returns a
  // span of exactly the specified length.  Else, returns NULL.
  Span* AllocLarge(Length n);

  // Coalesce span with neighboring spans if possible, prepend to
  // appropriate free list, and adjust stats.
  void MergeIntoFreeList(Span* span);

  // Commit the span.
  void CommitSpan(Span* span);

  // Decommit the span.
  void DecommitSpan(Span* span);

  // Prepends span to appropriate free list, and adjusts stats.
  void PrependToFreeList(Span* span);

  // Removes span from its free list, and adjust stats.
  void RemoveFromFreeList(Span* span);

  // Incrementally release some memory to the system.
  // IncrementalScavenge(n) is called whenever n pages are freed.
  void IncrementalScavenge(Length n);

  // Release the last span on the normal portion of this list.
  // Return the length of that span.
  Length ReleaseLastNormalSpan(SpanList* slist);


  // Number of pages to deallocate before doing more scavenging
  int64_t scavenge_counter_;

  // Index of last free list where we released memory to the OS.
  int release_index_;
};

}  // namespace tcmalloc

#ifdef _MSC_VER
#pragma warning(pop)
#endif

#endif  // TCMALLOC_PAGE_HEAP_H_
