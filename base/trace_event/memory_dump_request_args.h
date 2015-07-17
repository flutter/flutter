// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_MEMORY_DUMP_REQUEST_ARGS_H_
#define BASE_TRACE_EVENT_MEMORY_DUMP_REQUEST_ARGS_H_

// This file defines the types and structs used to issue memory dump requests.
// These are also used in the IPCs for coordinating inter-process memory dumps.

#include "base/base_export.h"
#include "base/callback.h"

namespace base {
namespace trace_event {

// Captures the reason why a memory dump is being requested. This is to allow
// selective enabling of dumps, filtering and post-processing.
enum class MemoryDumpType {
  TASK_BEGIN,         // Dumping memory at the beginning of a message-loop task.
  TASK_END,           // Dumping memory at the ending of a message-loop task.
  PERIODIC_INTERVAL,  // Dumping memory at periodic intervals.
  PERIODIC_INTERVAL_WITH_MMAPS,  // As above but w/ heavyweight mmaps dumps.
                                 // Temporary workaround for crbug.com/499731.
  EXPLICITLY_TRIGGERED,  // Non maskable dump request.
  LAST = EXPLICITLY_TRIGGERED // For IPC macros.
};

// Returns the name in string for the dump type given.
BASE_EXPORT const char* MemoryDumpTypeToString(const MemoryDumpType& dump_type);

using MemoryDumpCallback = Callback<void(uint64 dump_guid, bool success)>;

struct BASE_EXPORT MemoryDumpRequestArgs {
  // Globally unique identifier. In multi-process dumps, all processes issue a
  // local dump with the same guid. This allows the trace importers to
  // reconstruct the global dump.
  uint64 dump_guid;

  MemoryDumpType dump_type;
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_MEMORY_DUMP_REQUEST_ARGS_H_
