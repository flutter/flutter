// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PROCESS_MEMORY_H_
#define BASE_PROCESS_MEMORY_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/process/process_handle.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#endif

#ifdef PVALLOC_AVAILABLE
// Build config explicitly tells us whether or not pvalloc is available.
#elif defined(LIBC_GLIBC) && !defined(USE_TCMALLOC)
#define PVALLOC_AVAILABLE 1
#else
#define PVALLOC_AVAILABLE 0
#endif

namespace base {

// Enables low fragmentation heap (LFH) for every heaps of this process. This
// won't have any effect on heaps created after this function call. It will not
// modify data allocated in the heaps before calling this function. So it is
// better to call this function early in initialization and again before
// entering the main loop.
// Note: Returns true on Windows 2000 without doing anything.
BASE_EXPORT bool EnableLowFragmentationHeap();

// Enables 'terminate on heap corruption' flag. Helps protect against heap
// overflow. Has no effect if the OS doesn't provide the necessary facility.
BASE_EXPORT void EnableTerminationOnHeapCorruption();

// Turns on process termination if memory runs out.
BASE_EXPORT void EnableTerminationOnOutOfMemory();

// Terminates process. Should be called only for out of memory errors.
// Crash reporting classifies such crashes as OOM.
BASE_EXPORT void TerminateBecauseOutOfMemory(size_t size);

#if defined(OS_WIN)
// Returns the module handle to which an address belongs. The reference count
// of the module is not incremented.
BASE_EXPORT HMODULE GetModuleFromAddress(void* address);
#endif

#if defined(OS_LINUX) || defined(OS_ANDROID)
BASE_EXPORT extern size_t g_oom_size;

// The maximum allowed value for the OOM score.
const int kMaxOomScore = 1000;

// This adjusts /proc/<pid>/oom_score_adj so the Linux OOM killer will
// prefer to kill certain process types over others. The range for the
// adjustment is [-1000, 1000], with [0, 1000] being user accessible.
// If the Linux system doesn't support the newer oom_score_adj range
// of [0, 1000], then we revert to using the older oom_adj, and
// translate the given value into [0, 15].  Some aliasing of values
// may occur in that case, of course.
BASE_EXPORT bool AdjustOOMScore(ProcessId process, int score);
#endif

// Special allocator functions for callers that want to check for OOM.
// These will not abort if the allocation fails even if
// EnableTerminationOnOutOfMemory has been called.
// This can be useful for huge and/or unpredictable size memory allocations.
// Please only use this if you really handle the case when the allocation
// fails. Doing otherwise would risk security.
// These functions may still crash on OOM when running under memory tools,
// specifically ASan and other sanitizers.
// Return value tells whether the allocation succeeded. If it fails |result| is
// set to NULL, otherwise it holds the memory address.
BASE_EXPORT WARN_UNUSED_RESULT bool UncheckedMalloc(size_t size,
                                                    void** result);
BASE_EXPORT WARN_UNUSED_RESULT bool UncheckedCalloc(size_t num_items,
                                                    size_t size,
                                                    void** result);

}  // namespace base

#endif  // BASE_PROCESS_MEMORY_H_
