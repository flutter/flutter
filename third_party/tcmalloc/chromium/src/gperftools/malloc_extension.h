// Copyright (c) 2012, Google Inc.
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
// Extra extensions exported by some malloc implementations.  These
// extensions are accessed through a virtual base class so an
// application can link against a malloc that does not implement these
// extensions, and it will get default versions that do nothing.
//
// NOTE FOR C USERS: If you wish to use this functionality from within
// a C program, see malloc_extension_c.h.

#ifndef BASE_MALLOC_EXTENSION_H_
#define BASE_MALLOC_EXTENSION_H_

#include <stddef.h>
// I can't #include config.h in this public API file, but I should
// really use configure (and make malloc_extension.h a .in file) to
// figure out if the system has stdint.h or not.  But I'm lazy, so
// for now I'm assuming it's a problem only with MSVC.
#ifndef _MSC_VER
#include <stdint.h>
#endif
#include <string>
#include <vector>

// Annoying stuff for windows -- makes sure clients can import these functions
#ifndef PERFTOOLS_DLL_DECL
# ifdef _WIN32
#   define PERFTOOLS_DLL_DECL  __declspec(dllimport)
# else
#   define PERFTOOLS_DLL_DECL
# endif
#endif

static const int kMallocHistogramSize = 64;

// One day, we could support other types of writers (perhaps for C?)
typedef std::string MallocExtensionWriter;

namespace base {
struct MallocRange;
}

// Interface to a pluggable system allocator.
class SysAllocator {
 public:
  SysAllocator() {
  }
  virtual ~SysAllocator();

  // Allocates "size"-byte of memory from system aligned with "alignment".
  // Returns NULL if failed. Otherwise, the returned pointer p up to and
  // including (p + actual_size -1) have been allocated.
  virtual void* Alloc(size_t size, size_t *actual_size, size_t alignment) = 0;
};

// The default implementations of the following routines do nothing.
// All implementations should be thread-safe; the current one
// (TCMallocImplementation) is.
class PERFTOOLS_DLL_DECL MallocExtension {
 public:
  virtual ~MallocExtension();

  // Call this very early in the program execution -- say, in a global
  // constructor -- to set up parameters and state needed by all
  // instrumented malloc implemenatations.  One example: this routine
  // sets environemnt variables to tell STL to use libc's malloc()
  // instead of doing its own memory management.  This is safe to call
  // multiple times, as long as each time is before threads start up.
  static void Initialize();

  // See "verify_memory.h" to see what these routines do
  virtual bool VerifyAllMemory();
  virtual bool VerifyNewMemory(const void* p);
  virtual bool VerifyArrayNewMemory(const void* p);
  virtual bool VerifyMallocMemory(const void* p);
  virtual bool MallocMemoryStats(int* blocks, size_t* total,
                                 int histogram[kMallocHistogramSize]);

  // Get a human readable description of the current state of the malloc
  // data structures.  The state is stored as a null-terminated string
  // in a prefix of "buffer[0,buffer_length-1]".
  // REQUIRES: buffer_length > 0.
  virtual void GetStats(char* buffer, int buffer_length);

  // Outputs to "writer" a sample of live objects and the stack traces
  // that allocated these objects.  The format of the returned output
  // is equivalent to the output of the heap profiler and can
  // therefore be passed to "pprof". This function is equivalent to
  // ReadStackTraces. The main difference is that this function returns
  // serialized data appropriately formatted for use by the pprof tool.
  // NOTE: by default, tcmalloc does not do any heap sampling, and this
  //       function will always return an empty sample.  To get useful
  //       data from GetHeapSample, you must also set the environment
  //       variable TCMALLOC_SAMPLE_PARAMETER to a value such as 524288.
  virtual void GetHeapSample(MallocExtensionWriter* writer);

  // Outputs to "writer" the stack traces that caused growth in the
  // address space size.  The format of the returned output is
  // equivalent to the output of the heap profiler and can therefore
  // be passed to "pprof". This function is equivalent to
  // ReadHeapGrowthStackTraces. The main difference is that this function
  // returns serialized data appropriately formatted for use by the
  // pprof tool.  (This does not depend on, or require,
  // TCMALLOC_SAMPLE_PARAMETER.)
  virtual void GetHeapGrowthStacks(MallocExtensionWriter* writer);

  // Invokes func(arg, range) for every controlled memory
  // range.  *range is filled in with information about the range.
  //
  // This is a best-effort interface useful only for performance
  // analysis.  The implementation may not call func at all.
  typedef void (RangeFunction)(void*, const base::MallocRange*);
  virtual void Ranges(void* arg, RangeFunction func);

