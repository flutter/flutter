// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/allocation_counter.h"

#include <algorithm>
#include <cstdlib>
#include <new>

#include "flutter/fml/build_config.h"

#if FML_OS_WIN
#include <malloc.h>
#endif

namespace {
thread_local bool count_allocations = false;
thread_local size_t allocation_count = 0;

void* CountedAllocate(size_t size) {
  if (count_allocations) {
    allocation_count++;
  }
  return std::malloc(size ? size : 1);
}

// `malloc` only aligns for the fundamental types, so over-aligned types need
// their own allocator, and on Windows their own free.
void* CountedAllocateAligned(size_t size, std::align_val_t alignment) {
  if (count_allocations) {
    allocation_count++;
  }
  const size_t bytes = size ? size : 1;
#if FML_OS_WIN
  return _aligned_malloc(bytes, static_cast<size_t>(alignment));
#else
  void* memory = nullptr;
  // The alignment has to be a multiple of the pointer size.
  if (posix_memalign(&memory,
                     std::max(static_cast<size_t>(alignment), sizeof(void*)),
                     bytes) != 0) {
    return nullptr;
  }
  return memory;
#endif
}

void FreeAligned(void* memory) {
#if FML_OS_WIN
  _aligned_free(memory);
#else
  std::free(memory);
#endif
}
}  // namespace

// These stay out of the test sources. Seeing them there, the static analyzer
// follows every `new` into malloc and misreads googletest's placement new.
void* operator new(size_t size) {
  return CountedAllocate(size);
}

void* operator new[](size_t size) {
  return CountedAllocate(size);
}

void* operator new(size_t size, std::align_val_t alignment) {
  return CountedAllocateAligned(size, alignment);
}

void* operator new[](size_t size, std::align_val_t alignment) {
  return CountedAllocateAligned(size, alignment);
}

void operator delete(void* memory) noexcept {
  std::free(memory);
}

void operator delete[](void* memory) noexcept {
  std::free(memory);
}

void operator delete(void* memory, size_t) noexcept {
  std::free(memory);
}

void operator delete[](void* memory, size_t) noexcept {
  std::free(memory);
}

void operator delete(void* memory, std::align_val_t) noexcept {
  FreeAligned(memory);
}

void operator delete[](void* memory, std::align_val_t) noexcept {
  FreeAligned(memory);
}

void operator delete(void* memory, size_t, std::align_val_t) noexcept {
  FreeAligned(memory);
}

void operator delete[](void* memory, size_t, std::align_val_t) noexcept {
  FreeAligned(memory);
}

namespace flutter::gpu {

AllocationCounter::AllocationCounter() {
  allocation_count = 0;
  count_allocations = true;
}

AllocationCounter::~AllocationCounter() {
  count_allocations = false;
}

size_t AllocationCounter::Stop() {
  count_allocations = false;
  return allocation_count;
}

}  // namespace flutter::gpu
