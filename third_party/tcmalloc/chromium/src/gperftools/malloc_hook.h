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
// Some of our malloc implementations can invoke the following hooks whenever
// memory is allocated or deallocated.  MallocHook is thread-safe, and things
// you do before calling AddFooHook(MyHook) are visible to any resulting calls
// to MyHook.  Hooks must be thread-safe.  If you write:
//
//   CHECK(MallocHook::AddNewHook(&MyNewHook));
//
// MyNewHook will be invoked in subsequent calls in the current thread, but
// there are no guarantees on when it might be invoked in other threads.
//
// There are a limited number of slots available for each hook type.  Add*Hook
// will return false if there are no slots available.  Remove*Hook will return
// false if the given hook was not already installed.
//
// The order in which individual hooks are called in Invoke*Hook is undefined.
//
// It is safe for a hook to remove itself within Invoke*Hook and add other
// hooks.  Any hooks added inside a hook invocation (for the same hook type)
// will not be invoked for the current invocation.
//
// One important user of these hooks is the heap profiler.
//
// CAVEAT: If you add new MallocHook::Invoke* calls then those calls must be
// directly in the code of the (de)allocation function that is provided to the
// user and that function must have an ATTRIBUTE_SECTION(malloc_hook) attribute.
//
// Note: the Invoke*Hook() functions are defined in malloc_hook-inl.h.  If you
// need to invoke a hook (which you shouldn't unless you're part of tcmalloc),
// be sure to #include malloc_hook-inl.h in addition to malloc_hook.h.
//
// NOTE FOR C USERS: If you want to use malloc_hook functionality from
// a C program, #include malloc_hook_c.h instead of this file.

#ifndef _MALLOC_HOOK_H_
#define _MALLOC_HOOK_H_

#include <stddef.h>
#include <sys/types.h>
extern "C" {
#include <gperftools/malloc_hook_c.h>  // a C version of the malloc_hook interface
}

// Annoying stuff for windows -- makes sure clients can import these functions
#ifndef PERFTOOLS_DLL_DECL
# ifdef _WIN32
#   define PERFTOOLS_DLL_DECL  __declspec(dllimport)
# else
#   define PERFTOOLS_DLL_DECL
# endif
#endif

// The C++ methods below call the C version (MallocHook_*), and thus
// convert between an int and a bool.  Windows complains about this
// (a "performance warning") which we don't care about, so we suppress.
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable:4800)
#endif

// Note: malloc_hook_c.h defines MallocHook_*Hook and
// MallocHook_{Add,Remove}*Hook.  The version of these inside the MallocHook
// class are defined in terms of the malloc_hook_c version.  See malloc_hook_c.h
// for details of these types/functions.

class PERFTOOLS_DLL_DECL MallocHook {
 public:
  // The NewHook is invoked whenever an object is allocated.
  // It may be passed NULL if the allocator returned NULL.
  typedef MallocHook_NewHook NewHook;
  inline static bool AddNewHook(NewHook hook) {
    return MallocHook_AddNewHook(hook);
  }
  inline static bool RemoveNewHook(NewHook hook) {
    return MallocHook_RemoveNewHook(hook);
  }
  inline static void InvokeNewHook(const void* p, size_t s);

  // The DeleteHook is invoked whenever an object is deallocated.
  // It may be passed NULL if the caller is trying to delete NULL.
  typedef MallocHook_DeleteHook DeleteHook;
  inline static bool AddDeleteHook(DeleteHook hook) {
    return MallocHook_AddDeleteHook(hook);
  }
  inline static bool RemoveDeleteHook(DeleteHook hook) {
    return MallocHook_RemoveDeleteHook(hook);
  }
  inline static void InvokeDeleteHook(const void* p);

  // The PreMmapHook is invoked with mmap or mmap64 arguments just
  // before the call is actually made.  Such a hook may be useful
  // in memory limited contexts, to catch allocations that will exceed
  // a memory limit, and take outside actions to increase that limit.
  typedef MallocHook_PreMmapHook PreMmapHook;
  inline static bool AddPreMmapHook(PreMmapHook hook) {
    return MallocHook_AddPreMmapHook(hook);
  }
  inline static bool RemovePreMmapHook(PreMmapHook hook) {
    return MallocHook_RemovePreMmapHook(hook);
  }
  inline static void InvokePreMmapHook(const void* start,
                                       size_t size,
                                       int protection,
                                       int flags,
                                       int fd,
                                       off_t offset);

