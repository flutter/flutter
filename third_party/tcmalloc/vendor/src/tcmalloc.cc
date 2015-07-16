// Copyright (c) 2005, Google Inc.
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
//
// A malloc that uses a per-thread cache to satisfy small malloc requests.
// (The time for malloc/free of a small object drops from 300 ns to 50 ns.)
//
// See doc/tcmalloc.html for a high-level
// description of how this malloc works.
//
// SYNCHRONIZATION
//  1. The thread-specific lists are accessed without acquiring any locks.
//     This is safe because each such list is only accessed by one thread.
//  2. We have a lock per central free-list, and hold it while manipulating
//     the central free list for a particular size.
//  3. The central page allocator is protected by "pageheap_lock".
//  4. The pagemap (which maps from page-number to descriptor),
//     can be read without holding any locks, and written while holding
//     the "pageheap_lock".
//  5. To improve performance, a subset of the information one can get
//     from the pagemap is cached in a data structure, pagemap_cache_,
//     that atomically reads and writes its entries.  This cache can be
//     read and written without locking.
//
//     This multi-threaded access to the pagemap is safe for fairly
//     subtle reasons.  We basically assume that when an object X is
//     allocated by thread A and deallocated by thread B, there must
//     have been appropriate synchronization in the handoff of object
//     X from thread A to thread B.  The same logic applies to pagemap_cache_.
//
// THE PAGEID-TO-SIZECLASS CACHE
// Hot PageID-to-sizeclass mappings are held by pagemap_cache_.  If this cache
// returns 0 for a particular PageID then that means "no information," not that
// the sizeclass is 0.  The cache may have stale information for pages that do
// not hold the beginning of any free()'able object.  Staleness is eliminated
// in Populate() for pages with sizeclass > 0 objects, and in do_malloc() and
// do_memalign() for all other relevant pages.
//
// PAGEMAP
// -------
// Page map contains a mapping from page id to Span.
//
// If Span s occupies pages [p..q],
//      pagemap[p] == s
//      pagemap[q] == s
//      pagemap[p+1..q-1] are undefined
//      pagemap[p-1] and pagemap[q+1] are defined:
//         NULL if the corresponding page is not yet in the address space.
//         Otherwise it points to a Span.  This span may be free
//         or allocated.  If free, it is in one of pageheap's freelist.
//
// TODO: Bias reclamation to larger addresses
// TODO: implement mallinfo/mallopt
// TODO: Better testing
//
// 9/28/2003 (new page-level allocator replaces ptmalloc2):
// * malloc/free of small objects goes from ~300 ns to ~50 ns.
// * allocation of a reasonably complicated struct
//   goes from about 1100 ns to about 300 ns.

#include "config.h"
#include <gperftools/tcmalloc.h>

#include <errno.h>                      // for ENOMEM, EINVAL, errno
#ifdef HAVE_SYS_CDEFS_H
#include <sys/cdefs.h>                  // for __THROW
#endif
#if defined HAVE_STDINT_H
#include <stdint.h>
#elif defined HAVE_INTTYPES_H
#include <inttypes.h>
#else
#include <sys/types.h>
#endif
#include <stddef.h>                     // for size_t, NULL
#include <stdlib.h>                     // for getenv
#include <string.h>                     // for strcmp, memset, strlen, etc
#ifdef HAVE_UNISTD_H
#include <unistd.h>                     // for getpagesize, write, etc
#endif
#include <algorithm>                    // for max, min
#include <limits>                       // for numeric_limits
#include <new>                          // for nothrow_t (ptr only), etc
#include <vector>                       // for vector

#include <gperftools/malloc_extension.h>
#include <gperftools/malloc_hook.h>         // for MallocHook
#include "base/basictypes.h"            // for int64
#include "base/commandlineflags.h"      // for RegisterFlagValidator, etc
#include "base/dynamic_annotations.h"   // for RunningOnValgrind
#include "base/spinlock.h"              // for SpinLockHolder
#include "central_freelist.h"  // for CentralFreeListPadded
#include "common.h"            // for StackTrace, kPageShift, etc
#include "internal_logging.h"  // for ASSERT, TCMalloc_Printer, etc
#include "linked_list.h"       // for SLL_SetNext
#include "malloc_hook-inl.h"       // for MallocHook::InvokeNewHook, etc
#include "page_heap.h"         // for PageHeap, PageHeap::Stats
#include "page_heap_allocator.h"  // for PageHeapAllocator
#include "span.h"              // for Span, DLL_Prepend, etc
#include "stack_trace_table.h"  // for StackTraceTable
#include "static_vars.h"       // for Static
#include "system-alloc.h"      // for DumpSystemAllocatorStats, etc
#include "tcmalloc_guard.h"    // for TCMallocGuard
#include "thread_cache.h"      // for ThreadCache

// We only need malloc.h for struct mallinfo.
#ifdef HAVE_STRUCT_MALLINFO
// Malloc can be in several places on older versions of OS X.
# if defined(HAVE_MALLOC_H)
# include <malloc.h>
# elif defined(HAVE_SYS_MALLOC_H)
# include <sys/malloc.h>
# elif defined(HAVE_MALLOC_MALLOC_H)
# include <malloc/malloc.h>
# endif
#endif

#if (defined(_WIN32) && !defined(__CYGWIN__) && !defined(__CYGWIN32__)) && !defined(WIN32_OVERRIDE_ALLOCATORS)
# define WIN32_DO_PATCHING 1
#endif

// Some windows file somewhere (at least on cygwin) #define's small (!)
#undef small

using STL_NAMESPACE::max;
using STL_NAMESPACE::numeric_limits;
using STL_NAMESPACE::vector;

#include "libc_override.h"

// __THROW is defined in glibc (via <sys/cdefs.h>).  It means,
// counter-intuitively, "This function will never throw an exception."
// It's an optional optimization tool, but we may need to use it to
// match glibc prototypes.
#ifndef __THROW    // I guess we're not on a glibc system
# define __THROW   // __THROW is just an optimization, so ok to make it ""
#endif

using tcmalloc::AlignmentForSize;
using tcmalloc::kLog;
using tcmalloc::kCrash;
using tcmalloc::kCrashWithStats;
using tcmalloc::Log;
using tcmalloc::PageHeap;
using tcmalloc::PageHeapAllocator;
using tcmalloc::SizeMap;
using tcmalloc::Span;
using tcmalloc::StackTrace;
using tcmalloc::Static;
using tcmalloc::ThreadCache;

DECLARE_int64(tcmalloc_sample_parameter);
DECLARE_double(tcmalloc_release_rate);

// For windows, the printf we use to report large allocs is
// potentially dangerous: it could cause a malloc that would cause an
// infinite loop.  So by default we set the threshold to a huge number
// on windows, so this bad situation will never trigger.  You can
// always set TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD manually if you
// want this functionality.
#ifdef _WIN32
const int64 kDefaultLargeAllocReportThreshold = static_cast<int64>(1) << 62;
#else
const int64 kDefaultLargeAllocReportThreshold = static_cast<int64>(1) << 30;
#endif
DEFINE_int64(tcmalloc_large_alloc_report_threshold,
             EnvToInt64("TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD",
                        kDefaultLargeAllocReportThreshold),
             "Allocations larger than this value cause a stack "
             "trace to be dumped to stderr.  The threshold for "
             "dumping stack traces is increased by a factor of 1.125 "
             "every time we print a message so that the threshold "
             "automatically goes up by a factor of ~1000 every 60 "
             "messages.  This bounds the amount of extra logging "
             "generated by this flag.  Default value of this flag "
             "is very large and therefore you should see no extra "
             "logging unless the flag is overridden.  Set to 0 to "
             "disable reporting entirely.");


