// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/winheap_dump_provider_win.h"

#include <windows.h>

#include "base/debug/profiler.h"
#include "base/trace_event/process_memory_dump.h"
#include "base/win/windows_version.h"

namespace base {
namespace trace_event {

namespace {

// Report a heap dump to a process memory dump. The |heap_info| structure
// contains the information about this heap, and |dump_absolute_name| will be
// used to represent it in the report.
void ReportHeapDump(ProcessMemoryDump* pmd,
                    const WinHeapInfo& heap_info,
                    const std::string& dump_absolute_name) {
  MemoryAllocatorDump* outer_dump =
      pmd->CreateAllocatorDump(dump_absolute_name);
  outer_dump->AddScalar(MemoryAllocatorDump::kNameSize,
                        MemoryAllocatorDump::kUnitsBytes,
                        heap_info.committed_size);

  MemoryAllocatorDump* inner_dump =
      pmd->CreateAllocatorDump(dump_absolute_name + "/allocated_objects");
  inner_dump->AddScalar(MemoryAllocatorDump::kNameSize,
                        MemoryAllocatorDump::kUnitsBytes,
                        heap_info.allocated_size);
  inner_dump->AddScalar(MemoryAllocatorDump::kNameObjectsCount,
                        MemoryAllocatorDump::kUnitsObjects,
                        heap_info.block_count);
}

}  // namespace

WinHeapDumpProvider* WinHeapDumpProvider::GetInstance() {
  return Singleton<WinHeapDumpProvider,
                   LeakySingletonTraits<WinHeapDumpProvider>>::get();
}

bool WinHeapDumpProvider::OnMemoryDump(ProcessMemoryDump* pmd) {
  // This method might be flaky for 2 reasons:
  //   - GetProcessHeaps is racy by design. It returns a snapshot of the
  //     available heaps, but there's no guarantee that that snapshot remains
  //     valid. If a heap disappears between GetProcessHeaps() and HeapWalk()
  //     then chaos should be assumed. This flakyness is acceptable for tracing.
  //   - The MSDN page for HeapLock says: "If the HeapLock function is called on
  //     a heap created with the HEAP_NO_SERIALIZATION flag, the results are
  //     undefined.". This is a problem on Windows XP where some system DLLs are
  //     known for creating heaps with this particular flag. For this reason
  //     this function should be disabled on XP.
  //
  // See https://crbug.com/487291 for more details about this.
  if (base::win::GetVersion() < base::win::VERSION_VISTA)
    return false;

  // Disable this dump provider for the SyzyASan instrumented build
  // because they don't support the heap walking functions yet.
#if defined(SYZYASAN)
  if (base::debug::IsBinaryInstrumented())
    return false;
#endif

  // Retrieves the number of heaps in the current process.
  DWORD number_of_heaps = ::GetProcessHeaps(0, NULL);
  WinHeapInfo all_heap_info = {0};

  // Try to retrieve a handle to all the heaps owned by this process. Returns
  // false if the number of heaps has changed.
  //
  // This is inherently racy as is, but it's not something that we observe a lot
  // in Chrome, the heaps tend to be created at startup only.
  scoped_ptr<HANDLE[]> all_heaps(new HANDLE[number_of_heaps]);
  if (::GetProcessHeaps(number_of_heaps, all_heaps.get()) != number_of_heaps)
    return false;

  // Skip the pointer to the heap array to avoid accounting the memory used by
  // this dump provider.
  std::set<void*> block_to_skip;
  block_to_skip.insert(all_heaps.get());

  // Retrieves some metrics about each heap.
  for (size_t i = 0; i < number_of_heaps; ++i) {
    WinHeapInfo heap_info = {0};
    heap_info.heap_id = all_heaps[i];
    GetHeapInformation(&heap_info, block_to_skip);

    all_heap_info.allocated_size += heap_info.allocated_size;
    all_heap_info.committed_size += heap_info.committed_size;
    all_heap_info.block_count += heap_info.block_count;
  }
  // Report the heap dump.
  ReportHeapDump(pmd, all_heap_info, "winheap");
  return true;
}

bool WinHeapDumpProvider::GetHeapInformation(
    WinHeapInfo* heap_info,
    const std::set<void*>& block_to_skip) {
  CHECK(::HeapLock(heap_info->heap_id) == TRUE);
  PROCESS_HEAP_ENTRY heap_entry;
  heap_entry.lpData = nullptr;
  // Walk over all the entries in this heap.
  while (::HeapWalk(heap_info->heap_id, &heap_entry) != FALSE) {
    if (block_to_skip.count(heap_entry.lpData) == 1)
      continue;
    if ((heap_entry.wFlags & PROCESS_HEAP_ENTRY_BUSY) != 0) {
      heap_info->allocated_size += heap_entry.cbData;
      heap_info->block_count++;
    } else if ((heap_entry.wFlags & PROCESS_HEAP_REGION) != 0) {
      heap_info->committed_size += heap_entry.Region.dwCommittedSize;
    }
  }
  CHECK(::HeapUnlock(heap_info->heap_id) == TRUE);
  return true;
}

}  // namespace trace_event
}  // namespace base
