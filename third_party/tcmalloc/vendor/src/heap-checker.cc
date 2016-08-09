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
// All Rights Reserved.
//
// Author: Maxim Lifantsev
//

#include "config.h"

#include <fcntl.h>    // for O_RDONLY (we use syscall to do actual reads)
#include <string.h>
#include <errno.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_MMAP
#include <sys/mman.h>
#endif
#ifdef HAVE_PTHREAD
#include <pthread.h>
#endif
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <assert.h>

#if defined(HAVE_LINUX_PTRACE_H)
#include <linux/ptrace.h>
#endif
#ifdef HAVE_SYS_SYSCALL_H
#include <sys/syscall.h>
#endif
#if defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__) || defined(__MINGW32__)
#include <wtypes.h>
#include <winbase.h>
#undef ERROR     // windows defines these as macros, which can cause trouble
#undef max
#undef min
#endif

#include <string>
#include <vector>
#include <map>
#include <set>
#include <algorithm>
#include <functional>

#include <gperftools/heap-checker.h>

#include "base/basictypes.h"
#include "base/googleinit.h"
#include "base/logging.h"
#include <gperftools/stacktrace.h>
#include "base/commandlineflags.h"
#include "base/elfcore.h"              // for i386_regs
#include "base/thread_lister.h"
#include "heap-profile-table.h"
#include "base/low_level_alloc.h"
#include "malloc_hook-inl.h"
#include <gperftools/malloc_hook.h>
#include <gperftools/malloc_extension.h>
#include "maybe_threads.h"
#include "memory_region_map.h"
#include "base/spinlock.h"
#include "base/sysinfo.h"
#include "base/stl_allocator.h"

using std::string;
using std::basic_string;
using std::pair;
using std::map;
using std::set;
using std::vector;
using std::swap;
using std::make_pair;
using std::min;
using std::max;
using std::less;
using std::char_traits;

// If current process is being ptrace()d, 'TracerPid' in /proc/self/status
// will be non-zero.
static bool IsDebuggerAttached(void) {    // only works under linux, probably
  char buf[256];   // TracerPid comes relatively earlier in status output
  int fd = open("/proc/self/status", O_RDONLY);
  if (fd == -1) {
    return false;  // Can't tell for sure.
  }
  const int len = read(fd, buf, sizeof(buf));
  bool rc = false;
  if (len > 0) {
    const char *const kTracerPid = "TracerPid:\t";
    buf[len - 1] = '\0';
    const char *p = strstr(buf, kTracerPid);
    if (p != NULL) {
      rc = (strncmp(p + strlen(kTracerPid), "0\n", 2) != 0);
    }
  }
  close(fd);
  return rc;
}

// This is the default if you don't link in -lprofiler
extern "C" {
ATTRIBUTE_WEAK PERFTOOLS_DLL_DECL bool ProfilingIsEnabledForAllThreads();
bool ProfilingIsEnabledForAllThreads() { return false; }
}

//----------------------------------------------------------------------
// Flags that control heap-checking
//----------------------------------------------------------------------

DEFINE_string(heap_check,
              EnvToString("HEAPCHECK", ""),
              "The heap leak checking to be done over the whole executable: "
              "\"minimal\", \"normal\", \"strict\", "
              "\"draconian\", \"as-is\", and \"local\" "
              " or the empty string are the supported choices. "
              "(See HeapLeakChecker_InternalInitStart for details.)");

DEFINE_bool(heap_check_report, true, "Obsolete");

DEFINE_bool(heap_check_before_constructors,
            true,
            "deprecated; pretty much always true now");

DEFINE_bool(heap_check_after_destructors,
            EnvToBool("HEAP_CHECK_AFTER_DESTRUCTORS", false),
            "If overall heap check is to end after global destructors "
            "or right after all REGISTER_HEAPCHECK_CLEANUP's");

DEFINE_bool(heap_check_strict_check, true, "Obsolete");

DEFINE_bool(heap_check_ignore_global_live,
            EnvToBool("HEAP_CHECK_IGNORE_GLOBAL_LIVE", true),
            "If overall heap check is to ignore heap objects reachable "
            "from the global data");

DEFINE_bool(heap_check_identify_leaks,
            EnvToBool("HEAP_CHECK_IDENTIFY_LEAKS", false),
            "If heap check should generate the addresses of the leaked "
            "objects in the memory leak profiles.  This may be useful "
            "in tracking down leaks where only a small fraction of "
            "objects allocated at the same stack trace are leaked.");

DEFINE_bool(heap_check_ignore_thread_live,
            EnvToBool("HEAP_CHECK_IGNORE_THREAD_LIVE", true),
            "If set to true, objects reachable from thread stacks "
            "and registers are not reported as leaks");

DEFINE_bool(heap_check_test_pointer_alignment,
            EnvToBool("HEAP_CHECK_TEST_POINTER_ALIGNMENT", false),
            "Set to true to check if the found leak can be due to "
            "use of unaligned pointers");

// Alignment at which all pointers in memory are supposed to be located;
// use 1 if any alignment is ok.
// heap_check_test_pointer_alignment flag guides if we try the value of 1.
// The larger it can be, the lesser is the chance of missing real leaks.
static const size_t kPointerSourceAlignment = sizeof(void*);
DEFINE_int32(heap_check_pointer_source_alignment,
	     EnvToInt("HEAP_CHECK_POINTER_SOURCE_ALIGNMENT",
                      kPointerSourceAlignment),
             "Alignment at which all pointers in memory are supposed to be "
             "located.  Use 1 if any alignment is ok.");

// A reasonable default to handle pointers inside of typical class objects:
// Too low and we won't be able to traverse pointers to normally-used
// nested objects and base parts of multiple-inherited objects.
// Too high and it will both slow down leak checking (FindInsideAlloc
// in HaveOnHeapLocked will get slower when there are large on-heap objects)
// and make it probabilistically more likely to miss leaks
// of large-sized objects.
static const int64 kHeapCheckMaxPointerOffset = 1024;
DEFINE_int64(heap_check_max_pointer_offset,
	     EnvToInt("HEAP_CHECK_MAX_POINTER_OFFSET",
                      kHeapCheckMaxPointerOffset),
             "Largest pointer offset for which we traverse "
             "pointers going inside of heap allocated objects. "
             "Set to -1 to use the actual largest heap object size.");

DEFINE_bool(heap_check_run_under_gdb,
            EnvToBool("HEAP_CHECK_RUN_UNDER_GDB", false),
            "If false, turns off heap-checking library when running under gdb "
            "(normally, set to 'true' only when debugging the heap-checker)");

DEFINE_int32(heap_check_delay_seconds, 0,
             "Number of seconds to delay on-exit heap checking."
             " If you set this flag,"
             " you may also want to set exit_timeout_seconds in order to"
             " avoid exit timeouts.\n"
             "NOTE: This flag is to be used only to help diagnose issues"
             " where it is suspected that the heap checker is reporting"
             " false leaks that will disappear if the heap checker delays"
             " its checks. Report any such issues to the heap-checker"
             " maintainer(s).");

DEFINE_int32(heap_check_error_exit_code,
             EnvToInt("HEAP_CHECK_ERROR_EXIT_CODE", 1),
             "Exit code to return if any leaks were detected.");

//----------------------------------------------------------------------

DEFINE_string(heap_profile_pprof,
              EnvToString("PPROF_PATH", "pprof"),
              "OBSOLETE; not used");

DEFINE_string(heap_check_dump_directory,
              EnvToString("HEAP_CHECK_DUMP_DIRECTORY", "/tmp"),
              "Directory to put heap-checker leak dump information");


//----------------------------------------------------------------------
// HeapLeakChecker global data
//----------------------------------------------------------------------

// Global lock for all the global data of this module.
static SpinLock heap_checker_lock(SpinLock::LINKER_INITIALIZED);

//----------------------------------------------------------------------

// Heap profile prefix for leak checking profiles.
// Gets assigned once when leak checking is turned on, then never modified.
static const string* profile_name_prefix = NULL;

// Whole-program heap leak checker.
// Gets assigned once when leak checking is turned on,
// then main_heap_checker is never deleted.
static HeapLeakChecker* main_heap_checker = NULL;

// Whether we will use main_heap_checker to do a check at program exit
// automatically. In any case user can ask for more checks on main_heap_checker
// via GlobalChecker().
static bool do_main_heap_check = false;

// The heap profile we use to collect info about the heap.
// This is created in HeapLeakChecker::BeforeConstructorsLocked
// together with setting heap_checker_on (below) to true
// and registering our new/delete malloc hooks;
// similarly all are unset in HeapLeakChecker::TurnItselfOffLocked.
static HeapProfileTable* heap_profile = NULL;

// If we are doing (or going to do) any kind of heap-checking.
static bool heap_checker_on = false;

// pid of the process that does whole-program heap leak checking
static pid_t heap_checker_pid = 0;

// If we did heap profiling during global constructors execution
static bool constructor_heap_profiling = false;

// RAW_VLOG level we dump key INFO messages at.  If you want to turn
// off these messages, set the environment variable PERFTOOLS_VERBOSE=-1.
static const int heap_checker_info_level = 0;

//----------------------------------------------------------------------
// HeapLeakChecker's own memory allocator that is
// independent of the normal program allocator.
//----------------------------------------------------------------------

// Wrapper of LowLevelAlloc for STL_Allocator and direct use.
// We always access this class under held heap_checker_lock,
// this allows us to in particular protect the period when threads are stopped
// at random spots with ListAllProcessThreads by heap_checker_lock,
// w/o worrying about the lock in LowLevelAlloc::Arena.
// We rely on the fact that we use an own arena with an own lock here.
class HeapLeakChecker::Allocator {
 public:
  static void Init() {
    RAW_DCHECK(heap_checker_lock.IsHeld(), "");
    RAW_DCHECK(arena_ == NULL, "");
    arena_ = LowLevelAlloc::NewArena(0, LowLevelAlloc::DefaultArena());
  }
  static void Shutdown() {
    RAW_DCHECK(heap_checker_lock.IsHeld(), "");
    if (!LowLevelAlloc::DeleteArena(arena_)  ||  alloc_count_ != 0) {
      RAW_LOG(FATAL, "Internal heap checker leak of %d objects", alloc_count_);
    }
  }
  static int alloc_count() {
    RAW_DCHECK(heap_checker_lock.IsHeld(), "");
    return alloc_count_;
  }
  static void* Allocate(size_t n) {
    RAW_DCHECK(arena_  &&  heap_checker_lock.IsHeld(), "");
    void* p = LowLevelAlloc::AllocWithArena(n, arena_);
    if (p) alloc_count_ += 1;
    return p;
  }
  static void Free(void* p) {
    RAW_DCHECK(heap_checker_lock.IsHeld(), "");
    if (p) alloc_count_ -= 1;
    LowLevelAlloc::Free(p);
  }
  static void Free(void* p, size_t /* n */) {
    Free(p);
  }
  // destruct, free, and make *p to be NULL
  template<typename T> static void DeleteAndNull(T** p) {
    (*p)->~T();
    Free(*p);
    *p = NULL;
  }
  template<typename T> static void DeleteAndNullIfNot(T** p) {
    if (*p != NULL) DeleteAndNull(p);
  }
 private:
  static LowLevelAlloc::Arena* arena_;
  static int alloc_count_;
};

LowLevelAlloc::Arena* HeapLeakChecker::Allocator::arena_ = NULL;
int HeapLeakChecker::Allocator::alloc_count_ = 0;

//----------------------------------------------------------------------
// HeapLeakChecker live object tracking components
//----------------------------------------------------------------------

// Cases of live object placement we distinguish
enum ObjectPlacement {
  MUST_BE_ON_HEAP,   // Must point to a live object of the matching size in the
                     // heap_profile map of the heap when we get to it
  IGNORED_ON_HEAP,   // Is a live (ignored) object on heap
  MAYBE_LIVE,        // Is a piece of writable memory from /proc/self/maps
  IN_GLOBAL_DATA,    // Is part of global data region of the executable
  THREAD_DATA,       // Part of a thread stack and a thread descriptor with TLS
  THREAD_REGISTERS,  // Values in registers of some thread
};

