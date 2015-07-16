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
// Author: Sanjay Ghemawat
//
// TODO: Log large allocations

#include <config.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>    // for open()
#endif
#ifdef HAVE_MMAP
#include <sys/mman.h>
#endif
#include <errno.h>
#include <assert.h>
#include <sys/types.h>

#include <algorithm>
#include <string>

#include <gperftools/heap-profiler.h>

#include "base/logging.h"
#include "base/basictypes.h"   // for PRId64, among other things
#include "base/googleinit.h"
#include "base/commandlineflags.h"
#include "malloc_hook-inl.h"
#include "tcmalloc_guard.h"
#include <gperftools/malloc_hook.h>
#include <gperftools/malloc_extension.h>
#include "base/spinlock.h"
#include "base/low_level_alloc.h"
#include "base/sysinfo.h"      // for GetUniquePathFromEnv()
#include "deep-heap-profile.h"
#include "heap-profile-table.h"
#include "memory_region_map.h"


#ifndef	PATH_MAX
#ifdef MAXPATHLEN
#define	PATH_MAX	MAXPATHLEN
#else
#define	PATH_MAX	4096         // seems conservative for max filename len!
#endif
#endif

#if defined(__ANDROID__) || defined(ANDROID)
// On android, there are no environment variables.
// Instead, we use system properties, set via:
//   adb shell setprop prop_name prop_value
// From <sys/system_properties.h>,
//   PROP_NAME_MAX   32
//   PROP_VALUE_MAX  92
#define HEAPPROFILE "heapprof"
#define HEAP_PROFILE_ALLOCATION_INTERVAL "heapprof.allocation_interval"
#define HEAP_PROFILE_DEALLOCATION_INTERVAL "heapprof.deallocation_interval"
#define HEAP_PROFILE_INUSE_INTERVAL "heapprof.inuse_interval"
#define HEAP_PROFILE_TIME_INTERVAL "heapprof.time_interval"
#define HEAP_PROFILE_MMAP_LOG "heapprof.mmap_log"
#define HEAP_PROFILE_MMAP "heapprof.mmap"
#define HEAP_PROFILE_ONLY_MMAP "heapprof.only_mmap"
#define DEEP_HEAP_PROFILE "heapprof.deep_heap_profile"
#define DEEP_HEAP_PROFILE_PAGEFRAME "heapprof.deep.pageframe"
#define HEAP_PROFILE_TYPE_STATISTICS "heapprof.type_statistics"
#else  // defined(__ANDROID__) || defined(ANDROID)
#define HEAPPROFILE "HEAPPROFILE"
#define HEAP_PROFILE_ALLOCATION_INTERVAL "HEAP_PROFILE_ALLOCATION_INTERVAL"
#define HEAP_PROFILE_DEALLOCATION_INTERVAL "HEAP_PROFILE_DEALLOCATION_INTERVAL"
#define HEAP_PROFILE_INUSE_INTERVAL "HEAP_PROFILE_INUSE_INTERVAL"
#define HEAP_PROFILE_TIME_INTERVAL "HEAP_PROFILE_TIME_INTERVAL"
#define HEAP_PROFILE_MMAP_LOG "HEAP_PROFILE_MMAP_LOG"
#define HEAP_PROFILE_MMAP "HEAP_PROFILE_MMAP"
#define HEAP_PROFILE_ONLY_MMAP "HEAP_PROFILE_ONLY_MMAP"
#define DEEP_HEAP_PROFILE "DEEP_HEAP_PROFILE"
#define DEEP_HEAP_PROFILE_PAGEFRAME "DEEP_HEAP_PROFILE_PAGEFRAME"
#define HEAP_PROFILE_TYPE_STATISTICS "HEAP_PROFILE_TYPE_STATISTICS"
#endif  // defined(__ANDROID__) || defined(ANDROID)

using STL_NAMESPACE::string;
using STL_NAMESPACE::sort;

