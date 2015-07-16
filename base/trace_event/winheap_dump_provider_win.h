// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_WINHEAP_DUMP_PROVIDER_WIN_H_
#define BASE_TRACE_EVENT_WINHEAP_DUMP_PROVIDER_WIN_H_

#include <set>

#include "base/memory/singleton.h"
#include "base/trace_event/memory_dump_provider.h"

namespace base {
namespace trace_event {

// A structure containing some information about a given heap.
struct WinHeapInfo {
  HANDLE heap_id;
  size_t committed_size;
  size_t allocated_size;
  size_t block_count;
};

// Dump provider which collects process-wide heap memory stats. This provider
// iterates over all the heaps of the current process to gather some metrics
// about them.
class BASE_EXPORT WinHeapDumpProvider : public MemoryDumpProvider {
 public:
  static WinHeapDumpProvider* GetInstance();

  // MemoryDumpProvider implementation.
  bool OnMemoryDump(ProcessMemoryDump* pmd) override;

 private:
  friend struct DefaultSingletonTraits<WinHeapDumpProvider>;

  // Retrieves the information about given heap. The |heap_info| should contain
  // a valid handle to an existing heap. The blocks contained in the
  // |block_to_skip| set will be ignored.
  bool GetHeapInformation(WinHeapInfo* heap_info,
                          const std::set<void*>& block_to_skip);

  WinHeapDumpProvider() {}
  ~WinHeapDumpProvider() override {}

  DISALLOW_COPY_AND_ASSIGN(WinHeapDumpProvider);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_WINHEAP_DUMP_PROVIDER_WIN_H_