// Information about an allocated object
struct AllocObject {
  const void* ptr;        // the object
  uintptr_t size;         // its size
  ObjectPlacement place;  // where ptr points to

  AllocObject(const void* p, size_t s, ObjectPlacement l)
    : ptr(p), size(s), place(l) { }
};

// All objects (memory ranges) ignored via HeapLeakChecker::IgnoreObject
// Key is the object's address; value is its size.
typedef map<uintptr_t, size_t, less<uintptr_t>,
            STL_Allocator<pair<const uintptr_t, size_t>,
                          HeapLeakChecker::Allocator>
           > IgnoredObjectsMap;
static IgnoredObjectsMap* ignored_objects = NULL;

// All objects (memory ranges) that we consider to be the sources of pointers
// to live (not leaked) objects.
// At different times this holds (what can be reached from) global data regions
// and the objects we've been told to ignore.
// For any AllocObject::ptr "live_objects" is supposed to contain at most one
// record at any time. We maintain this by checking with the heap_profile map
// of the heap and removing the live heap objects we've handled from it.
// This vector is maintained as a stack and the frontier of reachable
// live heap objects in our flood traversal of them.
typedef vector<AllocObject,
               STL_Allocator<AllocObject, HeapLeakChecker::Allocator>
              > LiveObjectsStack;
static LiveObjectsStack* live_objects = NULL;

// A special string type that uses my allocator
typedef basic_string<char, char_traits<char>,
                     STL_Allocator<char, HeapLeakChecker::Allocator>
                    > HCL_string;

// A placeholder to fill-in the starting values for live_objects
// for each library so we can keep the library-name association for logging.
typedef map<HCL_string, LiveObjectsStack, less<HCL_string>,
            STL_Allocator<pair<const HCL_string, LiveObjectsStack>,
                          HeapLeakChecker::Allocator>
           > LibraryLiveObjectsStacks;
static LibraryLiveObjectsStacks* library_live_objects = NULL;

// Value stored in the map of disabled address ranges;
// its key is the end of the address range.
// We'll ignore allocations with a return address in a disabled range
// if the address occurs at 'max_depth' or less in the stack trace.
struct HeapLeakChecker::RangeValue {
  uintptr_t start_address;  // the start of the range
  int       max_depth;      // the maximal stack depth to disable at
};
typedef map<uintptr_t, HeapLeakChecker::RangeValue, less<uintptr_t>,
            STL_Allocator<pair<const uintptr_t, HeapLeakChecker::RangeValue>,
                          HeapLeakChecker::Allocator>
           > DisabledRangeMap;
// The disabled program counter address ranges for profile dumping
// that are registered with HeapLeakChecker::DisableChecksFromToLocked.
static DisabledRangeMap* disabled_ranges = NULL;

// Set of stack tops.
// These are used to consider live only appropriate chunks of the memory areas
// that are used for stacks (and maybe thread-specific data as well)
// so that we do not treat pointers from outdated stack frames as live.
typedef set<uintptr_t, less<uintptr_t>,
            STL_Allocator<uintptr_t, HeapLeakChecker::Allocator>
           > StackTopSet;
static StackTopSet* stack_tops = NULL;

// A map of ranges of code addresses for the system libraries
// that can mmap/mremap/sbrk-allocate memory regions for stacks
// and thread-local storage that we want to consider as live global data.
// Maps from the end address to the start address.
typedef map<uintptr_t, uintptr_t, less<uintptr_t>,
            STL_Allocator<pair<const uintptr_t, uintptr_t>,
                          HeapLeakChecker::Allocator>
           > GlobalRegionCallerRangeMap;
static GlobalRegionCallerRangeMap* global_region_caller_ranges = NULL;

// TODO(maxim): make our big data structs into own modules

// Disabler is implemented by keeping track of a per-thread count
// of active Disabler objects.  Any objects allocated while the
// count > 0 are not reported.

#ifdef HAVE_TLS

static __thread int thread_disable_counter
// The "inital exec" model is faster than the default TLS model, at
// the cost you can't dlopen this library.  But dlopen on heap-checker
// doesn't work anyway -- it must run before main -- so this is a good
// trade-off.
# ifdef HAVE___ATTRIBUTE__
   __attribute__ ((tls_model ("initial-exec")))
# endif
    ;
inline int get_thread_disable_counter() {
  return thread_disable_counter;
}
inline void set_thread_disable_counter(int value) {
  thread_disable_counter = value;
}

#else  // #ifdef HAVE_TLS

static pthread_key_t thread_disable_counter_key;
static int main_thread_counter;   // storage for use before main()
static bool use_main_thread_counter = true;

// TODO(csilvers): this is called from NewHook, in the middle of malloc().
// If perftools_pthread_getspecific calls malloc, that will lead to an
// infinite loop.  I don't know how to fix that, so I hope it never happens!
inline int get_thread_disable_counter() {
  if (use_main_thread_counter)  // means we're running really early
    return main_thread_counter;
  void* p = perftools_pthread_getspecific(thread_disable_counter_key);
  return (intptr_t)p;   // kinda evil: store the counter directly in the void*
}

inline void set_thread_disable_counter(int value) {
  if (use_main_thread_counter) {   // means we're running really early
    main_thread_counter = value;
    return;
  }
  intptr_t pointer_sized_value = value;
  // kinda evil: store the counter directly in the void*
  void* p = (void*)pointer_sized_value;
  // NOTE: this may call malloc, which will call NewHook which will call
  // get_thread_disable_counter() which will call pthread_getspecific().  I
  // don't know if anything bad can happen if we call getspecific() in the
  // middle of a setspecific() call.  It seems to work ok in practice...
  perftools_pthread_setspecific(thread_disable_counter_key, p);
}

// The idea here is that this initializer will run pretty late: after
// pthreads have been totally set up.  At this point we can call
// pthreads routines, so we set those up.
class InitThreadDisableCounter {
 public:
  InitThreadDisableCounter() {
    perftools_pthread_key_create(&thread_disable_counter_key, NULL);
    // Set up the main thread's value, which we have a special variable for.
    void* p = (void*)main_thread_counter;   // store the counter directly
    perftools_pthread_setspecific(thread_disable_counter_key, p);
    use_main_thread_counter = false;
  }
};
InitThreadDisableCounter init_thread_disable_counter;

#endif  // #ifdef HAVE_TLS

HeapLeakChecker::Disabler::Disabler() {
  // It is faster to unconditionally increment the thread-local
  // counter than to check whether or not heap-checking is on
  // in a thread-safe manner.
  int counter = get_thread_disable_counter();
  set_thread_disable_counter(counter + 1);
  RAW_VLOG(10, "Increasing thread disable counter to %d", counter + 1);
}

HeapLeakChecker::Disabler::~Disabler() {
  int counter = get_thread_disable_counter();
  RAW_DCHECK(counter > 0, "");
  if (counter > 0) {
    set_thread_disable_counter(counter - 1);
    RAW_VLOG(10, "Decreasing thread disable counter to %d", counter);
  } else {
    RAW_VLOG(0, "Thread disable counter underflow : %d", counter);
  }
}

//----------------------------------------------------------------------

// The size of the largest heap object allocated so far.
static size_t max_heap_object_size = 0;
// The possible range of addresses that can point
// into one of the elements of heap_objects.
static uintptr_t min_heap_address = uintptr_t(-1LL);
static uintptr_t max_heap_address = 0;

//----------------------------------------------------------------------

// Simple casting helpers for uintptr_t and void*:
template<typename T>
inline static const void* AsPtr(T addr) {
  return reinterpret_cast<void*>(addr);
}
inline static uintptr_t AsInt(const void* ptr) {
  return reinterpret_cast<uintptr_t>(ptr);
}

//----------------------------------------------------------------------

// We've seen reports that strstr causes heap-checker crashes in some
// libc's (?):
//    http://code.google.com/p/gperftools/issues/detail?id=263
// It's simple enough to use our own.  This is not in time-critical code.
static const char* hc_strstr(const char* s1, const char* s2) {
  const size_t len = strlen(s2);
  RAW_CHECK(len > 0, "Unexpected empty string passed to strstr()");
  for (const char* p = strchr(s1, *s2); p != NULL; p = strchr(p+1, *s2)) {
    if (strncmp(p, s2, len) == 0) {
      return p;
    }
  }
  return NULL;
}

//----------------------------------------------------------------------

// Our hooks for MallocHook
static void NewHook(const void* ptr, size_t size) {
  if (ptr != NULL) {
    const int counter = get_thread_disable_counter();
    const bool ignore = (counter > 0);
    RAW_VLOG(16, "Recording Alloc: %p of %"PRIuS "; %d", ptr, size,
             int(counter));

    // Fetch the caller's stack trace before acquiring heap_checker_lock.
    void* stack[HeapProfileTable::kMaxStackDepth];
    int depth = HeapProfileTable::GetCallerStackTrace(0, stack);

    { SpinLockHolder l(&heap_checker_lock);
      if (size > max_heap_object_size) max_heap_object_size = size;
      uintptr_t addr = AsInt(ptr);
      if (addr < min_heap_address) min_heap_address = addr;
      addr += size;
      if (addr > max_heap_address) max_heap_address = addr;
      if (heap_checker_on) {
        heap_profile->RecordAlloc(ptr, size, depth, stack);
        if (ignore) {
          heap_profile->MarkAsIgnored(ptr);
        }
      }
    }
    RAW_VLOG(17, "Alloc Recorded: %p of %"PRIuS"", ptr, size);
  }
}

static void DeleteHook(const void* ptr) {
  if (ptr != NULL) {
    RAW_VLOG(16, "Recording Free %p", ptr);
    { SpinLockHolder l(&heap_checker_lock);
      if (heap_checker_on) heap_profile->RecordFree(ptr);
    }
    RAW_VLOG(17, "Free Recorded: %p", ptr);
  }
}

//----------------------------------------------------------------------

enum StackDirection {
  GROWS_TOWARDS_HIGH_ADDRESSES,
  GROWS_TOWARDS_LOW_ADDRESSES,
  UNKNOWN_DIRECTION
};

// Determine which way the stack grows:

static StackDirection ATTRIBUTE_NOINLINE GetStackDirection(
    const uintptr_t *const ptr) {
  uintptr_t x;
  if (&x < ptr)
    return GROWS_TOWARDS_LOW_ADDRESSES;
  if (ptr < &x)
    return GROWS_TOWARDS_HIGH_ADDRESSES;

  RAW_CHECK(0, "");  // Couldn't determine the stack direction.

  return UNKNOWN_DIRECTION;
}

// Direction of stack growth (will initialize via GetStackDirection())
static StackDirection stack_direction = UNKNOWN_DIRECTION;