//----------------------------------------------------------------------
// Flags that control heap-profiling
//
// The thread-safety of the profiler depends on these being immutable
// after main starts, so don't change them.
//----------------------------------------------------------------------

DEFINE_int64(heap_profile_allocation_interval,
             EnvToInt64(HEAP_PROFILE_ALLOCATION_INTERVAL, 1 << 30 /*1GB*/),
             "If non-zero, dump heap profiling information once every "
             "specified number of bytes allocated by the program since "
             "the last dump.");
DEFINE_int64(heap_profile_deallocation_interval,
             EnvToInt64(HEAP_PROFILE_DEALLOCATION_INTERVAL, 0),
             "If non-zero, dump heap profiling information once every "
             "specified number of bytes deallocated by the program "
             "since the last dump.");
// We could also add flags that report whenever inuse_bytes changes by
// X or -X, but there hasn't been a need for that yet, so we haven't.
DEFINE_int64(heap_profile_inuse_interval,
             EnvToInt64(HEAP_PROFILE_INUSE_INTERVAL, 100 << 20 /*100MB*/),
             "If non-zero, dump heap profiling information whenever "
             "the high-water memory usage mark increases by the specified "
             "number of bytes.");
DEFINE_int64(heap_profile_time_interval,
             EnvToInt64(HEAP_PROFILE_TIME_INTERVAL, 0),
             "If non-zero, dump heap profiling information once every "
             "specified number of seconds since the last dump.");
DEFINE_bool(mmap_log,
            EnvToBool(HEAP_PROFILE_MMAP_LOG, false),
            "Should mmap/munmap calls be logged?");
DEFINE_bool(mmap_profile,
            EnvToBool(HEAP_PROFILE_MMAP, false),
            "If heap-profiling is on, also profile mmap, mremap, and sbrk)");
DEFINE_bool(only_mmap_profile,
            EnvToBool(HEAP_PROFILE_ONLY_MMAP, false),
            "If heap-profiling is on, only profile mmap, mremap, and sbrk; "
            "do not profile malloc/new/etc");
DEFINE_bool(deep_heap_profile,
            EnvToBool(DEEP_HEAP_PROFILE, false),
            "If heap-profiling is on, profile deeper (Linux and Android)");
DEFINE_int32(deep_heap_profile_pageframe,
             EnvToInt(DEEP_HEAP_PROFILE_PAGEFRAME, 0),
             "Needs deeper profile. If 1, dump page frame numbers (PFNs). "
             "If 2, dump page counts (/proc/kpagecount) with PFNs.");
#if defined(TYPE_PROFILING)
DEFINE_bool(heap_profile_type_statistics,
            EnvToBool(HEAP_PROFILE_TYPE_STATISTICS, false),
            "If heap-profiling is on, dump type statistics.");
#endif  // defined(TYPE_PROFILING)


//----------------------------------------------------------------------
// Locking
//----------------------------------------------------------------------

// A pthread_mutex has way too much lock contention to be used here.
//
// I would like to use Mutex, but it can call malloc(),
// which can cause us to fall into an infinite recursion.
//
// So we use a simple spinlock.
static SpinLock heap_lock(SpinLock::LINKER_INITIALIZED);

//----------------------------------------------------------------------
// Simple allocator for heap profiler's internal memory
//----------------------------------------------------------------------

static LowLevelAlloc::Arena *heap_profiler_memory;

static void* ProfilerMalloc(size_t bytes) {
  return LowLevelAlloc::AllocWithArena(bytes, heap_profiler_memory);
}
static void ProfilerFree(void* p) {
  LowLevelAlloc::Free(p);
}

// We use buffers of this size in DoGetHeapProfile.
static const int kProfileBufferSize = 1 << 20;