  // The MmapReplacement is invoked after the PreMmapHook but before
  // the call is actually made. The MmapReplacement should return true
  // if it handled the call, or false if it is still necessary to
  // call mmap/mmap64.
  // This should be used only by experts, and users must be be
  // extremely careful to avoid recursive calls to mmap. The replacement
  // should be async signal safe.
  // Only one MmapReplacement is supported. After setting an MmapReplacement
  // you must call RemoveMmapReplacement before calling SetMmapReplacement
  // again.
  typedef MallocHook_MmapReplacement MmapReplacement;
  inline static bool SetMmapReplacement(MmapReplacement hook) {
    return MallocHook_SetMmapReplacement(hook);
  }
  inline static bool RemoveMmapReplacement(MmapReplacement hook) {
    return MallocHook_RemoveMmapReplacement(hook);
  }
  inline static bool InvokeMmapReplacement(const void* start,
                                           size_t size,
                                           int protection,
                                           int flags,
                                           int fd,
                                           off_t offset,
                                           void** result);


  // The MmapHook is invoked whenever a region of memory is mapped.
  // It may be passed MAP_FAILED if the mmap failed.
  typedef MallocHook_MmapHook MmapHook;
  inline static bool AddMmapHook(MmapHook hook) {
    return MallocHook_AddMmapHook(hook);
  }
  inline static bool RemoveMmapHook(MmapHook hook) {
    return MallocHook_RemoveMmapHook(hook);
  }
  inline static void InvokeMmapHook(const void* result,
                                    const void* start,
                                    size_t size,
                                    int protection,
                                    int flags,
                                    int fd,
                                    off_t offset);

  // The MunmapReplacement is invoked with munmap arguments just before
  // the call is actually made. The MunmapReplacement should return true
  // if it handled the call, or false if it is still necessary to
  // call munmap.
  // This should be used only by experts. The replacement should be
  // async signal safe.
  // Only one MunmapReplacement is supported. After setting an
  // MunmapReplacement you must call RemoveMunmapReplacement before
  // calling SetMunmapReplacement again.
  typedef MallocHook_MunmapReplacement MunmapReplacement;
  inline static bool SetMunmapReplacement(MunmapReplacement hook) {
    return MallocHook_SetMunmapReplacement(hook);
  }
  inline static bool RemoveMunmapReplacement(MunmapReplacement hook) {
    return MallocHook_RemoveMunmapReplacement(hook);
  }
  inline static bool InvokeMunmapReplacement(const void* p,
                                             size_t size,
                                             int* result);

  // The MunmapHook is invoked whenever a region of memory is unmapped.
  typedef MallocHook_MunmapHook MunmapHook;
  inline static bool AddMunmapHook(MunmapHook hook) {
    return MallocHook_AddMunmapHook(hook);
  }
  inline static bool RemoveMunmapHook(MunmapHook hook) {
    return MallocHook_RemoveMunmapHook(hook);
  }
  inline static void InvokeMunmapHook(const void* p, size_t size);

  // The MremapHook is invoked whenever a region of memory is remapped.
  typedef MallocHook_MremapHook MremapHook;
  inline static bool AddMremapHook(MremapHook hook) {
    return MallocHook_AddMremapHook(hook);
  }
  inline static bool RemoveMremapHook(MremapHook hook) {
    return MallocHook_RemoveMremapHook(hook);
  }
  inline static void InvokeMremapHook(const void* result,
                                      const void* old_addr,
                                      size_t old_size,
                                      size_t new_size,
                                      int flags,
                                      const void* new_addr);

  // The PreSbrkHook is invoked just before sbrk is called -- except when
  // the increment is 0.  This is because sbrk(0) is often called
  // to get the top of the memory stack, and is not actually a
  // memory-allocation call.  It may be useful in memory-limited contexts,
  // to catch allocations that will exceed the limit and take outside
  // actions to increase such a limit.
  typedef MallocHook_PreSbrkHook PreSbrkHook;
  inline static bool AddPreSbrkHook(PreSbrkHook hook) {
    return MallocHook_AddPreSbrkHook(hook);
  }
  inline static bool RemovePreSbrkHook(PreSbrkHook hook) {
    return MallocHook_RemovePreSbrkHook(hook);
  }
  inline static void InvokePreSbrkHook(ptrdiff_t increment);