// This routine is called for every thread stack we know about to register it.
static void RegisterStackLocked(const void* top_ptr) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  RAW_DCHECK(MemoryRegionMap::LockIsHeld(), "");
  RAW_VLOG(10, "Thread stack at %p", top_ptr);
  uintptr_t top = AsInt(top_ptr);
  stack_tops->insert(top);  // add for later use

  // make sure stack_direction is initialized
  if (stack_direction == UNKNOWN_DIRECTION) {
    stack_direction = GetStackDirection(&top);
  }

  // Find memory region with this stack
  MemoryRegionMap::Region region;
  if (MemoryRegionMap::FindAndMarkStackRegion(top, &region)) {
    // Make the proper portion of the stack live:
    if (stack_direction == GROWS_TOWARDS_LOW_ADDRESSES) {
      RAW_VLOG(11, "Live stack at %p of %"PRIuPTR" bytes",
                  top_ptr, region.end_addr - top);
      live_objects->push_back(AllocObject(top_ptr, region.end_addr - top,
                                          THREAD_DATA));
    } else {  // GROWS_TOWARDS_HIGH_ADDRESSES
      RAW_VLOG(11, "Live stack at %p of %"PRIuPTR" bytes",
                  AsPtr(region.start_addr),
                  top - region.start_addr);
      live_objects->push_back(AllocObject(AsPtr(region.start_addr),
                                          top - region.start_addr,
                                          THREAD_DATA));
    }
  // not in MemoryRegionMap, look in library_live_objects:
  } else if (FLAGS_heap_check_ignore_global_live) {
    for (LibraryLiveObjectsStacks::iterator lib = library_live_objects->begin();
         lib != library_live_objects->end(); ++lib) {
      for (LiveObjectsStack::iterator span = lib->second.begin();
           span != lib->second.end(); ++span) {
        uintptr_t start = AsInt(span->ptr);
        uintptr_t end = start + span->size;
        if (start <= top  &&  top < end) {
          RAW_VLOG(11, "Stack at %p is inside /proc/self/maps chunk %p..%p",
                      top_ptr, AsPtr(start), AsPtr(end));
          // Shrink start..end region by chopping away the memory regions in
          // MemoryRegionMap that land in it to undo merging of regions
          // in /proc/self/maps, so that we correctly identify what portion
          // of start..end is actually the stack region.
          uintptr_t stack_start = start;
          uintptr_t stack_end = end;
          // can optimize-away this loop, but it does not run often
          RAW_DCHECK(MemoryRegionMap::LockIsHeld(), "");
          for (MemoryRegionMap::RegionIterator r =
                 MemoryRegionMap::BeginRegionLocked();
               r != MemoryRegionMap::EndRegionLocked(); ++r) {
            if (top < r->start_addr  &&  r->start_addr < stack_end) {
              stack_end = r->start_addr;
            }
            if (stack_start < r->end_addr  &&  r->end_addr <= top) {
              stack_start = r->end_addr;
            }
          }
          if (stack_start != start  ||  stack_end != end) {
            RAW_VLOG(11, "Stack at %p is actually inside memory chunk %p..%p",
                        top_ptr, AsPtr(stack_start), AsPtr(stack_end));
          }
          // Make the proper portion of the stack live:
          if (stack_direction == GROWS_TOWARDS_LOW_ADDRESSES) {
            RAW_VLOG(11, "Live stack at %p of %"PRIuPTR" bytes",
                        top_ptr, stack_end - top);
            live_objects->push_back(
              AllocObject(top_ptr, stack_end - top, THREAD_DATA));
          } else {  // GROWS_TOWARDS_HIGH_ADDRESSES
            RAW_VLOG(11, "Live stack at %p of %"PRIuPTR" bytes",
                        AsPtr(stack_start), top - stack_start);
            live_objects->push_back(
              AllocObject(AsPtr(stack_start), top - stack_start, THREAD_DATA));
          }
          lib->second.erase(span);  // kill the rest of the region
          // Put the non-stack part(s) of the region back:
          if (stack_start != start) {
            lib->second.push_back(AllocObject(AsPtr(start), stack_start - start,
                                  MAYBE_LIVE));
          }
          if (stack_end != end) {
            lib->second.push_back(AllocObject(AsPtr(stack_end), end - stack_end,
                                  MAYBE_LIVE));
          }
          return;
        }
      }
    }
    RAW_LOG(ERROR, "Memory region for stack at %p not found. "
                   "Will likely report false leak positives.", top_ptr);
  }
}

// Iterator for heap allocation map data to make ignored objects "live"
// (i.e., treated as roots for the mark-and-sweep phase)
static void MakeIgnoredObjectsLiveCallbackLocked(
    const void* ptr, const HeapProfileTable::AllocInfo& info) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  if (info.ignored) {
    live_objects->push_back(AllocObject(ptr, info.object_size,
                                        MUST_BE_ON_HEAP));
  }
}

// Iterator for heap allocation map data to make objects allocated from
// disabled regions of code to be live.
static void MakeDisabledLiveCallbackLocked(
    const void* ptr, const HeapProfileTable::AllocInfo& info) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  bool stack_disable = false;
  bool range_disable = false;
  for (int depth = 0; depth < info.stack_depth; depth++) {
    uintptr_t addr = AsInt(info.call_stack[depth]);
    if (disabled_ranges) {
      DisabledRangeMap::const_iterator iter
        = disabled_ranges->upper_bound(addr);
      if (iter != disabled_ranges->end()) {
        RAW_DCHECK(iter->first > addr, "");
        if (iter->second.start_address < addr  &&
            iter->second.max_depth > depth) {
          range_disable = true;  // in range; dropping
          break;
        }
      }
    }
  }
  if (stack_disable || range_disable) {
    uintptr_t start_address = AsInt(ptr);
    uintptr_t end_address = start_address + info.object_size;
    StackTopSet::const_iterator iter
      = stack_tops->lower_bound(start_address);
    if (iter != stack_tops->end()) {
      RAW_DCHECK(*iter >= start_address, "");
      if (*iter < end_address) {
        // We do not disable (treat as live) whole allocated regions
        // if they are used to hold thread call stacks
        // (i.e. when we find a stack inside).
        // The reason is that we'll treat as live the currently used
        // stack portions anyway (see RegisterStackLocked),
        // and the rest of the region where the stack lives can well
        // contain outdated stack variables which are not live anymore,
        // hence should not be treated as such.
        RAW_VLOG(11, "Not %s-disabling %"PRIuS" bytes at %p"
                    ": have stack inside: %p",
                    (stack_disable ? "stack" : "range"),
                    info.object_size, ptr, AsPtr(*iter));
        return;
      }
    }
    RAW_VLOG(11, "%s-disabling %"PRIuS" bytes at %p",
                (stack_disable ? "Stack" : "Range"), info.object_size, ptr);
    live_objects->push_back(AllocObject(ptr, info.object_size,
                                        MUST_BE_ON_HEAP));
  }
}

static const char kUnnamedProcSelfMapEntry[] = "UNNAMED";

// This function takes some fields from a /proc/self/maps line:
//
//   start_address  start address of a memory region.
//   end_address    end address of a memory region
//   permissions    rwx + private/shared bit
//   filename       filename of the mapped file
//
// If the region is not writeable, then it cannot have any heap
// pointers in it, otherwise we record it as a candidate live region
// to get filtered later.
static void RecordGlobalDataLocked(uintptr_t start_address,
                                   uintptr_t end_address,
                                   const char* permissions,
                                   const char* filename) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  // Ignore non-writeable regions.
  if (strchr(permissions, 'w') == NULL) return;
  if (filename == NULL  ||  *filename == '\0') {
    filename = kUnnamedProcSelfMapEntry;
  }
  RAW_VLOG(11, "Looking into %s: 0x%" PRIxPTR "..0x%" PRIxPTR,
              filename, start_address, end_address);
  (*library_live_objects)[filename].
    push_back(AllocObject(AsPtr(start_address),
                          end_address - start_address,
                          MAYBE_LIVE));
}

// See if 'library' from /proc/self/maps has base name 'library_base'
// i.e. contains it and has '.' or '-' after it.
static bool IsLibraryNamed(const char* library, const char* library_base) {
  const char* p = hc_strstr(library, library_base);
  size_t sz = strlen(library_base);
  return p != NULL  &&  (p[sz] == '.'  ||  p[sz] == '-');
}

// static
void HeapLeakChecker::DisableLibraryAllocsLocked(const char* library,
                                                 uintptr_t start_address,
                                                 uintptr_t end_address) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  int depth = 0;
  // TODO(maxim): maybe this should be extended to also use objdump
  //              and pick the text portion of the library more precisely.
  if (IsLibraryNamed(library, "/libpthread")  ||
        // libpthread has a lot of small "system" leaks we don't care about.
        // In particular it allocates memory to store data supplied via
        // pthread_setspecific (which can be the only pointer to a heap object).
      IsLibraryNamed(library, "/libdl")  ||
        // library loaders leak some "system" heap that we don't care about
      IsLibraryNamed(library, "/libcrypto")  ||
        // Sometimes libcrypto of OpenSSH is compiled with -fomit-frame-pointer
        // (any library can be, of course, but this one often is because speed
        // is so important for making crypto usable).  We ignore all its
        // allocations because we can't see the call stacks.  We'd prefer
        // to ignore allocations done in files/symbols that match
        // "default_malloc_ex|default_realloc_ex"
        // but that doesn't work when the end-result binary is stripped.
      IsLibraryNamed(library, "/libjvm")  ||
        // JVM has a lot of leaks we don't care about.
      IsLibraryNamed(library, "/libzip")
        // The JVM leaks java.util.zip.Inflater after loading classes.
     ) {
    depth = 1;  // only disable allocation calls directly from the library code
  } else if (IsLibraryNamed(library, "/ld")
               // library loader leaks some "system" heap
               // (e.g. thread-local storage) that we don't care about
            ) {
    depth = 2;  // disable allocation calls directly from the library code
                // and at depth 2 from it.
    // We need depth 2 here solely because of a libc bug that
    // forces us to jump through __memalign_hook and MemalignOverride hoops
    // in tcmalloc.cc.
    // Those buggy __libc_memalign() calls are in ld-linux.so and happen for
    // thread-local storage allocations that we want to ignore here.
    // We go with the depth-2 hack as a workaround for this libc bug:
    // otherwise we'd need to extend MallocHook interface
    // so that correct stack depth adjustment can be propagated from
    // the exceptional case of MemalignOverride.
    // Using depth 2 here should not mask real leaks because ld-linux.so
    // does not call user code.
  }
  if (depth) {
    RAW_VLOG(10, "Disabling allocations from %s at depth %d:", library, depth);
    DisableChecksFromToLocked(AsPtr(start_address), AsPtr(end_address), depth);
    if (IsLibraryNamed(library, "/libpthread")  ||
        IsLibraryNamed(library, "/libdl")  ||
        IsLibraryNamed(library, "/ld")) {
      RAW_VLOG(10, "Global memory regions made by %s will be live data",
                  library);
      if (global_region_caller_ranges == NULL) {
        global_region_caller_ranges =
          new(Allocator::Allocate(sizeof(GlobalRegionCallerRangeMap)))
            GlobalRegionCallerRangeMap;
      }
      global_region_caller_ranges
        ->insert(make_pair(end_address, start_address));
    }
  }
}

// static
HeapLeakChecker::ProcMapsResult HeapLeakChecker::UseProcMapsLocked(
                                  ProcMapsTask proc_maps_task) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  // Need to provide own scratch memory to ProcMapsIterator:
  ProcMapsIterator::Buffer buffer;
  ProcMapsIterator it(0, &buffer);
  if (!it.Valid()) {
    int errsv = errno;
    RAW_LOG(ERROR, "Could not open /proc/self/maps: errno=%d. "
                   "Libraries will not be handled correctly.", errsv);
    return CANT_OPEN_PROC_MAPS;
  }
  uint64 start_address, end_address, file_offset;
  int64 inode;
  char *permissions, *filename;
  bool saw_shared_lib = false;
  bool saw_nonzero_inode = false;
  bool saw_shared_lib_with_nonzero_inode = false;
  while (it.Next(&start_address, &end_address, &permissions,
                 &file_offset, &inode, &filename)) {
    if (start_address >= end_address) {
      // Warn if a line we can be interested in is ill-formed:
      if (inode != 0) {
        RAW_LOG(ERROR, "Errors reading /proc/self/maps. "
                       "Some global memory regions will not "
                       "be handled correctly.");
      }
      // Silently skip other ill-formed lines: some are possible
      // probably due to the interplay of how /proc/self/maps is updated
      // while we read it in chunks in ProcMapsIterator and
      // do things in this loop.
      continue;
    }
    // Determine if any shared libraries are present (this is the same
    // list of extensions as is found in pprof).  We want to ignore
    // 'fake' libraries with inode 0 when determining.  However, some
    // systems don't share inodes via /proc, so we turn off this check
    // if we don't see any evidence that we're getting inode info.
    if (inode != 0) {
      saw_nonzero_inode = true;
    }
    if ((hc_strstr(filename, "lib") && hc_strstr(filename, ".so")) ||
        hc_strstr(filename, ".dll") ||
        // not all .dylib filenames start with lib. .dylib is big enough
        // that we are unlikely to get false matches just checking that.
        hc_strstr(filename, ".dylib") || hc_strstr(filename, ".bundle")) {
      saw_shared_lib = true;
      if (inode != 0) {
        saw_shared_lib_with_nonzero_inode = true;
      }
    }

    switch (proc_maps_task) {
      case DISABLE_LIBRARY_ALLOCS:
        // All lines starting like
        // "401dc000-4030f000 r??p 00132000 03:01 13991972  lib/bin"
        // identify a data and code sections of a shared library or our binary
        if (inode != 0 && strncmp(permissions, "r-xp", 4) == 0) {
          DisableLibraryAllocsLocked(filename, start_address, end_address);
        }
        break;
      case RECORD_GLOBAL_DATA:
        RecordGlobalDataLocked(start_address, end_address,
                               permissions, filename);
        break;
      default:
        RAW_CHECK(0, "");
    }
  }
  // If /proc/self/maps is reporting inodes properly (we saw a
  // non-zero inode), then we only say we saw a shared lib if we saw a
  // 'real' one, with a non-zero inode.
  if (saw_nonzero_inode) {
    saw_shared_lib = saw_shared_lib_with_nonzero_inode;
  }
  if (!saw_shared_lib) {
    RAW_LOG(ERROR, "No shared libs detected. Will likely report false leak "
                   "positives for statically linked executables.");
    return NO_SHARED_LIBS_IN_PROC_MAPS;
  }
  return PROC_MAPS_USED;
}

