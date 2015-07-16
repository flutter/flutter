// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/allocator/allocator_extension.h"

#include "base/logging.h"

namespace base {
namespace allocator {

bool GetAllocatorWasteSize(size_t* size) {
  thunks::GetAllocatorWasteSizeFunction get_allocator_waste_size_function =
      thunks::GetGetAllocatorWasteSizeFunction();
  return get_allocator_waste_size_function != NULL &&
         get_allocator_waste_size_function(size);
}

void GetStats(char* buffer, int buffer_length) {
  DCHECK_GT(buffer_length, 0);
  thunks::GetStatsFunction get_stats_function = thunks::GetGetStatsFunction();
  if (get_stats_function)
    get_stats_function(buffer, buffer_length);
  else
    buffer[0] = '\0';
}

void ReleaseFreeMemory() {
  thunks::ReleaseFreeMemoryFunction release_free_memory_function =
      thunks::GetReleaseFreeMemoryFunction();
  if (release_free_memory_function)
    release_free_memory_function();
}

void SetGetAllocatorWasteSizeFunction(
    thunks::GetAllocatorWasteSizeFunction get_allocator_waste_size_function) {
  DCHECK_EQ(thunks::GetGetAllocatorWasteSizeFunction(),
            reinterpret_cast<thunks::GetAllocatorWasteSizeFunction>(NULL));
  thunks::SetGetAllocatorWasteSizeFunction(get_allocator_waste_size_function);
}

void SetGetStatsFunction(thunks::GetStatsFunction get_stats_function) {
  DCHECK_EQ(thunks::GetGetStatsFunction(),
            reinterpret_cast<thunks::GetStatsFunction>(NULL));
  thunks::SetGetStatsFunction(get_stats_function);
}

void SetReleaseFreeMemoryFunction(
    thunks::ReleaseFreeMemoryFunction release_free_memory_function) {
  DCHECK_EQ(thunks::GetReleaseFreeMemoryFunction(),
            reinterpret_cast<thunks::ReleaseFreeMemoryFunction>(NULL));
  thunks::SetReleaseFreeMemoryFunction(release_free_memory_function);
}

}  // namespace allocator
}  // namespace base
