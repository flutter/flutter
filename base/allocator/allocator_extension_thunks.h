// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ALLOCATOR_ALLOCATOR_EXTENSION_THUNKS_H_
#define BASE_ALLOCATOR_ALLOCATOR_EXTENSION_THUNKS_H_

#include <stddef.h> // for size_t

namespace base {
namespace allocator {
namespace thunks {

// WARNING: You probably don't want to use this file unless you are routing a
// new allocator extension from a specific allocator implementation to base.
// See allocator_extension.h to see the interface that base exports.

typedef bool (*GetAllocatorWasteSizeFunction)(size_t* size);
void SetGetAllocatorWasteSizeFunction(
    GetAllocatorWasteSizeFunction get_allocator_waste_size_function);
GetAllocatorWasteSizeFunction GetGetAllocatorWasteSizeFunction();

typedef void (*GetStatsFunction)(char* buffer, int buffer_length);
void SetGetStatsFunction(GetStatsFunction get_stats_function);
GetStatsFunction GetGetStatsFunction();

typedef void (*ReleaseFreeMemoryFunction)();
void SetReleaseFreeMemoryFunction(
    ReleaseFreeMemoryFunction release_free_memory_function);
ReleaseFreeMemoryFunction GetReleaseFreeMemoryFunction();

}  // namespace thunks
}  // namespace allocator
}  // namespace base

#endif  // BASE_ALLOCATOR_ALLOCATOR_EXTENSION_THUNKS_H_
