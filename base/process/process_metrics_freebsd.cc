// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_metrics.h"

#include <sys/sysctl.h>
#include <sys/user.h>
#include <unistd.h>

#include "base/sys_info.h"

namespace base {

ProcessMetrics::ProcessMetrics(ProcessHandle process)
    : process_(process),
      last_system_time_(0),
      last_cpu_(0) {
  processor_count_ = base::SysInfo::NumberOfProcessors();
}

// static
ProcessMetrics* ProcessMetrics::CreateProcessMetrics(ProcessHandle process) {
  return new ProcessMetrics(process);
}

size_t ProcessMetrics::GetPagefileUsage() const {
  struct kinfo_proc info;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process_ };
  size_t length = sizeof(info);

  if (sysctl(mib, arraysize(mib), &info, &length, NULL, 0) < 0)
    return 0;

  return info.ki_size;
}

size_t ProcessMetrics::GetPeakPagefileUsage() const {
  return 0;
}

size_t ProcessMetrics::GetWorkingSetSize() const {
  struct kinfo_proc info;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process_ };
  size_t length = sizeof(info);

  if (sysctl(mib, arraysize(mib), &info, &length, NULL, 0) < 0)
    return 0;

  return info.ki_rssize * getpagesize();
}

size_t ProcessMetrics::GetPeakWorkingSetSize() const {
  return 0;
}

bool ProcessMetrics::GetMemoryBytes(size_t* private_bytes,
                                    size_t* shared_bytes) {
  WorkingSetKBytes ws_usage;
  if (!GetWorkingSetKBytes(&ws_usage))
    return false;

  if (private_bytes)
    *private_bytes = ws_usage.priv << 10;

  if (shared_bytes)
    *shared_bytes = ws_usage.shared * 1024;

  return true;
}

bool ProcessMetrics::GetWorkingSetKBytes(WorkingSetKBytes* ws_usage) const {
// TODO(bapt) be sure we can't be precise
  size_t priv = GetWorkingSetSize();
  if (!priv)
    return false;
  ws_usage->priv = priv / 1024;
  ws_usage->shareable = 0;
  ws_usage->shared = 0;

  return true;
}

double ProcessMetrics::GetCPUUsage() {
  struct kinfo_proc info;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process_ };
  size_t length = sizeof(info);

  if (sysctl(mib, arraysize(mib), &info, &length, NULL, 0) < 0)
    return 0;

  return (info.ki_pctcpu / FSCALE) * 100.0;
}

bool ProcessMetrics::GetIOCounters(IoCounters* io_counters) const {
  return false;
}

size_t GetSystemCommitCharge() {
  int mib[2], pagesize;
  unsigned long mem_total, mem_free, mem_inactive;
  size_t length = sizeof(mem_total);

  if (sysctl(mib, arraysize(mib), &mem_total, &length, NULL, 0) < 0)
    return 0;

  length = sizeof(mem_free);
  if (sysctlbyname("vm.stats.vm.v_free_count", &mem_free, &length, NULL, 0) < 0)
    return 0;

  length = sizeof(mem_inactive);
  if (sysctlbyname("vm.stats.vm.v_inactive_count", &mem_inactive, &length,
      NULL, 0) < 0) {
    return 0;
  }

  pagesize = getpagesize();

  return mem_total - (mem_free*pagesize) - (mem_inactive*pagesize);
}

}  // namespace base
