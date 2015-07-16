// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_metrics.h"

#include "base/logging.h"
#include "base/values.h"

namespace base {

SystemMetrics::SystemMetrics() {
  committed_memory_ = 0;
}

SystemMetrics SystemMetrics::Sample() {
  SystemMetrics system_metrics;

  system_metrics.committed_memory_ = GetSystemCommitCharge();
#if defined(OS_LINUX) || defined(OS_ANDROID)
  GetSystemMemoryInfo(&system_metrics.memory_info_);
  GetSystemDiskInfo(&system_metrics.disk_info_);
#endif
#if defined(OS_CHROMEOS)
  GetSwapInfo(&system_metrics.swap_info_);
#endif

  return system_metrics;
}

scoped_ptr<Value> SystemMetrics::ToValue() const {
  scoped_ptr<DictionaryValue> res(new DictionaryValue());

  res->SetInteger("committed_memory", static_cast<int>(committed_memory_));
#if defined(OS_LINUX) || defined(OS_ANDROID)
  res->Set("meminfo", memory_info_.ToValue());
  res->Set("diskinfo", disk_info_.ToValue());
#endif
#if defined(OS_CHROMEOS)
  res->Set("swapinfo", swap_info_.ToValue());
#endif

  return res.Pass();
}

double ProcessMetrics::GetPlatformIndependentCPUUsage() {
#if defined(OS_WIN)
  return GetCPUUsage() * processor_count_;
#else
  return GetCPUUsage();
#endif
}

#if defined(OS_MACOSX) || defined(OS_LINUX)
int ProcessMetrics::CalculateIdleWakeupsPerSecond(
    uint64 absolute_idle_wakeups) {
  TimeTicks time = TimeTicks::Now();

  if (last_absolute_idle_wakeups_ == 0) {
    // First call, just set the last values.
    last_idle_wakeups_time_ = time;
    last_absolute_idle_wakeups_ = absolute_idle_wakeups;
    return 0;
  }

  int64 wakeups_delta = absolute_idle_wakeups - last_absolute_idle_wakeups_;
  int64 time_delta = (time - last_idle_wakeups_time_).InMicroseconds();
  if (time_delta == 0) {
    NOTREACHED();
    return 0;
  }

  last_idle_wakeups_time_ = time;
  last_absolute_idle_wakeups_ = absolute_idle_wakeups;

  // Round to average wakeups per second.
  int64 wakeups_delta_for_ms = wakeups_delta * Time::kMicrosecondsPerSecond;
  return (wakeups_delta_for_ms + time_delta / 2) / time_delta;
}
#else
int ProcessMetrics::GetIdleWakeupsPerSecond() {
  NOTIMPLEMENTED();  // http://crbug.com/120488
  return 0;
}
#endif  // defined(OS_MACOSX) || defined(OS_LINUX)

}  // namespace base
