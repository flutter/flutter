// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_TRACE_EVENT_SYSTEM_STATS_MONITOR_H_
#define BASE_TRACE_EVENT_TRACE_EVENT_SYSTEM_STATS_MONITOR_H_

#include "base/base_export.h"
#include "base/gtest_prod_util.h"
#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "base/process/process_metrics.h"
#include "base/timer/timer.h"
#include "base/trace_event/trace_event_impl.h"

namespace base {

class SingleThreadTaskRunner;

namespace trace_event {

// Watches for chrome://tracing to be enabled or disabled. When tracing is
// enabled, also enables system events profiling. This class is the preferred
// way to turn system tracing on and off.
class BASE_EXPORT TraceEventSystemStatsMonitor
    : public TraceLog::EnabledStateObserver {
 public:
  // Length of time interval between stat profiles.
  static const int kSamplingIntervalMilliseconds = 2000;

  // |task_runner| must be the primary thread for the client
  // process, e.g. the UI thread in a browser.
  explicit TraceEventSystemStatsMonitor(
      scoped_refptr<SingleThreadTaskRunner> task_runner);

  ~TraceEventSystemStatsMonitor() override;

  // base::trace_event::TraceLog::EnabledStateChangedObserver overrides:
  void OnTraceLogEnabled() override;
  void OnTraceLogDisabled() override;

  // Retrieves system profiling at the current time.
  void DumpSystemStats();

 private:
  FRIEND_TEST_ALL_PREFIXES(TraceSystemStatsMonitorTest,
                           TraceEventSystemStatsMonitor);

  bool IsTimerRunningForTest() const;

  void StartProfiling();

  void StopProfiling();

  // Ensures the observer starts and stops tracing on the primary thread.
  scoped_refptr<SingleThreadTaskRunner> task_runner_;

  // Timer to schedule system profile dumps.
  RepeatingTimer<TraceEventSystemStatsMonitor> dump_timer_;

  WeakPtrFactory<TraceEventSystemStatsMonitor> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(TraceEventSystemStatsMonitor);
};

// Converts system memory profiling stats in |input| to
// trace event compatible JSON and appends to |output|. Visible for testing.
BASE_EXPORT void AppendSystemProfileAsTraceFormat(const SystemMetrics&
                                                  system_stats,
                                                  std::string* output);

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_TRACE_EVENT_SYSTEM_STATS_MONITOR_H_
