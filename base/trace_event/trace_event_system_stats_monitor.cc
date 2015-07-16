// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_system_stats_monitor.h"

#include "base/debug/leak_annotations.h"
#include "base/json/json_writer.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/thread_local_storage.h"
#include "base/trace_event/trace_event.h"

namespace base {
namespace trace_event {

namespace {

/////////////////////////////////////////////////////////////////////////////
// Holds profiled system stats until the tracing system needs to serialize it.
class SystemStatsHolder : public base::trace_event::ConvertableToTraceFormat {
 public:
  SystemStatsHolder() { }

  // Fills system_metrics_ with profiled system memory and disk stats.
  // Uses the previous stats to compute rates if this is not the first profile.
  void GetSystemProfilingStats();

  // base::trace_event::ConvertableToTraceFormat overrides:
  void AppendAsTraceFormat(std::string* out) const override {
    AppendSystemProfileAsTraceFormat(system_stats_, out);
  }

 private:
  ~SystemStatsHolder() override {}

  SystemMetrics system_stats_;

  DISALLOW_COPY_AND_ASSIGN(SystemStatsHolder);
};

void SystemStatsHolder::GetSystemProfilingStats() {
  system_stats_ = SystemMetrics::Sample();
}

}  // namespace

//////////////////////////////////////////////////////////////////////////////

TraceEventSystemStatsMonitor::TraceEventSystemStatsMonitor(
    scoped_refptr<SingleThreadTaskRunner> task_runner)
    : task_runner_(task_runner),
      weak_factory_(this) {
  // Force the "system_stats" category to show up in the trace viewer.
  TraceLog::GetCategoryGroupEnabled(TRACE_DISABLED_BY_DEFAULT("system_stats"));

  // Allow this to be instantiated on unsupported platforms, but don't run.
  TraceLog::GetInstance()->AddEnabledStateObserver(this);
}

TraceEventSystemStatsMonitor::~TraceEventSystemStatsMonitor() {
  if (dump_timer_.IsRunning())
    StopProfiling();
  TraceLog::GetInstance()->RemoveEnabledStateObserver(this);
}

void TraceEventSystemStatsMonitor::OnTraceLogEnabled() {
  // Check to see if system tracing is enabled.
  bool enabled;

  TRACE_EVENT_CATEGORY_GROUP_ENABLED(TRACE_DISABLED_BY_DEFAULT(
                                     "system_stats"), &enabled);
  if (!enabled)
    return;
  task_runner_->PostTask(
      FROM_HERE,
      base::Bind(&TraceEventSystemStatsMonitor::StartProfiling,
                 weak_factory_.GetWeakPtr()));
}

void TraceEventSystemStatsMonitor::OnTraceLogDisabled() {
  task_runner_->PostTask(
      FROM_HERE,
      base::Bind(&TraceEventSystemStatsMonitor::StopProfiling,
                 weak_factory_.GetWeakPtr()));
}

void TraceEventSystemStatsMonitor::StartProfiling() {
  // Watch for the tracing framework sending enabling more than once.
  if (dump_timer_.IsRunning())
    return;

  dump_timer_.Start(FROM_HERE,
                    TimeDelta::FromMilliseconds(TraceEventSystemStatsMonitor::
                                                kSamplingIntervalMilliseconds),
                    base::Bind(&TraceEventSystemStatsMonitor::
                               DumpSystemStats,
                               weak_factory_.GetWeakPtr()));
}

// If system tracing is enabled, dumps a profile to the tracing system.
void TraceEventSystemStatsMonitor::DumpSystemStats() {
  scoped_refptr<SystemStatsHolder> dump_holder = new SystemStatsHolder();
  dump_holder->GetSystemProfilingStats();

  TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID(
      TRACE_DISABLED_BY_DEFAULT("system_stats"),
      "base::TraceEventSystemStatsMonitor::SystemStats",
      this,
      scoped_refptr<ConvertableToTraceFormat>(dump_holder));
}

void TraceEventSystemStatsMonitor::StopProfiling() {
  dump_timer_.Stop();
}

bool TraceEventSystemStatsMonitor::IsTimerRunningForTest() const {
  return dump_timer_.IsRunning();
}

void AppendSystemProfileAsTraceFormat(const SystemMetrics& system_metrics,
                                      std::string* output) {
  std::string tmp;
  base::JSONWriter::Write(*system_metrics.ToValue(), &tmp);
  *output += tmp;
}

}  // namespace trace_event
}  // namespace base