// Total number and size of live objects dropped from the profile;
// (re)initialized in IgnoreAllLiveObjectsLocked.
static int64 live_objects_total;
static int64 live_bytes_total;

// pid of the thread that is doing the current leak check
// (protected by our lock; IgnoreAllLiveObjectsLocked sets it)
static pid_t self_thread_pid = 0;

// Status of our thread listing callback execution
// (protected by our lock; used from within IgnoreAllLiveObjectsLocked)
static enum {
  CALLBACK_NOT_STARTED,
  CALLBACK_STARTED,
  CALLBACK_COMPLETED,
} thread_listing_status = CALLBACK_NOT_STARTED;

// Ideally to avoid deadlocks this function should not result in any libc
// or other function calls that might need to lock a mutex:
// It is called when all threads of a process are stopped
// at arbitrary points thus potentially holding those locks.
//
// In practice we are calling some simple i/o and sprintf-type library functions
// for logging messages, but use only our own LowLevelAlloc::Arena allocator.
//
// This is known to be buggy: the library i/o function calls are able to cause
// deadlocks when they request a lock that a stopped thread happens to hold.
// This issue as far as we know have so far not resulted in any deadlocks
// in practice, so for now we are taking our chance that the deadlocks
// have insignificant frequency.
//
// If such deadlocks become a problem we should make the i/o calls
// into appropriately direct system calls (or eliminate them),
// in particular write() is not safe and vsnprintf() is potentially dangerous
// due to reliance on locale functions (these are called through RAW_LOG
// and in other ways).
//
/*static*/ int HeapLeakChecker::IgnoreLiveThreadsLocked(void* parameter,
                                                        int num_threads,
                                                        pid_t* thread_pids,
                                                        va_list /*ap*/) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  thread_listing_status = CALLBACK_STARTED;
  RAW_VLOG(11, "Found %d threads (from pid %d)", num_threads, getpid());

  if (FLAGS_heap_check_ignore_global_live) {
    UseProcMapsLocked(RECORD_GLOBAL_DATA);
  }

  // We put the registers from other threads here
  // to make pointers stored in them live.
  vector<void*, STL_Allocator<void*, Allocator> > thread_registers;

  int failures = 0;
  for (int i = 0; i < num_threads; ++i) {
    // the leak checking thread itself is handled
    // specially via self_thread_stack, not here:
    if (thread_pids[i] == self_thread_pid) continue;
    RAW_VLOG(11, "Handling thread with pid %d", thread_pids[i]);
#if (defined(__i386__) || defined(__x86_64)) && \
    defined(HAVE_LINUX_PTRACE_H) && defined(HAVE_SYS_SYSCALL_H) && defined(DUMPER)
    i386_regs thread_regs;
#define sys_ptrace(r, p, a, d)  syscall(SYS_ptrace, (r), (p), (a), (d))
    // We use sys_ptrace to avoid thread locking
    // because this is called from ListAllProcessThreads
    // when all but this thread are suspended.
    if (sys_ptrace(PTRACE_GETREGS, thread_pids[i], NULL, &thread_regs) == 0) {
      // Need to use SP to get all the data from the very last stack frame:
      COMPILE_ASSERT(sizeof(thread_regs.SP) == sizeof(void*),
                     SP_register_does_not_look_like_a_pointer);
      RegisterStackLocked(reinterpret_cast<void*>(thread_regs.SP));
      // Make registers live (just in case PTRACE_ATTACH resulted in some
      // register pointers still being in the registers and not on the stack):
      for (void** p = reinterpret_cast<void**>(&thread_regs);
           p < reinterpret_cast<void**>(&thread_regs + 1); ++p) {
        RAW_VLOG(12, "Thread register %p", *p);
        thread_registers.push_back(*p);
      }
    } else {
      failures += 1;
    }
#else
    failures += 1;
#endif
  }
  // Use all the collected thread (stack) liveness sources:
  IgnoreLiveObjectsLocked("threads stack data", "");
  if (thread_registers.size()) {
    // Make thread registers be live heap data sources.
    // we rely here on the fact that vector is in one memory chunk:
    RAW_VLOG(11, "Live registers at %p of %"PRIuS" bytes",
                &thread_registers[0], thread_registers.size() * sizeof(void*));
    live_objects->push_back(AllocObject(&thread_registers[0],
                                        thread_registers.size() * sizeof(void*),
                                        THREAD_REGISTERS));
    IgnoreLiveObjectsLocked("threads register data", "");
  }
  // Do all other liveness walking while all threads are stopped:
  IgnoreNonThreadLiveObjectsLocked();
  // Can now resume the threads:
  ResumeAllProcessThreads(num_threads, thread_pids);
  thread_listing_status = CALLBACK_COMPLETED;
  return failures;
}

// Stack top of the thread that is doing the current leak check
// (protected by our lock; IgnoreAllLiveObjectsLocked sets it)
static const void* self_thread_stack_top;

// static
void HeapLeakChecker::IgnoreNonThreadLiveObjectsLocked() {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  RAW_DCHECK(MemoryRegionMap::LockIsHeld(), "");
  RAW_VLOG(11, "Handling self thread with pid %d", self_thread_pid);
  // Register our own stack:

  // Important that all stack ranges (including the one here)
  // are known before we start looking at them
  // in MakeDisabledLiveCallbackLocked:
  RegisterStackLocked(self_thread_stack_top);
  IgnoreLiveObjectsLocked("stack data", "");

  // Make objects we were told to ignore live:
  if (ignored_objects) {
    for (IgnoredObjectsMap::const_iterator object = ignored_objects->begin();
         object != ignored_objects->end(); ++object) {
      const void* ptr = AsPtr(object->first);
      RAW_VLOG(11, "Ignored live object at %p of %"PRIuS" bytes",
                  ptr, object->second);
      live_objects->
        push_back(AllocObject(ptr, object->second, MUST_BE_ON_HEAP));
      // we do this liveness check for ignored_objects before doing any
      // live heap walking to make sure it does not fail needlessly:
      size_t object_size;
      if (!(heap_profile->FindAlloc(ptr, &object_size)  &&
            object->second == object_size)) {
        RAW_LOG(FATAL, "Object at %p of %"PRIuS" bytes from an"
                       " IgnoreObject() has disappeared", ptr, object->second);
      }
    }
    IgnoreLiveObjectsLocked("ignored objects", "");
  }

  // Treat objects that were allocated when a Disabler was live as
  // roots.  I.e., if X was allocated while a Disabler was active,
  // and Y is reachable from X, arrange that neither X nor Y are
  // treated as leaks.
  heap_profile->IterateAllocs(MakeIgnoredObjectsLiveCallbackLocked);
  IgnoreLiveObjectsLocked("disabled objects", "");

  // Make code-address-disabled objects live and ignored:
  // This in particular makes all thread-specific data live
  // because the basic data structure to hold pointers to thread-specific data
  // is allocated from libpthreads and we have range-disabled that
  // library code with UseProcMapsLocked(DISABLE_LIBRARY_ALLOCS);
  // so now we declare all thread-specific data reachable from there as live.
  heap_profile->IterateAllocs(MakeDisabledLiveCallbackLocked);
  IgnoreLiveObjectsLocked("disabled code", "");

  // Actually make global data live:
  if (FLAGS_heap_check_ignore_global_live) {
    bool have_null_region_callers = false;
    for (LibraryLiveObjectsStacks::iterator l = library_live_objects->begin();
         l != library_live_objects->end(); ++l) {
      RAW_CHECK(live_objects->empty(), "");
      // Process library_live_objects in l->second
      // filtering them by MemoryRegionMap:
      // It's safe to iterate over MemoryRegionMap
      // w/o locks here as we are inside MemoryRegionMap::Lock():
      RAW_DCHECK(MemoryRegionMap::LockIsHeld(), "");
      // The only change to MemoryRegionMap possible in this loop
      // is region addition as a result of allocating more memory
      // for live_objects. This won't invalidate the RegionIterator
      // or the intent of the loop.
      // --see the comment by MemoryRegionMap::BeginRegionLocked().
      for (MemoryRegionMap::RegionIterator region =
             MemoryRegionMap::BeginRegionLocked();
           region != MemoryRegionMap::EndRegionLocked(); ++region) {
        // "region" from MemoryRegionMap is to be subtracted from
        // (tentatively live) regions in l->second
        // if it has a stack inside or it was allocated by
        // a non-special caller (not one covered by a range
        // in global_region_caller_ranges).
        // This will in particular exclude all memory chunks used
        // by the heap itself as well as what's been allocated with
        // any allocator on top of mmap.
        bool subtract = true;
        if (!region->is_stack  &&  global_region_caller_ranges) {
          if (region->caller() == static_cast<uintptr_t>(NULL)) {
            have_null_region_callers = true;
          } else {
            GlobalRegionCallerRangeMap::const_iterator iter
              = global_region_caller_ranges->upper_bound(region->caller());
            if (iter != global_region_caller_ranges->end()) {
              RAW_DCHECK(iter->first > region->caller(), "");
              if (iter->second < region->caller()) {  // in special region
                subtract = false;
              }
            }
          }
        }
        if (subtract) {
          // The loop puts the result of filtering l->second into live_objects:
          for (LiveObjectsStack::const_iterator i = l->second.begin();
               i != l->second.end(); ++i) {
            // subtract *region from *i
            uintptr_t start = AsInt(i->ptr);
            uintptr_t end = start + i->size;
            if (region->start_addr <= start  &&  end <= region->end_addr) {
              // full deletion due to subsumption
            } else if (start < region->start_addr  &&
                       region->end_addr < end) {  // cutting-out split
              live_objects->push_back(AllocObject(i->ptr,
                                                  region->start_addr - start,
                                                  IN_GLOBAL_DATA));
              live_objects->push_back(AllocObject(AsPtr(region->end_addr),
                                                  end - region->end_addr,
                                                  IN_GLOBAL_DATA));
            } else if (region->end_addr > start  &&
                       region->start_addr <= start) {  // cut from start
              live_objects->push_back(AllocObject(AsPtr(region->end_addr),
                                                  end - region->end_addr,
                                                  IN_GLOBAL_DATA));
            } else if (region->start_addr > start  &&
                       region->start_addr < end) {  // cut from end
              live_objects->push_back(AllocObject(i->ptr,
                                                  region->start_addr - start,
                                                  IN_GLOBAL_DATA));
            } else {  // pass: no intersection
              live_objects->push_back(AllocObject(i->ptr, i->size,
                                                  IN_GLOBAL_DATA));
            }
          }
          // Move live_objects back into l->second
          // for filtering by the next region.
          live_objects->swap(l->second);
          live_objects->clear();
        }
      }
      // Now get and use live_objects from the final version of l->second:
      if (VLOG_IS_ON(11)) {
        for (LiveObjectsStack::const_iterator i = l->second.begin();
             i != l->second.end(); ++i) {
          RAW_VLOG(11, "Library live region at %p of %"PRIuPTR" bytes",
                      i->ptr, i->size);
        }
      }
      live_objects->swap(l->second);
      IgnoreLiveObjectsLocked("in globals of\n  ", l->first.c_str());
    }
    if (have_null_region_callers) {
      RAW_LOG(ERROR, "Have memory regions w/o callers: "
                     "might report false leaks");
    }
    Allocator::DeleteAndNull(&library_live_objects);
  }
}

