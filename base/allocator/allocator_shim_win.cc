// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <malloc.h>
#include <new.h>
#include <windows.h>

#include "base/basictypes.h"

// This shim make it possible to perform additional checks on allocations
// before passing them to the Heap functions.

// Heap functions are stripped from libcmt.lib using the prep_libc.py
// for each object file stripped, we re-implement them here to allow us to
// perform additional checks:
// 1. Enforcing the maximum size that can be allocated to 2Gb.
// 2. Calling new_handler if malloc fails.

extern "C" {
// We set this to 1 because part of the CRT uses a check of _crtheap != 0
// to test whether the CRT has been initialized.  Once we've ripped out
// the allocators from libcmt, we need to provide this definition so that
// the rest of the CRT is still usable.
// heapinit.c
void* _crtheap = reinterpret_cast<void*>(1);
}

namespace {

const size_t kWindowsPageSize = 4096;
const size_t kMaxWindowsAllocation = INT_MAX - kWindowsPageSize;
int new_mode = 0;

// VS2013 crt uses the process heap as its heap, so we do the same here.
// See heapinit.c in VS CRT sources.
bool win_heap_init() {
  // Set the _crtheap global here.  THis allows us to offload most of the
  // memory management to the CRT, except the functions we need to shim.
  _crtheap = GetProcessHeap();
  if (_crtheap == NULL)
    return false;

  ULONG enable_lfh = 2;
  // NOTE: Setting LFH may fail.  Vista already has it enabled.
  //       And under the debugger, it won't use LFH.  So we
  //       ignore any errors.
  HeapSetInformation(_crtheap, HeapCompatibilityInformation, &enable_lfh,
                     sizeof(enable_lfh));

  return true;
}

void* win_heap_malloc(size_t size) {
  if (size < kMaxWindowsAllocation)
    return HeapAlloc(_crtheap, 0, size);
  return NULL;
}

void win_heap_free(void* size) {
  HeapFree(_crtheap, 0, size);
}

void* win_heap_realloc(void* ptr, size_t size) {
  if (!ptr)
    return win_heap_malloc(size);
  if (!size) {
    win_heap_free(ptr);
    return NULL;
  }
  if (size < kMaxWindowsAllocation)
    return HeapReAlloc(_crtheap, 0, ptr, size);
  return NULL;
}

void win_heap_term() {
  _crtheap = NULL;
}

// Call the new handler, if one has been set.
// Returns true on successfully calling the handler, false otherwise.
inline bool call_new_handler(bool nothrow, size_t size) {
  // Get the current new handler.
  _PNH nh = _query_new_handler();
#if defined(_HAS_EXCEPTIONS) && !_HAS_EXCEPTIONS
  if (!nh)
    return false;
  // Since exceptions are disabled, we don't really know if new_handler
  // failed.  Assume it will abort if it fails.
  return nh(size);
#else
#error "Exceptions in allocator shim are not supported!"
#endif  // defined(_HAS_EXCEPTIONS) && !_HAS_EXCEPTIONS
  return false;
}

// Implement a C++ style allocation, which always calls the new_handler
// on failure.
inline void* generic_cpp_alloc(size_t size, bool nothrow) {
  void* ptr;
  for (;;) {
    ptr = malloc(size);
    if (ptr)
      return ptr;
    if (!call_new_handler(nothrow, size))
      break;
  }
  return ptr;
}

}  // namespace

// new.cpp
void* operator new(size_t size) {
  return generic_cpp_alloc(size, false);
}

// delete.cpp
void operator delete(void* p) throw() {
  free(p);
}

// new2.cpp
void* operator new[](size_t size) {
  return generic_cpp_alloc(size, false);
}

// delete2.cpp
void operator delete[](void* p) throw() {
  free(p);
}

// newopnt.cpp
void* operator new(size_t size, const std::nothrow_t& nt) {
  return generic_cpp_alloc(size, true);
}

// newaopnt.cpp
void* operator new[](size_t size, const std::nothrow_t& nt) {
  return generic_cpp_alloc(size, true);
}

