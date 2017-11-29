// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/wtf/allocator/PartitionAllocator.h"

#include "base/allocator/partition_allocator/partition_alloc.h"
#include "flutter/sky/engine/wtf/allocator/Partitions.h"

namespace WTF {

void* PartitionAllocator::AllocateBacking(size_t size, const char* type_name) {
  return Partitions::BufferMalloc(size, type_name);
}

void PartitionAllocator::FreeVectorBacking(void* address) {
  Partitions::BufferFree(address);
}

void PartitionAllocator::FreeHashTableBacking(void* address) {
  Partitions::BufferFree(address);
}

template <>
char* PartitionAllocator::AllocateVectorBacking<char>(size_t size) {
  return reinterpret_cast<char*>(
      AllocateBacking(size, "PartitionAllocator::allocateVectorBacking<char>"));
}

template <>
char* PartitionAllocator::AllocateExpandedVectorBacking<char>(size_t size) {
  return reinterpret_cast<char*>(AllocateBacking(
      size, "PartitionAllocator::allocateExpandedVectorBacking<char>"));
}

}  // namespace WTF