  // -------------------------------------------------------------------
  // Control operations for getting and setting malloc implementation
  // specific parameters.  Some currently useful properties:
  //
  // generic
  // -------
  // "generic.current_allocated_bytes"
  //      Number of bytes currently allocated by application
  //      This property is not writable.
  //
  // "generic.heap_size"
  //      Number of bytes in the heap ==
  //            current_allocated_bytes +
  //            fragmentation +
  //            freed memory regions
  //      This property is not writable.
  //
  // tcmalloc
  // --------
  // "tcmalloc.max_total_thread_cache_bytes"
  //      Upper limit on total number of bytes stored across all
  //      per-thread caches.  Default: 16MB.
  //
  // "tcmalloc.current_total_thread_cache_bytes"
  //      Number of bytes used across all thread caches.
  //      This property is not writable.
  //
  // "tcmalloc.pageheap_free_bytes"
  //      Number of bytes in free, mapped pages in page heap.  These
  //      bytes can be used to fulfill allocation requests.  They
  //      always count towards virtual memory usage, and unless the
  //      underlying memory is swapped out by the OS, they also count
  //      towards physical memory usage.  This property is not writable.
  //
  // "tcmalloc.pageheap_unmapped_bytes"
  //        Number of bytes in free, unmapped pages in page heap.
  //        These are bytes that have been released back to the OS,
  //        possibly by one of the MallocExtension "Release" calls.
  //        They can be used to fulfill allocation requests, but
  //        typically incur a page fault.  They always count towards
  //        virtual memory usage, and depending on the OS, typically
  //        do not count towards physical memory usage.  This property
  //        is not writable.
  // -------------------------------------------------------------------

  // Get the named "property"'s value.  Returns true if the property
  // is known.  Returns false if the property is not a valid property
  // name for the current malloc implementation.
  // REQUIRES: property != NULL; value != NULL
  virtual bool GetNumericProperty(const char* property, size_t* value);

  // Set the named "property"'s value.  Returns true if the property
  // is known and writable.  Returns false if the property is not a
  // valid property name for the current malloc implementation, or
  // is not writable.
  // REQUIRES: property != NULL
  virtual bool SetNumericProperty(const char* property, size_t value);

  // Mark the current thread as "idle".  This routine may optionally
  // be called by threads as a hint to the malloc implementation that
  // any thread-specific resources should be released.  Note: this may
  // be an expensive routine, so it should not be called too often.
  //
  // Also, if the code that calls this routine will go to sleep for
  // a while, it should take care to not allocate anything between
  // the call to this routine and the beginning of the sleep.
  //
  // Most malloc implementations ignore this routine.
  virtual void MarkThreadIdle();

  // Mark the current thread as "busy".  This routine should be
  // called after MarkThreadIdle() if the thread will now do more
  // work.  If this method is not called, performance may suffer.
  //
  // Most malloc implementations ignore this routine.
  virtual void MarkThreadBusy();

  // Gets the system allocator used by the malloc extension instance. Returns
  // NULL for malloc implementations that do not support pluggable system
  // allocators.
  virtual SysAllocator* GetSystemAllocator();

  // Sets the system allocator to the specified.
  //
  // Users could register their own system allocators for malloc implementation
  // that supports pluggable system allocators, such as TCMalloc, by doing:
  //   alloc = new MyOwnSysAllocator();
  //   MallocExtension::instance()->SetSystemAllocator(alloc);
  // It's up to users whether to fall back (recommended) to the default
  // system allocator (use GetSystemAllocator() above) or not. The caller is
  // responsible to any necessary locking.
  // See tcmalloc/system-alloc.h for the interface and
  //     tcmalloc/memfs_malloc.cc for the examples.
  //
  // It's a no-op for malloc implementations that do not support pluggable
  // system allocators.
  virtual void SetSystemAllocator(SysAllocator *a);

  // Try to release num_bytes of free memory back to the operating
  // system for reuse.  Use this extension with caution -- to get this
  // memory back may require faulting pages back in by the OS, and
  // that may be slow.  (Currently only implemented in tcmalloc.)
  virtual void ReleaseToSystem(size_t num_bytes);

  // Same as ReleaseToSystem() but release as much memory as possible.
  virtual void ReleaseFreeMemory();

  // Sets the rate at which we release unused memory to the system.
  // Zero means we never release memory back to the system.  Increase
  // this flag to return memory faster; decrease it to return memory
  // slower.  Reasonable rates are in the range [0,10].  (Currently
  // only implemented in tcmalloc).
  virtual void SetMemoryReleaseRate(double rate);

  // Gets the release rate.  Returns a value < 0 if unknown.
  virtual double GetMemoryReleaseRate();

  // Returns the estimated number of bytes that will be allocated for
  // a request of "size" bytes.  This is an estimate: an allocation of
  // SIZE bytes may reserve more bytes, but will never reserve less.
  // (Currently only implemented in tcmalloc, other implementations
  // always return SIZE.)
  // This is equivalent to malloc_good_size() in OS X.
  virtual size_t GetEstimatedAllocatedSize(size_t size);

  // Returns the actual number N of bytes reserved by tcmalloc for the
  // pointer p.  The client is allowed to use the range of bytes
  // [p, p+N) in any way it wishes (i.e. N is the "usable size" of this
  // allocation).  This number may be equal to or greater than the number
  // of bytes requested when p was allocated.
  // p must have been allocated by this malloc implementation,
  // must not be an interior pointer -- that is, must be exactly
  // the pointer returned to by malloc() et al., not some offset
  // from that -- and should not have been freed yet.  p may be NULL.
  // (Currently only implemented in tcmalloc; other implementations
  // will return 0.)
  // This is equivalent to malloc_size() in OS X, malloc_usable_size()
  // in glibc, and _msize() for windows.
  virtual size_t GetAllocatedSize(const void* p);

