// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/memory_dump_request_args.h"

#include "base/logging.h"

namespace base {
namespace trace_event {

// static
const char* MemoryDumpTypeToString(
    const MemoryDumpType& dump_type) {
  switch (dump_type) {
    case MemoryDumpType::TASK_BEGIN:
      return "TASK_BEGIN";
    case MemoryDumpType::TASK_END:
      return "TASK_END";
    case MemoryDumpType::PERIODIC_INTERVAL:
      return "PERIODIC_INTERVAL";
    case MemoryDumpType::PERIODIC_INTERVAL_WITH_MMAPS:
      return "PERIODIC_INTERVAL_WITH_MMAPS";
    case MemoryDumpType::EXPLICITLY_TRIGGERED:
      return "EXPLICITLY_TRIGGERED";
  }
  NOTREACHED();
  return "UNKNOWN";
}

}  // namespace trace_event
}  // namespace base