// Callback for ListAllProcessThreads in IgnoreAllLiveObjectsLocked below
// to test/verify that we have just the one main thread, in which case
// we can do everything in that main thread,
// so that CPU profiler can collect all its samples.
// Returns the number of threads in the process.
static int IsOneThread(void* parameter, int num_threads,
                       pid_t* thread_pids, va_list ap) {
  if (num_threads != 1) {
    RAW_LOG(WARNING, "Have threads: Won't CPU-profile the bulk of leak "
                     "checking work happening in IgnoreLiveThreadsLocked!");
  }
  ResumeAllProcessThreads(num_threads, thread_pids);
  return num_threads;
}

// Dummy for IgnoreAllLiveObjectsLocked below.
// Making it global helps with compiler warnings.
static va_list dummy_ap;

// static
void HeapLeakChecker::IgnoreAllLiveObjectsLocked(const void* self_stack_top) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  RAW_CHECK(live_objects == NULL, "");
  live_objects = new(Allocator::Allocate(sizeof(LiveObjectsStack)))
                   LiveObjectsStack;
  stack_tops = new(Allocator::Allocate(sizeof(StackTopSet))) StackTopSet;
  // reset the counts
  live_objects_total = 0;
  live_bytes_total = 0;
  // Reduce max_heap_object_size to FLAGS_heap_check_max_pointer_offset
  // for the time of leak check.
  // FLAGS_heap_check_max_pointer_offset caps max_heap_object_size
  // to manage reasonably low chances of random bytes
  // appearing to be pointing into large actually leaked heap objects.
  const size_t old_max_heap_object_size = max_heap_object_size;
  max_heap_object_size = (
    FLAGS_heap_check_max_pointer_offset != -1
    ? min(size_t(FLAGS_heap_check_max_pointer_offset), max_heap_object_size)
    : max_heap_object_size);
  // Record global data as live:
  if (FLAGS_heap_check_ignore_global_live) {
    library_live_objects =
      new(Allocator::Allocate(sizeof(LibraryLiveObjectsStacks)))
        LibraryLiveObjectsStacks;
  }
  // Ignore all thread stacks:
  thread_listing_status = CALLBACK_NOT_STARTED;
  bool need_to_ignore_non_thread_objects = true;
  self_thread_pid = getpid();
  self_thread_stack_top = self_stack_top;
  if (FLAGS_heap_check_ignore_thread_live) {
    // In case we are doing CPU profiling we'd like to do all the work
    // in the main thread, not in the special thread created by
    // ListAllProcessThreads, so that CPU profiler can collect all its samples.
    // The machinery of ListAllProcessThreads conflicts with the CPU profiler
    // by also relying on signals and ::sigaction.
    // We can do this (run everything in the main thread) safely
    // only if there's just the main thread itself in our process.
    // This variable reflects these two conditions:
    bool want_and_can_run_in_main_thread =
      ProfilingIsEnabledForAllThreads()  &&
      ListAllProcessThreads(NULL, IsOneThread) == 1;
    // When the normal path of ListAllProcessThreads below is taken,
    // we fully suspend the threads right here before any liveness checking
    // and keep them suspended for the whole time of liveness checking
    // inside of the IgnoreLiveThreadsLocked callback.
    // (The threads can't (de)allocate due to lock on the delete hook but
    //  if not suspended they could still mess with the pointer
    //  graph while we walk it).
    int r = want_and_can_run_in_main_thread
            ? IgnoreLiveThreadsLocked(NULL, 1, &self_thread_pid, dummy_ap)
            : ListAllProcessThreads(NULL, IgnoreLiveThreadsLocked);
    need_to_ignore_non_thread_objects = r < 0;
    if (r < 0) {
      RAW_LOG(WARNING, "Thread finding failed with %d errno=%d", r, errno);
      if (thread_listing_status == CALLBACK_COMPLETED) {
        RAW_LOG(INFO, "Thread finding callback "
                      "finished ok; hopefully everything is fine");
        need_to_ignore_non_thread_objects = false;
      } else if (thread_listing_status == CALLBACK_STARTED) {
        RAW_LOG(FATAL, "Thread finding callback was "
                       "interrupted or crashed; can't fix this");
      } else {  // CALLBACK_NOT_STARTED
        RAW_LOG(ERROR, "Could not find thread stacks. "
                       "Will likely report false leak positives.");
      }
    } else if (r != 0) {
      RAW_LOG(ERROR, "Thread stacks not found for %d threads. "
                     "Will likely report false leak positives.", r);
    } else {
      RAW_VLOG(11, "Thread stacks appear to be found for all threads");
    }
  } else {
    RAW_LOG(WARNING, "Not looking for thread stacks; "
                     "objects reachable only from there "
                     "will be reported as leaks");
  }
  // Do all other live data ignoring here if we did not do it
  // within thread listing callback with all threads stopped.
  if (need_to_ignore_non_thread_objects) {
    if (FLAGS_heap_check_ignore_global_live) {
      UseProcMapsLocked(RECORD_GLOBAL_DATA);
    }
    IgnoreNonThreadLiveObjectsLocked();
  }
  if (live_objects_total) {
    RAW_VLOG(10, "Ignoring %"PRId64" reachable objects of %"PRId64" bytes",
                live_objects_total, live_bytes_total);
  }
  // Free these: we made them here and heap_profile never saw them
  Allocator::DeleteAndNull(&live_objects);
  Allocator::DeleteAndNull(&stack_tops);
  max_heap_object_size = old_max_heap_object_size;  // reset this var
}

// Alignment at which we should consider pointer positions
// in IgnoreLiveObjectsLocked. Will normally use the value of
// FLAGS_heap_check_pointer_source_alignment.
static size_t pointer_source_alignment = kPointerSourceAlignment;
// Global lock for HeapLeakChecker::DoNoLeaks
// to protect pointer_source_alignment.
static SpinLock alignment_checker_lock(SpinLock::LINKER_INITIALIZED);

// This function changes the live bits in the heap_profile-table's state:
// we only record the live objects to be skipped.
//
// When checking if a byte sequence points to a heap object we use
// HeapProfileTable::FindInsideAlloc to handle both pointers to
// the start and inside of heap-allocated objects.
// The "inside" case needs to be checked to support
// at least the following relatively common cases:
// - C++ arrays allocated with new FooClass[size] for classes
//   with destructors have their size recorded in a sizeof(int) field
//   before the place normal pointers point to.
// - basic_string<>-s for e.g. the C++ library of gcc 3.4
//   have the meta-info in basic_string<...>::_Rep recorded
//   before the place normal pointers point to.
// - Multiple-inherited objects have their pointers when cast to
//   different base classes pointing inside of the actually
//   allocated object.
// - Sometimes reachability pointers point to member objects of heap objects,
//   and then those member objects point to the full heap object.
// - Third party UnicodeString: it stores a 32-bit refcount
//   (in both 32-bit and 64-bit binaries) as the first uint32
//   in the allocated memory and a normal pointer points at
//   the second uint32 behind the refcount.
// By finding these additional objects here
// we slightly increase the chance to mistake random memory bytes
// for a pointer and miss a leak in a particular run of a binary.
//
/*static*/ void HeapLeakChecker::IgnoreLiveObjectsLocked(const char* name,
                                                         const char* name2) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  int64 live_object_count = 0;
  int64 live_byte_count = 0;
  while (!live_objects->empty()) {
    const char* object =
      reinterpret_cast<const char*>(live_objects->back().ptr);
    size_t size = live_objects->back().size;
    const ObjectPlacement place = live_objects->back().place;
    live_objects->pop_back();
    if (place == MUST_BE_ON_HEAP  &&  heap_profile->MarkAsLive(object)) {
      live_object_count += 1;
      live_byte_count += size;
    }
    RAW_VLOG(13, "Looking for heap pointers in %p of %"PRIuS" bytes",
                object, size);
    const char* const whole_object = object;
    size_t const whole_size = size;
    // Try interpretting any byte sequence in object,size as a heap pointer:
    const size_t remainder = AsInt(object) % pointer_source_alignment;
    if (remainder) {
      object += pointer_source_alignment - remainder;
      if (size >= pointer_source_alignment - remainder) {
        size -= pointer_source_alignment - remainder;
      } else {
        size = 0;
      }
    }
    if (size < sizeof(void*)) continue;

#ifdef NO_FRAME_POINTER
    // Frame pointer omission requires us to use libunwind, which uses direct
    // mmap and munmap system calls, and that needs special handling.
    if (name2 == kUnnamedProcSelfMapEntry) {
      static const uintptr_t page_mask = ~(getpagesize() - 1);
      const uintptr_t addr = reinterpret_cast<uintptr_t>(object);
      if ((addr & page_mask) == 0 && (size & page_mask) == 0) {
        // This is an object we slurped from /proc/self/maps.
        // It may or may not be readable at this point.
        //
        // In case all the above conditions made a mistake, and the object is
        // not related to libunwind, we also verify that it's not readable
        // before ignoring it.
        if (msync(const_cast<char*>(object), size, MS_ASYNC) != 0) {
          // Skip unreadable object, so we don't crash trying to sweep it.
          RAW_VLOG(0, "Ignoring inaccessible object [%p, %p) "
                   "(msync error %d (%s))",
                   object, object + size, errno, strerror(errno));
          continue;
        }
      }
    }
#endif

    const char* const max_object = object + size - sizeof(void*);
    while (object <= max_object) {
      // potentially unaligned load:
      const uintptr_t addr = *reinterpret_cast<const uintptr_t*>(object);
      // Do fast check before the more expensive HaveOnHeapLocked lookup:
      // this code runs for all memory words that are potentially pointers:
      const bool can_be_on_heap =
        // Order tests by the likelyhood of the test failing in 64/32 bit modes.
        // Yes, this matters: we either lose 5..6% speed in 32 bit mode
        // (which is already slower) or by a factor of 1.5..1.91 in 64 bit mode.
        // After the alignment test got dropped the above performance figures
        // must have changed; might need to revisit this.
#if defined(__x86_64__)
        addr <= max_heap_address  &&  // <= is for 0-sized object with max addr
        min_heap_address <= addr;
#else
        min_heap_address <= addr  &&
        addr <= max_heap_address;  // <= is for 0-sized object with max addr
#endif
      if (can_be_on_heap) {
        const void* ptr = reinterpret_cast<const void*>(addr);
        // Too expensive (inner loop): manually uncomment when debugging:
        // RAW_VLOG(17, "Trying pointer to %p at %p", ptr, object);
        size_t object_size;
        if (HaveOnHeapLocked(&ptr, &object_size)  &&
            heap_profile->MarkAsLive(ptr)) {
          // We take the (hopefully low) risk here of encountering by accident
          // a byte sequence in memory that matches an address of
          // a heap object which is in fact leaked.
          // I.e. in very rare and probably not repeatable/lasting cases
          // we might miss some real heap memory leaks.
          RAW_VLOG(14, "Found pointer to %p of %"PRIuS" bytes at %p "
                      "inside %p of size %"PRIuS"",
                      ptr, object_size, object, whole_object, whole_size);
          if (VLOG_IS_ON(15)) {
            // log call stacks to help debug how come something is not a leak
            HeapProfileTable::AllocInfo alloc;
            if (!heap_profile->FindAllocDetails(ptr, &alloc)) {
              RAW_LOG(FATAL, "FindAllocDetails failed on ptr %p", ptr);
            }
            RAW_LOG(INFO, "New live %p object's alloc stack:", ptr);
            for (int i = 0; i < alloc.stack_depth; ++i) {
              RAW_LOG(INFO, "  @ %p", alloc.call_stack[i]);
            }
          }
          live_object_count += 1;
          live_byte_count += object_size;
          live_objects->push_back(AllocObject(ptr, object_size,
                                              IGNORED_ON_HEAP));
        }
      }
      object += pointer_source_alignment;
    }
  }
  live_objects_total += live_object_count;
  live_bytes_total += live_byte_count;
  if (live_object_count) {
    RAW_VLOG(10, "Removed %"PRId64" live heap objects of %"PRId64" bytes: %s%s",
                live_object_count, live_byte_count, name, name2);
  }
}