// This is a last-ditch buffer we use in DumpProfileLocked in case we
// can't allocate more memory from ProfilerMalloc.  We expect this
// will be used by HeapProfileEndWriter when the application has to
// exit due to out-of-memory.  This buffer is allocated in
// HeapProfilerStart.  Access to this must be protected by heap_lock.
static char* global_profiler_buffer = NULL;


//----------------------------------------------------------------------
// Profiling control/state data
//----------------------------------------------------------------------

// Access to all of these is protected by heap_lock.
static bool  is_on = false;           // If are on as a subsytem.
static bool  dumping = false;         // Dumping status to prevent recursion
static char* filename_prefix = NULL;  // Prefix used for profile file names
                                      // (NULL if no need for dumping yet)
static int   dump_count = 0;          // How many dumps so far
static int64 last_dump_alloc = 0;     // alloc_size when did we last dump
static int64 last_dump_free = 0;      // free_size when did we last dump
static int64 high_water_mark = 0;     // In-use-bytes at last high-water dump
static int64 last_dump_time = 0;      // The time of the last dump

static HeapProfileTable* heap_profile = NULL;  // the heap profile table
static DeepHeapProfile* deep_profile = NULL;  // deep memory profiler

// Callback to generate a stack trace for an allocation. May be overriden
// by an application to provide its own pseudo-stacks.
static StackGeneratorFunction stack_generator_function =
    HeapProfileTable::GetCallerStackTrace;

//----------------------------------------------------------------------
// Profile generation
//----------------------------------------------------------------------

// Input must be a buffer of size at least 1MB.
static char* DoGetHeapProfileLocked(char* buf, int buflen) {
  // We used to be smarter about estimating the required memory and
  // then capping it to 1MB and generating the profile into that.
  if (buf == NULL || buflen < 1)
    return NULL;

  RAW_DCHECK(heap_lock.IsHeld(), "");
  int bytes_written = 0;
  if (is_on) {
    HeapProfileTable::Stats const stats = heap_profile->total();
    (void)stats;   // avoid an unused-variable warning in non-debug mode.
    bytes_written = heap_profile->FillOrderedProfile(buf, buflen - 1);
    // FillOrderedProfile should not reduce the set of active mmap-ed regions,
    // hence MemoryRegionMap will let us remove everything we've added above:
    RAW_DCHECK(stats.Equivalent(heap_profile->total()), "");
    // if this fails, we somehow removed by FillOrderedProfile
    // more than we have added.
  }
  buf[bytes_written] = '\0';
  RAW_DCHECK(bytes_written == strlen(buf), "");

  return buf;
}

extern "C" char* GetHeapProfile() {
  // Use normal malloc: we return the profile to the user to free it:
  char* buffer = reinterpret_cast<char*>(malloc(kProfileBufferSize));
  SpinLockHolder l(&heap_lock);
  return DoGetHeapProfileLocked(buffer, kProfileBufferSize);
}

// defined below
static void NewHook(const void* ptr, size_t size);
static void DeleteHook(const void* ptr);

