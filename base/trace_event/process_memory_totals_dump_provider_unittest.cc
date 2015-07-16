// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/process_memory_totals_dump_provider.h"

#include "base/trace_event/process_memory_dump.h"
#include "base/trace_event/process_memory_totals.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

TEST(ProcessMemoryTotalsDumpProviderTest, DumpRSS) {
  auto pmtdp = ProcessMemoryTotalsDumpProvider::GetInstance();
  scoped_ptr<ProcessMemoryDump> pmd_before(new ProcessMemoryDump(nullptr));
  scoped_ptr<ProcessMemoryDump> pmd_after(new ProcessMemoryDump(nullptr));

  ProcessMemoryTotalsDumpProvider::rss_bytes_for_testing = 1024;
  pmtdp->OnMemoryDump(pmd_before.get());

  // Pretend that the RSS of the process increased of +1M.
  const size_t kAllocSize = 1048576;
  ProcessMemoryTotalsDumpProvider::rss_bytes_for_testing += kAllocSize;

  pmtdp->OnMemoryDump(pmd_after.get());

  ProcessMemoryTotalsDumpProvider::rss_bytes_for_testing = 0;

  ASSERT_TRUE(pmd_before->has_process_totals());
  ASSERT_TRUE(pmd_after->has_process_totals());

  const uint64 rss_before = pmd_before->process_totals()->resident_set_bytes();
  const uint64 rss_after = pmd_after->process_totals()->resident_set_bytes();

  EXPECT_NE(0U, rss_before);
  EXPECT_NE(0U, rss_after);

  EXPECT_EQ(rss_after - rss_before, kAllocSize);
}

}  // namespace trace_event
}  // namespace base
