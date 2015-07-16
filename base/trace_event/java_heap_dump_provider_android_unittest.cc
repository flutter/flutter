// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/java_heap_dump_provider_android.h"

#include "base/trace_event/process_memory_dump.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

TEST(JavaHeapDumpProviderTest, JavaHeapDump) {
  auto jhdp = JavaHeapDumpProvider::GetInstance();
  scoped_ptr<ProcessMemoryDump> pmd(new ProcessMemoryDump(nullptr));

  jhdp->OnMemoryDump(pmd.get());
}

}  // namespace trace_event
}  // namespace base
