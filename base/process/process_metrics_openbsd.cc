// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_metrics.h"

#include <sys/param.h>
#include <sys/sysctl.h>

namespace base {

// static
ProcessMetrics* ProcessMetrics::CreateProcessMetrics(ProcessHandle process) {
  return new ProcessMetrics(process);
}

size_t ProcessMetrics::GetPagefileUsage() const {
  struct kinfo_proc info;
  size_t length;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process_,
                sizeof(struct kinfo_proc), 0 };

  if (sysctl(mib, arraysize(mib), NULL, &length, NULL, 0) < 0)
    return -1;

  mib[5] = (length / sizeof(struct kinfo_proc));

  if (sysctl(mib, arraysize(mib), &info, &length, NULL, 0) < 0)
    return -1;

  return (info.p_vm_tsize + info.p_vm_dsize + info.p_vm_ssize);
}

size_t ProcessMetrics::GetPeakPagefileUsage() const {
  return 0;
}

size_t ProcessMetrics::GetWorkingSetSize() const {
  struct kinfo_proc info;
  size_t length;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process_,
                sizeof(struct kinfo_proc), 0 };

  if (sysctl(mib, arraysize(mib), NULL, &length, NULL, 0) < 0)
    return -1;

  mib[5] = (length / sizeof(struct kinfo_proc));

  if (sysctl(mib, arraysize(mib), &info, &length, NULL, 0) < 0)
    return -1;

  return info.p_vm_rssize * getpagesize();
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
  // TODO(bapt): be sure we can't be precise
  size_t priv = GetWorkingSetSize();
  if (!priv)
    return false;
  ws_usage->priv = priv / 1024;
  ws_usage->shareable = 0;
  ws_usage->shared = 0;

  return true;
}

bool ProcessMetrics::GetIOCounters(IoCounters* io_counters) const {
  return false;
}

static int GetProcessCPU(pid_t pid) {
  struct kinfo_proc info;
  size_t length;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid,
                sizeof(struct kinfo_proc), 0 };

  if (sysctl(mib, arraysize(mib), NULL, &length, NULL, 0) < 0)
    return -1;

  mib[5] = (length / sizeof(struct kinfo_proc));

  if (sysctl(mib, arraysize(mib), &info, &length, NULL, 0) < 0)
    return 0;

  return info.p_pctcpu;
}

double ProcessMetrics::GetCPUUsage() {
  TimeTicks time = TimeTicks::Now();

  if (last_cpu_ == 0) {
    // First call, just set the last values.
    last_cpu_time_ = time;
    last_cpu_ = GetProcessCPU(process_);
    return 0;
  }

  int64 time_delta = (time - last_cpu_time_).InMicroseconds();
  DCHECK_NE(time_delta, 0);

  if (time_delta == 0)
    return 0;

  int cpu = GetProcessCPU(process_);

  last_cpu_time_ = time;
  last_cpu_ = cpu;

  double percentage = static_cast<double>((cpu * 100.0) / FSCALE);

  return percentage;
}

ProcessMetrics::ProcessMetrics(ProcessHandle process)
    : process_(process),
      last_system_time_(0),
      last_cpu_(0) {

  processor_count_ = base::SysInfo::NumberOfProcessors();
}

size_t GetSystemCommitCharge() {
  int mib[] = { CTL_VM, VM_METER };
  int pagesize;
  struct vmtotal vmtotal;
  unsigned long mem_total, mem_free, mem_inactive;
  size_t len = sizeof(vmtotal);

  if (sysctl(mib, arraysize(mib), &vmtotal, &len, NULL, 0) < 0)
    return 0;

  mem_total = vmtotal.t_vm;
  mem_free = vmtotal.t_free;
  mem_inactive = vmtotal.t_vm - vmtotal.t_avm;

  pagesize = getpagesize();

  return mem_total - (mem_free*pagesize) - (mem_inactive*pagesize);
}

}  // namespace base
