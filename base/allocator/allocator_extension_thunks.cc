// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/allocator/allocator_extension_thunks.h"

#include <cstddef> // for NULL

namespace base {
namespace allocator {
namespace thunks {

// This slightly odd translation unit exists because of the peculularity of how
// allocator_unittests work on windows.  That target has to perform
// tcmalloc-specific initialization on windows, but it cannot depend on base
// otherwise. This target sits in the middle - base and allocator_unittests
// can depend on it. This file can't depend on anything else in base, including
// logging.

static GetAllocatorWasteSizeFunction g_get_allocator_waste_size_function = NULL;
static GetStatsFunction g_get_stats_function = NULL;
static ReleaseFreeMemoryFunction g_release_free_memory_function = NULL;

void SetGetAllocatorWasteSizeFunction(
    GetAllocatorWasteSizeFunction get_allocator_waste_size_function) {
  g_get_allocator_waste_size_function = get_allocator_waste_size_function;
}

GetAllocatorWasteSizeFunction GetGetAllocatorWasteSizeFunction() {
  return g_get_allocator_waste_size_function;
}

void SetGetStatsFunction(GetStatsFunction get_stats_function) {
  g_get_stats_function = get_stats_function;
}

GetStatsFunction GetGetStatsFunction() {
  return g_get_stats_function;
}

void SetReleaseFreeMemoryFunction(
    ReleaseFreeMemoryFunction release_free_memory_function) {
  g_release_free_memory_function = release_free_memory_function;
}

ReleaseFreeMemoryFunction GetReleaseFreeMemoryFunction() {
  return g_release_free_memory_function;
}

}  // namespace thunks
}  // namespace allocator
}  // namespace base