  // Returns kOwned if this malloc implementation allocated the memory
  // pointed to by p, or kNotOwned if some other malloc implementation
  // allocated it or p is NULL.  May also return kUnknownOwnership if
  // the malloc implementation does not keep track of ownership.
  // REQUIRES: p must be a value returned from a previous call to
  // malloc(), calloc(), realloc(), memalign(), posix_memalign(),
  // valloc(), pvalloc(), new, or new[], and must refer to memory that
  // is currently allocated (so, for instance, you should not pass in
  // a pointer after having called free() on it).
  enum Ownership {
    // NOTE: Enum values MUST be kept in sync with the version in
    // malloc_extension_c.h
    kUnknownOwnership = 0,
    kOwned,
    kNotOwned
  };
  virtual Ownership GetOwnership(const void* p);

  // The current malloc implementation.  Always non-NULL.
  static MallocExtension* instance();

  // Change the malloc implementation.  Typically called by the
  // malloc implementation during initialization.
  static void Register(MallocExtension* implementation);

  // On the current thread, return the total number of bytes allocated.
  // This function is added in Chromium for profiling.
  // Currently only implemented in tcmalloc. Returns 0 if tcmalloc is not used.
  // Note that malloc_extension can be used without tcmalloc if gperftools'
  // heap-profiler is enabled without the tcmalloc memory allocator.
  static unsigned int GetBytesAllocatedOnCurrentThread();

  // Returns detailed information about malloc's freelists. For each list,
  // return a FreeListInfo:
  struct FreeListInfo {
    size_t min_object_size;
    size_t max_object_size;
    size_t total_bytes_free;
    const char* type;
  };
  // Each item in the vector refers to a different freelist. The lists
  // are identified by the range of allocations that objects in the
  // list can satisfy ([min_object_size, max_object_size]) and the
  // type of freelist (see below). The current size of the list is
  // returned in total_bytes_free (which count against a processes
  // resident and virtual size).
  //
  // Currently supported types are:
  //
  // "tcmalloc.page{_unmapped}" - tcmalloc's page heap. An entry for each size
  //          class in the page heap is returned. Bytes in "page_unmapped"
  //          are no longer backed by physical memory and do not count against
  //          the resident size of a process.
  //
  // "tcmalloc.large{_unmapped}" - tcmalloc's list of objects larger
  //          than the largest page heap size class. Only one "large"
  //          entry is returned. There is no upper-bound on the size
  //          of objects in the large free list; this call returns
  //          kint64max for max_object_size.  Bytes in
  //          "large_unmapped" are no longer backed by physical memory
  //          and do not count against the resident size of a process.
  //
  // "tcmalloc.central" - tcmalloc's central free-list. One entry per
  //          size-class is returned. Never unmapped.
  //
  // "debug.free_queue" - free objects queued by the debug allocator
  //                      and not returned to tcmalloc.
  //
  // "tcmalloc.thread" - tcmalloc's per-thread caches. Never unmapped.
  virtual void GetFreeListSizes(std::vector<FreeListInfo>* v);

  // Get a list of stack traces of sampled allocation points.  Returns
  // a pointer to a "new[]-ed" result array, and stores the sample
  // period in "sample_period".
  //
  // The state is stored as a sequence of adjacent entries
  // in the returned array.  Each entry has the following form:
  //    uintptr_t count;        // Number of objects with following trace
  //    uintptr_t size;         // Total size of objects with following trace
  //    uintptr_t depth;        // Number of PC values in stack trace
  //    void*     stack[depth]; // PC values that form the stack trace
  //
  // The list of entries is terminated by a "count" of 0.
  //
  // It is the responsibility of the caller to "delete[]" the returned array.
  //
  // May return NULL to indicate no results.
  //
  // This is an internal extension.  Callers should use the more
  // convenient "GetHeapSample(string*)" method defined above.
  virtual void** ReadStackTraces(int* sample_period);

  // Like ReadStackTraces(), but returns stack traces that caused growth
  // in the address space size.
  virtual void** ReadHeapGrowthStackTraces();
};

namespace base {

// Information passed per range.  More fields may be added later.
struct MallocRange {
  enum Type {
    INUSE,                // Application is using this range
    FREE,                 // Range is currently free
    UNMAPPED,             // Backing physical memory has been returned to the OS
    UNKNOWN,
    // More enum values may be added in the future
  };

  uintptr_t address;    // Address of range
  size_t length;        // Byte length of range
  Type type;            // Type of this range
  double fraction;      // Fraction of range that is being used (0 if !INUSE)

  // Perhaps add the following:
  // - stack trace if this range was sampled
  // - heap growth stack trace if applicable to this range
  // - age when allocated (for inuse) or freed (if not in use)
};

} // namespace base

#endif  // BASE_MALLOC_EXTENSION_H_
