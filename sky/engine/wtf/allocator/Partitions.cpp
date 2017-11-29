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

#include "platform/wtf/allocator/Partitions.h"

#include "base/allocator/partition_allocator/oom.h"
#include "base/allocator/partition_allocator/page_allocator.h"
#include "base/debug/alias.h"
#include "base/lazy_instance.h"
#include "platform/wtf/allocator/PartitionAllocator.h"

namespace WTF {

const char* const Partitions::kAllocatedObjectPoolName =
    "partition_alloc/allocated_objects";

static base::LazyInstance<base::subtle::SpinLock>::Leaky initialization_lock_ =
    LAZY_INSTANCE_INITIALIZER;
bool Partitions::initialized_ = false;

// These statics are inlined, so cannot be LazyInstances. We create
// LazyInstances below, and then set the pointers correctly in Initialize().
base::PartitionAllocatorGeneric* Partitions::fast_malloc_allocator_ = nullptr;
base::PartitionAllocatorGeneric* Partitions::array_buffer_allocator_ = nullptr;
base::PartitionAllocatorGeneric* Partitions::buffer_allocator_ = nullptr;
base::SizeSpecificPartitionAllocator<1024>* Partitions::layout_allocator_ =
    nullptr;

static base::LazyInstance<base::PartitionAllocatorGeneric>::Leaky
    lazy_fast_malloc = LAZY_INSTANCE_INITIALIZER;
static base::LazyInstance<base::PartitionAllocatorGeneric>::Leaky
    lazy_array_buffer = LAZY_INSTANCE_INITIALIZER;
static base::LazyInstance<base::PartitionAllocatorGeneric>::Leaky lazy_buffer =
    LAZY_INSTANCE_INITIALIZER;
static base::LazyInstance<base::SizeSpecificPartitionAllocator<1024>>::Leaky
    lazy_layout = LAZY_INSTANCE_INITIALIZER;

Partitions::ReportPartitionAllocSizeFunction Partitions::report_size_function_ =
    nullptr;

void Partitions::Initialize(
    ReportPartitionAllocSizeFunction report_size_function) {
  base::subtle::SpinLock::Guard guard(initialization_lock_.Get());

  if (!initialized_) {
    fast_malloc_allocator_ = lazy_fast_malloc.Pointer();
    array_buffer_allocator_ = lazy_array_buffer.Pointer();
    buffer_allocator_ = lazy_buffer.Pointer();
    layout_allocator_ = lazy_layout.Pointer();

    base::PartitionAllocGlobalInit(&Partitions::HandleOutOfMemory);
    fast_malloc_allocator_->init();
    array_buffer_allocator_->init();
    buffer_allocator_->init();
    layout_allocator_->init();
    report_size_function_ = report_size_function;
    initialized_ = true;
  }
}

void Partitions::DecommitFreeableMemory() {
  CHECK(IsMainThread());
  if (!initialized_)
    return;

  base::PartitionPurgeMemoryGeneric(
      ArrayBufferPartition(), base::PartitionPurgeDecommitEmptyPages |
                                  base::PartitionPurgeDiscardUnusedSystemPages);
  base::PartitionPurgeMemoryGeneric(
      BufferPartition(), base::PartitionPurgeDecommitEmptyPages |
                             base::PartitionPurgeDiscardUnusedSystemPages);
  base::PartitionPurgeMemoryGeneric(
      FastMallocPartition(), base::PartitionPurgeDecommitEmptyPages |
                                 base::PartitionPurgeDiscardUnusedSystemPages);
  base::PartitionPurgeMemory(LayoutPartition(),
                             base::PartitionPurgeDecommitEmptyPages |
                                 base::PartitionPurgeDiscardUnusedSystemPages);
}

void Partitions::ReportMemoryUsageHistogram() {
  static size_t observed_max_size_in_mb = 0;

  if (!report_size_function_)
    return;
  // We only report the memory in the main thread.
  if (!IsMainThread())
    return;
  // +1 is for rounding up the sizeInMB.
  size_t size_in_mb = Partitions::TotalSizeOfCommittedPages() / 1024 / 1024 + 1;
  if (size_in_mb > observed_max_size_in_mb) {
    report_size_function_(size_in_mb);
    observed_max_size_in_mb = size_in_mb;
  }
}

void Partitions::DumpMemoryStats(
    bool is_light_dump,
    base::PartitionStatsDumper* partition_stats_dumper) {
  // Object model and rendering partitions are not thread safe and can be
  // accessed only on the main thread.
  DCHECK(IsMainThread());

  DecommitFreeableMemory();
  PartitionDumpStatsGeneric(FastMallocPartition(), "fast_malloc", is_light_dump,
                            partition_stats_dumper);
  PartitionDumpStatsGeneric(ArrayBufferPartition(), "array_buffer",
                            is_light_dump, partition_stats_dumper);
  PartitionDumpStatsGeneric(BufferPartition(), "buffer", is_light_dump,
                            partition_stats_dumper);
  PartitionDumpStats(LayoutPartition(), "layout", is_light_dump,
                     partition_stats_dumper);
}

namespace {

class LightPartitionStatsDumperImpl : public WTF::PartitionStatsDumper {
 public:
  LightPartitionStatsDumperImpl() : total_active_bytes_(0) {}

