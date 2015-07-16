// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/process_memory_totals_dump_provider.h"

#include "base/process/process_metrics.h"
#include "base/trace_event/process_memory_dump.h"
#include "base/trace_event/process_memory_totals.h"

#if defined(OS_LINUX) || defined(OS_ANDROID)
#include <fcntl.h>

#include "base/files/file_util.h"

namespace {
bool kernel_supports_rss_peak_reset = true;
const char kClearPeakRssCommand[] = "5";
}
#endif

namespace base {
namespace trace_event {

// static
uint64 ProcessMemoryTotalsDumpProvider::rss_bytes_for_testing = 0;

namespace {

ProcessMetrics* CreateProcessMetricsForCurrentProcess() {
#if !defined(OS_MACOSX) || defined(OS_IOS)
  return ProcessMetrics::CreateProcessMetrics(GetCurrentProcessHandle());
#else
  return ProcessMetrics::CreateProcessMetrics(GetCurrentProcessHandle(), NULL);
#endif
}
}  // namespace

// static
ProcessMemoryTotalsDumpProvider*
ProcessMemoryTotalsDumpProvider::GetInstance() {
  return Singleton<
      ProcessMemoryTotalsDumpProvider,
      LeakySingletonTraits<ProcessMemoryTotalsDumpProvider>>::get();
}

ProcessMemoryTotalsDumpProvider::ProcessMemoryTotalsDumpProvider()
    : process_metrics_(CreateProcessMetricsForCurrentProcess()) {
}

ProcessMemoryTotalsDumpProvider::~ProcessMemoryTotalsDumpProvider() {
}

// Called at trace dump point time. Creates a snapshot the memory counters for
// the current process.
bool ProcessMemoryTotalsDumpProvider::OnMemoryDump(ProcessMemoryDump* pmd) {
  const uint64 rss_bytes = rss_bytes_for_testing
                               ? rss_bytes_for_testing
                               : process_metrics_->GetWorkingSetSize();

  uint64 peak_rss_bytes = 0;

#if !defined(OS_IOS)
  peak_rss_bytes = process_metrics_->GetPeakWorkingSetSize();
#if defined(OS_LINUX) || defined(OS_ANDROID)
  if (kernel_supports_rss_peak_reset) {
    // TODO(ssid): Fix crbug.com/461788 to write to the file from sandboxed
    // processes.
    int clear_refs_fd = open("/proc/self/clear_refs", O_WRONLY);
    if (clear_refs_fd > 0 &&
        WriteFileDescriptor(clear_refs_fd, kClearPeakRssCommand,
                            sizeof(kClearPeakRssCommand))) {
      pmd->process_totals()->set_is_peak_rss_resetable(true);
    } else {
      kernel_supports_rss_peak_reset = false;
    }
    close(clear_refs_fd);
  }
#endif  // defined(OS_LINUX) || defined(OS_ANDROID)
#endif  // !defined(OS_IOS)

  if (rss_bytes > 0) {
    pmd->process_totals()->set_resident_set_bytes(rss_bytes);
    pmd->process_totals()->set_peak_resident_set_bytes(peak_rss_bytes);
    pmd->set_has_process_totals();
    return true;
  }

  return false;
}

}  // namespace trace_event
}  // namespace base