// We already declared these functions in tcmalloc.h, but we have to
// declare them again to give them an ATTRIBUTE_SECTION: we want to
// put all callers of MallocHook::Invoke* in this module into
// ATTRIBUTE_SECTION(google_malloc) section, so that
// MallocHook::GetCallerStackTrace can function accurately.
#ifndef _WIN32   // windows doesn't have attribute_section, so don't bother
extern "C" {
  void* tc_malloc(size_t size) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void tc_free(void* ptr) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void* tc_realloc(void* ptr, size_t size) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void* tc_calloc(size_t nmemb, size_t size) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void tc_cfree(void* ptr) __THROW
      ATTRIBUTE_SECTION(google_malloc);

  void* tc_memalign(size_t __alignment, size_t __size) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  int tc_posix_memalign(void** ptr, size_t align, size_t size) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void* tc_valloc(size_t __size) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void* tc_pvalloc(size_t __size) __THROW
      ATTRIBUTE_SECTION(google_malloc);

  void tc_malloc_stats(void) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  int tc_mallopt(int cmd, int value) __THROW
      ATTRIBUTE_SECTION(google_malloc);
#ifdef HAVE_STRUCT_MALLINFO
  struct mallinfo tc_mallinfo(void) __THROW
      ATTRIBUTE_SECTION(google_malloc);
#endif

  void* tc_new(size_t size)
      ATTRIBUTE_SECTION(google_malloc);
  void tc_delete(void* p) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void* tc_newarray(size_t size)
      ATTRIBUTE_SECTION(google_malloc);
  void tc_deletearray(void* p) __THROW
      ATTRIBUTE_SECTION(google_malloc);

  // And the nothrow variants of these:
  void* tc_new_nothrow(size_t size, const std::nothrow_t&) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void* tc_newarray_nothrow(size_t size, const std::nothrow_t&) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  // Surprisingly, standard C++ library implementations use a
  // nothrow-delete internally.  See, eg:
  // http://www.dinkumware.com/manuals/?manual=compleat&page=new.html
  void tc_delete_nothrow(void* ptr, const std::nothrow_t&) __THROW
      ATTRIBUTE_SECTION(google_malloc);
  void tc_deletearray_nothrow(void* ptr, const std::nothrow_t&) __THROW
      ATTRIBUTE_SECTION(google_malloc);

  // Some non-standard extensions that we support.

  // This is equivalent to
  //    OS X: malloc_size()
  //    glibc: malloc_usable_size()
  //    Windows: _msize()
  size_t tc_malloc_size(void* p) __THROW
      ATTRIBUTE_SECTION(google_malloc);
}  // extern "C"
#endif  // #ifndef _WIN32

// ----------------------- IMPLEMENTATION -------------------------------

static int tc_new_mode = 0;  // See tc_set_new_mode().

// Routines such as free() and realloc() catch some erroneous pointers
// passed to them, and invoke the below when they do.  (An erroneous pointer
// won't be caught if it's within a valid span or a stale span for which
// the pagemap cache has a non-zero sizeclass.) This is a cheap (source-editing
// required) kind of exception handling for these routines.
namespace {
void InvalidFree(void* ptr) {
  Log(kCrash, __FILE__, __LINE__, "Attempt to free invalid pointer", ptr);
}

size_t InvalidGetSizeForRealloc(const void* old_ptr) {
  Log(kCrash, __FILE__, __LINE__,
      "Attempt to realloc invalid pointer", old_ptr);
  return 0;
}

size_t InvalidGetAllocatedSize(const void* ptr) {
  Log(kCrash, __FILE__, __LINE__,
      "Attempt to get the size of an invalid pointer", ptr);
  return 0;
}
}  // unnamed namespace

// Extract interesting stats
struct TCMallocStats {
  uint64_t thread_bytes;      // Bytes in thread caches
  uint64_t central_bytes;     // Bytes in central cache
  uint64_t transfer_bytes;    // Bytes in central transfer cache
  uint64_t metadata_bytes;    // Bytes alloced for metadata
  PageHeap::Stats pageheap;   // Stats from page heap
};

// Get stats into "r".  Also get per-size-class counts if class_count != NULL
static void ExtractStats(TCMallocStats* r, uint64_t* class_count,
                         PageHeap::SmallSpanStats* small_spans,
                         PageHeap::LargeSpanStats* large_spans) {
  r->central_bytes = 0;
  r->transfer_bytes = 0;
  for (int cl = 0; cl < kNumClasses; ++cl) {
    const int length = Static::central_cache()[cl].length();
    const int tc_length = Static::central_cache()[cl].tc_length();
    const size_t cache_overhead = Static::central_cache()[cl].OverheadBytes();
    const size_t size = static_cast<uint64_t>(
        Static::sizemap()->ByteSizeForClass(cl));
    r->central_bytes += (size * length) + cache_overhead;
    r->transfer_bytes += (size * tc_length);
    if (class_count) class_count[cl] = length + tc_length;
  }

  // Add stats from per-thread heaps
  r->thread_bytes = 0;
  { // scope
    SpinLockHolder h(Static::pageheap_lock());
    ThreadCache::GetThreadStats(&r->thread_bytes, class_count);
    r->metadata_bytes = tcmalloc::metadata_system_bytes();
    r->pageheap = Static::pageheap()->stats();
    if (small_spans != NULL) {
      Static::pageheap()->GetSmallSpanStats(small_spans);
    }
    if (large_spans != NULL) {
      Static::pageheap()->GetLargeSpanStats(large_spans);
    }
  }
}

static double PagesToMiB(uint64_t pages) {
  return (pages << kPageShift) / 1048576.0;
}