// Helper for HeapProfilerDump.
static void DumpProfileLocked(const char* reason) {
  RAW_DCHECK(heap_lock.IsHeld(), "");
  RAW_DCHECK(is_on, "");
  RAW_DCHECK(!dumping, "");

  if (filename_prefix == NULL) return;  // we do not yet need dumping

  dumping = true;

  // Make file name
  char file_name[1000];
  dump_count++;
  snprintf(file_name, sizeof(file_name), "%s.%05d.%04d%s",
           filename_prefix, getpid(), dump_count, HeapProfileTable::kFileExt);

  // Dump the profile
  RAW_VLOG(0, "Dumping heap profile to %s (%s)", file_name, reason);
  // We must use file routines that don't access memory, since we hold
  // a memory lock now.
  RawFD fd = RawOpenForWriting(file_name);
  if (fd == kIllegalRawFD) {
    RAW_LOG(ERROR, "Failed dumping heap profile to %s", file_name);
    dumping = false;
    return;
  }

  // This case may be impossible, but it's best to be safe.
  // It's safe to use the global buffer: we're protected by heap_lock.
  if (global_profiler_buffer == NULL) {
    global_profiler_buffer =
        reinterpret_cast<char*>(ProfilerMalloc(kProfileBufferSize));
  }

  if (deep_profile) {
    deep_profile->DumpOrderedProfile(reason, global_profiler_buffer,
                                     kProfileBufferSize, fd);
  } else {
    char* profile = DoGetHeapProfileLocked(global_profiler_buffer,
                                           kProfileBufferSize);
    RawWrite(fd, profile, strlen(profile));
  }
  RawClose(fd);

#if defined(TYPE_PROFILING)
  if (FLAGS_heap_profile_type_statistics) {
    snprintf(file_name, sizeof(file_name), "%s.%05d.%04d.type",
             filename_prefix, getpid(), dump_count);
    RAW_VLOG(0, "Dumping type statistics to %s", file_name);
    heap_profile->DumpTypeStatistics(file_name);
  }
#endif  // defined(TYPE_PROFILING)

  dumping = false;
}

//----------------------------------------------------------------------
// Profile collection
//----------------------------------------------------------------------

// Dump a profile after either an allocation or deallocation, if
// the memory use has changed enough since the last dump.
static void MaybeDumpProfileLocked() {
  if (!dumping) {
    const HeapProfileTable::Stats& total = heap_profile->total();
    const int64 inuse_bytes = total.alloc_size - total.free_size;
    bool need_to_dump = false;
    char buf[128];
    int64 current_time = time(NULL);
    if (FLAGS_heap_profile_allocation_interval > 0 &&
        total.alloc_size >=
        last_dump_alloc + FLAGS_heap_profile_allocation_interval) {
      snprintf(buf, sizeof(buf), ("%" PRId64 " MB allocated cumulatively, "
                                  "%" PRId64 " MB currently in use"),
               total.alloc_size >> 20, inuse_bytes >> 20);
      need_to_dump = true;
    } else if (FLAGS_heap_profile_deallocation_interval > 0 &&
               total.free_size >=
               last_dump_free + FLAGS_heap_profile_deallocation_interval) {
      snprintf(buf, sizeof(buf), ("%" PRId64 " MB freed cumulatively, "
                                  "%" PRId64 " MB currently in use"),
               total.free_size >> 20, inuse_bytes >> 20);
      need_to_dump = true;
    } else if (FLAGS_heap_profile_inuse_interval > 0 &&
               inuse_bytes >
               high_water_mark + FLAGS_heap_profile_inuse_interval) {
      snprintf(buf, sizeof(buf), "%" PRId64 " MB currently in use",
               inuse_bytes >> 20);
      need_to_dump = true;
    } else if (FLAGS_heap_profile_time_interval > 0 &&
               current_time - last_dump_time >=
               FLAGS_heap_profile_time_interval) {
      snprintf(buf, sizeof(buf), "%" PRId64 " sec since the last dump",
               current_time - last_dump_time);
      need_to_dump = true;
      last_dump_time = current_time;
    }
    if (need_to_dump) {
      DumpProfileLocked(buf);

      last_dump_alloc = total.alloc_size;
      last_dump_free = total.free_size;
      if (inuse_bytes > high_water_mark)
        high_water_mark = inuse_bytes;
    }
  }
}

// Record an allocation in the profile.
static void RecordAlloc(const void* ptr, size_t bytes, int skip_count) {
  // Take the stack trace outside the critical section.
  void* stack[HeapProfileTable::kMaxStackDepth];
  int depth = stack_generator_function(skip_count + 1, stack);
  SpinLockHolder l(&heap_lock);
  if (is_on) {
    heap_profile->RecordAlloc(ptr, bytes, depth, stack);
    MaybeDumpProfileLocked();
  }
}