  void PartitionDumpTotals(
      const char* partition_name,
      const WTF::PartitionMemoryStats* memory_stats) override {
    total_active_bytes_ += memory_stats->total_active_bytes;
  }

  void PartitionsDumpBucketStats(
      const char* partition_name,
      const WTF::PartitionBucketMemoryStats*) override {}

  size_t TotalActiveBytes() const { return total_active_bytes_; }

 private:
  size_t total_active_bytes_;
};

}  // namespace

size_t Partitions::TotalActiveBytes() {
  LightPartitionStatsDumperImpl dumper;
  WTF::Partitions::DumpMemoryStats(true, &dumper);
  return dumper.TotalActiveBytes();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing2G() {
  size_t signature = 2UL * 1024 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing1G() {
  size_t signature = 1UL * 1024 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing512M() {
  size_t signature = 512 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing256M() {
  size_t signature = 256 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing128M() {
  size_t signature = 128 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing64M() {
  size_t signature = 64 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing32M() {
  size_t signature = 32 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsing16M() {
  size_t signature = 16 * 1024 * 1024;
  base::debug::Alias(&signature);
  OOM_CRASH();
}

static NEVER_INLINE void PartitionsOutOfMemoryUsingLessThan16M() {
  size_t signature = 16 * 1024 * 1024 - 1;
  base::debug::Alias(&signature);
  DLOG(FATAL) << "ParitionAlloc: out of memory with < 16M usage (error:"
              << GetAllocPageErrorCode() << ")";
}

void Partitions::HandleOutOfMemory() {
  volatile size_t total_usage = TotalSizeOfCommittedPages();
  uint32_t alloc_page_error_code = GetAllocPageErrorCode();
  base::debug::Alias(&alloc_page_error_code);

  if (total_usage >= 2UL * 1024 * 1024 * 1024)
    PartitionsOutOfMemoryUsing2G();
  if (total_usage >= 1UL * 1024 * 1024 * 1024)
    PartitionsOutOfMemoryUsing1G();
  if (total_usage >= 512 * 1024 * 1024)
    PartitionsOutOfMemoryUsing512M();
  if (total_usage >= 256 * 1024 * 1024)
    PartitionsOutOfMemoryUsing256M();
  if (total_usage >= 128 * 1024 * 1024)
    PartitionsOutOfMemoryUsing128M();
  if (total_usage >= 64 * 1024 * 1024)
    PartitionsOutOfMemoryUsing64M();
  if (total_usage >= 32 * 1024 * 1024)
    PartitionsOutOfMemoryUsing32M();
  if (total_usage >= 16 * 1024 * 1024)
    PartitionsOutOfMemoryUsing16M();
  PartitionsOutOfMemoryUsingLessThan16M();
}

}  // namespace WTF