// WRITE stats to "out"
static void DumpStats(TCMalloc_Printer* out, int level) {
  TCMallocStats stats;
  uint64_t class_count[kNumClasses];
  PageHeap::SmallSpanStats small;
  PageHeap::LargeSpanStats large;
  if (level >= 2) {
    ExtractStats(&stats, class_count, &small, &large);
  } else {
    ExtractStats(&stats, NULL, NULL, NULL);
  }

  static const double MiB = 1048576.0;

  const uint64_t virtual_memory_used = (stats.pageheap.system_bytes
                                        + stats.metadata_bytes);
  const uint64_t physical_memory_used = (virtual_memory_used
                                         - stats.pageheap.unmapped_bytes);
  const uint64_t bytes_in_use_by_app = (physical_memory_used
                                        - stats.metadata_bytes
                                        - stats.pageheap.free_bytes
                                        - stats.central_bytes
                                        - stats.transfer_bytes
                                        - stats.thread_bytes);

#ifdef TCMALLOC_SMALL_BUT_SLOW
  out->printf(
      "NOTE:  SMALL MEMORY MODEL IS IN USE, PERFORMANCE MAY SUFFER.\n");
#endif
  out->printf(
      "------------------------------------------------\n"
      "MALLOC:   %12" PRIu64 " (%7.1f MiB) Bytes in use by application\n"
      "MALLOC: + %12" PRIu64 " (%7.1f MiB) Bytes in page heap freelist\n"
      "MALLOC: + %12" PRIu64 " (%7.1f MiB) Bytes in central cache freelist\n"
      "MALLOC: + %12" PRIu64 " (%7.1f MiB) Bytes in transfer cache freelist\n"
      "MALLOC: + %12" PRIu64 " (%7.1f MiB) Bytes in thread cache freelists\n"
      "MALLOC: + %12" PRIu64 " (%7.1f MiB) Bytes in malloc metadata\n"
      "MALLOC:   ------------\n"
      "MALLOC: = %12" PRIu64 " (%7.1f MiB) Actual memory used (physical + swap)\n"
      "MALLOC: + %12" PRIu64 " (%7.1f MiB) Bytes released to OS (aka unmapped)\n"
      "MALLOC:   ------------\n"
      "MALLOC: = %12" PRIu64 " (%7.1f MiB) Virtual address space used\n"
      "MALLOC:\n"
      "MALLOC:   %12" PRIu64 "              Spans in use\n"
      "MALLOC:   %12" PRIu64 "              Thread heaps in use\n"
      "MALLOC:   %12" PRIu64 "              Tcmalloc page size\n"
      "------------------------------------------------\n"
      "Call ReleaseFreeMemory() to release freelist memory to the OS"
      " (via madvise()).\n"
      "Bytes released to the OS take up virtual address space"
      " but no physical memory.\n",
      bytes_in_use_by_app, bytes_in_use_by_app / MiB,
      stats.pageheap.free_bytes, stats.pageheap.free_bytes / MiB,
      stats.central_bytes, stats.central_bytes / MiB,
      stats.transfer_bytes, stats.transfer_bytes / MiB,
      stats.thread_bytes, stats.thread_bytes / MiB,
      stats.metadata_bytes, stats.metadata_bytes / MiB,
      physical_memory_used, physical_memory_used / MiB,
      stats.pageheap.unmapped_bytes, stats.pageheap.unmapped_bytes / MiB,
      virtual_memory_used, virtual_memory_used / MiB,
      uint64_t(Static::span_allocator()->inuse()),
      uint64_t(ThreadCache::HeapsInUse()),
      uint64_t(kPageSize));

  if (level >= 2) {
    out->printf("------------------------------------------------\n");
    out->printf("Size class breakdown\n");
    out->printf("------------------------------------------------\n");
    uint64_t cumulative = 0;
    for (int cl = 0; cl < kNumClasses; ++cl) {
      if (class_count[cl] > 0) {
        uint64_t class_bytes =
            class_count[cl] * Static::sizemap()->ByteSizeForClass(cl);
        cumulative += class_bytes;
        out->printf("class %3d [ %8" PRIuS " bytes ] : "
                "%8" PRIu64 " objs; %5.1f MiB; %5.1f cum MiB\n",
                cl, Static::sizemap()->ByteSizeForClass(cl),
                class_count[cl],
                class_bytes / MiB,
                cumulative / MiB);
      }
    }

    // append page heap info
    int nonempty_sizes = 0;
    for (int s = 0; s < kMaxPages; s++) {
      if (small.normal_length[s] + small.returned_length[s] > 0) {
        nonempty_sizes++;
      }
    }
    out->printf("------------------------------------------------\n");
    out->printf("PageHeap: %d sizes; %6.1f MiB free; %6.1f MiB unmapped\n",
                nonempty_sizes, stats.pageheap.free_bytes / MiB,
                stats.pageheap.unmapped_bytes / MiB);
    out->printf("------------------------------------------------\n");
    uint64_t total_normal = 0;
    uint64_t total_returned = 0;
    for (int s = 0; s < kMaxPages; s++) {
      const int n_length = small.normal_length[s];
      const int r_length = small.returned_length[s];
      if (n_length + r_length > 0) {
        uint64_t n_pages = s * n_length;
        uint64_t r_pages = s * r_length;
        total_normal += n_pages;
        total_returned += r_pages;
        out->printf("%6u pages * %6u spans ~ %6.1f MiB; %6.1f MiB cum"
                    "; unmapped: %6.1f MiB; %6.1f MiB cum\n",
                    s,
                    (n_length + r_length),
                    PagesToMiB(n_pages + r_pages),
                    PagesToMiB(total_normal + total_returned),
                    PagesToMiB(r_pages),
                    PagesToMiB(total_returned));
      }
    }

    total_normal += large.normal_pages;
    total_returned += large.returned_pages;
    out->printf(">255   large * %6u spans ~ %6.1f MiB; %6.1f MiB cum"
                "; unmapped: %6.1f MiB; %6.1f MiB cum\n",
                static_cast<unsigned int>(large.spans),
                PagesToMiB(large.normal_pages + large.returned_pages),
                PagesToMiB(total_normal + total_returned),
                PagesToMiB(large.returned_pages),
                PagesToMiB(total_returned));
  }
}

static void PrintStats(int level) {
  const int kBufferSize = 16 << 10;
  char* buffer = new char[kBufferSize];
  TCMalloc_Printer printer(buffer, kBufferSize);
  DumpStats(&printer, level);
  write(STDERR_FILENO, buffer, strlen(buffer));
  delete[] buffer;
}

static void** DumpHeapGrowthStackTraces() {
  // Count how much space we need
  int needed_slots = 0;
  {
    SpinLockHolder h(Static::pageheap_lock());
    for (StackTrace* t = Static::growth_stacks();
         t != NULL;
         t = reinterpret_cast<StackTrace*>(
             t->stack[tcmalloc::kMaxStackDepth-1])) {
      needed_slots += 3 + t->depth;
    }
    needed_slots += 100;            // Slop in case list grows
    needed_slots += needed_slots/8; // An extra 12.5% slop
  }

  void** result = new void*[needed_slots];
  if (result == NULL) {
    Log(kLog, __FILE__, __LINE__,
        "tcmalloc: allocation failed for stack trace slots",
        needed_slots * sizeof(*result));
    return NULL;
  }

  SpinLockHolder h(Static::pageheap_lock());
  int used_slots = 0;
  for (StackTrace* t = Static::growth_stacks();
       t != NULL;
       t = reinterpret_cast<StackTrace*>(
           t->stack[tcmalloc::kMaxStackDepth-1])) {
    ASSERT(used_slots < needed_slots);  // Need to leave room for terminator
    if (used_slots + 3 + t->depth >= needed_slots) {
      // No more room
      break;
    }

    result[used_slots+0] = reinterpret_cast<void*>(static_cast<uintptr_t>(1));
    result[used_slots+1] = reinterpret_cast<void*>(t->size);
    result[used_slots+2] = reinterpret_cast<void*>(t->depth);
    for (int d = 0; d < t->depth; d++) {
      result[used_slots+3+d] = t->stack[d];
    }
    used_slots += 3 + t->depth;
  }
  result[used_slots] = reinterpret_cast<void*>(static_cast<uintptr_t>(0));
  return result;
}

static void IterateOverRanges(void* arg, MallocExtension::RangeFunction func) {
  PageID page = 1;  // Some code may assume that page==0 is never used
  bool done = false;
  while (!done) {
    // Accumulate a small number of ranges in a local buffer
    static const int kNumRanges = 16;
    static base::MallocRange ranges[kNumRanges];
    int n = 0;
    {
      SpinLockHolder h(Static::pageheap_lock());
      while (n < kNumRanges) {
        if (!Static::pageheap()->GetNextRange(page, &ranges[n])) {
          done = true;
          break;
        } else {
          uintptr_t limit = ranges[n].address + ranges[n].length;
          page = (limit + kPageSize - 1) >> kPageShift;
          n++;
        }
      }
    }

    for (int i = 0; i < n; i++) {
      (*func)(arg, &ranges[i]);
    }
  }
}

// TCMalloc's support for extra malloc interfaces
class TCMallocImplementation : public MallocExtension {
 private:
  // ReleaseToSystem() might release more than the requested bytes because
  // the page heap releases at the span granularity, and spans are of wildly
  // different sizes.  This member keeps track of the extra bytes bytes
  // released so that the app can periodically call ReleaseToSystem() to
  // release memory at a constant rate.
  // NOTE: Protected by Static::pageheap_lock().
  size_t extra_bytes_released_;

 public:
  TCMallocImplementation()
      : extra_bytes_released_(0) {
  }

  virtual void GetStats(char* buffer, int buffer_length) {
    ASSERT(buffer_length > 0);
    TCMalloc_Printer printer(buffer, buffer_length);

    // Print level one stats unless lots of space is available
    if (buffer_length < 10000) {
      DumpStats(&printer, 1);
    } else {
      DumpStats(&printer, 2);
    }
  }

  // We may print an extra, tcmalloc-specific warning message here.
  virtual void GetHeapSample(MallocExtensionWriter* writer) {
    if (FLAGS_tcmalloc_sample_parameter == 0) {
      const char* const kWarningMsg =
          "%warn\n"
          "%warn This heap profile does not have any data in it, because\n"
          "%warn the application was run with heap sampling turned off.\n"
          "%warn To get useful data from GetHeapSample(), you must\n"
          "%warn set the environment variable TCMALLOC_SAMPLE_PARAMETER to\n"
          "%warn a positive sampling period, such as 524288.\n"
          "%warn\n";
      writer->append(kWarningMsg, strlen(kWarningMsg));
    }
    MallocExtension::GetHeapSample(writer);
  }