// Record a deallocation in the profile.
static void RecordFree(const void* ptr) {
  SpinLockHolder l(&heap_lock);
  if (is_on) {
    heap_profile->RecordFree(ptr);
    MaybeDumpProfileLocked();
  }
}

//----------------------------------------------------------------------
// Allocation/deallocation hooks for MallocHook
//----------------------------------------------------------------------

// static
void NewHook(const void* ptr, size_t size) {
  if (ptr != NULL) RecordAlloc(ptr, size, 0);
}

// static
void DeleteHook(const void* ptr) {
  if (ptr != NULL) RecordFree(ptr);
}

// TODO(jandrews): Re-enable stack tracing
#ifdef TODO_REENABLE_STACK_TRACING
static void RawInfoStackDumper(const char* message, void*) {
  RAW_LOG(INFO, "%.*s", static_cast<int>(strlen(message) - 1), message);
  // -1 is to chop the \n which will be added by RAW_LOG
}
#endif

static void MmapHook(const void* result, const void* start, size_t size,
                     int prot, int flags, int fd, off_t offset) {
  if (FLAGS_mmap_log) {  // log it
    // We use PRIxS not just '%p' to avoid deadlocks
    // in pretty-printing of NULL as "nil".
    // TODO(maxim): instead should use a safe snprintf reimplementation
    RAW_LOG(INFO,
            "mmap(start=0x%" PRIxPTR ", len=%" PRIuS ", prot=0x%x, flags=0x%x, "
            "fd=%d, offset=0x%x) = 0x%" PRIxPTR,
            (uintptr_t) start, size, prot, flags, fd, (unsigned int) offset,
            (uintptr_t) result);
#ifdef TODO_REENABLE_STACK_TRACING
    DumpStackTrace(1, RawInfoStackDumper, NULL);
#endif
  }
}

static void MremapHook(const void* result, const void* old_addr,
                       size_t old_size, size_t new_size,
                       int flags, const void* new_addr) {
  if (FLAGS_mmap_log) {  // log it
    // We use PRIxS not just '%p' to avoid deadlocks
    // in pretty-printing of NULL as "nil".
    // TODO(maxim): instead should use a safe snprintf reimplementation
    RAW_LOG(INFO,
            "mremap(old_addr=0x%" PRIxPTR ", old_size=%" PRIuS ", "
            "new_size=%" PRIuS ", flags=0x%x, new_addr=0x%" PRIxPTR ") = "
            "0x%" PRIxPTR,
            (uintptr_t) old_addr, old_size, new_size, flags,
            (uintptr_t) new_addr, (uintptr_t) result);
#ifdef TODO_REENABLE_STACK_TRACING
    DumpStackTrace(1, RawInfoStackDumper, NULL);
#endif
  }
}

static void MunmapHook(const void* ptr, size_t size) {
  if (FLAGS_mmap_log) {  // log it
    // We use PRIxS not just '%p' to avoid deadlocks
    // in pretty-printing of NULL as "nil".
    // TODO(maxim): instead should use a safe snprintf reimplementation
    RAW_LOG(INFO, "munmap(start=0x%" PRIxPTR ", len=%" PRIuS ")",
                  (uintptr_t) ptr, size);
#ifdef TODO_REENABLE_STACK_TRACING
    DumpStackTrace(1, RawInfoStackDumper, NULL);
#endif
  }
}

static void SbrkHook(const void* result, ptrdiff_t increment) {
  if (FLAGS_mmap_log) {  // log it
    RAW_LOG(INFO, "sbrk(inc=%" PRIdS ") = 0x%" PRIxPTR,
                  increment, (uintptr_t) result);
#ifdef TODO_REENABLE_STACK_TRACING
    DumpStackTrace(1, RawInfoStackDumper, NULL);
#endif
  }
}

//----------------------------------------------------------------------
// Starting/stopping/dumping
//----------------------------------------------------------------------

