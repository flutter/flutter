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

#include "config.h"
#include <algorithm>
#include "central_freelist.h"
#include "free_list.h"         // for FL_Next, FL_Push, etc
#include "internal_logging.h"  // for ASSERT, MESSAGE
#include "page_heap.h"         // for PageHeap
#include "static_vars.h"       // for Static

using std::min;
using std::max;

namespace tcmalloc {

void CentralFreeList::Init(size_t cl) {
  size_class_ = cl;
  tcmalloc::DLL_Init(&empty_);
  tcmalloc::DLL_Init(&nonempty_);
  num_spans_ = 0;
  counter_ = 0;

  max_cache_size_ = kMaxNumTransferEntries;
#ifdef TCMALLOC_SMALL_BUT_SLOW
  // Disable the transfer cache for the small footprint case.
  cache_size_ = 0;
#else
  cache_size_ = 16;
#endif
  if (cl > 0) {
    // Limit the maximum size of the cache based on the size class.  If this
    // is not done, large size class objects will consume a lot of memory if
    // they just sit in the transfer cache.
    int32_t bytes = Static::sizemap()->ByteSizeForClass(cl);
    int32_t objs_to_move = Static::sizemap()->num_objects_to_move(cl);

    ASSERT(objs_to_move > 0 && bytes > 0);
    // Limit each size class cache to at most 1MB of objects or one entry,
    // whichever is greater. Total transfer cache memory used across all
    // size classes then can't be greater than approximately
    // 1MB * kMaxNumTransferEntries.
    // min and max are in parens to avoid macro-expansion on windows.
    max_cache_size_ = (min)(max_cache_size_,
                          (max)(1, (1024 * 1024) / (bytes * objs_to_move)));
    cache_size_ = (min)(cache_size_, max_cache_size_);
  }
  used_slots_ = 0;
  ASSERT(cache_size_ <= max_cache_size_);
}

void CentralFreeList::ReleaseListToSpans(void* start) {
  while (start) {
    void *next = FL_Next(start);
    ReleaseToSpans(start);
    start = next;
  }
}

// MapObjectToSpan should logically be part of ReleaseToSpans.  But
// this triggers an optimization bug in gcc 4.5.0.  Moving to a
// separate function, and making sure that function isn't inlined,
// seems to fix the problem.  It also should be fixed for gcc 4.5.1.
static
#if __GNUC__ == 4 && __GNUC_MINOR__ == 5 && __GNUC_PATCHLEVEL__ == 0
__attribute__ ((noinline))
#endif
Span* MapObjectToSpan(void* object) {
  const PageID p = reinterpret_cast<uintptr_t>(object) >> kPageShift;
  Span* span = Static::pageheap()->GetDescriptor(p);
  return span;
}

void CentralFreeList::ReleaseToSpans(void* object) {
  Span* span = MapObjectToSpan(object);
  ASSERT(span != NULL);
  ASSERT(span->refcount > 0);

  // If span is empty, move it to non-empty list
  if (span->objects == NULL) {
    tcmalloc::DLL_Remove(span);
    tcmalloc::DLL_Prepend(&nonempty_, span);
    Event(span, 'N', 0);
  }

  // The following check is expensive, so it is disabled by default
  if (false) {
    // Check that object does not occur in list
    int got = 0;
    for (void* p = span->objects; p != NULL; p = FL_Next(p)){
      ASSERT(p != object);
      got++;
    }
    ASSERT(got + span->refcount ==
           (span->length<<kPageShift) /
           Static::sizemap()->ByteSizeForClass(span->sizeclass));
  }

  counter_++;
  span->refcount--;
  if (span->refcount == 0) {
    Event(span, '#', 0);
    counter_ -= ((span->length<<kPageShift) /
                 Static::sizemap()->ByteSizeForClass(span->sizeclass));
    tcmalloc::DLL_Remove(span);
    --num_spans_;

    // Release central list lock while operating on pageheap
    lock_.Unlock();
    {
      SpinLockHolder h(Static::pageheap_lock());
      Static::pageheap()->Delete(span);
    }
    lock_.Lock();
  } else {
    FL_Push(&(span->objects), object);
  }
}

bool CentralFreeList::EvictRandomSizeClass(
    int locked_size_class, bool force) {
  static int race_counter = 0;
  int t = race_counter++;  // Updated without a lock, but who cares.
  if (t >= kNumClasses) {
    while (t >= kNumClasses) {
      t -= kNumClasses;
    }
    race_counter = t;
  }
  ASSERT(t >= 0);
  ASSERT(t < kNumClasses);
  if (t == locked_size_class) return false;
  return Static::central_cache()[t].ShrinkCache(locked_size_class, force);
}

bool CentralFreeList::MakeCacheSpace() {
  // Is there room in the cache?
  if (used_slots_ < cache_size_) return true;
  // Check if we can expand this cache?
  if (cache_size_ == max_cache_size_) return false;
  // Ok, we'll try to grab an entry from some other size class.
  if (EvictRandomSizeClass(size_class_, false) ||
      EvictRandomSizeClass(size_class_, true)) {
    // Succeeded in evicting, we're going to make our cache larger.
    // However, we may have dropped and re-acquired the lock in
    // EvictRandomSizeClass (via ShrinkCache and the LockInverter), so the
    // cache_size may have changed.  Therefore, check and verify that it is
    // still OK to increase the cache_size.
    if (cache_size_ < max_cache_size_) {
      cache_size_++;
      return true;
    }
  }
  return false;
}


namespace {
class LockInverter {
 private:
  SpinLock *held_, *temp_;
 public:
  inline explicit LockInverter(SpinLock* held, SpinLock *temp)
    : held_(held), temp_(temp) { held_->Unlock(); temp_->Lock(); }
  inline ~LockInverter() { temp_->Unlock(); held_->Lock();  }
};
}

// This function is marked as NO_THREAD_SAFETY_ANALYSIS because it uses
// LockInverter to release one lock and acquire another in scoped-lock
// style, which our current annotation/analysis does not support.
bool CentralFreeList::ShrinkCache(int locked_size_class, bool force)
    NO_THREAD_SAFETY_ANALYSIS {
  // Start with a quick check without taking a lock.
  if (cache_size_ == 0) return false;
  // We don't evict from a full cache unless we are 'forcing'.
  if (force == false && used_slots_ == cache_size_) return false;

  // Grab lock, but first release the other lock held by this thread.  We use
  // the lock inverter to ensure that we never hold two size class locks
  // concurrently.  That can create a deadlock because there is no well
  // defined nesting order.
  LockInverter li(&Static::central_cache()[locked_size_class].lock_, &lock_);
  ASSERT(used_slots_ <= cache_size_);
  ASSERT(0 <= cache_size_);
  if (cache_size_ == 0) return false;
  if (used_slots_ == cache_size_) {
    if (force == false) return false;
    // ReleaseListToSpans releases the lock, so we have to make all the
    // updates to the central list before calling it.
    cache_size_--;
    used_slots_--;
    ReleaseListToSpans(tc_slots_[used_slots_].head);
    return true;
  }
  cache_size_--;
  return true;
}

void CentralFreeList::InsertRange(void *start, void *end, int N) {
  SpinLockHolder h(&lock_);
  if (N == Static::sizemap()->num_objects_to_move(size_class_) &&
    MakeCacheSpace()) {
    int slot = used_slots_++;
    ASSERT(slot >=0);
    ASSERT(slot < max_cache_size_);
    TCEntry *entry = &tc_slots_[slot];
    entry->head = start;
    entry->tail = end;
    return;
  }
  ReleaseListToSpans(start);
}

int CentralFreeList::RemoveRange(void **start, void **end, int N) {
  ASSERT(N > 0);
  lock_.Lock();
  if (N == Static::sizemap()->num_objects_to_move(size_class_) &&
      used_slots_ > 0) {
    int slot = --used_slots_;
    ASSERT(slot >= 0);
    TCEntry *entry = &tc_slots_[slot];
    *start = entry->head;
    *end = entry->tail;
    lock_.Unlock();
    return N;
  }

  int result = 0;
  void* head = NULL;
  void* tail = NULL;
  // TODO: Prefetch multiple TCEntries?
  tail = FetchFromSpansSafe();
  if (tail != NULL) {
    FL_Push(&head, tail);
    result = 1;
    while (result < N) {
      void *t = FetchFromSpans();
      if (!t) break;
      FL_Push(&head, t);
      result++;
    }
  }
  lock_.Unlock();
  *start = head;
  *end = tail;
  return result;
}


void* CentralFreeList::FetchFromSpansSafe() {
  void *t = FetchFromSpans();
  if (!t) {
    Populate();
    t = FetchFromSpans();
  }
  return t;
}

void* CentralFreeList::FetchFromSpans() {
  if (tcmalloc::DLL_IsEmpty(&nonempty_)) return NULL;
  Span* span = nonempty_.next;

  ASSERT(span->objects != NULL);
  span->refcount++;
  void *result = FL_Pop(&(span->objects));
  if (span->objects == NULL) {
    // Move to empty list
    tcmalloc::DLL_Remove(span);
    tcmalloc::DLL_Prepend(&empty_, span);
    Event(span, 'E', 0);
  }
  counter_--;
  return result;
}

// Fetch memory from the system and add to the central cache freelist.
void CentralFreeList::Populate() {
  // Release central list lock while operating on pageheap
  lock_.Unlock();
  const size_t npages = Static::sizemap()->class_to_pages(size_class_);

  Span* span;
  {
    SpinLockHolder h(Static::pageheap_lock());
    span = Static::pageheap()->New(npages);
    if (span) Static::pageheap()->RegisterSizeClass(span, size_class_);
  }
  if (span == NULL) {
    Log(kLog, __FILE__, __LINE__,
        "tcmalloc: allocation failed", npages << kPageShift);
    lock_.Lock();
    return;
  }
  ASSERT(span->length == npages);
  // Cache sizeclass info eagerly.  Locking is not necessary.
  // (Instead of being eager, we could just replace any stale info
  // about this span, but that seems to be no better in practice.)
  for (int i = 0; i < npages; i++) {
    Static::pageheap()->CacheSizeClass(span->start + i, size_class_);
  }

  // Split the block into pieces and add to the free-list
  // TODO: coloring of objects to avoid cache conflicts?
  void* list = NULL;
  char* ptr = reinterpret_cast<char*>(span->start << kPageShift);
  char* limit = ptr + (npages << kPageShift);
  const size_t size = Static::sizemap()->ByteSizeForClass(size_class_);
  int num = 0;
  while (ptr + size <= limit) {
    FL_Push(&list, ptr);
    ptr += size;
    num++;
  }
  ASSERT(ptr <= limit);
  span->objects = list;
  span->refcount = 0; // No sub-object in use yet

  // Add span to list of non-empty spans
  lock_.Lock();
  tcmalloc::DLL_Prepend(&nonempty_, span);
  ++num_spans_;
  counter_ += num;
}

int CentralFreeList::tc_length() {
  SpinLockHolder h(&lock_);
  return used_slots_ * Static::sizemap()->num_objects_to_move(size_class_);
}

size_t CentralFreeList::OverheadBytes() {
  SpinLockHolder h(&lock_);
  if (size_class_ == 0) {  // 0 holds the 0-sized allocations
    return 0;
  }
  const size_t pages_per_span = Static::sizemap()->class_to_pages(size_class_);
  const size_t object_size = Static::sizemap()->class_to_size(size_class_);
  ASSERT(object_size > 0);
  const size_t overhead_per_span = (pages_per_span * kPageSize) % object_size;
  return num_spans_ * overhead_per_span;
}

}  // namespace tcmalloc