  virtual void** ReadStackTraces(int* sample_period) {
    tcmalloc::StackTraceTable table;
    {
      SpinLockHolder h(Static::pageheap_lock());
      Span* sampled = Static::sampled_objects();
      for (Span* s = sampled->next; s != sampled; s = s->next) {
        table.AddTrace(*reinterpret_cast<StackTrace*>(s->objects));
      }
    }
    *sample_period = ThreadCache::GetCache()->GetSamplePeriod();
    return table.ReadStackTracesAndClear(); // grabs and releases pageheap_lock
  }

  virtual void** ReadHeapGrowthStackTraces() {
    return DumpHeapGrowthStackTraces();
  }

  virtual void Ranges(void* arg, RangeFunction func) {
    IterateOverRanges(arg, func);
  }

  virtual bool GetNumericProperty(const char* name, size_t* value) {
    ASSERT(name != NULL);

    if (strcmp(name, "generic.current_allocated_bytes") == 0) {
      TCMallocStats stats;
      ExtractStats(&stats, NULL, NULL, NULL);
      *value = stats.pageheap.system_bytes
               - stats.thread_bytes
               - stats.central_bytes
               - stats.transfer_bytes
               - stats.pageheap.free_bytes
               - stats.pageheap.unmapped_bytes;
      return true;
    }

    if (strcmp(name, "generic.heap_size") == 0) {
      TCMallocStats stats;
      ExtractStats(&stats, NULL, NULL, NULL);
      *value = stats.pageheap.system_bytes;
      return true;
    }

    if (strcmp(name, "tcmalloc.slack_bytes") == 0) {
      // Kept for backwards compatibility.  Now defined externally as:
      //    pageheap_free_bytes + pageheap_unmapped_bytes.
      SpinLockHolder l(Static::pageheap_lock());
      PageHeap::Stats stats = Static::pageheap()->stats();
      *value = stats.free_bytes + stats.unmapped_bytes;
      return true;
    }

    if (strcmp(name, "tcmalloc.central_cache_free_bytes") == 0) {
      TCMallocStats stats;
      ExtractStats(&stats, NULL, NULL, NULL);
      *value = stats.central_bytes;
      return true;
    }

    if (strcmp(name, "tcmalloc.transfer_cache_free_bytes") == 0) {
      TCMallocStats stats;
      ExtractStats(&stats, NULL, NULL, NULL);
      *value = stats.transfer_bytes;
      return true;
    }

    if (strcmp(name, "tcmalloc.thread_cache_free_bytes") == 0) {
      TCMallocStats stats;
      ExtractStats(&stats, NULL, NULL, NULL);
      *value = stats.thread_bytes;
      return true;
    }

    if (strcmp(name, "tcmalloc.pageheap_free_bytes") == 0) {
      SpinLockHolder l(Static::pageheap_lock());
      *value = Static::pageheap()->stats().free_bytes;
      return true;
    }

    if (strcmp(name, "tcmalloc.pageheap_unmapped_bytes") == 0) {
      SpinLockHolder l(Static::pageheap_lock());
      *value = Static::pageheap()->stats().unmapped_bytes;
      return true;
    }

    if (strcmp(name, "tcmalloc.max_total_thread_cache_bytes") == 0) {
      SpinLockHolder l(Static::pageheap_lock());
      *value = ThreadCache::overall_thread_cache_size();
      return true;
    }

    if (strcmp(name, "tcmalloc.current_total_thread_cache_bytes") == 0) {
      TCMallocStats stats;
      ExtractStats(&stats, NULL, NULL, NULL);
      *value = stats.thread_bytes;
      return true;
    }

    return false;
  }

  virtual bool SetNumericProperty(const char* name, size_t value) {
    ASSERT(name != NULL);

    if (strcmp(name, "tcmalloc.max_total_thread_cache_bytes") == 0) {
      SpinLockHolder l(Static::pageheap_lock());
      ThreadCache::set_overall_thread_cache_size(value);
      return true;
    }

    return false;
  }

  virtual void MarkThreadIdle() {
    ThreadCache::BecomeIdle();
  }

  virtual void MarkThreadBusy();  // Implemented below

  virtual SysAllocator* GetSystemAllocator() {
    SpinLockHolder h(Static::pageheap_lock());
    return sys_alloc;
  }

  virtual void SetSystemAllocator(SysAllocator* alloc) {
    SpinLockHolder h(Static::pageheap_lock());
    sys_alloc = alloc;
  }

  virtual void ReleaseToSystem(size_t num_bytes) {
    SpinLockHolder h(Static::pageheap_lock());
    if (num_bytes <= extra_bytes_released_) {
      // We released too much on a prior call, so don't release any
      // more this time.
      extra_bytes_released_ = extra_bytes_released_ - num_bytes;
      return;
    }
    num_bytes = num_bytes - extra_bytes_released_;
    // num_bytes might be less than one page.  If we pass zero to
    // ReleaseAtLeastNPages, it won't do anything, so we release a whole
    // page now and let extra_bytes_released_ smooth it out over time.
    Length num_pages = max<Length>(num_bytes >> kPageShift, 1);
    size_t bytes_released = Static::pageheap()->ReleaseAtLeastNPages(
        num_pages) << kPageShift;
    if (bytes_released > num_bytes) {
      extra_bytes_released_ = bytes_released - num_bytes;
    } else {
      // The PageHeap wasn't able to release num_bytes.  Don't try to
      // compensate with a big release next time.  Specifically,
      // ReleaseFreeMemory() calls ReleaseToSystem(LONG_MAX).
      extra_bytes_released_ = 0;
    }
  }

  virtual void SetMemoryReleaseRate(double rate) {
    FLAGS_tcmalloc_release_rate = rate;
  }

  virtual double GetMemoryReleaseRate() {
    return FLAGS_tcmalloc_release_rate;
  }
  virtual size_t GetEstimatedAllocatedSize(size_t size) {
    if (size <= kMaxSize) {
      const size_t cl = Static::sizemap()->SizeClass(size);
      const size_t alloc_size = Static::sizemap()->ByteSizeForClass(cl);
      return alloc_size;
    } else {
      return tcmalloc::pages(size) << kPageShift;
    }
  }

  // This just calls GetSizeWithCallback, but because that's in an
  // unnamed namespace, we need to move the definition below it in the
  // file.
  virtual size_t GetAllocatedSize(const void* ptr);

  // This duplicates some of the logic in GetSizeWithCallback, but is
  // faster.  This is important on OS X, where this function is called
  // on every allocation operation.
  virtual Ownership GetOwnership(const void* ptr) {
    const PageID p = reinterpret_cast<uintptr_t>(ptr) >> kPageShift;
    // The rest of tcmalloc assumes that all allocated pointers use at
    // most kAddressBits bits.  If ptr doesn't, then it definitely
    // wasn't alloacted by tcmalloc.
    if ((p >> (kAddressBits - kPageShift)) > 0) {
      return kNotOwned;
    }
    size_t cl = Static::pageheap()->GetSizeClassIfCached(p);
    if (cl != 0) {
      return kOwned;
    }
    const Span *span = Static::pageheap()->GetDescriptor(p);
    return span ? kOwned : kNotOwned;
  }

