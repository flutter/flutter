/* Copyright (c) 2007, Google Inc.
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
 *
 * ---
 * Author: Craig Silverstein
 */

#ifndef _WIN32
# error You should only be including windows/port.cc in a windows environment!
#endif

#define NOMINMAX       // so std::max, below, compiles correctly
#include <config.h>
#include <string.h>    // for strlen(), memset(), memcmp()
#include <assert.h>
#include <stdarg.h>    // for va_list, va_start, va_end
#include <windows.h>
#include <algorithm>
#include "port.h"
#include "base/logging.h"
#include "base/spinlock.h"
#include "internal_logging.h"
#include "system-alloc.h"

// -----------------------------------------------------------------------
// Basic libraries

int getpagesize() {
  static int pagesize = 0;
  if (pagesize == 0) {
    SYSTEM_INFO system_info;
    GetSystemInfo(&system_info);
    pagesize = std::max(system_info.dwPageSize,
                        system_info.dwAllocationGranularity);
  }
  return pagesize;
}

extern "C" PERFTOOLS_DLL_DECL void* __sbrk(ptrdiff_t increment) {
  LOG(FATAL, "Windows doesn't implement sbrk!\n");
  return NULL;
}

// We need to write to 'stderr' without having windows allocate memory.
// The safest way is via a low-level call like WriteConsoleA().  But
// even then we need to be sure to print in small bursts so as to not
// require memory allocation.
extern "C" PERFTOOLS_DLL_DECL void WriteToStderr(const char* buf, int len) {
  // Looks like windows allocates for writes of >80 bytes
  for (int i = 0; i < len; i += 80) {
    write(STDERR_FILENO, buf + i, std::min(80, len - i));
  }
}


// -----------------------------------------------------------------------
// Threads code

// Declared (not extern "C") in thread_cache.h
bool CheckIfKernelSupportsTLS() {
  // TODO(csilvers): return true (all win's since win95, at least, support this)
  return false;
}

// Windows doesn't support pthread_key_create's destr_function, and in
// fact it's a bit tricky to get code to run when a thread exits.  This
// is cargo-cult magic from http://www.codeproject.com/threads/tls.asp.
// This code is for VC++ 7.1 and later; VC++ 6.0 support is possible
// but more busy-work -- see the webpage for how to do it.  If all
// this fails, we could use DllMain instead.  The big problem with
// DllMain is it doesn't run if this code is statically linked into a
// binary (it also doesn't run if the thread is terminated via
// TerminateThread, which if we're lucky this routine does).

// Force a reference to _tls_used to make the linker create the TLS directory
// if it's not already there (that is, even if __declspec(thread) is not used).
// Force a reference to p_thread_callback_tcmalloc and p_process_term_tcmalloc
// to prevent whole program optimization from discarding the variables.
#ifdef _MSC_VER
#if defined(_M_IX86)
#pragma comment(linker, "/INCLUDE:__tls_used")
#pragma comment(linker, "/INCLUDE:_p_thread_callback_tcmalloc")
#pragma comment(linker, "/INCLUDE:_p_process_term_tcmalloc")
#elif defined(_M_X64)
#pragma comment(linker, "/INCLUDE:_tls_used")
#pragma comment(linker, "/INCLUDE:p_thread_callback_tcmalloc")
#pragma comment(linker, "/INCLUDE:p_process_term_tcmalloc")
#endif
#endif

// When destr_fn eventually runs, it's supposed to take as its
// argument the tls-value associated with key that pthread_key_create
// creates.  (Yeah, it sounds confusing but it's really not.)  We
// store the destr_fn/key pair in this data structure.  Because we
// store this in a single var, this implies we can only have one
// destr_fn in a program!  That's enough in practice.  If asserts
// trigger because we end up needing more, we'll have to turn this
// into an array.
struct DestrFnClosure {
  void (*destr_fn)(void*);
  pthread_key_t key_for_destr_fn_arg;
};

static DestrFnClosure destr_fn_info;   // initted to all NULL/0.