//----------------------------------------------------------------------
// HeapLeakChecker leak check disabling components
//----------------------------------------------------------------------

// static
void HeapLeakChecker::DisableChecksIn(const char* pattern) {
  RAW_LOG(WARNING, "DisableChecksIn(%s) is ignored", pattern);
}

// static
void HeapLeakChecker::DoIgnoreObject(const void* ptr) {
  SpinLockHolder l(&heap_checker_lock);
  if (!heap_checker_on) return;
  size_t object_size;
  if (!HaveOnHeapLocked(&ptr, &object_size)) {
    RAW_LOG(ERROR, "No live heap object at %p to ignore", ptr);
  } else {
    RAW_VLOG(10, "Going to ignore live object at %p of %"PRIuS" bytes",
                ptr, object_size);
    if (ignored_objects == NULL)  {
      ignored_objects = new(Allocator::Allocate(sizeof(IgnoredObjectsMap)))
                          IgnoredObjectsMap;
    }
    if (!ignored_objects->insert(make_pair(AsInt(ptr), object_size)).second) {
      RAW_LOG(WARNING, "Object at %p is already being ignored", ptr);
    }
  }
}

// static
void HeapLeakChecker::UnIgnoreObject(const void* ptr) {
  SpinLockHolder l(&heap_checker_lock);
  if (!heap_checker_on) return;
  size_t object_size;
  if (!HaveOnHeapLocked(&ptr, &object_size)) {
    RAW_LOG(FATAL, "No live heap object at %p to un-ignore", ptr);
  } else {
    bool found = false;
    if (ignored_objects) {
      IgnoredObjectsMap::iterator object = ignored_objects->find(AsInt(ptr));
      if (object != ignored_objects->end()  &&  object_size == object->second) {
        ignored_objects->erase(object);
        found = true;
        RAW_VLOG(10, "Now not going to ignore live object "
                    "at %p of %"PRIuS" bytes", ptr, object_size);
      }
    }
    if (!found)  RAW_LOG(FATAL, "Object at %p has not been ignored", ptr);
  }
}

//----------------------------------------------------------------------
// HeapLeakChecker non-static functions
//----------------------------------------------------------------------

char* HeapLeakChecker::MakeProfileNameLocked() {
  RAW_DCHECK(lock_->IsHeld(), "");
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  const int len = profile_name_prefix->size() + strlen(name_) + 5 +
                  strlen(HeapProfileTable::kFileExt) + 1;
  char* file_name = reinterpret_cast<char*>(Allocator::Allocate(len));
  snprintf(file_name, len, "%s.%s-end%s",
           profile_name_prefix->c_str(), name_,
           HeapProfileTable::kFileExt);
  return file_name;
}

void HeapLeakChecker::Create(const char *name, bool make_start_snapshot) {
  SpinLockHolder l(lock_);
  name_ = NULL;  // checker is inactive
  start_snapshot_ = NULL;
  has_checked_ = false;
  inuse_bytes_increase_ = 0;
  inuse_allocs_increase_ = 0;
  keep_profiles_ = false;
  char* n = new char[strlen(name) + 1];   // do this before we lock
  IgnoreObject(n);  // otherwise it might be treated as live due to our stack
  { // Heap activity in other threads is paused for this whole scope.
    SpinLockHolder al(&alignment_checker_lock);
    SpinLockHolder hl(&heap_checker_lock);
    MemoryRegionMap::LockHolder ml;
    if (heap_checker_on  &&  profile_name_prefix != NULL) {
      RAW_DCHECK(strchr(name, '/') == NULL, "must be a simple name");
      memcpy(n, name, strlen(name) + 1);
      name_ = n;  // checker is active
      if (make_start_snapshot) {
        start_snapshot_ = heap_profile->TakeSnapshot();
      }

      const HeapProfileTable::Stats& t = heap_profile->total();
      const size_t start_inuse_bytes = t.alloc_size - t.free_size;
      const size_t start_inuse_allocs = t.allocs - t.frees;
      RAW_VLOG(10, "Start check \"%s\" profile: %"PRIuS" bytes "
               "in %"PRIuS" objects",
               name_, start_inuse_bytes, start_inuse_allocs);
    } else {
      RAW_LOG(WARNING, "Heap checker is not active, "
                       "hence checker \"%s\" will do nothing!", name);
    RAW_LOG(WARNING, "To activate set the HEAPCHECK environment variable.\n");
    }
  }
  if (name_ == NULL) {
    UnIgnoreObject(n);
    delete[] n;  // must be done after we unlock
  }
}

HeapLeakChecker::HeapLeakChecker(const char *name) : lock_(new SpinLock) {
  RAW_DCHECK(strcmp(name, "_main_") != 0, "_main_ is reserved");
  Create(name, true/*create start_snapshot_*/);
}

HeapLeakChecker::HeapLeakChecker() : lock_(new SpinLock) {
  if (FLAGS_heap_check_before_constructors) {
    // We want to check for leaks of objects allocated during global
    // constructors (i.e., objects allocated already).  So we do not
    // create a baseline snapshot and hence check for leaks of objects
    // that may have already been created.
    Create("_main_", false);
  } else {
    // We want to ignore leaks of objects allocated during global
    // constructors (i.e., objects allocated already).  So we snapshot
    // the current heap contents and use them as a baseline that is
    // not reported by the leak checker.
    Create("_main_", true);
  }
}

ssize_t HeapLeakChecker::BytesLeaked() const {
  SpinLockHolder l(lock_);
  if (!has_checked_) {
    RAW_LOG(FATAL, "*NoLeaks|SameHeap must execute before this call");
  }
  return inuse_bytes_increase_;
}

ssize_t HeapLeakChecker::ObjectsLeaked() const {
  SpinLockHolder l(lock_);
  if (!has_checked_) {
    RAW_LOG(FATAL, "*NoLeaks|SameHeap must execute before this call");
  }
  return inuse_allocs_increase_;
}

// Save pid of main thread for using in naming dump files
static int32 main_thread_pid = getpid();
#ifdef HAVE_PROGRAM_INVOCATION_NAME
extern char* program_invocation_name;
extern char* program_invocation_short_name;
static const char* invocation_name() { return program_invocation_short_name; }
static string invocation_path() { return program_invocation_name; }
#else
static const char* invocation_name() { return "<your binary>"; }
static string invocation_path() { return "<your binary>"; }
#endif

// Prints commands that users can run to get more information
// about the reported leaks.
static void SuggestPprofCommand(const char* pprof_file_arg) {
  // Extra help information to print for the user when the test is
  // being run in a way where the straightforward pprof command will
  // not suffice.
  string extra_help;

  // Common header info to print for remote runs
  const string remote_header =
      "This program is being executed remotely and therefore the pprof\n"
      "command printed above will not work.  Either run this program\n"
      "locally, or adjust the pprof command as follows to allow it to\n"
      "work on your local machine:\n";

  // Extra command for fetching remote data
  string fetch_cmd;

  RAW_LOG(WARNING,
          "\n\n"
          "If the preceding stack traces are not enough to find "
          "the leaks, try running THIS shell command:\n\n"
          "%s%s %s \"%s\" --inuse_objects --lines --heapcheck "
          " --edgefraction=1e-10 --nodefraction=1e-10 --gv\n"
          "\n"
          "%s"
          "If you are still puzzled about why the leaks are "
          "there, try rerunning this program with "
          "HEAP_CHECK_TEST_POINTER_ALIGNMENT=1 and/or with "
          "HEAP_CHECK_MAX_POINTER_OFFSET=-1\n"
          "If the leak report occurs in a small fraction of runs, "
          "try running with TCMALLOC_MAX_FREE_QUEUE_SIZE of few hundred MB "
          "or with TCMALLOC_RECLAIM_MEMORY=false, "  // only works for debugalloc
          "it might help find leaks more repeatably\n",
          fetch_cmd.c_str(),
          "pprof",           // works as long as pprof is on your path
          invocation_path().c_str(),
          pprof_file_arg,
          extra_help.c_str()
          );
}

bool HeapLeakChecker::DoNoLeaks(ShouldSymbolize should_symbolize) {
  SpinLockHolder l(lock_);
  // The locking also helps us keep the messages
  // for the two checks close together.
  SpinLockHolder al(&alignment_checker_lock);

  // thread-safe: protected by alignment_checker_lock
  static bool have_disabled_hooks_for_symbolize = false;
  // Once we've checked for leaks and symbolized the results once, it's
  // not safe to do it again.  This is because in order to symbolize
  // safely, we had to disable all the malloc hooks here, so we no
  // longer can be confident we've collected all the data we need.
  if (have_disabled_hooks_for_symbolize) {
    RAW_LOG(FATAL, "Must not call heap leak checker manually after "
            " program-exit's automatic check.");
  }

  HeapProfileTable::Snapshot* leaks = NULL;
  char* pprof_file = NULL;

  {
    // Heap activity in other threads is paused during this function
    // (i.e. until we got all profile difference info).
    SpinLockHolder hl(&heap_checker_lock);
    if (heap_checker_on == false) {
      if (name_ != NULL) {  // leak checking enabled when created the checker
        RAW_LOG(WARNING, "Heap leak checker got turned off after checker "
                "\"%s\" has been created, no leak check is being done for it!",
                name_);
      }
      return true;
    }

    // Update global_region_caller_ranges. They may need to change since
    // e.g. initialization because shared libraries might have been loaded or
    // unloaded.
    Allocator::DeleteAndNullIfNot(&global_region_caller_ranges);
    ProcMapsResult pm_result = UseProcMapsLocked(DISABLE_LIBRARY_ALLOCS);
    RAW_CHECK(pm_result == PROC_MAPS_USED, "");

    // Keep track of number of internally allocated objects so we
    // can detect leaks in the heap-leak-checket itself
    const int initial_allocs = Allocator::alloc_count();

    if (name_ == NULL) {
      RAW_LOG(FATAL, "Heap leak checker must not be turned on "
              "after construction of a HeapLeakChecker");
    }

    MemoryRegionMap::LockHolder ml;
    int a_local_var;  // Use our stack ptr to make stack data live:

    // Make the heap profile, other threads are locked out.
    HeapProfileTable::Snapshot* base =
        reinterpret_cast<HeapProfileTable::Snapshot*>(start_snapshot_);
    RAW_DCHECK(FLAGS_heap_check_pointer_source_alignment > 0, "");
    pointer_source_alignment = FLAGS_heap_check_pointer_source_alignment;
    IgnoreAllLiveObjectsLocked(&a_local_var);
    leaks = heap_profile->NonLiveSnapshot(base);

    inuse_bytes_increase_ = static_cast<ssize_t>(leaks->total().alloc_size);
    inuse_allocs_increase_ = static_cast<ssize_t>(leaks->total().allocs);
    if (leaks->Empty()) {
      heap_profile->ReleaseSnapshot(leaks);
      leaks = NULL;

      // We can only check for internal leaks along the no-user-leak
      // path since in the leak path we temporarily release
      // heap_checker_lock and another thread can come in and disturb
      // allocation counts.
      if (Allocator::alloc_count() != initial_allocs) {
        RAW_LOG(FATAL, "Internal HeapChecker leak of %d objects ; %d -> %d",
                Allocator::alloc_count() - initial_allocs,
                initial_allocs, Allocator::alloc_count());
      }
    } else if (FLAGS_heap_check_test_pointer_alignment) {
      if (pointer_source_alignment == 1) {
        RAW_LOG(WARNING, "--heap_check_test_pointer_alignment has no effect: "
                "--heap_check_pointer_source_alignment was already set to 1");
      } else {
        // Try with reduced pointer aligment
        pointer_source_alignment = 1;
        IgnoreAllLiveObjectsLocked(&a_local_var);
        HeapProfileTable::Snapshot* leaks_wo_align =
            heap_profile->NonLiveSnapshot(base);
        pointer_source_alignment = FLAGS_heap_check_pointer_source_alignment;
        if (leaks_wo_align->Empty()) {
          RAW_LOG(WARNING, "Found no leaks without pointer alignment: "
                  "something might be placing pointers at "
                  "unaligned addresses! This needs to be fixed.");
        } else {
          RAW_LOG(INFO, "Found leaks without pointer alignment as well: "
                  "unaligned pointers must not be the cause of leaks.");
          RAW_LOG(INFO, "--heap_check_test_pointer_alignment did not help "
                  "to diagnose the leaks.");
        }
        heap_profile->ReleaseSnapshot(leaks_wo_align);
      }
    }

    if (leaks != NULL) {
      pprof_file = MakeProfileNameLocked();
    }
  }

  has_checked_ = true;
  if (leaks == NULL) {
    if (FLAGS_heap_check_max_pointer_offset == -1) {
      RAW_LOG(WARNING,
              "Found no leaks without max_pointer_offset restriction: "
              "it's possible that the default value of "
              "heap_check_max_pointer_offset flag is too low. "
              "Do you use pointers with larger than that offsets "
              "pointing in the middle of heap-allocated objects?");
    }
    const HeapProfileTable::Stats& stats = heap_profile->total();
    RAW_VLOG(heap_checker_info_level,
             "No leaks found for check \"%s\" "
             "(but no 100%% guarantee that there aren't any): "
             "found %"PRId64" reachable heap objects of %"PRId64" bytes",
             name_,
             int64(stats.allocs - stats.frees),
             int64(stats.alloc_size - stats.free_size));
  } else {
    if (should_symbolize == SYMBOLIZE) {
      // To turn addresses into symbols, we need to fork, which is a
      // problem if both parent and child end up trying to call the
      // same malloc-hooks we've set up, at the same time.  To avoid
      // trouble, we turn off the hooks before symbolizing.  Note that
      // this makes it unsafe to ever leak-report again!  Luckily, we
      // typically only want to report once in a program's run, at the
      // very end.
      if (MallocHook::GetNewHook() == NewHook)
        MallocHook::SetNewHook(NULL);
      if (MallocHook::GetDeleteHook() == DeleteHook)
        MallocHook::SetDeleteHook(NULL);
      MemoryRegionMap::Shutdown();
      // Make sure all the hooks really got unset:
      RAW_CHECK(MallocHook::GetNewHook() == NULL, "");
      RAW_CHECK(MallocHook::GetDeleteHook() == NULL, "");
      RAW_CHECK(MallocHook::GetMmapHook() == NULL, "");
      RAW_CHECK(MallocHook::GetSbrkHook() == NULL, "");
      have_disabled_hooks_for_symbolize = true;
      leaks->ReportLeaks(name_, pprof_file, true);  // true = should_symbolize
    } else {
      leaks->ReportLeaks(name_, pprof_file, false);
    }
    if (FLAGS_heap_check_identify_leaks) {
      leaks->ReportIndividualObjects();
    }

    SuggestPprofCommand(pprof_file);

    {
      SpinLockHolder hl(&heap_checker_lock);
      heap_profile->ReleaseSnapshot(leaks);
      Allocator::Free(pprof_file);
    }
  }

  return (leaks == NULL);
}