  virtual void GetFreeListSizes(vector<MallocExtension::FreeListInfo>* v) {
    static const char* kCentralCacheType = "tcmalloc.central";
    static const char* kTransferCacheType = "tcmalloc.transfer";
    static const char* kThreadCacheType = "tcmalloc.thread";
    static const char* kPageHeapType = "tcmalloc.page";
    static const char* kPageHeapUnmappedType = "tcmalloc.page_unmapped";
    static const char* kLargeSpanType = "tcmalloc.large";
    static const char* kLargeUnmappedSpanType = "tcmalloc.large_unmapped";

    v->clear();

    // central class information
    int64 prev_class_size = 0;
    for (int cl = 1; cl < kNumClasses; ++cl) {
      size_t class_size = Static::sizemap()->ByteSizeForClass(cl);
      MallocExtension::FreeListInfo i;
      i.min_object_size = prev_class_size + 1;
      i.max_object_size = class_size;
      i.total_bytes_free =
          Static::central_cache()[cl].length() * class_size;
      i.type = kCentralCacheType;
      v->push_back(i);

      // transfer cache
      i.total_bytes_free =
          Static::central_cache()[cl].tc_length() * class_size;
      i.type = kTransferCacheType;
      v->push_back(i);

      prev_class_size = Static::sizemap()->ByteSizeForClass(cl);
    }

    // Add stats from per-thread heaps
    uint64_t class_count[kNumClasses];
    memset(class_count, 0, sizeof(class_count));
    {
      SpinLockHolder h(Static::pageheap_lock());
      uint64_t thread_bytes = 0;
      ThreadCache::GetThreadStats(&thread_bytes, class_count);
    }

    prev_class_size = 0;
    for (int cl = 1; cl < kNumClasses; ++cl) {
      MallocExtension::FreeListInfo i;
      i.min_object_size = prev_class_size + 1;
      i.max_object_size = Static::sizemap()->ByteSizeForClass(cl);
      i.total_bytes_free =
          class_count[cl] * Static::sizemap()->ByteSizeForClass(cl);
      i.type = kThreadCacheType;
      v->push_back(i);
    }

    // append page heap info
    PageHeap::SmallSpanStats small;
    PageHeap::LargeSpanStats large;
    {
      SpinLockHolder h(Static::pageheap_lock());
      Static::pageheap()->GetSmallSpanStats(&small);
      Static::pageheap()->GetLargeSpanStats(&large);
    }

    // large spans: mapped
    MallocExtension::FreeListInfo span_info;
    span_info.type = kLargeSpanType;
    span_info.max_object_size = (numeric_limits<size_t>::max)();
    span_info.min_object_size = kMaxPages << kPageShift;
    span_info.total_bytes_free = large.normal_pages << kPageShift;
    v->push_back(span_info);

    // large spans: unmapped
    span_info.type = kLargeUnmappedSpanType;
    span_info.total_bytes_free = large.returned_pages << kPageShift;
    v->push_back(span_info);

    // small spans
    for (int s = 1; s < kMaxPages; s++) {
      MallocExtension::FreeListInfo i;
      i.max_object_size = (s << kPageShift);
      i.min_object_size = ((s - 1) << kPageShift);

      i.type = kPageHeapType;
      i.total_bytes_free = (s << kPageShift) * small.normal_length[s];
      v->push_back(i);

      i.type = kPageHeapUnmappedType;
      i.total_bytes_free = (s << kPageShift) * small.returned_length[s];
      v->push_back(i);
    }
  }
};

// The constructor allocates an object to ensure that initialization
// runs before main(), and therefore we do not have a chance to become
// multi-threaded before initialization.  We also create the TSD key
// here.  Presumably by the time this constructor runs, glibc is in
// good enough shape to handle pthread_key_create().
//
// The constructor also takes the opportunity to tell STL to use
// tcmalloc.  We want to do this early, before construct time, so
// all user STL allocations go through tcmalloc (which works really
// well for STL).
//
// The destructor prints stats when the program exits.
static int tcmallocguard_refcount = 0;  // no lock needed: runs before main()
TCMallocGuard::TCMallocGuard() {
  if (tcmallocguard_refcount++ == 0) {
#ifdef HAVE_TLS    // this is true if the cc/ld/libc combo support TLS
    // Check whether the kernel also supports TLS (needs to happen at runtime)
    tcmalloc::CheckIfKernelSupportsTLS();
#endif
    ReplaceSystemAlloc();    // defined in libc_override_*.h
    tc_free(tc_malloc(1));
    ThreadCache::InitTSD();
    tc_free(tc_malloc(1));
    // Either we, or debugallocation.cc, or valgrind will control memory
    // management.  We register our extension if we're the winner.
#ifdef TCMALLOC_USING_DEBUGALLOCATION
    // Let debugallocation register its extension.
#else
    if (RunningOnValgrind()) {
      // Let Valgrind uses its own malloc (so don't register our extension).
    } else {
      MallocExtension::Register(new TCMallocImplementation);
    }
#endif
  }
}

TCMallocGuard::~TCMallocGuard() {
  if (--tcmallocguard_refcount == 0) {
    const char* env = getenv("MALLOCSTATS");
    if (env != NULL) {
      int level = atoi(env);
      if (level < 1) level = 1;
      PrintStats(level);
    }
  }
}
#ifndef WIN32_OVERRIDE_ALLOCATORS
static TCMallocGuard module_enter_exit_hook;
#endif

//-------------------------------------------------------------------
// Helpers for the exported routines below
//-------------------------------------------------------------------

static inline bool CheckCachedSizeClass(void *ptr) {
  PageID p = reinterpret_cast<uintptr_t>(ptr) >> kPageShift;
  size_t cached_value = Static::pageheap()->GetSizeClassIfCached(p);
  return cached_value == 0 ||
      cached_value == Static::pageheap()->GetDescriptor(p)->sizeclass;
}

static inline void* CheckedMallocResult(void *result) {
  ASSERT(result == NULL || CheckCachedSizeClass(result));
  return result;
}

static inline void* SpanToMallocResult(Span *span) {
  Static::pageheap()->CacheSizeClass(span->start, 0);
  return
      CheckedMallocResult(reinterpret_cast<void*>(span->start << kPageShift));
}

static void* DoSampledAllocation(size_t size) {
  // Grab the stack trace outside the heap lock
  StackTrace tmp;
  tmp.depth = GetStackTrace(tmp.stack, tcmalloc::kMaxStackDepth, 1);
  tmp.size = size;

  SpinLockHolder h(Static::pageheap_lock());
  // Allocate span
  Span *span = Static::pageheap()->New(tcmalloc::pages(size == 0 ? 1 : size));
  if (span == NULL) {
    return NULL;
  }

  // Allocate stack trace
  StackTrace *stack = Static::stacktrace_allocator()->New();
  if (stack == NULL) {
    // Sampling failed because of lack of memory
    return span;
  }
  *stack = tmp;
  span->sample = 1;
  span->objects = stack;
  tcmalloc::DLL_Prepend(Static::sampled_objects(), span);

  return SpanToMallocResult(span);
}