static int on_process_term(void) {
  if (destr_fn_info.destr_fn) {
    void *ptr = TlsGetValue(destr_fn_info.key_for_destr_fn_arg);
    // This shouldn't be necessary, but in Release mode, Windows
    // sometimes trashes the pointer in the TLS slot, so we need to
    // remove the pointer from the TLS slot before the thread dies.
    TlsSetValue(destr_fn_info.key_for_destr_fn_arg, NULL);
    if (ptr)  // pthread semantics say not to call if ptr is NULL
      (*destr_fn_info.destr_fn)(ptr);
  }
  return 0;
}

static void NTAPI on_tls_callback(HINSTANCE h, DWORD dwReason, PVOID pv) {
  if (dwReason == DLL_THREAD_DETACH) {   // thread is being destroyed!
    on_process_term();
  }
}

#ifdef _MSC_VER

// extern "C" suppresses C++ name mangling so we know the symbol names
// for the linker /INCLUDE:symbol pragmas above.
extern "C" {
// This tells the linker to run these functions.
// We use CRT$XLY instead of CRT$XLB to ensure we're called LATER in sequence.
#pragma section(".CRT$XLY", read)
_declspec(allocate(".CRT$XLY")) \
  void (NTAPI *p_thread_callback_tcmalloc)(
    HINSTANCE h, DWORD dwReason, PVOID pv) = on_tls_callback;
#pragma section(".CRT$XTU", read)
_declspec(allocate(".CRT$XTU")) \
  int (*p_process_term_tcmalloc)(void) = on_process_term;
}  // extern "C"

#else  // #ifdef _MSC_VER  [probably msys/mingw]

// We have to try the DllMain solution here, because we can't use the
// msvc-specific pragmas.
BOOL WINAPI DllMain(HINSTANCE h, DWORD dwReason, PVOID pv) {
  if (dwReason == DLL_THREAD_DETACH)
    on_tls_callback(h, dwReason, pv);
  else if (dwReason == DLL_PROCESS_DETACH)
    on_process_term();
  return TRUE;
}

#endif  // #ifdef _MSC_VER

extern "C" pthread_key_t PthreadKeyCreate(void (*destr_fn)(void*)) {
  // Semantics are: we create a new key, and then promise to call
  // destr_fn with TlsGetValue(key) when the thread is destroyed
  // (as long as TlsGetValue(key) is not NULL).
  pthread_key_t key = TlsAlloc();
  if (destr_fn) {   // register it
    // If this assert fails, we'll need to support an array of destr_fn_infos
    assert(destr_fn_info.destr_fn == NULL);
    destr_fn_info.destr_fn = destr_fn;
    destr_fn_info.key_for_destr_fn_arg = key;
  }
  return key;
}

// NOTE: this is Win2K and later.  For Win98 we could use a CRITICAL_SECTION...
extern "C" int perftools_pthread_once(pthread_once_t *once_control,
                                      void (*init_routine)(void)) {
  // Try for a fast path first. Note: this should be an acquire semantics read.
  // It is on x86 and x64, where Windows runs.
  if (*once_control != 1) {
    while (true) {
      switch (InterlockedCompareExchange(once_control, 2, 0)) {
        case 0:
          init_routine();
          InterlockedExchange(once_control, 1);
          return 0;
        case 1:
          // The initializer has already been executed
          return 0;
        default:
          // The initializer is being processed by another thread
          SwitchToThread();
      }
    }
  }
  return 0;
}


// -----------------------------------------------------------------------
// These functions replace system-alloc.cc

// This is mostly like MmapSysAllocator::Alloc, except it does these weird
// munmap's in the middle of the page, which is forbidden in windows.
extern void* TCMalloc_SystemAlloc(size_t size, size_t *actual_size,
                                  size_t alignment) {
  // Align on the pagesize boundary
  const int pagesize = getpagesize();
  if (alignment < pagesize) alignment = pagesize;
  size = ((size + alignment - 1) / alignment) * alignment;

  // Report the total number of bytes the OS actually delivered.  This might be
  // greater than |size| because of alignment concerns.  The full size is
  // necessary so that adjacent spans can be coalesced.
  // TODO(antonm): proper processing of alignments
  // in actual_size and decommitting.
  if (actual_size) {
    *actual_size = size;
  }

  // We currently do not support alignments larger than the pagesize or
  // alignments that are not multiples of the pagesize after being floored.
  // If this ability is needed it can be done by the caller (assuming it knows
  // the page size).
  assert(alignment <= pagesize);

  void* result = VirtualAlloc(0, size,
                              MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE);
  if (result == NULL)
    return NULL;

  // If the result is not aligned memory fragmentation will result which can
  // lead to pathological memory use.
  assert((reinterpret_cast<uintptr_t>(result) & (alignment - 1)) == 0);

  return result;
}