HeapLeakChecker::~HeapLeakChecker() {
  if (name_ != NULL) {  // had leak checking enabled when created the checker
    if (!has_checked_) {
      RAW_LOG(FATAL, "Some *NoLeaks|SameHeap method"
                     " must be called on any created HeapLeakChecker");
    }

    // Deallocate any snapshot taken at start
    if (start_snapshot_ != NULL) {
      SpinLockHolder l(&heap_checker_lock);
      heap_profile->ReleaseSnapshot(
          reinterpret_cast<HeapProfileTable::Snapshot*>(start_snapshot_));
    }

    UnIgnoreObject(name_);
    delete[] name_;
    name_ = NULL;
  }
  delete lock_;
}

//----------------------------------------------------------------------
// HeapLeakChecker overall heap check components
//----------------------------------------------------------------------

// static
bool HeapLeakChecker::IsActive() {
  SpinLockHolder l(&heap_checker_lock);
  return heap_checker_on;
}

vector<HeapCleaner::void_function>* HeapCleaner::heap_cleanups_ = NULL;

// When a HeapCleaner object is intialized, add its function to the static list
// of cleaners to be run before leaks checking.
HeapCleaner::HeapCleaner(void_function f) {
  if (heap_cleanups_ == NULL)
    heap_cleanups_ = new vector<HeapCleaner::void_function>;
  heap_cleanups_->push_back(f);
}

// Run all of the cleanup functions and delete the vector.
void HeapCleaner::RunHeapCleanups() {
  if (!heap_cleanups_)
    return;
  for (int i = 0; i < heap_cleanups_->size(); i++) {
    void (*f)(void) = (*heap_cleanups_)[i];
    f();
  }
  delete heap_cleanups_;
  heap_cleanups_ = NULL;
}

// Program exit heap cleanup registered as a module object destructor.
// Will not get executed when we crash on a signal.
//
void HeapLeakChecker_RunHeapCleanups() {
  if (FLAGS_heap_check == "local")   // don't check heap in this mode
    return;
  { SpinLockHolder l(&heap_checker_lock);
    // can get here (via forks?) with other pids
    if (heap_checker_pid != getpid()) return;
  }
  HeapCleaner::RunHeapCleanups();
  if (!FLAGS_heap_check_after_destructors) HeapLeakChecker::DoMainHeapCheck();
}

static bool internal_init_start_has_run = false;

// Called exactly once, before main() (but hopefully just before).
// This picks a good unique name for the dumped leak checking heap profiles.
//
// Because we crash when InternalInitStart is called more than once,
// it's fine that we hold heap_checker_lock only around pieces of
// this function: this is still enough for thread-safety w.r.t. other functions
// of this module.
// We can't hold heap_checker_lock throughout because it would deadlock
// on a memory allocation since our new/delete hooks can be on.
//
void HeapLeakChecker_InternalInitStart() {
  { SpinLockHolder l(&heap_checker_lock);
    RAW_CHECK(!internal_init_start_has_run,
              "Heap-check constructor called twice.  Perhaps you both linked"
              " in the heap checker, and also used LD_PRELOAD to load it?");
    internal_init_start_has_run = true;

#ifdef ADDRESS_SANITIZER
    // AddressSanitizer's custom malloc conflicts with HeapChecker.
    FLAGS_heap_check = "";
#endif

    if (FLAGS_heap_check.empty()) {
      // turns out we do not need checking in the end; can stop profiling
      HeapLeakChecker::TurnItselfOffLocked();
      return;
    } else if (RunningOnValgrind()) {
      // There is no point in trying -- we'll just fail.
      RAW_LOG(WARNING, "Can't run under Valgrind; will turn itself off");
      HeapLeakChecker::TurnItselfOffLocked();
      return;
    }
  }

  // Changing this to false can be useful when debugging heap-checker itself:
  if (!FLAGS_heap_check_run_under_gdb && IsDebuggerAttached()) {
    RAW_LOG(WARNING, "Someone is ptrace()ing us; will turn itself off");
    SpinLockHolder l(&heap_checker_lock);
    HeapLeakChecker::TurnItselfOffLocked();
    return;
  }

  { SpinLockHolder l(&heap_checker_lock);
    if (!constructor_heap_profiling) {
      RAW_LOG(FATAL, "Can not start so late. You have to enable heap checking "
	             "with HEAPCHECK=<mode>.");
    }
  }

  // Set all flags
  RAW_DCHECK(FLAGS_heap_check_pointer_source_alignment > 0, "");
  if (FLAGS_heap_check == "minimal") {
    // The least we can check.
    FLAGS_heap_check_before_constructors = false;  // from after main
                                                   // (ignore more)
    FLAGS_heap_check_after_destructors = false;  // to after cleanup
                                                 // (most data is live)
    FLAGS_heap_check_ignore_thread_live = true;  // ignore all live
    FLAGS_heap_check_ignore_global_live = true;  // ignore all live
  } else if (FLAGS_heap_check == "normal") {
    // Faster than 'minimal' and not much stricter.
    FLAGS_heap_check_before_constructors = true;  // from no profile (fast)
    FLAGS_heap_check_after_destructors = false;  // to after cleanup
                                                 // (most data is live)
    FLAGS_heap_check_ignore_thread_live = true;  // ignore all live
    FLAGS_heap_check_ignore_global_live = true;  // ignore all live
  } else if (FLAGS_heap_check == "strict") {
    // A bit stricter than 'normal': global destructors must fully clean up
    // after themselves if they are present.
    FLAGS_heap_check_before_constructors = true;  // from no profile (fast)
    FLAGS_heap_check_after_destructors = true;  // to after destructors
                                                // (less data live)
    FLAGS_heap_check_ignore_thread_live = true;  // ignore all live
    FLAGS_heap_check_ignore_global_live = true;  // ignore all live
  } else if (FLAGS_heap_check == "draconian") {
    // Drop not very portable and not very exact live heap flooding.
    FLAGS_heap_check_before_constructors = true;  // from no profile (fast)
    FLAGS_heap_check_after_destructors = true;  // to after destructors
                                                // (need them)
    FLAGS_heap_check_ignore_thread_live = false;  // no live flood (stricter)
    FLAGS_heap_check_ignore_global_live = false;  // no live flood (stricter)
  } else if (FLAGS_heap_check == "as-is") {
    // do nothing: use other flags as is
  } else if (FLAGS_heap_check == "local") {
    // do nothing
  } else {
    RAW_LOG(FATAL, "Unsupported heap_check flag: %s",
                   FLAGS_heap_check.c_str());
  }
  // FreeBSD doesn't seem to honor atexit execution order:
  //    http://code.google.com/p/gperftools/issues/detail?id=375
  // Since heap-checking before destructors depends on atexit running
  // at the right time, on FreeBSD we always check after, even in the
  // less strict modes.  This just means FreeBSD is always a bit
  // stricter in its checking than other OSes.
#ifdef __FreeBSD__
  FLAGS_heap_check_after_destructors = true;
#endif

  { SpinLockHolder l(&heap_checker_lock);
    RAW_DCHECK(heap_checker_pid == getpid(), "");
    heap_checker_on = true;
    RAW_DCHECK(heap_profile, "");
    HeapLeakChecker::ProcMapsResult pm_result = HeapLeakChecker::UseProcMapsLocked(HeapLeakChecker::DISABLE_LIBRARY_ALLOCS);
      // might neeed to do this more than once
      // if one later dynamically loads libraries that we want disabled
    if (pm_result != HeapLeakChecker::PROC_MAPS_USED) {  // can't function
      HeapLeakChecker::TurnItselfOffLocked();
      return;
    }
  }

  // make a good place and name for heap profile leak dumps
  string* profile_prefix =
    new string(FLAGS_heap_check_dump_directory + "/" + invocation_name());

  // Finalize prefix for dumping leak checking profiles.
  const int32 our_pid = getpid();   // safest to call getpid() outside lock
  { SpinLockHolder l(&heap_checker_lock);
    // main_thread_pid might still be 0 if this function is being called before
    // global constructors.  In that case, our pid *is* the main pid.
    if (main_thread_pid == 0)
      main_thread_pid = our_pid;
  }
  char pid_buf[15];
  snprintf(pid_buf, sizeof(pid_buf), ".%d", main_thread_pid);
  *profile_prefix += pid_buf;
  { SpinLockHolder l(&heap_checker_lock);
    RAW_DCHECK(profile_name_prefix == NULL, "");
    profile_name_prefix = profile_prefix;
  }

  // Make sure new/delete hooks are installed properly
  // and heap profiler is indeed able to keep track
  // of the objects being allocated.
  // We test this to make sure we are indeed checking for leaks.
  char* test_str = new char[5];
  size_t size;
  { SpinLockHolder l(&heap_checker_lock);
    RAW_CHECK(heap_profile->FindAlloc(test_str, &size),
              "our own new/delete not linked?");
  }
  delete[] test_str;
  { SpinLockHolder l(&heap_checker_lock);
    // This check can fail when it should not if another thread allocates
    // into this same spot right this moment,
    // which is unlikely since this code runs in InitGoogle.
    RAW_CHECK(!heap_profile->FindAlloc(test_str, &size),
              "our own new/delete not linked?");
  }
  // If we crash in the above code, it probably means that
  // "nm <this_binary> | grep new" will show that tcmalloc's new/delete
  // implementation did not get linked-in into this binary
  // (i.e. nm will list __builtin_new and __builtin_vec_new as undefined).
  // If this happens, it is a BUILD bug to be fixed.

  RAW_VLOG(heap_checker_info_level,
           "WARNING: Perftools heap leak checker is active "
           "-- Performance may suffer");

  if (FLAGS_heap_check != "local") {
    HeapLeakChecker* main_hc = new HeapLeakChecker();
    SpinLockHolder l(&heap_checker_lock);
    RAW_DCHECK(main_heap_checker == NULL,
               "Repeated creation of main_heap_checker");
    main_heap_checker = main_hc;
    do_main_heap_check = true;
  }

  { SpinLockHolder l(&heap_checker_lock);
    RAW_CHECK(heap_checker_on  &&  constructor_heap_profiling,
              "Leak checking is expected to be fully turned on now");
  }

  // For binaries built in debug mode, this will set release queue of
  // debugallocation.cc to 100M to make it less likely for real leaks to
  // be hidden due to reuse of heap memory object addresses.
  // Running a test with --malloc_reclaim_memory=0 would help find leaks even
  // better, but the test might run out of memory as a result.
  // The scenario is that a heap object at address X is allocated and freed,
  // but some other data-structure still retains a pointer to X.
  // Then the same heap memory is used for another object, which is leaked,
  // but the leak is not noticed due to the pointer to the original object at X.
  // TODO(csilvers): support this in some manner.
#if 0
  SetCommandLineOptionWithMode("max_free_queue_size", "104857600",  // 100M
                               SET_FLAG_IF_DEFAULT);
#endif
}