namespace {

// Copy of FLAGS_tcmalloc_large_alloc_report_threshold with
// automatic increases factored in.
static int64_t large_alloc_threshold =
  (kPageSize > FLAGS_tcmalloc_large_alloc_report_threshold
   ? kPageSize : FLAGS_tcmalloc_large_alloc_report_threshold);

static void ReportLargeAlloc(Length num_pages, void* result) {
  StackTrace stack;
  stack.depth = GetStackTrace(stack.stack, tcmalloc::kMaxStackDepth, 1);

  static const int N = 1000;
  char buffer[N];
  TCMalloc_Printer printer(buffer, N);
  printer.printf("tcmalloc: large alloc %"PRIu64" bytes == %p @ ",
                 static_cast<uint64>(num_pages) << kPageShift,
                 result);
  for (int i = 0; i < stack.depth; i++) {
    printer.printf(" %p", stack.stack[i]);
  }
  printer.printf("\n");
  write(STDERR_FILENO, buffer, strlen(buffer));
}

inline void* cpp_alloc(size_t size, bool nothrow);
inline void* do_malloc(size_t size);

// TODO(willchan): Investigate whether or not lining this much is harmful to
// performance.
// This is equivalent to do_malloc() except when tc_new_mode is set to true.
// Otherwise, it will run the std::new_handler if set.
inline void* do_malloc_or_cpp_alloc(size_t size) {
  return tc_new_mode ? cpp_alloc(size, true) : do_malloc(size);
}

void* cpp_memalign(size_t align, size_t size);
void* do_memalign(size_t align, size_t size);

inline void* do_memalign_or_cpp_memalign(size_t align, size_t size) {
  return tc_new_mode ? cpp_memalign(align, size) : do_memalign(align, size);
}

// Must be called with the page lock held.
inline bool should_report_large(Length num_pages) {
  const int64 threshold = large_alloc_threshold;
  if (threshold > 0 && num_pages >= (threshold >> kPageShift)) {
    // Increase the threshold by 1/8 every time we generate a report.
    // We cap the threshold at 8GiB to avoid overflow problems.
    large_alloc_threshold = (threshold + threshold/8 < 8ll<<30
                             ? threshold + threshold/8 : 8ll<<30);
    return true;
  }
  return false;
}

// Helper for do_malloc().
inline void* do_malloc_pages(ThreadCache* heap, size_t size) {
  void* result;
  bool report_large;

  Length num_pages = tcmalloc::pages(size);
  size = num_pages << kPageShift;

  if ((FLAGS_tcmalloc_sample_parameter > 0) && heap->SampleAllocation(size)) {
    result = DoSampledAllocation(size);

    SpinLockHolder h(Static::pageheap_lock());
    report_large = should_report_large(num_pages);
  } else {
    SpinLockHolder h(Static::pageheap_lock());
    Span* span = Static::pageheap()->New(num_pages);
    result = (span == NULL ? NULL : SpanToMallocResult(span));
    report_large = should_report_large(num_pages);
  }

  if (report_large) {
    ReportLargeAlloc(num_pages, result);
  }
  return result;
}

inline void* do_malloc(size_t size) {
  void* ret = NULL;

  // The following call forces module initialization
  ThreadCache* heap = ThreadCache::GetCache();
  if (size <= kMaxSize) {
    size_t cl = Static::sizemap()->SizeClass(size);
    size = Static::sizemap()->class_to_size(cl);

    if ((FLAGS_tcmalloc_sample_parameter > 0) && heap->SampleAllocation(size)) {
      ret = DoSampledAllocation(size);
    } else {
      // The common case, and also the simplest.  This just pops the
      // size-appropriate freelist, after replenishing it if it's empty.
      ret = CheckedMallocResult(heap->Allocate(size, cl));
    }
  } else {
    ret = do_malloc_pages(heap, size);
  }
  if (ret == NULL) errno = ENOMEM;
  return ret;
}

inline void* do_calloc(size_t n, size_t elem_size) {
  // Overflow check
  const size_t size = n * elem_size;
  if (elem_size != 0 && size / elem_size != n) return NULL;

  void* result = do_malloc_or_cpp_alloc(size);
  if (result != NULL) {
    memset(result, 0, size);
  }
  return result;
}

static inline ThreadCache* GetCacheIfPresent() {
  void* const p = ThreadCache::GetCacheIfPresent();
  return reinterpret_cast<ThreadCache*>(p);
}

// This lets you call back to a given function pointer if ptr is invalid.
// It is used primarily by windows code which wants a specialized callback.
inline void do_free_with_callback(void* ptr, void (*invalid_free_fn)(void*)) {
  if (ptr == NULL) return;
  if (Static::pageheap() == NULL) {
    // We called free() before malloc().  This can occur if the
    // (system) malloc() is called before tcmalloc is loaded, and then
    // free() is called after tcmalloc is loaded (and tc_free has
    // replaced free), but before the global constructor has run that
    // sets up the tcmalloc data structures.
    (*invalid_free_fn)(ptr);  // Decide how to handle the bad free request
    return;
  }
  const PageID p = reinterpret_cast<uintptr_t>(ptr) >> kPageShift;
  Span* span = NULL;
  size_t cl = Static::pageheap()->GetSizeClassIfCached(p);

  if (cl == 0) {
    span = Static::pageheap()->GetDescriptor(p);
    if (!span) {
      // span can be NULL because the pointer passed in is invalid
      // (not something returned by malloc or friends), or because the
      // pointer was allocated with some other allocator besides
      // tcmalloc.  The latter can happen if tcmalloc is linked in via
      // a dynamic library, but is not listed last on the link line.
      // In that case, libraries after it on the link line will
      // allocate with libc malloc, but free with tcmalloc's free.
      (*invalid_free_fn)(ptr);  // Decide how to handle the bad free request
      return;
    }
    cl = span->sizeclass;
    Static::pageheap()->CacheSizeClass(p, cl);
  }
  if (cl != 0) {
    ASSERT(!Static::pageheap()->GetDescriptor(p)->sample);
    ThreadCache* heap = GetCacheIfPresent();
    if (heap != NULL) {
      heap->Deallocate(ptr, cl);
    } else {
      // Delete directly into central cache
      tcmalloc::SLL_SetNext(ptr, NULL);
      Static::central_cache()[cl].InsertRange(ptr, ptr, 1);
    }
  } else {
    SpinLockHolder h(Static::pageheap_lock());
    ASSERT(reinterpret_cast<uintptr_t>(ptr) % kPageSize == 0);
    ASSERT(span != NULL && span->start == p);
    if (span->sample) {
      StackTrace* st = reinterpret_cast<StackTrace*>(span->objects);
      tcmalloc::DLL_Remove(span);
      Static::stacktrace_allocator()->Delete(st);
      span->objects = NULL;
    }
    Static::pageheap()->Delete(span);
  }
}

// The default "do_free" that uses the default callback.
inline void do_free(void* ptr) {
  return do_free_with_callback(ptr, &InvalidFree);
}

// NOTE: some logic here is duplicated in GetOwnership (above), for
// speed.  If you change this function, look at that one too.
inline size_t GetSizeWithCallback(const void* ptr,
                                  size_t (*invalid_getsize_fn)(const void*)) {
  if (ptr == NULL)
    return 0;
  const PageID p = reinterpret_cast<uintptr_t>(ptr) >> kPageShift;
  size_t cl = Static::pageheap()->GetSizeClassIfCached(p);
  if (cl != 0) {
    return Static::sizemap()->ByteSizeForClass(cl);
  } else {
    const Span *span = Static::pageheap()->GetDescriptor(p);
    if (span == NULL) {  // means we do not own this memory
      return (*invalid_getsize_fn)(ptr);
    } else if (span->sizeclass != 0) {
      Static::pageheap()->CacheSizeClass(p, span->sizeclass);
      return Static::sizemap()->ByteSizeForClass(span->sizeclass);
    } else {
      return span->length << kPageShift;
    }
  }
}

// This lets you call back to a given function pointer if ptr is invalid.
// It is used primarily by windows code which wants a specialized callback.
inline void* do_realloc_with_callback(
    void* old_ptr, size_t new_size,
    void (*invalid_free_fn)(void*),
    size_t (*invalid_get_size_fn)(const void*)) {
  // Get the size of the old entry
  const size_t old_size = GetSizeWithCallback(old_ptr, invalid_get_size_fn);

  // Reallocate if the new size is larger than the old size,
  // or if the new size is significantly smaller than the old size.
  // We do hysteresis to avoid resizing ping-pongs:
  //    . If we need to grow, grow to max(new_size, old_size * 1.X)
  //    . Don't shrink unless new_size < old_size * 0.Y
  // X and Y trade-off time for wasted space.  For now we do 1.25 and 0.5.
  const int lower_bound_to_grow = old_size + old_size / 4;
  const int upper_bound_to_shrink = old_size / 2;
  if ((new_size > old_size) || (new_size < upper_bound_to_shrink)) {
    // Need to reallocate.
    void* new_ptr = NULL;

    if (new_size > old_size && new_size < lower_bound_to_grow) {
      new_ptr = do_malloc_or_cpp_alloc(lower_bound_to_grow);
    }
    if (new_ptr == NULL) {
      // Either new_size is not a tiny increment, or last do_malloc failed.
      new_ptr = do_malloc_or_cpp_alloc(new_size);
    }
    if (new_ptr == NULL) {
      return NULL;
    }
    MallocHook::InvokeNewHook(new_ptr, new_size);
    memcpy(new_ptr, old_ptr, ((old_size < new_size) ? old_size : new_size));
    MallocHook::InvokeDeleteHook(old_ptr);
    // We could use a variant of do_free() that leverages the fact
    // that we already know the sizeclass of old_ptr.  The benefit
    // would be small, so don't bother.
    do_free_with_callback(old_ptr, invalid_free_fn);
    return new_ptr;
  } else {
    // We still need to call hooks to report the updated size:
    MallocHook::InvokeDeleteHook(old_ptr);
    MallocHook::InvokeNewHook(old_ptr, new_size);
    return old_ptr;
  }
}

inline void* do_realloc(void* old_ptr, size_t new_size) {
  return do_realloc_with_callback(old_ptr, new_size,
                                  &InvalidFree, &InvalidGetSizeForRealloc);
}

// For use by exported routines below that want specific alignments
//
// Note: this code can be slow for alignments > 16, and can
// significantly fragment memory.  The expectation is that
// memalign/posix_memalign/valloc/pvalloc will not be invoked very
// often.  This requirement simplifies our implementation and allows
// us to tune for expected allocation patterns.
void* do_memalign(size_t align, size_t size) {
  ASSERT((align & (align - 1)) == 0);
  ASSERT(align > 0);
  if (size + align < size) return NULL;         // Overflow

  // Fall back to malloc if we would already align this memory access properly.
  if (align <= AlignmentForSize(size)) {
    void* p = do_malloc(size);
    ASSERT((reinterpret_cast<uintptr_t>(p) % align) == 0);
    return p;
  }

  if (Static::pageheap() == NULL) ThreadCache::InitModule();

  // Allocate at least one byte to avoid boundary conditions below
  if (size == 0) size = 1;

  if (size <= kMaxSize && align < kPageSize) {
    // Search through acceptable size classes looking for one with
    // enough alignment.  This depends on the fact that
    // InitSizeClasses() currently produces several size classes that
    // are aligned at powers of two.  We will waste time and space if
    // we miss in the size class array, but that is deemed acceptable
    // since memalign() should be used rarely.
    int cl = Static::sizemap()->SizeClass(size);
    while (cl < kNumClasses &&
           ((Static::sizemap()->class_to_size(cl) & (align - 1)) != 0)) {
      cl++;
    }
    if (cl < kNumClasses) {
      ThreadCache* heap = ThreadCache::GetCache();
      size = Static::sizemap()->class_to_size(cl);
      return CheckedMallocResult(heap->Allocate(size, cl));
    }
  }

  // We will allocate directly from the page heap
  SpinLockHolder h(Static::pageheap_lock());

  if (align <= kPageSize) {
    // Any page-level allocation will be fine
    // TODO: We could put the rest of this page in the appropriate
    // TODO: cache but it does not seem worth it.
    Span* span = Static::pageheap()->New(tcmalloc::pages(size));
    return span == NULL ? NULL : SpanToMallocResult(span);
  }

  // Allocate extra pages and carve off an aligned portion
  const Length alloc = tcmalloc::pages(size + align);
  Span* span = Static::pageheap()->New(alloc);
  if (span == NULL) return NULL;

  // Skip starting portion so that we end up aligned
  Length skip = 0;
  while ((((span->start+skip) << kPageShift) & (align - 1)) != 0) {
    skip++;
  }
  ASSERT(skip < alloc);
  if (skip > 0) {
    Span* rest = Static::pageheap()->Split(span, skip);
    Static::pageheap()->Delete(span);
    span = rest;
  }

  // Skip trailing portion that we do not need to return
  const Length needed = tcmalloc::pages(size);
  ASSERT(span->length >= needed);
  if (span->length > needed) {
    Span* trailer = Static::pageheap()->Split(span, needed);
    Static::pageheap()->Delete(trailer);
  }
  return SpanToMallocResult(span);
}

// Helpers for use by exported routines below:

inline void do_malloc_stats() {
  PrintStats(1);
}

inline int do_mallopt(int cmd, int value) {
  return 1;     // Indicates error
}

#ifdef HAVE_STRUCT_MALLINFO
inline struct mallinfo do_mallinfo() {
  TCMallocStats stats;
  ExtractStats(&stats, NULL, NULL, NULL);

  // Just some of the fields are filled in.
  struct mallinfo info;
  memset(&info, 0, sizeof(info));

  // Unfortunately, the struct contains "int" field, so some of the
  // size values will be truncated.
  info.arena     = static_cast<int>(stats.pageheap.system_bytes);
  info.fsmblks   = static_cast<int>(stats.thread_bytes
                                    + stats.central_bytes
                                    + stats.transfer_bytes);
  info.fordblks  = static_cast<int>(stats.pageheap.free_bytes +
                                    stats.pageheap.unmapped_bytes);
  info.uordblks  = static_cast<int>(stats.pageheap.system_bytes
                                    - stats.thread_bytes
                                    - stats.central_bytes
                                    - stats.transfer_bytes
                                    - stats.pageheap.free_bytes
                                    - stats.pageheap.unmapped_bytes);

  return info;
}
#endif  // HAVE_STRUCT_MALLINFO

static SpinLock set_new_handler_lock(SpinLock::LINKER_INITIALIZED);

inline void* cpp_alloc(size_t size, bool nothrow) {
  for (;;) {
    void* p = do_malloc(size);
#ifdef PREANSINEW
    return p;
#else
    if (p == NULL) {  // allocation failed
      // Get the current new handler.  NB: this function is not
      // thread-safe.  We make a feeble stab at making it so here, but
      // this lock only protects against tcmalloc interfering with
      // itself, not with other libraries calling set_new_handler.
      std::new_handler nh;
      {
        SpinLockHolder h(&set_new_handler_lock);
        nh = std::set_new_handler(0);
        (void) std::set_new_handler(nh);
      }
#if (defined(__GNUC__) && !defined(__EXCEPTIONS)) || (defined(_HAS_EXCEPTIONS) && !_HAS_EXCEPTIONS)
      if (nh) {
        // Since exceptions are disabled, we don't really know if new_handler
        // failed.  Assume it will abort if it fails.
        (*nh)();
        continue;
      }
      return 0;
#else
      // If no new_handler is established, the allocation failed.
      if (!nh) {
        if (nothrow) return 0;
        throw std::bad_alloc();
      }
      // Otherwise, try the new_handler.  If it returns, retry the
      // allocation.  If it throws std::bad_alloc, fail the allocation.
      // if it throws something else, don't interfere.
      try {
        (*nh)();
      } catch (const std::bad_alloc&) {
        if (!nothrow) throw;
        return p;
      }
#endif  // (defined(__GNUC__) && !defined(__EXCEPTIONS)) || (defined(_HAS_EXCEPTIONS) && !_HAS_EXCEPTIONS)
    } else {  // allocation success
      return p;
    }
#endif  // PREANSINEW
  }
}

void* cpp_memalign(size_t align, size_t size) {
  for (;;) {
    void* p = do_memalign(align, size);
#ifdef PREANSINEW
    return p;
#else
    if (p == NULL) {  // allocation failed
      // Get the current new handler.  NB: this function is not
      // thread-safe.  We make a feeble stab at making it so here, but
      // this lock only protects against tcmalloc interfering with
      // itself, not with other libraries calling set_new_handler.
      std::new_handler nh;
      {
        SpinLockHolder h(&set_new_handler_lock);
        nh = std::set_new_handler(0);
        (void) std::set_new_handler(nh);
      }
#if (defined(__GNUC__) && !defined(__EXCEPTIONS)) || (defined(_HAS_EXCEPTIONS) && !_HAS_EXCEPTIONS)
      if (nh) {
        // Since exceptions are disabled, we don't really know if new_handler
        // failed.  Assume it will abort if it fails.
        (*nh)();
        continue;
      }
      return 0;
#else
      // If no new_handler is established, the allocation failed.
      if (!nh)
        return 0;

      // Otherwise, try the new_handler.  If it returns, retry the
      // allocation.  If it throws std::bad_alloc, fail the allocation.
      // if it throws something else, don't interfere.
      try {
        (*nh)();
      } catch (const std::bad_alloc&) {
        return p;
      }
#endif  // (defined(__GNUC__) && !defined(__EXCEPTIONS)) || (defined(_HAS_EXCEPTIONS) && !_HAS_EXCEPTIONS)
    } else {  // allocation success
      return p;
    }
#endif  // PREANSINEW
  }
}

}  // end unnamed namespace