  // The SbrkHook is invoked whenever sbrk is called -- except when
  // the increment is 0.  This is because sbrk(0) is often called
  // to get the top of the memory stack, and is not actually a
  // memory-allocation call.
  typedef MallocHook_SbrkHook SbrkHook;
  inline static bool AddSbrkHook(SbrkHook hook) {
    return MallocHook_AddSbrkHook(hook);
  }
  inline static bool RemoveSbrkHook(SbrkHook hook) {
    return MallocHook_RemoveSbrkHook(hook);
  }
  inline static void InvokeSbrkHook(const void* result, ptrdiff_t increment);

  // Get the current stack trace.  Try to skip all routines up to and
  // and including the caller of MallocHook::Invoke*.
  // Use "skip_count" (similarly to GetStackTrace from stacktrace.h)
  // as a hint about how many routines to skip if better information
  // is not available.
  inline static int GetCallerStackTrace(void** result, int max_depth,
                                        int skip_count) {
    return MallocHook_GetCallerStackTrace(result, max_depth, skip_count);
  }

  // Unhooked versions of mmap() and munmap().   These should be used
  // only by experts, since they bypass heapchecking, etc.
  // Note: These do not run hooks, but they still use the MmapReplacement
  // and MunmapReplacement.
  static void* UnhookedMMap(void *start, size_t length, int prot, int flags,
                            int fd, off_t offset);
  static int UnhookedMUnmap(void *start, size_t length);

  // The following are DEPRECATED.
  inline static NewHook GetNewHook();
  inline static NewHook SetNewHook(NewHook hook) {
    return MallocHook_SetNewHook(hook);
  }

  inline static DeleteHook GetDeleteHook();
  inline static DeleteHook SetDeleteHook(DeleteHook hook) {
    return MallocHook_SetDeleteHook(hook);
  }

  inline static PreMmapHook GetPreMmapHook();
  inline static PreMmapHook SetPreMmapHook(PreMmapHook hook) {
    return MallocHook_SetPreMmapHook(hook);
  }

  inline static MmapHook GetMmapHook();
  inline static MmapHook SetMmapHook(MmapHook hook) {
    return MallocHook_SetMmapHook(hook);
  }

  inline static MunmapHook GetMunmapHook();
  inline static MunmapHook SetMunmapHook(MunmapHook hook) {
    return MallocHook_SetMunmapHook(hook);
  }

  inline static MremapHook GetMremapHook();
  inline static MremapHook SetMremapHook(MremapHook hook) {
    return MallocHook_SetMremapHook(hook);
  }

  inline static PreSbrkHook GetPreSbrkHook();
  inline static PreSbrkHook SetPreSbrkHook(PreSbrkHook hook) {
    return MallocHook_SetPreSbrkHook(hook);
  }

  inline static SbrkHook GetSbrkHook();
  inline static SbrkHook SetSbrkHook(SbrkHook hook) {
    return MallocHook_SetSbrkHook(hook);
  }
  // End of DEPRECATED methods.

 private:
  // Slow path versions of Invoke*Hook.
  static void InvokeNewHookSlow(const void* p, size_t s);
  static void InvokeDeleteHookSlow(const void* p);
  static void InvokePreMmapHookSlow(const void* start,
                                    size_t size,
                                    int protection,
                                    int flags,
                                    int fd,
                                    off_t offset);
  static void InvokeMmapHookSlow(const void* result,
                                 const void* start,
                                 size_t size,
                                 int protection,
                                 int flags,
                                 int fd,
                                 off_t offset);
  static bool InvokeMmapReplacementSlow(const void* start,
                                        size_t size,
                                        int protection,
                                        int flags,
                                        int fd,
                                        off_t offset,
                                        void** result);
  static void InvokeMunmapHookSlow(const void* p, size_t size);
  static bool InvokeMunmapReplacementSlow(const void* p,
                                          size_t size,
                                          int* result);
  static void InvokeMremapHookSlow(const void* result,
                                   const void* old_addr,
                                   size_t old_size,
                                   size_t new_size,
                                   int flags,
                                   const void* new_addr);
  static void InvokePreSbrkHookSlow(ptrdiff_t increment);
  static void InvokeSbrkHookSlow(const void* result, ptrdiff_t increment);
};

#ifdef _MSC_VER
#pragma warning(pop)
#endif


#endif /* _MALLOC_HOOK_H_ */
