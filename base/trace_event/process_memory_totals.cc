// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/process_memory_totals.h"

#include "base/format_macros.h"
#include "base/strings/stringprintf.h"
#include "base/trace_event/trace_event_argument.h"

namespace base {
namespace trace_event {

ProcessMemoryTotals::ProcessMemoryTotals()
    : resident_set_bytes_(0),
      peak_resident_set_bytes_(0),
      is_peak_rss_resetable_(false) {
}

void ProcessMemoryTotals::AsValueInto(TracedValue* value) const {
  value->SetString("resident_set_bytes",
                   StringPrintf("%" PRIx64, resident_set_bytes_));
  if (peak_resident_set_bytes_ > 0) {
    value->SetString("peak_resident_set_bytes",
                     StringPrintf("%" PRIx64, peak_resident_set_bytes_));
    value->SetBoolean("is_peak_rss_resetable", is_peak_rss_resetable_);
  }
}

void ProcessMemoryTotals::Clear() {
  resident_set_bytes_ = 0;
}

}  // namespace trace_event
}  // namespace base
