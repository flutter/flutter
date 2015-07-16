// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_PROCESS_MEMORY_MAPS_DUMP_PROVIDER_H_
#define BASE_TRACE_EVENT_PROCESS_MEMORY_MAPS_DUMP_PROVIDER_H_

#include <istream>

#include "base/gtest_prod_util.h"
#include "base/memory/singleton.h"
#include "base/trace_event/memory_dump_provider.h"

namespace base {
namespace trace_event {

// Dump provider which collects process-wide memory stats.
class BASE_EXPORT ProcessMemoryMapsDumpProvider : public MemoryDumpProvider {
 public:
  static ProcessMemoryMapsDumpProvider* GetInstance();

  // MemoryDumpProvider implementation.
  bool OnMemoryDump(ProcessMemoryDump* pmd) override;

 private:
  friend struct DefaultSingletonTraits<ProcessMemoryMapsDumpProvider>;
  FRIEND_TEST_ALL_PREFIXES(ProcessMemoryMapsDumpProviderTest, ParseProcSmaps);

#if defined(OS_LINUX) || defined(OS_ANDROID)
  static std::istream* proc_smaps_for_testing;
#endif

  ProcessMemoryMapsDumpProvider();
  ~ProcessMemoryMapsDumpProvider() override;

  DISALLOW_COPY_AND_ASSIGN(ProcessMemoryMapsDumpProvider);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_PROCESS_MEMORY_MAPS_DUMP_PROVIDER_H_
