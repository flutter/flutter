// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_PROCESS_MEMORY_TOTALS_H_
#define BASE_TRACE_EVENT_PROCESS_MEMORY_TOTALS_H_

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {
namespace trace_event {

class TracedValue;

// Data model for process-wide memory stats.
class BASE_EXPORT ProcessMemoryTotals {
 public:
  ProcessMemoryTotals();

  // Called at trace generation time to populate the TracedValue.
  void AsValueInto(TracedValue* value) const;

  // Clears up all the data collected.
  void Clear();

  uint64 resident_set_bytes() const { return resident_set_bytes_; }
  void set_resident_set_bytes(uint64 value) { resident_set_bytes_ = value; }

  uint64 peak_resident_set_bytes() const { return peak_resident_set_bytes_; }
  void set_peak_resident_set_bytes(uint64 value) {
    peak_resident_set_bytes_ = value;
  }

  // On some platforms (recent linux kernels, see goo.gl/sMvAVz) the peak rss
  // can be reset. When is_peak_rss_resettable == true, the peak refers to
  // peak from the previous measurement. When false, it is the absolute peak
  // since the start of the process.
  bool is_peak_rss_resetable() const { return is_peak_rss_resetable_; }
  void set_is_peak_rss_resetable(bool value) { is_peak_rss_resetable_ = value; }

 private:
  uint64 resident_set_bytes_;
  uint64 peak_resident_set_bytes_;
  bool is_peak_rss_resetable_;

  DISALLOW_COPY_AND_ASSIGN(ProcessMemoryTotals);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_PROCESS_MEMORY_TOTALS_H_
