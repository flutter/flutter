// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/winheap_dump_provider_win.h"

#include <windows.h>

#include "base/trace_event/memory_dump_session_state.h"
#include "base/trace_event/process_memory_dump.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

TEST(WinHeapDumpProviderTest, OnMemoryDump) {
  ProcessMemoryDump pmd(make_scoped_refptr(new MemoryDumpSessionState()));

  WinHeapDumpProvider* winheap_dump_provider =
      WinHeapDumpProvider::GetInstance();
  ASSERT_NE(static_cast<WinHeapDumpProvider*>(nullptr), winheap_dump_provider);

  ASSERT_NO_FATAL_FAILURE(winheap_dump_provider->OnMemoryDump(&pmd));
}

}  // namespace trace_event
}  // namespace base