// This function behaves similarly to MSVC's _set_new_mode.
// If flag is 0 (default), calls to malloc will behave normally.
// If flag is 1, calls to malloc will behave like calls to new,
// and the std_new_handler will be invoked on failure.
// Returns the previous mode.
// new_mode.cpp
int _set_new_mode(int flag) throw() {
  int old_mode = new_mode;
  new_mode = flag;
  return old_mode;
}

// new_mode.cpp
int _query_new_mode() {
  return new_mode;
}

extern "C" {
// malloc.c
void* malloc(size_t size) {
  void* ptr;
  for (;;) {
    ptr = win_heap_malloc(size);
    if (ptr)
      return ptr;

    if (!new_mode || !call_new_handler(true, size))
      break;
  }
  return ptr;
}

// free.c
void free(void* p) {
  win_heap_free(p);
  return;
}

// realloc.c
void* realloc(void* ptr, size_t size) {
  // Webkit is brittle for allocators that return NULL for malloc(0).  The
  // realloc(0, 0) code path does not guarantee a non-NULL return, so be sure
  // to call malloc for this case.
  if (!ptr)
    return malloc(size);

  void* new_ptr;
  for (;;) {
    new_ptr = win_heap_realloc(ptr, size);

    // Subtle warning:  NULL return does not alwas indicate out-of-memory.  If
    // the requested new size is zero, realloc should free the ptr and return
    // NULL.
    if (new_ptr || !size)
      return new_ptr;
    if (!new_mode || !call_new_handler(true, size))
      break;
  }
  return new_ptr;
}

// heapinit.c
intptr_t _get_heap_handle() {
  return reinterpret_cast<intptr_t>(_crtheap);
}

// heapinit.c
int _heap_init() {
  return win_heap_init() ? 1 : 0;
}

// heapinit.c
void _heap_term() {
  win_heap_term();
}

// calloc.c
void* calloc(size_t n, size_t elem_size) {
  // Overflow check.
  const size_t size = n * elem_size;
  if (elem_size != 0 && size / elem_size != n)
    return NULL;

  void* result = malloc(size);
  if (result != NULL) {
    memset(result, 0, size);
  }
  return result;
}

// recalloc.c
void* _recalloc(void* p, size_t n, size_t elem_size) {
  if (!p)
    return calloc(n, elem_size);

  // This API is a bit odd.
  // Note: recalloc only guarantees zeroed memory when p is NULL.
  //   Generally, calls to malloc() have padding.  So a request
  //   to malloc N bytes actually malloc's N+x bytes.  Later, if
  //   that buffer is passed to recalloc, we don't know what N
  //   was anymore.  We only know what N+x is.  As such, there is
  //   no way to know what to zero out.
  const size_t size = n * elem_size;
  if (elem_size != 0 && size / elem_size != n)
    return NULL;
  return realloc(p, size);
}

// calloc_impl.c
void* _calloc_impl(size_t n, size_t size) {
  return calloc(n, size);
}

#ifndef NDEBUG
#undef malloc
#undef free
#undef calloc

static int error_handler(int reportType) {
  switch (reportType) {
    case 0:  // _CRT_WARN
      __debugbreak();
      return 0;

    case 1:  // _CRT_ERROR
      __debugbreak();
      return 0;

    case 2:  // _CRT_ASSERT
      __debugbreak();
      return 0;
  }
  char* p = NULL;
  *p = '\0';
  return 0;
}

int _CrtDbgReport(int reportType,
                  const char*,
                  int,
                  const char*,
                  const char*,
                  ...) {
  return error_handler(reportType);
}

int _CrtDbgReportW(int reportType,
                   const wchar_t*,
                   int,
                   const wchar_t*,
                   const wchar_t*,
                   ...) {
  return error_handler(reportType);
}

int _CrtSetReportMode(int, int) {
  return 0;
}

void* _malloc_dbg(size_t size, int, const char*, int) {
  return malloc(size);
}

void* _realloc_dbg(void* ptr, size_t size, int, const char*, int) {
  return realloc(ptr, size);
}

void _free_dbg(void* ptr, int) {
  free(ptr);
}

void* _calloc_dbg(size_t n, size_t size, int, const char*, int) {
  return calloc(n, size);
}
#endif  // NDEBUG

}  // extern C