// As promised, the definition of this function, declared above.
size_t TCMallocImplementation::GetAllocatedSize(const void* ptr) {
  ASSERT(TCMallocImplementation::GetOwnership(ptr)
         != TCMallocImplementation::kNotOwned);
  return GetSizeWithCallback(ptr, &InvalidGetAllocatedSize);
}

void TCMallocImplementation::MarkThreadBusy() {
  // Allocate to force the creation of a thread cache, but avoid
  // invoking any hooks.
  do_free(do_malloc(0));
}

//-------------------------------------------------------------------
// Exported routines
//-------------------------------------------------------------------

extern "C" PERFTOOLS_DLL_DECL const char* tc_version(
    int* major, int* minor, const char** patch) __THROW {
  if (major) *major = TC_VERSION_MAJOR;
  if (minor) *minor = TC_VERSION_MINOR;
  if (patch) *patch = TC_VERSION_PATCH;
  return TC_VERSION_STRING;
}

// This function behaves similarly to MSVC's _set_new_mode.
// If flag is 0 (default), calls to malloc will behave normally.
// If flag is 1, calls to malloc will behave like calls to new,
// and the std_new_handler will be invoked on failure.
// Returns the previous mode.
extern "C" PERFTOOLS_DLL_DECL int tc_set_new_mode(int flag) __THROW {
  int old_mode = tc_new_mode;
  tc_new_mode = flag;
  return old_mode;
}

