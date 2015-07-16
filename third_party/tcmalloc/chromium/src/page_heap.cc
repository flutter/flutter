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

#include <config.h>
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>                   // for PRIuPTR
#endif
#include <gperftools/malloc_extension.h>      // for MallocRange, etc
#include "base/basictypes.h"
#include "base/commandlineflags.h"
#include "internal_logging.h"  // for ASSERT, TCMalloc_Printer, etc
#include "page_heap_allocator.h"  // for PageHeapAllocator
#include "static_vars.h"       // for Static
#include "system-alloc.h"      // for TCMalloc_SystemAlloc, etc

DEFINE_double(tcmalloc_release_rate,
              EnvToDouble("TCMALLOC_RELEASE_RATE", 1.0),
              "Rate at which we release unused memory to the system.  "
              "Zero means we never release memory back to the system.  "
              "Increase this flag to return memory faster; decrease it "
              "to return memory slower.  Reasonable rates are in the "
              "range [0,10]");

namespace tcmalloc {

PageHeap::PageHeap()
    : pagemap_(MetaDataAlloc),
      pagemap_cache_(0),
      scavenge_counter_(0),
      // Start scavenging at kMaxPages list
      release_index_(kMaxPages) {
  COMPILE_ASSERT(kNumClasses <= (1 << PageMapCache::kValuebits), valuebits);
  DLL_Init(&large_.normal);
  DLL_Init(&large_.returned);
  for (int i = 0; i < kMaxPages; i++) {
    DLL_Init(&free_[i].normal);
    DLL_Init(&free_[i].returned);
  }
}

Span* PageHeap::SearchFreeAndLargeLists(Length n) {
  ASSERT(Check());
  ASSERT(n > 0);

  // Find first size >= n that has a non-empty list
  for (Length s = n; s < kMaxPages; s++) {
    Span* ll = &free_[s].normal;
    // If we're lucky, ll is non-empty, meaning it has a suitable span.
    if (!DLL_IsEmpty(ll)) {
      ASSERT(ll->next->location == Span::ON_NORMAL_FREELIST);
      return Carve(ll->next, n);
    }
    // Alternatively, maybe there's a usable returned span.
    ll = &free_[s].returned;
    if (!DLL_IsEmpty(ll)) {
      ASSERT(ll->next->location == Span::ON_RETURNED_FREELIST);
      return Carve(ll->next, n);
    }
  }
  // No luck in free lists, our last chance is in a larger class.
  return AllocLarge(n);  // May be NULL
}

Span* PageHeap::New(Length n) {
  ASSERT(Check());
  ASSERT(n > 0);

  Span* result = SearchFreeAndLargeLists(n);
  if (result != NULL)
    return result;

  // Grow the heap and try again.
  if (!GrowHeap(n)) {
    ASSERT(stats_.unmapped_bytes+ stats_.committed_bytes==stats_.system_bytes);
    ASSERT(Check());
    return NULL;
  }
  return SearchFreeAndLargeLists(n);
}

Span* PageHeap::AllocLarge(Length n) {
  // find the best span (closest to n in size).
  // The following loops implements address-ordered best-fit.
  Span *best = NULL;

  // Search through normal list
  for (Span* span = large_.normal.next;
       span != &large_.normal;
       span = span->next) {
    if (span->length >= n) {
      if ((best == NULL)
          || (span->length < best->length)
          || ((span->length == best->length) && (span->start < best->start))) {
        best = span;
        ASSERT(best->location == Span::ON_NORMAL_FREELIST);
      }
    }
  }

  // Search through released list in case it has a better fit
  for (Span* span = large_.returned.next;
       span != &large_.returned;
       span = span->next) {
    if (span->length >= n) {
      if ((best == NULL)
          || (span->length < best->length)
          || ((span->length == best->length) && (span->start < best->start))) {
        best = span;
        ASSERT(best->location == Span::ON_RETURNED_FREELIST);
      }
    }
  }

  return best == NULL ? NULL : Carve(best, n);
}

Span* PageHeap::Split(Span* span, Length n) {
  ASSERT(0 < n);
  ASSERT(n < span->length);
  ASSERT(span->location == Span::IN_USE);
  ASSERT(span->sizeclass == 0);
  Event(span, 'T', n);

  const int extra = span->length - n;
  Span* leftover = NewSpan(span->start + n, extra);
  ASSERT(leftover->location == Span::IN_USE);
  Event(leftover, 'U', extra);
  RecordSpan(leftover);
  pagemap_.set(span->start + n - 1, span); // Update map from pageid to span
  span->length = n;

  return leftover;
}

void PageHeap::CommitSpan(Span* span) {
  TCMalloc_SystemCommit(reinterpret_cast<void*>(span->start << kPageShift),
                        static_cast<size_t>(span->length << kPageShift));
  stats_.committed_bytes += span->length << kPageShift;
}

void PageHeap::DecommitSpan(Span* span) {
  TCMalloc_SystemRelease(reinterpret_cast<void*>(span->start << kPageShift),
                         static_cast<size_t>(span->length << kPageShift));
  stats_.committed_bytes -= span->length << kPageShift;
}

Span* PageHeap::Carve(Span* span, Length n) {
  ASSERT(n > 0);
  ASSERT(span->location != Span::IN_USE);
  const int old_location = span->location;
  RemoveFromFreeList(span);
  span->location = Span::IN_USE;
  Event(span, 'A', n);

  const int extra = span->length - n;
  ASSERT(extra >= 0);
  if (extra > 0) {
    Span* leftover = NewSpan(span->start + n, extra);
    leftover->location = old_location;
    Event(leftover, 'S', extra);
    RecordSpan(leftover);

    // The previous span of |leftover| was just splitted -- no need to
    // coalesce them. The next span of |leftover| was not previously coalesced
    // with |span|, i.e. is NULL or has got location other than |old_location|.
    const PageID p = leftover->start;
    const Length len = leftover->length;
    Span* next = GetDescriptor(p+len);
    ASSERT (next == NULL ||
            next->location == Span::IN_USE ||
            next->location != leftover->location);

    PrependToFreeList(leftover);  // Skip coalescing - no candidates possible
    span->length = n;
    pagemap_.set(span->start + n - 1, span);
  }
  ASSERT(Check());
  if (old_location == Span::ON_RETURNED_FREELIST) {
    // We need to recommit this address space.
    CommitSpan(span);
  }
  ASSERT(span->location == Span::IN_USE);
  ASSERT(span->length == n);
  ASSERT(stats_.unmapped_bytes+ stats_.committed_bytes==stats_.system_bytes);
  return span;
}

void PageHeap::Delete(Span* span) {
  ASSERT(Check());
  ASSERT(span->location == Span::IN_USE);
  ASSERT(span->length > 0);
  ASSERT(GetDescriptor(span->start) == span);
  ASSERT(GetDescriptor(span->start + span->length - 1) == span);
  const Length n = span->length;
  span->sizeclass = 0;
  span->sample = 0;
  span->location = Span::ON_NORMAL_FREELIST;
  Event(span, 'D', span->length);
  MergeIntoFreeList(span);  // Coalesces if possible
  IncrementalScavenge(n);
  ASSERT(stats_.unmapped_bytes+ stats_.committed_bytes==stats_.system_bytes);
  ASSERT(Check());
}

void PageHeap::MergeIntoFreeList(Span* span) {
  ASSERT(span->location != Span::IN_USE);

  // Coalesce -- we guarantee that "p" != 0, so no bounds checking
  // necessary.  We do not bother resetting the stale pagemap
  // entries for the pieces we are merging together because we only
  // care about the pagemap entries for the boundaries.
  //
  // Note that the adjacent spans we merge into "span" may come out of a
  // "normal" (committed) list, and cleanly merge with our IN_USE span, which
  // is implicitly committed.  If the adjacents spans are on the "returned"
  // (decommitted) list, then we must get both spans into the same state before
  // or after we coalesce them.  The current code always decomits. This is
  // achieved by blindly decommitting the entire coalesced region, which  may
  // include any combination of committed and decommitted spans, at the end of
  // the method.

  // TODO(jar): "Always decommit" causes some extra calls to commit when we are
  // called in GrowHeap() during an allocation :-/.  We need to eval the cost of
  // that oscillation, and possibly do something to reduce it.

  // TODO(jar): We need a better strategy for deciding to commit, or decommit,
  // based on memory usage and free heap sizes.

  const PageID p = span->start;
  const Length n = span->length;
  Span* prev = GetDescriptor(p-1);
  if (prev != NULL && prev->location != Span::IN_USE) {
    // Merge preceding span into this span
    ASSERT(prev->start + prev->length == p);
    const Length len = prev->length;
    if (prev->location == Span::ON_RETURNED_FREELIST) {
      // We're about to put the merge span into the returned freelist and call
      // DecommitSpan() on it, which will mark the entire span including this
      // one as released and decrease stats_.committed_bytes by the size of the
      // merged span.  To make the math work out we temporarily increase the
      // stats_.committed_bytes amount.
      stats_.committed_bytes += prev->length << kPageShift;
    }
    RemoveFromFreeList(prev);
    DeleteSpan(prev);
    span->start -= len;
    span->length += len;
    pagemap_.set(span->start, span);
    Event(span, 'L', len);
  }
  Span* next = GetDescriptor(p+n);
  if (next != NULL && next->location != Span::IN_USE) {
    // Merge next span into this span
    ASSERT(next->start == p+n);
    const Length len = next->length;
    if (next->location == Span::ON_RETURNED_FREELIST) {
      // See the comment below 'if (prev->location ...' for explanation.
      stats_.committed_bytes += next->length << kPageShift;
    }
    RemoveFromFreeList(next);
    DeleteSpan(next);
    span->length += len;
    pagemap_.set(span->start + span->length - 1, span);
    Event(span, 'R', len);
  }

  Event(span, 'D', span->length);
  span->location = Span::ON_RETURNED_FREELIST;
  DecommitSpan(span);
  PrependToFreeList(span);
}

void PageHeap::PrependToFreeList(Span* span) {
  ASSERT(span->location != Span::IN_USE);
  SpanList* list = (span->length < kMaxPages) ? &free_[span->length] : &large_;
  if (span->location == Span::ON_NORMAL_FREELIST) {
    stats_.free_bytes += (span->length << kPageShift);
    DLL_Prepend(&list->normal, span);
  } else {
    stats_.unmapped_bytes += (span->length << kPageShift);
    DLL_Prepend(&list->returned, span);
  }
}

void PageHeap::RemoveFromFreeList(Span* span) {
  ASSERT(span->location != Span::IN_USE);
  if (span->location == Span::ON_NORMAL_FREELIST) {
    stats_.free_bytes -= (span->length << kPageShift);
  } else {
    stats_.unmapped_bytes -= (span->length << kPageShift);
  }
  DLL_Remove(span);
}

void PageHeap::IncrementalScavenge(Length n) {
  // Fast path; not yet time to release memory
  scavenge_counter_ -= n;
  if (scavenge_counter_ >= 0) return;  // Not yet time to scavenge

  const double rate = FLAGS_tcmalloc_release_rate;
  if (rate <= 1e-6) {
    // Tiny release rate means that releasing is disabled.
    scavenge_counter_ = kDefaultReleaseDelay;
    return;
  }

  Length released_pages = ReleaseAtLeastNPages(1);

  if (released_pages == 0) {
    // Nothing to scavenge, delay for a while.
    scavenge_counter_ = kDefaultReleaseDelay;
  } else {
    // Compute how long to wait until we return memory.
    // FLAGS_tcmalloc_release_rate==1 means wait for 1000 pages
    // after releasing one page.
    const double mult = 1000.0 / rate;
    double wait = mult * static_cast<double>(released_pages);
    if (wait > kMaxReleaseDelay) {
      // Avoid overflow and bound to reasonable range.
      wait = kMaxReleaseDelay;
    }
    scavenge_counter_ = static_cast<int64_t>(wait);
  }
}

Length PageHeap::ReleaseLastNormalSpan(SpanList* slist) {
  Span* s = slist->normal.prev;
  ASSERT(s->location == Span::ON_NORMAL_FREELIST);
  RemoveFromFreeList(s);
  const Length n = s->length;
  TCMalloc_SystemRelease(reinterpret_cast<void*>(s->start << kPageShift),
                         static_cast<size_t>(s->length << kPageShift));
  s->location = Span::ON_RETURNED_FREELIST;
  MergeIntoFreeList(s);  // Coalesces if possible.
  return n;
}

Length PageHeap::ReleaseAtLeastNPages(Length num_pages) {
  Length released_pages = 0;
  Length prev_released_pages = -1;

  // Round robin through the lists of free spans, releasing the last
  // span in each list.  Stop after releasing at least num_pages.
  while (released_pages < num_pages) {
    if (released_pages == prev_released_pages) {
      // Last iteration of while loop made no progress.
      break;
    }
    prev_released_pages = released_pages;

    for (int i = 0; i < kMaxPages+1 && released_pages < num_pages;
         i++, release_index_++) {
      if (release_index_ > kMaxPages) release_index_ = 0;
      SpanList* slist = (release_index_ == kMaxPages) ?
          &large_ : &free_[release_index_];
      if (!DLL_IsEmpty(&slist->normal)) {
        Length released_len = ReleaseLastNormalSpan(slist);
        released_pages += released_len;
      }
    }
  }
  return released_pages;
}

void PageHeap::RegisterSizeClass(Span* span, size_t sc) {
  // Associate span object with all interior pages as well
  ASSERT(span->location == Span::IN_USE);
  ASSERT(GetDescriptor(span->start) == span);
  ASSERT(GetDescriptor(span->start+span->length-1) == span);
  Event(span, 'C', sc);
  span->sizeclass = sc;
  for (Length i = 1; i < span->length-1; i++) {
    pagemap_.set(span->start+i, span);
  }
}

void PageHeap::GetSmallSpanStats(SmallSpanStats* result) {
  for (int s = 0; s < kMaxPages; s++) {
    result->normal_length[s] = DLL_Length(&free_[s].normal);
    result->returned_length[s] = DLL_Length(&free_[s].returned);
  }
}

void PageHeap::GetLargeSpanStats(LargeSpanStats* result) {
  result->spans = 0;
  result->normal_pages = 0;
  result->returned_pages = 0;
  for (Span* s = large_.normal.next; s != &large_.normal; s = s->next) {
    result->normal_pages += s->length;;
    result->spans++;
  }
  for (Span* s = large_.returned.next; s != &large_.returned; s = s->next) {
    result->returned_pages += s->length;
    result->spans++;
  }
}

bool PageHeap::GetNextRange(PageID start, base::MallocRange* r) {
  Span* span = reinterpret_cast<Span*>(pagemap_.Next(start));
  if (span == NULL) {
    return false;
  }
  r->address = span->start << kPageShift;
  r->length = span->length << kPageShift;
  r->fraction = 0;
  switch (span->location) {
    case Span::IN_USE:
      r->type = base::MallocRange::INUSE;
      r->fraction = 1;
      if (span->sizeclass > 0) {
        // Only some of the objects in this span may be in use.
        const size_t osize = Static::sizemap()->class_to_size(span->sizeclass);
        r->fraction = (1.0 * osize * span->refcount) / r->length;
      }
      break;
    case Span::ON_NORMAL_FREELIST:
      r->type = base::MallocRange::FREE;
      break;
    case Span::ON_RETURNED_FREELIST:
      r->type = base::MallocRange::UNMAPPED;
      break;
    default:
      r->type = base::MallocRange::UNKNOWN;
      break;
  }
  return true;
}

static void RecordGrowth(size_t growth) {
  StackTrace* t = Static::stacktrace_allocator()->New();
  t->depth = GetStackTrace(t->stack, kMaxStackDepth-1, 3);
  t->size = growth;
  t->stack[kMaxStackDepth-1] = reinterpret_cast<void*>(Static::growth_stacks());
  Static::set_growth_stacks(t);
}

bool PageHeap::GrowHeap(Length n) {
  ASSERT(kMaxPages >= kMinSystemAlloc);
  if (n > kMaxValidPages) return false;
  Length ask = (n>kMinSystemAlloc) ? n : static_cast<Length>(kMinSystemAlloc);
  size_t actual_size;
  void* ptr = TCMalloc_SystemAlloc(ask << kPageShift, &actual_size, kPageSize);
  if (ptr == NULL) {
    if (n < ask) {
      // Try growing just "n" pages
      ask = n;
      ptr = TCMalloc_SystemAlloc(ask << kPageShift, &actual_size, kPageSize);
    }
    if (ptr == NULL) return false;
  }
  ask = actual_size >> kPageShift;
  RecordGrowth(ask << kPageShift);

  uint64_t old_system_bytes = stats_.system_bytes;
  stats_.system_bytes += (ask << kPageShift);
  stats_.committed_bytes += (ask << kPageShift);
  const PageID p = reinterpret_cast<uintptr_t>(ptr) >> kPageShift;
  ASSERT(p > 0);

  // If we have already a lot of pages allocated, just pre allocate a bunch of
  // memory for the page map. This prevents fragmentation by pagemap metadata
  // when a program keeps allocating and freeing large blocks.

  if (old_system_bytes < kPageMapBigAllocationThreshold
      && stats_.system_bytes >= kPageMapBigAllocationThreshold) {
    pagemap_.PreallocateMoreMemory();
  }

  // Make sure pagemap_ has entries for all of the new pages.
  // Plus ensure one before and one after so coalescing code
  // does not need bounds-checking.
  if (pagemap_.Ensure(p-1, ask+2)) {
    // Pretend the new area is allocated and then Delete() it to cause
    // any necessary coalescing to occur.
    Span* span = NewSpan(p, ask);
    RecordSpan(span);
    Delete(span);
    ASSERT(stats_.unmapped_bytes+ stats_.committed_bytes==stats_.system_bytes);
    ASSERT(Check());
    return true;
  } else {
    // We could not allocate memory within "pagemap_"
    // TODO: Once we can return memory to the system, return the new span
    return false;
  }
}

bool PageHeap::Check() {
  ASSERT(free_[0].normal.next == &free_[0].normal);
  ASSERT(free_[0].returned.next == &free_[0].returned);
  return true;
}

bool PageHeap::CheckExpensive() {
  bool result = Check();
  CheckList(&large_.normal, kMaxPages, 1000000000, Span::ON_NORMAL_FREELIST);
  CheckList(&large_.returned, kMaxPages, 1000000000, Span::ON_RETURNED_FREELIST);
  for (Length s = 1; s < kMaxPages; s++) {
    CheckList(&free_[s].normal, s, s, Span::ON_NORMAL_FREELIST);
    CheckList(&free_[s].returned, s, s, Span::ON_RETURNED_FREELIST);
  }
  return result;
}

bool PageHeap::CheckList(Span* list, Length min_pages, Length max_pages,
                         int freelist) {
  for (Span* s = list->next; s != list; s = s->next) {
    CHECK_CONDITION(s->location == freelist);  // NORMAL or RETURNED
    CHECK_CONDITION(s->length >= min_pages);
    CHECK_CONDITION(s->length <= max_pages);
    CHECK_CONDITION(GetDescriptor(s->start) == s);
    CHECK_CONDITION(GetDescriptor(s->start+s->length-1) == s);
  }
  return true;
}

}  // namespace tcmalloc
