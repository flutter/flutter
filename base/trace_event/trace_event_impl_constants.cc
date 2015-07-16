// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_impl.h"

namespace base {
namespace trace_event {

// Constant used by TraceLog's internal implementation of trace_option.
const TraceLog::InternalTraceOptions
    TraceLog::kInternalNone = 0;
const TraceLog::InternalTraceOptions
    TraceLog::kInternalRecordUntilFull = 1 << 0;
const TraceLog::InternalTraceOptions
    TraceLog::kInternalRecordContinuously = 1 << 1;
const TraceLog::InternalTraceOptions
    TraceLog::kInternalEnableSampling = 1 << 2;
const TraceLog::InternalTraceOptions
    TraceLog::kInternalEchoToConsole = 1 << 3;
const TraceLog::InternalTraceOptions
    TraceLog::kInternalRecordAsMuchAsPossible = 1 << 4;
const TraceLog::InternalTraceOptions
    TraceLog::kInternalEnableArgumentFilter = 1 << 5;

}  // namespace trace_event
}  // namespace base