extern "C" void HeapProfilerStart(const char* prefix) {
  SpinLockHolder l(&heap_lock);

  if (is_on) return;

  is_on = true;

  RAW_VLOG(0, "Starting tracking the heap");

  // This should be done before the hooks are set up, since it should
  // call new, and we want that to be accounted for correctly.
  MallocExtension::Initialize();

  if (FLAGS_only_mmap_profile) {
    FLAGS_mmap_profile = true;
  }

  if (FLAGS_mmap_profile) {
    // Ask MemoryRegionMap to record all mmap, mremap, and sbrk
    // call stack traces of at least size kMaxStackDepth:
    MemoryRegionMap::Init(HeapProfileTable::kMaxStackDepth,
                          /* use_buckets */ true);
  }

  if (FLAGS_mmap_log) {
    // Install our hooks to do the logging:
    RAW_CHECK(MallocHook::AddMmapHook(&MmapHook), "");
    RAW_CHECK(MallocHook::AddMremapHook(&MremapHook), "");
    RAW_CHECK(MallocHook::AddMunmapHook(&MunmapHook), "");
    RAW_CHECK(MallocHook::AddSbrkHook(&SbrkHook), "");
  }

  heap_profiler_memory =
    LowLevelAlloc::NewArena(0, LowLevelAlloc::DefaultArena());

  // Reserve space now for the heap profiler, so we can still write a
  // heap profile even if the application runs out of memory.
  global_profiler_buffer =
      reinterpret_cast<char*>(ProfilerMalloc(kProfileBufferSize));

  heap_profile = new(ProfilerMalloc(sizeof(HeapProfileTable)))
      HeapProfileTable(ProfilerMalloc, ProfilerFree, FLAGS_mmap_profile);

  last_dump_alloc = 0;
  last_dump_free = 0;
  high_water_mark = 0;
  last_dump_time = 0;

  if (FLAGS_deep_heap_profile) {
    // Initialize deep memory profiler
    RAW_VLOG(0, "[%d] Starting a deep memory profiler", getpid());
    deep_profile = new(ProfilerMalloc(sizeof(DeepHeapProfile)))
        DeepHeapProfile(heap_profile, prefix, DeepHeapProfile::PageFrameType(
            FLAGS_deep_heap_profile_pageframe));
  }

  // We do not reset dump_count so if the user does a sequence of
  // HeapProfilerStart/HeapProfileStop, we will get a continuous
  // sequence of profiles.

  if (FLAGS_only_mmap_profile == false) {
    // Now set the hooks that capture new/delete and malloc/free.
    RAW_CHECK(MallocHook::AddNewHook(&NewHook), "");
    RAW_CHECK(MallocHook::AddDeleteHook(&DeleteHook), "");
  }

  // Copy filename prefix only if provided.
  if (!prefix)
    return;
  RAW_DCHECK(filename_prefix == NULL, "");
  const int prefix_length = strlen(prefix);
  filename_prefix = reinterpret_cast<char*>(ProfilerMalloc(prefix_length + 1));
  memcpy(filename_prefix, prefix, prefix_length);
  filename_prefix[prefix_length] = '\0';
}

extern "C" void HeapProfilerWithPseudoStackStart(
    StackGeneratorFunction callback) {
  {
    // Ensure the callback is set before allocations can be recorded.
    SpinLockHolder l(&heap_lock);
    stack_generator_function = callback;
  }
  HeapProfilerStart(NULL);
}

extern "C" void IterateAllocatedObjects(AddressVisitor visitor, void* data) {
  SpinLockHolder l(&heap_lock);

  if (!is_on) return;

  heap_profile->IterateAllocationAddresses(visitor, data);
}

extern "C" int IsHeapProfilerRunning() {
  SpinLockHolder l(&heap_lock);
  return is_on ? 1 : 0;   // return an int, because C code doesn't have bool
}

