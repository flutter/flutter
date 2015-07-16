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
// Author: Ken Ashcraft <opensource@google.com>

#include <config.h>
#include "thread_cache.h"
#include <errno.h>
#include <string.h>                     // for memcpy
#include <algorithm>                    // for max, min
#include "base/commandlineflags.h"      // for SpinLockHolder
#include "base/spinlock.h"              // for SpinLockHolder
#include "central_freelist.h"           // for CentralFreeListPadded
#include "maybe_threads.h"

using std::min;
using std::max;

DEFINE_int64(tcmalloc_max_total_thread_cache_bytes,
             EnvToInt64("TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES",
                        kDefaultOverallThreadCacheSize),
             "Bound on the total amount of bytes allocated to "
             "thread caches. This bound is not strict, so it is possible "
             "for the cache to go over this bound in certain circumstances. "
             "Maximum value of this flag is capped to 1 GB.");

namespace tcmalloc {

static bool phinited = false;

volatile size_t ThreadCache::per_thread_cache_size_ = kMaxThreadCacheSize;
size_t ThreadCache::overall_thread_cache_size_ = kDefaultOverallThreadCacheSize;
ssize_t ThreadCache::unclaimed_cache_space_ = kDefaultOverallThreadCacheSize;
PageHeapAllocator<ThreadCache> threadcache_allocator;
ThreadCache* ThreadCache::thread_heaps_ = NULL;
int ThreadCache::thread_heap_count_ = 0;
ThreadCache* ThreadCache::next_memory_steal_ = NULL;
#ifdef HAVE_TLS
__thread ThreadCache* ThreadCache::threadlocal_heap_
# ifdef HAVE___ATTRIBUTE__
   __attribute__ ((tls_model ("initial-exec")))
# endif
   ;
#endif
bool ThreadCache::tsd_inited_ = false;
pthread_key_t ThreadCache::heap_key_;

#if defined(HAVE_TLS)
bool kernel_supports_tls = false;      // be conservative
# if defined(_WIN32)    // windows has supported TLS since winnt, I think.
    void CheckIfKernelSupportsTLS() {
      kernel_supports_tls = true;
    }
# elif !HAVE_DECL_UNAME    // if too old for uname, probably too old for TLS
    void CheckIfKernelSupportsTLS() {
      kernel_supports_tls = false;
    }
# else
#   include <sys/utsname.h>    // DECL_UNAME checked for <sys/utsname.h> too
    void CheckIfKernelSupportsTLS() {
      struct utsname buf;
      if (uname(&buf) < 0) {   // should be impossible
        Log(kLog, __FILE__, __LINE__,
            "uname failed assuming no TLS support (errno)", errno);
        kernel_supports_tls = false;
      } else if (strcasecmp(buf.sysname, "linux") == 0) {
        // The linux case: the first kernel to support TLS was 2.6.0
        if (buf.release[0] < '2' && buf.release[1] == '.')    // 0.x or 1.x
          kernel_supports_tls = false;
        else if (buf.release[0] == '2' && buf.release[1] == '.' &&
                 buf.release[2] >= '0' && buf.release[2] < '6' &&
                 buf.release[3] == '.')                       // 2.0 - 2.5
          kernel_supports_tls = false;
        else
          kernel_supports_tls = true;
      } else if (strcasecmp(buf.sysname, "CYGWIN_NT-6.1-WOW64") == 0) {
        // In my testing, this version of cygwin, at least, would hang
        // when using TLS.
        kernel_supports_tls = false;
      } else {        // some other kernel, we'll be optimisitic
        kernel_supports_tls = true;
      }
      // TODO(csilvers): VLOG(1) the tls status once we support RAW_VLOG
    }
#  endif  // HAVE_DECL_UNAME
#endif    // HAVE_TLS

void ThreadCache::Init(pthread_t tid) {
  size_ = 0;

  max_size_ = 0;
  IncreaseCacheLimitLocked();
  if (max_size_ == 0) {
    // There isn't enough memory to go around.  Just give the minimum to
    // this thread.
    max_size_ = kMinThreadCacheSize;

    // Take unclaimed_cache_space_ negative.
    unclaimed_cache_space_ -= kMinThreadCacheSize;
    ASSERT(unclaimed_cache_space_ < 0);
  }

  next_ = NULL;
  prev_ = NULL;
  tid_  = tid;
  in_setspecific_ = false;
  for (size_t cl = 0; cl < kNumClasses; ++cl) {
    list_[cl].Init();
  }

  uint32_t sampler_seed;
  memcpy(&sampler_seed, &tid, sizeof(sampler_seed));
  sampler_.Init(sampler_seed);
}

void ThreadCache::Cleanup() {
  // Put unused memory back into central cache
  for (int cl = 0; cl < kNumClasses; ++cl) {
    if (list_[cl].length() > 0) {
      ReleaseToCentralCache(&list_[cl], cl, list_[cl].length());
    }
  }
}

// Remove some objects of class "cl" from central cache and add to thread heap.
// On success, return the first object for immediate use; otherwise return NULL.
void* ThreadCache::FetchFromCentralCache(size_t cl, size_t byte_size) {
  FreeList* list = &list_[cl];
  ASSERT(list->empty());
  const int batch_size = Static::sizemap()->num_objects_to_move(cl);

  const int num_to_move = min<int>(list->max_length(), batch_size);
  void *start, *end;
  int fetch_count = Static::central_cache()[cl].RemoveRange(
      &start, &end, num_to_move);

  ASSERT((start == NULL) == (fetch_count == 0));
  if (--fetch_count >= 0) {
    size_ += byte_size * fetch_count;
    list->PushRange(fetch_count, SLL_Next(start), end);
  }

  // Increase max length slowly up to batch_size.  After that,
  // increase by batch_size in one shot so that the length is a
  // multiple of batch_size.
  if (list->max_length() < batch_size) {
    list->set_max_length(list->max_length() + 1);
  } else {
    // Don't let the list get too long.  In 32 bit builds, the length
    // is represented by a 16 bit int, so we need to watch out for
    // integer overflow.
    int new_length = min<int>(list->max_length() + batch_size,
                              kMaxDynamicFreeListLength);
    // The list's max_length must always be a multiple of batch_size,
    // and kMaxDynamicFreeListLength is not necessarily a multiple
    // of batch_size.
    new_length -= new_length % batch_size;
    ASSERT(new_length % batch_size == 0);
    list->set_max_length(new_length);
  }
  return start;
}

void ThreadCache::ListTooLong(FreeList* list, size_t cl) {
  const int batch_size = Static::sizemap()->num_objects_to_move(cl);
  ReleaseToCentralCache(list, cl, batch_size);

  // If the list is too long, we need to transfer some number of
  // objects to the central cache.  Ideally, we would transfer
  // num_objects_to_move, so the code below tries to make max_length
  // converge on num_objects_to_move.

  if (list->max_length() < batch_size) {
    // Slow start the max_length so we don't overreserve.
    list->set_max_length(list->max_length() + 1);
  } else if (list->max_length() > batch_size) {
    // If we consistently go over max_length, shrink max_length.  If we don't
    // shrink it, some amount of memory will always stay in this freelist.
    list->set_length_overages(list->length_overages() + 1);
    if (list->length_overages() > kMaxOverages) {
      ASSERT(list->max_length() > batch_size);
      list->set_max_length(list->max_length() - batch_size);
      list->set_length_overages(0);
    }
  }
}

// Remove some objects of class "cl" from thread heap and add to central cache
void ThreadCache::ReleaseToCentralCache(FreeList* src, size_t cl, int N) {
  ASSERT(src == &list_[cl]);
  if (N > src->length()) N = src->length();
  size_t delta_bytes = N * Static::sizemap()->ByteSizeForClass(cl);

  // We return prepackaged chains of the correct size to the central cache.
  // TODO: Use the same format internally in the thread caches?
  int batch_size = Static::sizemap()->num_objects_to_move(cl);
  while (N > batch_size) {
    void *tail, *head;
    src->PopRange(batch_size, &head, &tail);
    Static::central_cache()[cl].InsertRange(head, tail, batch_size);
    N -= batch_size;
  }
  void *tail, *head;
  src->PopRange(N, &head, &tail);
  Static::central_cache()[cl].InsertRange(head, tail, N);
  size_ -= delta_bytes;
}

// Release idle memory to the central cache
void ThreadCache::Scavenge() {
  // If the low-water mark for the free list is L, it means we would
  // not have had to allocate anything from the central cache even if
  // we had reduced the free list size by L.  We aim to get closer to
  // that situation by dropping L/2 nodes from the free list.  This
  // may not release much memory, but if so we will call scavenge again
  // pretty soon and the low-water marks will be high on that call.
  //int64 start = CycleClock::Now();
  for (int cl = 0; cl < kNumClasses; cl++) {
    FreeList* list = &list_[cl];
    const int lowmark = list->lowwatermark();
    if (lowmark > 0) {
      const int drop = (lowmark > 1) ? lowmark/2 : 1;
      ReleaseToCentralCache(list, cl, drop);

      // Shrink the max length if it isn't used.  Only shrink down to
      // batch_size -- if the thread was active enough to get the max_length
      // above batch_size, it will likely be that active again.  If
      // max_length shinks below batch_size, the thread will have to
      // go through the slow-start behavior again.  The slow-start is useful
      // mainly for threads that stay relatively idle for their entire
      // lifetime.
      const int batch_size = Static::sizemap()->num_objects_to_move(cl);
      if (list->max_length() > batch_size) {
        list->set_max_length(
            max<int>(list->max_length() - batch_size, batch_size));
      }
    }
    list->clear_lowwatermark();
  }

  IncreaseCacheLimit();
}

void ThreadCache::IncreaseCacheLimit() {
  SpinLockHolder h(Static::pageheap_lock());
  IncreaseCacheLimitLocked();
}

void ThreadCache::IncreaseCacheLimitLocked() {
  if (unclaimed_cache_space_ > 0) {
    // Possibly make unclaimed_cache_space_ negative.
    unclaimed_cache_space_ -= kStealAmount;
    max_size_ += kStealAmount;
    return;
  }
  // Don't hold pageheap_lock too long.  Try to steal from 10 other
  // threads before giving up.  The i < 10 condition also prevents an
  // infinite loop in case none of the existing thread heaps are
  // suitable places to steal from.
  for (int i = 0; i < 10;
       ++i, next_memory_steal_ = next_memory_steal_->next_) {
    // Reached the end of the linked list.  Start at the beginning.
    if (next_memory_steal_ == NULL) {
      ASSERT(thread_heaps_ != NULL);
      next_memory_steal_ = thread_heaps_;
    }
    if (next_memory_steal_ == this ||
        next_memory_steal_->max_size_ <= kMinThreadCacheSize) {
      continue;
    }
    next_memory_steal_->max_size_ -= kStealAmount;
    max_size_ += kStealAmount;

    next_memory_steal_ = next_memory_steal_->next_;
    return;
  }
}

int ThreadCache::GetSamplePeriod() {
  return sampler_.GetSamplePeriod();
}

void ThreadCache::InitModule() {
  SpinLockHolder h(Static::pageheap_lock());
  if (!phinited) {
    Static::InitStaticVars();
    threadcache_allocator.Init();
    phinited = 1;
  }
}

void ThreadCache::InitTSD() {
  ASSERT(!tsd_inited_);
  perftools_pthread_key_create(&heap_key_, DestroyThreadCache);
  tsd_inited_ = true;

#ifdef PTHREADS_CRASHES_IF_RUN_TOO_EARLY
  // We may have used a fake pthread_t for the main thread.  Fix it.
  pthread_t zero;
  memset(&zero, 0, sizeof(zero));
  SpinLockHolder h(Static::pageheap_lock());
  for (ThreadCache* h = thread_heaps_; h != NULL; h = h->next_) {
    if (h->tid_ == zero) {
      h->tid_ = pthread_self();
    }
  }
#endif
}

ThreadCache* ThreadCache::CreateCacheIfNecessary() {
  // Initialize per-thread data if necessary
  ThreadCache* heap = NULL;
  {
    SpinLockHolder h(Static::pageheap_lock());
    // On some old glibc's, and on freebsd's libc (as of freebsd 8.1),
    // calling pthread routines (even pthread_self) too early could
    // cause a segfault.  Since we can call pthreads quite early, we
    // have to protect against that in such situations by making a
    // 'fake' pthread.  This is not ideal since it doesn't work well
    // when linking tcmalloc statically with apps that create threads
    // before main, so we only do it if we have to.
#ifdef PTHREADS_CRASHES_IF_RUN_TOO_EARLY
    pthread_t me;
    if (!tsd_inited_) {
      memset(&me, 0, sizeof(me));
    } else {
      me = pthread_self();
    }
#else
    const pthread_t me = pthread_self();
#endif

    // This may be a recursive malloc call from pthread_setspecific()
    // In that case, the heap for this thread has already been created
    // and added to the linked list.  So we search for that first.
    for (ThreadCache* h = thread_heaps_; h != NULL; h = h->next_) {
      if (h->tid_ == me) {
        heap = h;
        break;
      }
    }

    if (heap == NULL) heap = NewHeap(me);
  }

  // We call pthread_setspecific() outside the lock because it may
  // call malloc() recursively.  We check for the recursive call using
  // the "in_setspecific_" flag so that we can avoid calling
  // pthread_setspecific() if we are already inside pthread_setspecific().
  if (!heap->in_setspecific_ && tsd_inited_) {
    heap->in_setspecific_ = true;
    perftools_pthread_setspecific(heap_key_, heap);
#ifdef HAVE_TLS
    // Also keep a copy in __thread for faster retrieval
    threadlocal_heap_ = heap;
#endif
    heap->in_setspecific_ = false;
  }
  return heap;
}

ThreadCache* ThreadCache::NewHeap(pthread_t tid) {
  // Create the heap and add it to the linked list
  ThreadCache *heap = threadcache_allocator.New();
  heap->Init(tid);
  heap->next_ = thread_heaps_;
  heap->prev_ = NULL;
  if (thread_heaps_ != NULL) {
    thread_heaps_->prev_ = heap;
  } else {
    // This is the only thread heap at the momment.
    ASSERT(next_memory_steal_ == NULL);
    next_memory_steal_ = heap;
  }
  thread_heaps_ = heap;
  thread_heap_count_++;
  return heap;
}

void ThreadCache::BecomeIdle() {
  if (!tsd_inited_) return;              // No caches yet
  ThreadCache* heap = GetThreadHeap();
  if (heap == NULL) return;             // No thread cache to remove
  if (heap->in_setspecific_) return;    // Do not disturb the active caller

  heap->in_setspecific_ = true;
  perftools_pthread_setspecific(heap_key_, NULL);
#ifdef HAVE_TLS
  // Also update the copy in __thread
  threadlocal_heap_ = NULL;
#endif
  heap->in_setspecific_ = false;
  if (GetThreadHeap() == heap) {
    // Somehow heap got reinstated by a recursive call to malloc
    // from pthread_setspecific.  We give up in this case.
    return;
  }

  // We can now get rid of the heap
  DeleteCache(heap);
}

void ThreadCache::DestroyThreadCache(void* ptr) {
  // Note that "ptr" cannot be NULL since pthread promises not
  // to invoke the destructor on NULL values, but for safety,
  // we check anyway.
  if (ptr == NULL) return;
#ifdef HAVE_TLS
  // Prevent fast path of GetThreadHeap() from returning heap.
  threadlocal_heap_ = NULL;
#endif
  DeleteCache(reinterpret_cast<ThreadCache*>(ptr));
}

void ThreadCache::DeleteCache(ThreadCache* heap) {
  // Remove all memory from heap
  heap->Cleanup();

  // Remove from linked list
  SpinLockHolder h(Static::pageheap_lock());
  if (heap->next_ != NULL) heap->next_->prev_ = heap->prev_;
  if (heap->prev_ != NULL) heap->prev_->next_ = heap->next_;
  if (thread_heaps_ == heap) thread_heaps_ = heap->next_;
  thread_heap_count_--;

  if (next_memory_steal_ == heap) next_memory_steal_ = heap->next_;
  if (next_memory_steal_ == NULL) next_memory_steal_ = thread_heaps_;
  unclaimed_cache_space_ += heap->max_size_;

  threadcache_allocator.Delete(heap);
}

void ThreadCache::RecomputePerThreadCacheSize() {
  // Divide available space across threads
  int n = thread_heap_count_ > 0 ? thread_heap_count_ : 1;
  size_t space = overall_thread_cache_size_ / n;

  // Limit to allowed range
  if (space < kMinThreadCacheSize) space = kMinThreadCacheSize;
  if (space > kMaxThreadCacheSize) space = kMaxThreadCacheSize;

  double ratio = space / max<double>(1, per_thread_cache_size_);
  size_t claimed = 0;
  for (ThreadCache* h = thread_heaps_; h != NULL; h = h->next_) {
    // Increasing the total cache size should not circumvent the
    // slow-start growth of max_size_.
    if (ratio < 1.0) {
        h->max_size_ = static_cast<size_t>(h->max_size_ * ratio);
    }
    claimed += h->max_size_;
  }
  unclaimed_cache_space_ = overall_thread_cache_size_ - claimed;
  per_thread_cache_size_ = space;
}

void ThreadCache::GetThreadStats(uint64_t* total_bytes, uint64_t* class_count) {
  for (ThreadCache* h = thread_heaps_; h != NULL; h = h->next_) {
    *total_bytes += h->Size();
    if (class_count) {
      for (int cl = 0; cl < kNumClasses; ++cl) {
        class_count[cl] += h->freelist_length(cl);
      }
    }
  }
}

void ThreadCache::set_overall_thread_cache_size(size_t new_size) {
  // Clip the value to a reasonable range
  if (new_size < kMinThreadCacheSize) new_size = kMinThreadCacheSize;
  if (new_size > (1<<30)) new_size = (1<<30);     // Limit to 1GB
  overall_thread_cache_size_ = new_size;

  RecomputePerThreadCacheSize();
}

}  // namespace tcmalloc
