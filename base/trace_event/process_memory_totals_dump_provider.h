// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_PROCESS_MEMORY_TOTALS_DUMP_PROVIDER_H_
#define BASE_TRACE_EVENT_PROCESS_MEMORY_TOTALS_DUMP_PROVIDER_H_

#include "base/gtest_prod_util.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/singleton.h"
#include "base/trace_event/memory_dump_provider.h"

namespace base {

class ProcessMetrics;

namespace trace_event {

// Dump provider which collects process-wide memory stats.
class BASE_EXPORT ProcessMemoryTotalsDumpProvider : public MemoryDumpProvider {
 public:
  static ProcessMemoryTotalsDumpProvider* GetInstance();

  // MemoryDumpProvider implementation.
  bool OnMemoryDump(ProcessMemoryDump* pmd) override;

 private:
  friend struct DefaultSingletonTraits<ProcessMemoryTotalsDumpProvider>;
  FRIEND_TEST_ALL_PREFIXES(ProcessMemoryTotalsDumpProviderTest, DumpRSS);

  static uint64 rss_bytes_for_testing;

  ProcessMemoryTotalsDumpProvider();
  ~ProcessMemoryTotalsDumpProvider() override;

  scoped_ptr<ProcessMetrics> process_metrics_;

  DISALLOW_COPY_AND_ASSIGN(ProcessMemoryTotalsDumpProvider);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_PROCESS_MEMORY_TOTALS_DUMP_PROVIDER_H_