extern "C" void HeapProfilerStop() {
  SpinLockHolder l(&heap_lock);

  if (!is_on) return;

  if (FLAGS_only_mmap_profile == false) {
    // Unset our new/delete hooks, checking they were set:
    RAW_CHECK(MallocHook::RemoveNewHook(&NewHook), "");
    RAW_CHECK(MallocHook::RemoveDeleteHook(&DeleteHook), "");
  }
  if (FLAGS_mmap_log) {
    // Restore mmap/sbrk hooks, checking that our hooks were set:
    RAW_CHECK(MallocHook::RemoveMmapHook(&MmapHook), "");
    RAW_CHECK(MallocHook::RemoveMremapHook(&MremapHook), "");
    RAW_CHECK(MallocHook::RemoveSbrkHook(&SbrkHook), "");
    RAW_CHECK(MallocHook::RemoveMunmapHook(&MunmapHook), "");
  }

  if (deep_profile) {
    // free deep memory profiler
    deep_profile->~DeepHeapProfile();
    ProfilerFree(deep_profile);
    deep_profile = NULL;
  }

  // free profile
  heap_profile->~HeapProfileTable();
  ProfilerFree(heap_profile);
  heap_profile = NULL;

  // free output-buffer memory
  ProfilerFree(global_profiler_buffer);

  // free prefix
  ProfilerFree(filename_prefix);
  filename_prefix = NULL;

  if (!LowLevelAlloc::DeleteArena(heap_profiler_memory)) {
    RAW_LOG(FATAL, "Memory leak in HeapProfiler:");
  }

  if (FLAGS_mmap_profile) {
    MemoryRegionMap::Shutdown();
  }

  is_on = false;
}

extern "C" void HeapProfilerDump(const char* reason) {
  SpinLockHolder l(&heap_lock);
  if (is_on && !dumping) {
    DumpProfileLocked(reason);
  }
}

extern "C" void HeapProfilerMarkBaseline() {
  SpinLockHolder l(&heap_lock);

  if (!is_on) return;

  heap_profile->MarkCurrentAllocations(HeapProfileTable::MARK_ONE);
}

extern "C" void HeapProfilerMarkInteresting() {
  SpinLockHolder l(&heap_lock);

  if (!is_on) return;

  heap_profile->MarkUnmarkedAllocations(HeapProfileTable::MARK_TWO);
}

extern "C" void HeapProfilerDumpAliveObjects(const char* filename) {
  SpinLockHolder l(&heap_lock);

  if (!is_on) return;

  heap_profile->DumpMarkedObjects(HeapProfileTable::MARK_TWO, filename);
}

//----------------------------------------------------------------------
// Initialization/finalization code
//----------------------------------------------------------------------
#if defined(ENABLE_PROFILING)
// Initialization code
static void HeapProfilerInit() {
  // Everything after this point is for setting up the profiler based on envvar
  char fname[PATH_MAX];
  if (!GetUniquePathFromEnv(HEAPPROFILE, fname)) {
    return;
  }
  // We do a uid check so we don't write out files in a setuid executable.
#ifdef HAVE_GETEUID
  if (getuid() != geteuid()) {
    RAW_LOG(WARNING, ("HeapProfiler: ignoring " HEAPPROFILE " because "
                      "program seems to be setuid\n"));
    return;
  }
#endif

  HeapProfileTable::CleanupOldProfiles(fname);

  HeapProfilerStart(fname);
}

// class used for finalization -- dumps the heap-profile at program exit
struct HeapProfileEndWriter {
  ~HeapProfileEndWriter() { HeapProfilerDump("Exiting"); }
};

// We want to make sure tcmalloc is up and running before starting the profiler
static const TCMallocGuard tcmalloc_initializer;
REGISTER_MODULE_INITIALIZER(heapprofiler, HeapProfilerInit());
static HeapProfileEndWriter heap_profile_end_writer;
#endif   // defined(ENABLE_PROFILING)
