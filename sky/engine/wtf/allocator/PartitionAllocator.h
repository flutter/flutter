// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WTF_PartitionAllocator_h
#define WTF_PartitionAllocator_h

// This is the allocator that is used for allocations that are not on the
// traced, garbage collected heap. It uses FastMalloc for collections,
// but uses the partition allocator for the backing store of the collections.

#include <string.h>
#include "base/allocator/partition_allocator/partition_alloc.h"
#include "flutter/sky/engine/wtf/Allocator.h"
#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/TypeTraits.h"
#include "flutter/sky/engine/wtf/WTFExport.h"

namespace WTF {

class PartitionAllocatorDummyVisitor {
  DISALLOW_NEW();
};

class WTF_EXPORT PartitionAllocator {
 public:
  typedef PartitionAllocatorDummyVisitor Visitor;
  static const bool kIsGarbageCollected = false;

  template <typename T>
  static size_t MaxElementCountInBackingStore() {
    return base::kGenericMaxDirectMapped / sizeof(T);
  }

  template <typename T>
  static size_t QuantizedSize(size_t count) {
    CHECK_LE(count, MaxElementCountInBackingStore<T>());
    return PartitionAllocActualSize(WTF::Partitions::BufferPartition(),
                                    count * sizeof(T));
  }
  template <typename T>
  static T* AllocateVectorBacking(size_t size) {
    return reinterpret_cast<T*>(
        AllocateBacking(size, WTF_HEAP_PROFILER_TYPE_NAME(T)));
  }
  template <typename T>
  static T* AllocateExpandedVectorBacking(size_t size) {
    return reinterpret_cast<T*>(
        AllocateBacking(size, WTF_HEAP_PROFILER_TYPE_NAME(T)));
  }
  static void FreeVectorBacking(void* address);
  static inline bool ExpandVectorBacking(void*, size_t) { return false; }
  static inline bool ShrinkVectorBacking(void* address,
                                         size_t quantized_current_size,
                                         size_t quantized_shrunk_size) {
    // Optimization: if we're downsizing inside the same allocator bucket,
    // we can skip reallocation.
    return quantized_current_size == quantized_shrunk_size;
  }
  template <typename T>
  static T* AllocateInlineVectorBacking(size_t size) {
    return AllocateVectorBacking<T>(size);
  }
  static inline void FreeInlineVectorBacking(void* address) {
    FreeVectorBacking(address);
  }
  static inline bool ExpandInlineVectorBacking(void*, size_t) { return false; }
  static inline bool ShrinkInlineVectorBacking(void* address,
                                               size_t quantized_current_size,
                                               size_t quantized_shrunk_size) {
    return ShrinkVectorBacking(address, quantized_current_size,
                               quantized_shrunk_size);
  }

  template <typename T, typename HashTable>
  static T* AllocateHashTableBacking(size_t size) {
    return reinterpret_cast<T*>(
        AllocateBacking(size, WTF_HEAP_PROFILER_TYPE_NAME(T)));
  }
  template <typename T, typename HashTable>
  static T* AllocateZeroedHashTableBacking(size_t size) {
    void* result = AllocateBacking(size, WTF_HEAP_PROFILER_TYPE_NAME(T));
    memset(result, 0, size);
    return reinterpret_cast<T*>(result);
  }
  static void FreeHashTableBacking(void* address);

  template <typename Return, typename Metadata>
  static Return Malloc(size_t size, const char* type_name) {
    return reinterpret_cast<Return>(
        WTF::Partitions::FastMalloc(size, type_name));
  }

  static inline bool ExpandHashTableBacking(void*, size_t) { return false; }
  static void Free(void* address) { WTF::Partitions::FastFree(address); }
  template <typename T>
  static void* NewArray(size_t bytes) {
    return Malloc<void*, void>(bytes, WTF_HEAP_PROFILER_TYPE_NAME(T));
  }
  static void DeleteArray(void* ptr) {
    Free(ptr);  // Not the system free, the one from this class.
  }

  static bool IsAllocationAllowed() { return true; }
  static bool IsObjectResurrectionForbidden() { return false; }

  static void EnterGCForbiddenScope() {}
  static void LeaveGCForbiddenScope() {}

 private:
  static void* AllocateBacking(size_t, const char* type_name);
};

// Specializations for heap profiling, so type profiling of |char| is possible
// even in official builds (because |char| makes up a large portion of the
// heap.)
template <>
WTF_EXPORT char* PartitionAllocator::AllocateVectorBacking<char>(size_t);
template <>
WTF_EXPORT char* PartitionAllocator::AllocateExpandedVectorBacking<char>(
    size_t);

}  // namespace WTF

#define USE_ALLOCATOR(ClassName, Allocator)                       \
 public:                                                          \
  void* operator new(size_t size) {                               \
    return Allocator::template Malloc<void*, ClassName>(          \
        size, WTF_HEAP_PROFILER_TYPE_NAME(ClassName));            \
  }                                                               \
  void operator delete(void* p) { Allocator::Free(p); }           \
  void* operator new[](size_t size) {                             \
    return Allocator::template NewArray<ClassName>(size);         \
  }                                                               \
  void operator delete[](void* p) { Allocator::DeleteArray(p); }  \
  void* operator new(size_t, NotNullTag, void* location) {        \
    DCHECK(location);                                             \
    return location;                                              \
  }                                                               \
  void* operator new(size_t, void* location) { return location; } \
                                                                  \
 private:                                                         \
  typedef int __thisIsHereToForceASemicolonAfterThisMacro

#endif  // WTF_PartitionAllocator_h
