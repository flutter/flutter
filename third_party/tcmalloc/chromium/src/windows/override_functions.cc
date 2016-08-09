// Copyright (c) 2007, Google Inc.
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
//
// ---
// Author: Mike Belshe
// 
// To link tcmalloc into a EXE or DLL statically without using the patching
// facility, we can take a stock libcmt and remove all the allocator functions.
// When we relink the EXE/DLL with the modified libcmt and tcmalloc, a few
// functions are missing.  This file contains the additional overrides which
// are required in the VS2005 libcmt in order to link the modified libcmt.
//
// See also
// http://groups.google.com/group/google-perftools/browse_thread/thread/41cd3710af85e57b

#include <config.h>

#ifndef _WIN32
# error You should only be including this file in a windows environment!
#endif

#ifndef WIN32_OVERRIDE_ALLOCATORS
# error This file is intended for use when overriding allocators
#endif

#include "tcmalloc.cc"

extern "C" void* _recalloc(void* p, size_t n, size_t size) {
  void* result = realloc(p, n * size);
  memset(result, 0, n * size);
  return result;
}

extern "C" void* _calloc_impl(size_t n, size_t size) {
  return calloc(n, size);
}

extern "C" size_t _msize(void* p) {
  return MallocExtension::instance()->GetAllocatedSize(p);
}

extern "C" intptr_t _get_heap_handle() {
  return 0;
}

// The CRT heap initialization stub.
extern "C" int _heap_init() {
  // We intentionally leak this object.  It lasts for the process
  // lifetime.  Trying to teardown at _heap_term() is so late that
  // you can't do anything useful anyway.
  new TCMallocGuard();
  return 1;
}

// The CRT heap cleanup stub.
extern "C" void _heap_term() {
}

extern "C" int _set_new_mode(int flag) {
  return tc_set_new_mode(flag);
}

#ifndef NDEBUG
#undef malloc
#undef free
#undef calloc
int _CrtDbgReport(int, const char*, int, const char*, const char*, ...) {
  return 0;
}

int _CrtDbgReportW(int, const wchar_t*, int, const wchar_t*, const wchar_t*, ...) {
  return 0;
}

int _CrtSetReportMode(int, int) {
  return 0;
}

extern "C" void* _malloc_dbg(size_t size, int , const char*, int) {
  return malloc(size);
}

extern "C" void _free_dbg(void* ptr, int) {
  free(ptr);
}

extern "C" void* _calloc_dbg(size_t n, size_t size, int, const char*, int) {
  return calloc(n, size);
}
#endif  // NDEBUG

// We set this to 1 because part of the CRT uses a check of _crtheap != 0
// to test whether the CRT has been initialized.  Once we've ripped out
// the allocators from libcmt, we need to provide this definition so that
// the rest of the CRT is still usable.
extern "C" void* _crtheap = reinterpret_cast<void*>(1);
