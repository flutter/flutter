// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/allocation_counter.h"

#include <cstdlib>
#include <new>

namespace {
thread_local bool count_allocations = false;
thread_local size_t allocation_count = 0;

void* CountedAllocate(size_t size) {
  if (count_allocations) {
    allocation_count++;
  }
  return std::malloc(size ? size : 1);
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
