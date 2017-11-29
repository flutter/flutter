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

#ifndef Partitions_h
#define Partitions_h

#include <string.h>
#include "base/allocator/partition_allocator/partition_alloc.h"
#include "base/allocator/partition_allocator/spin_lock.h"
#include "base/numerics/checked_math.h"
#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/WTF.h"
#include "flutter/sky/engine/wtf/WTFExport.h"

namespace WTF {

class WTF_EXPORT Partitions {
 public:
  typedef void (*ReportPartitionAllocSizeFunction)(size_t);

  // Name of allocator used by tracing for marking sub-allocations while take
  // memory snapshots.
  static const char* const kAllocatedObjectPoolName;

  static void Initialize(ReportPartitionAllocSizeFunction);
  ALWAYS_INLINE static base::PartitionRootGeneric* ArrayBufferPartition() {
    DCHECK(initialized_);
    return array_buffer_allocator_->root();
  }

  ALWAYS_INLINE static base::PartitionRootGeneric* BufferPartition() {
    DCHECK(initialized_);
    return buffer_allocator_->root();
  }

  ALWAYS_INLINE static base::PartitionRootGeneric* FastMallocPartition() {
    DCHECK(initialized_);
    return fast_malloc_allocator_->root();
  }

  ALWAYS_INLINE static base::PartitionRoot* NodePartition() {
    NOTREACHED();
    return nullptr;
  }

  ALWAYS_INLINE static base::PartitionRoot* LayoutPartition() {
    DCHECK(initialized_);
    return layout_allocator_->root();
  }

  ALWAYS_INLINE static size_t ComputeAllocationSize(size_t count, size_t size) {
    base::CheckedNumeric<size_t> total = count;
    total *= size;
    return total.ValueOrDie();
  }

  static size_t CurrentDOMMemoryUsage() {
    NOTREACHED();
    return 0;
  }

  static size_t TotalSizeOfCommittedPages() {
    DCHECK(initialized_);
    size_t total_size = 0;
    total_size += fast_malloc_allocator_->root()->total_size_of_committed_pages;
    total_size +=
        array_buffer_allocator_->root()->total_size_of_committed_pages;
    total_size += buffer_allocator_->root()->total_size_of_committed_pages;
    total_size += layout_allocator_->root()->total_size_of_committed_pages;
    return total_size;
  }

  static size_t TotalActiveBytes();

  static void DecommitFreeableMemory();

  static void ReportMemoryUsageHistogram();

  static void DumpMemoryStats(bool is_light_dump, base::PartitionStatsDumper*);

  ALWAYS_INLINE static void* BufferMalloc(size_t n, const char* type_name) {
    return base::PartitionAllocGeneric(BufferPartition(), n, type_name);
  }
  ALWAYS_INLINE static void* BufferRealloc(void* p,
                                           size_t n,
                                           const char* type_name) {
    return base::PartitionReallocGeneric(BufferPartition(), p, n, type_name);
  }
  ALWAYS_INLINE static void BufferFree(void* p) {
    base::PartitionFreeGeneric(BufferPartition(), p);
  }
  ALWAYS_INLINE static size_t BufferActualSize(size_t n) {
    return base::PartitionAllocActualSize(BufferPartition(), n);
  }
  static void* FastMalloc(size_t n, const char* type_name) {
    return base::PartitionAllocGeneric(Partitions::FastMallocPartition(), n,
                                       type_name);
  }
  static void* FastZeroedMalloc(size_t n, const char* type_name) {
    void* result = FastMalloc(n, type_name);
    memset(result, 0, n);
    return result;
  }
  static void* FastRealloc(void* p, size_t n, const char* type_name) {
    return base::PartitionReallocGeneric(Partitions::FastMallocPartition(), p,
                                         n, type_name);
  }
  static void FastFree(void* p) {
    base::PartitionFreeGeneric(Partitions::FastMallocPartition(), p);
  }

  static void HandleOutOfMemory();

 private:
  static bool initialized_;

  // See Allocator.md for a description of these partitions.
  static base::PartitionAllocatorGeneric* fast_malloc_allocator_;
  static base::PartitionAllocatorGeneric* array_buffer_allocator_;
  static base::PartitionAllocatorGeneric* buffer_allocator_;
  static base::SizeSpecificPartitionAllocator<1024>* layout_allocator_;
  static ReportPartitionAllocSizeFunction report_size_function_;
};

using base::kGenericMaxDirectMapped;
using base::kPageAllocationGranularity;
using base::kPageAllocationGranularityBaseMask;
using base::kPageAllocationGranularityOffsetMask;
using base::kSystemPageSize;

using base::AllocPages;
using base::DecommitSystemPages;
using base::DiscardSystemPages;
using base::FreePages;
using base::GetAllocPageErrorCode;
using base::PartitionAlloc;
using base::PartitionFree;
using base::RecommitSystemPages;
using base::RoundDownToSystemPage;
using base::RoundUpToSystemPage;
using base::SetSystemPagesAccess;

using base::PageInaccessible;
using base::PageReadWrite;
using base::PartitionAllocHooks;
using base::PartitionBucketMemoryStats;
using base::PartitionMemoryStats;
using base::PartitionStatsDumper;

using CheckedSizeT = base::CheckedNumeric<size_t>;

}  // namespace WTF

#endif  // Partitions_h
