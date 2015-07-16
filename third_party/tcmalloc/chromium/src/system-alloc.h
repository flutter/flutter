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
// Routine that uses sbrk/mmap to allocate memory from the system.
// Useful for implementing malloc.

#ifndef TCMALLOC_SYSTEM_ALLOC_H_
#define TCMALLOC_SYSTEM_ALLOC_H_

#include <config.h>
#include <stddef.h>                     // for size_t

class SysAllocator;

// REQUIRES: "alignment" is a power of two or "0" to indicate default alignment
//
// Allocate and return "N" bytes of zeroed memory.
//
// If actual_bytes is NULL then the returned memory is exactly the
// requested size.  If actual bytes is non-NULL then the allocator
// may optionally return more bytes than asked for (i.e. return an
// entire "huge" page if a huge page allocator is in use).
//
// The returned pointer is a multiple of "alignment" if non-zero. The
// returned pointer will always be aligned suitably for holding a
// void*, double, or size_t. In addition, if this platform defines
// CACHELINE_ALIGNED, the return pointer will always be cacheline
// aligned.
//
// Returns NULL when out of memory.
extern void* TCMalloc_SystemAlloc(size_t bytes, size_t *actual_bytes,
                                  size_t alignment = 0);

// This call is a hint to the operating system that the pages
// contained in the specified range of memory will not be used for a
// while, and can be released for use by other processes or the OS.
// Pages which are released in this way may be destroyed (zeroed) by
// the OS.  The benefit of this function is that it frees memory for
// use by the system, the cost is that the pages are faulted back into
// the address space next time they are touched, which can impact
// performance.  (Only pages fully covered by the memory region will
// be released, partial pages will not.)
extern void TCMalloc_SystemRelease(void* start, size_t length);

// Called to ressurect memory which has been previously released
// to the system via TCMalloc_SystemRelease.  An attempt to
// commit a page that is already committed does not cause this
// function to fail.
extern void TCMalloc_SystemCommit(void* start, size_t length);

// Guards the first page in the supplied range of memory and returns the size
// of the guard page. Will return 0 if a guard cannot be added to the page
// (e.g. start is not aligned or size is not large enough).
extern size_t TCMalloc_SystemAddGuard(void* start, size_t size);

// The current system allocator.
extern PERFTOOLS_DLL_DECL SysAllocator* sys_alloc;

#endif /* TCMALLOC_SYSTEM_ALLOC_H_ */