#ifndef TCMALLOC_USING_DEBUGALLOCATION  // debugallocation.cc defines its own

// CAVEAT: The code structure below ensures that MallocHook methods are always
//         called from the stack frame of the invoked allocation function.
//         heap-checker.cc depends on this to start a stack trace from
//         the call to the (de)allocation function.

extern "C" PERFTOOLS_DLL_DECL void* tc_malloc(size_t size) __THROW {
  void* result = do_malloc_or_cpp_alloc(size);
  MallocHook::InvokeNewHook(result, size);
  return result;
}

extern "C" PERFTOOLS_DLL_DECL void tc_free(void* ptr) __THROW {
  MallocHook::InvokeDeleteHook(ptr);
  do_free(ptr);
}

extern "C" PERFTOOLS_DLL_DECL void* tc_calloc(size_t n,
                                              size_t elem_size) __THROW {
  void* result = do_calloc(n, elem_size);
  MallocHook::InvokeNewHook(result, n * elem_size);
  return result;
}

extern "C" PERFTOOLS_DLL_DECL void tc_cfree(void* ptr) __THROW {
  MallocHook::InvokeDeleteHook(ptr);
  do_free(ptr);
}

extern "C" PERFTOOLS_DLL_DECL void* tc_realloc(void* old_ptr,
                                               size_t new_size) __THROW {
  if (old_ptr == NULL) {
    void* result = do_malloc_or_cpp_alloc(new_size);
    MallocHook::InvokeNewHook(result, new_size);
    return result;
  }
  if (new_size == 0) {
    MallocHook::InvokeDeleteHook(old_ptr);
    do_free(old_ptr);
    return NULL;
  }
  return do_realloc(old_ptr, new_size);
}

extern "C" PERFTOOLS_DLL_DECL void* tc_new(size_t size) {
  void* p = cpp_alloc(size, false);
  // We keep this next instruction out of cpp_alloc for a reason: when
  // it's in, and new just calls cpp_alloc, the optimizer may fold the
  // new call into cpp_alloc, which messes up our whole section-based
  // stacktracing (see ATTRIBUTE_SECTION, above).  This ensures cpp_alloc
  // isn't the last thing this fn calls, and prevents the folding.
  MallocHook::InvokeNewHook(p, size);
  return p;
}

extern "C" PERFTOOLS_DLL_DECL void* tc_new_nothrow(size_t size, const std::nothrow_t&) __THROW {
  void* p = cpp_alloc(size, true);
  MallocHook::InvokeNewHook(p, size);
  return p;
}

extern "C" PERFTOOLS_DLL_DECL void tc_delete(void* p) __THROW {
  MallocHook::InvokeDeleteHook(p);
  do_free(p);
}

// Standard C++ library implementations define and use this
// (via ::operator delete(ptr, nothrow)).
// But it's really the same as normal delete, so we just do the same thing.
extern "C" PERFTOOLS_DLL_DECL void tc_delete_nothrow(void* p, const std::nothrow_t&) __THROW {
  MallocHook::InvokeDeleteHook(p);
  do_free(p);
}

extern "C" PERFTOOLS_DLL_DECL void* tc_newarray(size_t size) {
  void* p = cpp_alloc(size, false);
  // We keep this next instruction out of cpp_alloc for a reason: when
  // it's in, and new just calls cpp_alloc, the optimizer may fold the
  // new call into cpp_alloc, which messes up our whole section-based
  // stacktracing (see ATTRIBUTE_SECTION, above).  This ensures cpp_alloc
  // isn't the last thing this fn calls, and prevents the folding.
  MallocHook::InvokeNewHook(p, size);
  return p;
}

extern "C" PERFTOOLS_DLL_DECL void* tc_newarray_nothrow(size_t size, const std::nothrow_t&)
    __THROW {
  void* p = cpp_alloc(size, true);
  MallocHook::InvokeNewHook(p, size);
  return p;
}

extern "C" PERFTOOLS_DLL_DECL void tc_deletearray(void* p) __THROW {
  MallocHook::InvokeDeleteHook(p);
  do_free(p);
}

extern "C" PERFTOOLS_DLL_DECL void tc_deletearray_nothrow(void* p, const std::nothrow_t&) __THROW {
  MallocHook::InvokeDeleteHook(p);
  do_free(p);
}

extern "C" PERFTOOLS_DLL_DECL void* tc_memalign(size_t align,
                                                size_t size) __THROW {
  void* result = do_memalign_or_cpp_memalign(align, size);
  MallocHook::InvokeNewHook(result, size);
  return result;
}

extern "C" PERFTOOLS_DLL_DECL int tc_posix_memalign(
    void** result_ptr, size_t align, size_t size) __THROW {
  if (((align % sizeof(void*)) != 0) ||
      ((align & (align - 1)) != 0) ||
      (align == 0)) {
    return EINVAL;
  }

  void* result = do_memalign_or_cpp_memalign(align, size);
  MallocHook::InvokeNewHook(result, size);
  if (result == NULL) {
    return ENOMEM;
  } else {
    *result_ptr = result;
    return 0;
  }
}

static size_t pagesize = 0;

extern "C" PERFTOOLS_DLL_DECL void* tc_valloc(size_t size) __THROW {
  // Allocate page-aligned object of length >= size bytes
  if (pagesize == 0) pagesize = getpagesize();
  void* result = do_memalign_or_cpp_memalign(pagesize, size);
  MallocHook::InvokeNewHook(result, size);
  return result;
}

extern "C" PERFTOOLS_DLL_DECL void* tc_pvalloc(size_t size) __THROW {
  // Round up size to a multiple of pagesize
  if (pagesize == 0) pagesize = getpagesize();
  if (size == 0) {     // pvalloc(0) should allocate one page, according to
    size = pagesize;   // http://man.free4web.biz/man3/libmpatrol.3.html
  }
  size = (size + pagesize - 1) & ~(pagesize - 1);
  void* result = do_memalign_or_cpp_memalign(pagesize, size);
  MallocHook::InvokeNewHook(result, size);
  return result;
}

extern "C" PERFTOOLS_DLL_DECL void tc_malloc_stats(void) __THROW {
  do_malloc_stats();
}

extern "C" PERFTOOLS_DLL_DECL int tc_mallopt(int cmd, int value) __THROW {
  return do_mallopt(cmd, value);
}

#ifdef HAVE_STRUCT_MALLINFO
extern "C" PERFTOOLS_DLL_DECL struct mallinfo tc_mallinfo(void) __THROW {
  return do_mallinfo();
}
#endif

extern "C" PERFTOOLS_DLL_DECL size_t tc_malloc_size(void* ptr) __THROW {
  return MallocExtension::instance()->GetAllocatedSize(ptr);
}

#endif  // TCMALLOC_USING_DEBUGALLOCATION