size_t TCMalloc_SystemAddGuard(void* start, size_t size) {
  static size_t pagesize = 0;
  if (pagesize == 0) {
    SYSTEM_INFO system_info;
    GetSystemInfo(&system_info);
    pagesize = system_info.dwPageSize;
  }

  // We know that TCMalloc_SystemAlloc will give us a correct page alignment
  // regardless, so we can just assert to detect erroneous callers.
  assert(reinterpret_cast<size_t>(start) % pagesize == 0);

  // Add a guard page to catch metadata corruption. We're using the
  // PAGE_GUARD flag rather than NO_ACCESS because we want the unique
  // exception in crash reports.
  DWORD permissions = 0;
  if (size > pagesize &&
      VirtualProtect(start, pagesize, PAGE_READONLY | PAGE_GUARD,
                     &permissions)) {
    return pagesize;
  }

  return 0;
}

void TCMalloc_SystemRelease(void* start, size_t length) {
  if (VirtualFree(start, length, MEM_DECOMMIT))
    return;

  // The decommit may fail if the memory region consists of allocations
  // from more than one call to VirtualAlloc.  In this case, fall back to
  // using VirtualQuery to retrieve the allocation boundaries and decommit
  // them each individually.

  char* ptr = static_cast<char*>(start);
  char* end = ptr + length;
  MEMORY_BASIC_INFORMATION info;
  while (ptr < end) {
    size_t resultSize = VirtualQuery(ptr, &info, sizeof(info));
    assert(resultSize == sizeof(info));
    size_t decommitSize = std::min<size_t>(info.RegionSize, end - ptr);
    BOOL success = VirtualFree(ptr, decommitSize, MEM_DECOMMIT);
    assert(success == TRUE);
    ptr += decommitSize;
  }
}

void TCMalloc_SystemCommit(void* start, size_t length) {
  if (VirtualAlloc(start, length, MEM_COMMIT, PAGE_READWRITE) == start)
    return;

  // The commit may fail if the memory region consists of allocations
  // from more than one call to VirtualAlloc.  In this case, fall back to
  // using VirtualQuery to retrieve the allocation boundaries and commit them
  // each individually.

  char* ptr = static_cast<char*>(start);
  char* end = ptr + length;
  MEMORY_BASIC_INFORMATION info;
  while (ptr < end) {
    size_t resultSize = VirtualQuery(ptr, &info, sizeof(info));
    assert(resultSize == sizeof(info));

    size_t commitSize = std::min<size_t>(info.RegionSize, end - ptr);
    void* newAddress = VirtualAlloc(ptr, commitSize, MEM_COMMIT,
                                    PAGE_READWRITE);
    assert(newAddress == ptr);
    ptr += commitSize;
  }
}

bool RegisterSystemAllocator(SysAllocator *allocator, int priority) {
  return false;   // we don't allow registration on windows, right now
}

void DumpSystemAllocatorStats(TCMalloc_Printer* printer) {
  // We don't dump stats on windows, right now
}

// The current system allocator
SysAllocator* sys_alloc = NULL;


// -----------------------------------------------------------------------
// These functions rework existing functions of the same name in the
// Google codebase.

// A replacement for HeapProfiler::CleanupOldProfiles.
void DeleteMatchingFiles(const char* prefix, const char* full_glob) {
  WIN32_FIND_DATAA found;  // that final A is for Ansi (as opposed to Unicode)
  HANDLE hFind = FindFirstFileA(full_glob, &found);   // A is for Ansi
  if (hFind != INVALID_HANDLE_VALUE) {
    const int prefix_length = strlen(prefix);
    do {
      const char *fname = found.cFileName;
      if ((strlen(fname) >= prefix_length) &&
          (memcmp(fname, prefix, prefix_length) == 0)) {
        RAW_VLOG(0, "Removing old heap profile %s\n", fname);
        // TODO(csilvers): we really need to unlink dirname + fname
        _unlink(fname);
      }
    } while (FindNextFileA(hFind, &found) != FALSE);  // A is for Ansi
    FindClose(hFind);
  }
}
