/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
 */

#ifndef WTF_PageAllocator_h
#define WTF_PageAllocator_h

#include "wtf/Assertions.h"
#include "wtf/CPU.h"
#include "wtf/WTFExport.h"
#include <stdint.h>

namespace WTF {

#if OS(WIN)
static const size_t kPageAllocationGranularityShift = 16; // 64KB
#else
static const size_t kPageAllocationGranularityShift = 12; // 4KB
#endif
static const size_t kPageAllocationGranularity = 1 << kPageAllocationGranularityShift;
static const size_t kPageAllocationGranularityOffsetMask = kPageAllocationGranularity - 1;
static const size_t kPageAllocationGranularityBaseMask = ~kPageAllocationGranularityOffsetMask;

// All Blink-supported systems have 4096 sized system pages and can handle
// permissions and commit / decommit at this granularity.
static const size_t kSystemPageSize = 4096;
static const size_t kSystemPageOffsetMask = kSystemPageSize - 1;
static const size_t kSystemPageBaseMask = ~kSystemPageOffsetMask;

// Allocate one or more pages. Addresses in the range will be readable and
// writeable but not executable.
// The requested address is just a hint; the actual address returned may
// differ. The returned address will be aligned at least to align bytes.
// len is in bytes, and must be a multiple of kPageAllocationGranularity.
// align is in bytes, and must be a power-of-two multiple of
// kPageAllocationGranularity.
// If addr is null, then a suitable and randomized address will be chosen
// automatically.
// This call will return null if the allocation cannot be satisfied.
WTF_EXPORT void* allocPages(void* addr, size_t len, size_t align);

// Free one or more pages.
// addr and len must match a previous call to allocPages().
WTF_EXPORT void freePages(void* addr, size_t len);

// Mark one or more system pages as being inaccessible.
// Subsequently accessing any address in the range will fault, and the
// addresses will not be re-used by future allocations.
// len must be a multiple of kSystemPageSize bytes.
WTF_EXPORT void setSystemPagesInaccessible(void* addr, size_t len);

// Mark one or more system pages as being accessible.
// The pages will be readable and writeable.
// len must be a multiple of kSystemPageSize bytes.
WTF_EXPORT void setSystemPagesAccessible(void* addr, size_t len);

// Decommit one or more system pages. Decommitted means that the physical memory
// is released to the system, but the virtual address space remains reserved.
// System pages are re-committed by calling recommitSystemPages(). Touching
// a decommitted page _may_ fault.
// Clients should not make any assumptions about the contents of decommitted
// system pages, before or after they write to the page. The only guarantee
// provided is that the contents of the system page will be deterministic again
// after recommitting and writing to it. In particlar note that system pages are// not guaranteed to be zero-filled upon re-commit.
// len must be a multiple of kSystemPageSize bytes.
WTF_EXPORT void decommitSystemPages(void* addr, size_t len);

// Recommit one or more system pages. Decommitted system pages must be
// recommitted before they are read are written again.
// Note that this operation may be a no-op on some platforms.
// len must be a multiple of kSystemPageSize bytes.
WTF_EXPORT void recommitSystemPages(void* addr, size_t len);

} // namespace WTF

#endif // WTF_PageAllocator_h