// We want this to run early as well, but not so early as
// ::BeforeConstructors (we want flag assignments to have already
// happened, for instance).  Initializer-registration does the trick.
REGISTER_MODULE_INITIALIZER(init_start, HeapLeakChecker_InternalInitStart());
REGISTER_MODULE_DESTRUCTOR(init_start, HeapLeakChecker_RunHeapCleanups());

// static
bool HeapLeakChecker::NoGlobalLeaksMaybeSymbolize(
    ShouldSymbolize should_symbolize) {
  // we never delete or change main_heap_checker once it's set:
  HeapLeakChecker* main_hc = GlobalChecker();
  if (main_hc) {
    RAW_VLOG(10, "Checking for whole-program memory leaks");
    return main_hc->DoNoLeaks(should_symbolize);
  }
  return true;
}

// static
bool HeapLeakChecker::DoMainHeapCheck() {
  if (FLAGS_heap_check_delay_seconds > 0) {
    sleep(FLAGS_heap_check_delay_seconds);
  }
  { SpinLockHolder l(&heap_checker_lock);
    if (!do_main_heap_check) return false;
    RAW_DCHECK(heap_checker_pid == getpid(), "");
    do_main_heap_check = false;  // will do it now; no need to do it more
  }

  // The program is over, so it's safe to symbolize addresses (which
  // requires a fork) because no serious work is expected to be done
  // after this.  Symbolizing is really useful -- knowing what
  // function has a leak is better than knowing just an address --
  // and while we can only safely symbolize once in a program run,
  // now is the time (after all, there's no "later" that would be better).
  if (!NoGlobalLeaksMaybeSymbolize(SYMBOLIZE)) {
    if (FLAGS_heap_check_identify_leaks) {
      RAW_LOG(FATAL, "Whole-program memory leaks found.");
    }
    RAW_LOG(ERROR, "Exiting with error code (instead of crashing) "
                   "because of whole-program memory leaks");
    // We don't want to call atexit() routines!
    _exit(FLAGS_heap_check_error_exit_code);
  }
  return true;
}

// static
HeapLeakChecker* HeapLeakChecker::GlobalChecker() {
  SpinLockHolder l(&heap_checker_lock);
  return main_heap_checker;
}

// static
bool HeapLeakChecker::NoGlobalLeaks() {
  // symbolizing requires a fork, which isn't safe to do in general.
  return NoGlobalLeaksMaybeSymbolize(DO_NOT_SYMBOLIZE);
}

// static
void HeapLeakChecker::CancelGlobalCheck() {
  SpinLockHolder l(&heap_checker_lock);
  if (do_main_heap_check) {
    RAW_VLOG(heap_checker_info_level,
             "Canceling the automatic at-exit whole-program memory leak check");
    do_main_heap_check = false;
  }
}

// static
void HeapLeakChecker::BeforeConstructorsLocked() {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  RAW_CHECK(!constructor_heap_profiling,
            "BeforeConstructorsLocked called multiple times");
#ifdef ADDRESS_SANITIZER
  // AddressSanitizer's custom malloc conflicts with HeapChecker.
  return;
#endif
  // Set hooks early to crash if 'new' gets called before we make heap_profile,
  // and make sure no other hooks existed:
  RAW_CHECK(MallocHook::AddNewHook(&NewHook), "");
  RAW_CHECK(MallocHook::AddDeleteHook(&DeleteHook), "");
  constructor_heap_profiling = true;
  MemoryRegionMap::Init(1);
    // Set up MemoryRegionMap with (at least) one caller stack frame to record
    // (important that it's done before HeapProfileTable creation below).
  Allocator::Init();
  RAW_CHECK(heap_profile == NULL, "");
  heap_profile = new(Allocator::Allocate(sizeof(HeapProfileTable)))
                   HeapProfileTable(&Allocator::Allocate, &Allocator::Free);
  RAW_VLOG(10, "Starting tracking the heap");
  heap_checker_on = true;
}

// static
void HeapLeakChecker::TurnItselfOffLocked() {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  // Set FLAGS_heap_check to "", for users who test for it
  if (!FLAGS_heap_check.empty())  // be a noop in the common case
    FLAGS_heap_check.clear();     // because clear() could allocate memory
  if (constructor_heap_profiling) {
    RAW_CHECK(heap_checker_on, "");
    RAW_VLOG(heap_checker_info_level, "Turning perftools heap leak checking off");
    heap_checker_on = false;
    // Unset our hooks checking they were set:
    RAW_CHECK(MallocHook::RemoveNewHook(&NewHook), "");
    RAW_CHECK(MallocHook::RemoveDeleteHook(&DeleteHook), "");
    Allocator::DeleteAndNull(&heap_profile);
    // free our optional global data:
    Allocator::DeleteAndNullIfNot(&ignored_objects);
    Allocator::DeleteAndNullIfNot(&disabled_ranges);
    Allocator::DeleteAndNullIfNot(&global_region_caller_ranges);
    Allocator::Shutdown();
    MemoryRegionMap::Shutdown();
  }
  RAW_CHECK(!heap_checker_on, "");
}

extern bool heap_leak_checker_bcad_variable;  // in heap-checker-bcad.cc

static bool has_called_before_constructors = false;

// TODO(maxim): inline this function with
// MallocHook_InitAtFirstAllocation_HeapLeakChecker, and also rename
// HeapLeakChecker::BeforeConstructorsLocked.
void HeapLeakChecker_BeforeConstructors() {
  SpinLockHolder l(&heap_checker_lock);
  // We can be called from several places: the first mmap/sbrk/alloc call
  // or the first global c-tor from heap-checker-bcad.cc:
  // Do not re-execute initialization:
  if (has_called_before_constructors) return;
  has_called_before_constructors = true;

  heap_checker_pid = getpid();  // set it always
  heap_leak_checker_bcad_variable = true;
  // just to reference it, so that heap-checker-bcad.o is linked in

  // This function can be called *very* early, before the normal
  // global-constructor that sets FLAGS_verbose.  Set it manually now,
  // so the RAW_LOG messages here are controllable.
  const char* verbose_str = GetenvBeforeMain("PERFTOOLS_VERBOSE");
  if (verbose_str && atoi(verbose_str)) {  // different than the default of 0?
    FLAGS_verbose = atoi(verbose_str);
  }

  bool need_heap_check = true;
  // The user indicates a desire for heap-checking via the HEAPCHECK
  // environment variable.  If it's not set, there's no way to do
  // heap-checking.
  if (!GetenvBeforeMain("HEAPCHECK")) {
    need_heap_check = false;
  }
#ifdef HAVE_GETEUID
  if (need_heap_check && getuid() != geteuid()) {
    // heap-checker writes out files.  Thus, for security reasons, we don't
    // recognize the env. var. to turn on heap-checking if we're setuid.
    RAW_LOG(WARNING, ("HeapChecker: ignoring HEAPCHECK because "
                      "program seems to be setuid\n"));
    need_heap_check = false;
  }
#endif
  if (need_heap_check) {
    HeapLeakChecker::BeforeConstructorsLocked();
  }
}

// This function overrides the weak function defined in malloc_hook.cc and
// called by one of the initial malloc hooks (malloc_hook.cc) when the very
// first memory allocation or an mmap/sbrk happens.  This ensures that
// HeapLeakChecker is initialized and installs all its hooks early enough to
// track absolutely all memory allocations and all memory region acquisitions
// via mmap and sbrk.
extern "C" void MallocHook_InitAtFirstAllocation_HeapLeakChecker() {
  HeapLeakChecker_BeforeConstructors();
}

// This function is executed after all global object destructors run.
void HeapLeakChecker_AfterDestructors() {
  { SpinLockHolder l(&heap_checker_lock);
    // can get here (via forks?) with other pids
    if (heap_checker_pid != getpid()) return;
  }
  if (FLAGS_heap_check_after_destructors) {
    if (HeapLeakChecker::DoMainHeapCheck()) {
      const struct timespec sleep_time = { 0, 500000000 };  // 500 ms
      nanosleep(&sleep_time, NULL);
        // Need this hack to wait for other pthreads to exit.
        // Otherwise tcmalloc find errors
        // on a free() call from pthreads.
    }
  }
  SpinLockHolder l(&heap_checker_lock);
  RAW_CHECK(!do_main_heap_check, "should have done it");
}

//----------------------------------------------------------------------
// HeapLeakChecker disabling helpers
//----------------------------------------------------------------------

// These functions are at the end of the file to prevent their inlining:

// static
void HeapLeakChecker::DisableChecksFromToLocked(const void* start_address,
                                                const void* end_address,
                                                int max_depth) {
  RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  RAW_DCHECK(start_address < end_address, "");
  if (disabled_ranges == NULL) {
    disabled_ranges = new(Allocator::Allocate(sizeof(DisabledRangeMap)))
                        DisabledRangeMap;
  }
  RangeValue value;
  value.start_address = AsInt(start_address);
  value.max_depth = max_depth;
  if (disabled_ranges->insert(make_pair(AsInt(end_address), value)).second) {
    RAW_VLOG(10, "Disabling leak checking in stack traces "
                "under frame addresses between %p..%p",
                start_address, end_address);
  } else {  // check that this is just a verbatim repetition
    RangeValue const& val = disabled_ranges->find(AsInt(end_address))->second;
    if (val.max_depth != value.max_depth  ||
        val.start_address != value.start_address) {
      RAW_LOG(FATAL, "Two DisableChecksToHereFrom calls conflict: "
                     "(%p, %p, %d) vs. (%p, %p, %d)",
                     AsPtr(val.start_address), end_address, val.max_depth,
                     start_address, end_address, max_depth);
    }
  }
}

// static
inline bool HeapLeakChecker::HaveOnHeapLocked(const void** ptr,
                                              size_t* object_size) {
  // Commented-out because HaveOnHeapLocked is very performance-critical:
  // RAW_DCHECK(heap_checker_lock.IsHeld(), "");
  const uintptr_t addr = AsInt(*ptr);
  if (heap_profile->FindInsideAlloc(
        *ptr, max_heap_object_size, ptr, object_size)) {
    RAW_VLOG(16, "Got pointer into %p at +%"PRIuPTR" offset",
             *ptr, addr - AsInt(*ptr));
    return true;
  }
  return false;
}

// static
const void* HeapLeakChecker::GetAllocCaller(void* ptr) {
  // this is used only in the unittest, so the heavy checks are fine
  HeapProfileTable::AllocInfo info;
  { SpinLockHolder l(&heap_checker_lock);
    RAW_CHECK(heap_profile->FindAllocDetails(ptr, &info), "");
  }
  RAW_CHECK(info.stack_depth >= 1, "");
  return info.call_stack[0];
}
