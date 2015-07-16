// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/memory_pressure_monitor_win.h"

#include <windows.h>

#include "base/metrics/histogram_macros.h"
#include "base/single_thread_task_runner.h"
#include "base/thread_task_runner_handle.h"
#include "base/time/time.h"

namespace base {
namespace win {

namespace {

static const DWORDLONG kMBBytes = 1024 * 1024;

// Enumeration of UMA memory pressure levels. This needs to be kept in sync with
// histograms.xml and the memory pressure levels defined in
// MemoryPressureListener.
enum MemoryPressureLevelUMA {
  UMA_MEMORY_PRESSURE_LEVEL_NONE = 0,
  UMA_MEMORY_PRESSURE_LEVEL_MODERATE = 1,
  UMA_MEMORY_PRESSURE_LEVEL_CRITICAL = 2,
  // This must be the last value in the enum.
  UMA_MEMORY_PRESSURE_LEVEL_COUNT,
};

// Converts a memory pressure level to an UMA enumeration value.
MemoryPressureLevelUMA MemoryPressureLevelToUmaEnumValue(
    MemoryPressureListener::MemoryPressureLevel level) {
  switch (level) {
    case MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE:
      return UMA_MEMORY_PRESSURE_LEVEL_NONE;
    case MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE:
      return UMA_MEMORY_PRESSURE_LEVEL_MODERATE;
    case MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL:
      return UMA_MEMORY_PRESSURE_LEVEL_CRITICAL;
  }
  NOTREACHED();
  return UMA_MEMORY_PRESSURE_LEVEL_NONE;
}

}  // namespace

// The following constants have been lifted from similar values in the ChromeOS
// memory pressure monitor. The values were determined experimentally to ensure
// sufficient responsiveness of the memory pressure subsystem, and minimal
// overhead.
const int MemoryPressureMonitor::kPollingIntervalMs = 5000;
const int MemoryPressureMonitor::kModeratePressureCooldownMs = 10000;
const int MemoryPressureMonitor::kModeratePressureCooldownCycles =
    kModeratePressureCooldownMs / kPollingIntervalMs;

// TODO(chrisha): Explore the following constants further with an experiment.

// A system is considered 'high memory' if it has more than 1.5GB of system
// memory available for use by the memory manager (not reserved for hardware
// and drivers). This is a fuzzy version of the ~2GB discussed below.
const int MemoryPressureMonitor::kLargeMemoryThresholdMb = 1536;

// These are the default thresholds used for systems with < ~2GB of physical
// memory. Such systems have been observed to always maintain ~100MB of
// available memory, paging until that is the case. To try to avoid paging a
// threshold slightly above this is chosen. The moderate threshold is slightly
// less grounded in reality and chosen as 2.5x critical.
const int MemoryPressureMonitor::kSmallMemoryDefaultModerateThresholdMb = 500;
const int MemoryPressureMonitor::kSmallMemoryDefaultCriticalThresholdMb = 200;

// These are the default thresholds used for systems with >= ~2GB of physical
// memory. Such systems have been observed to always maintain ~300MB of
// available memory, paging until that is the case.
const int MemoryPressureMonitor::kLargeMemoryDefaultModerateThresholdMb = 1000;
const int MemoryPressureMonitor::kLargeMemoryDefaultCriticalThresholdMb = 400;

MemoryPressureMonitor::MemoryPressureMonitor()
    : moderate_threshold_mb_(0),
      critical_threshold_mb_(0),
      current_memory_pressure_level_(
          MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE),
      moderate_pressure_repeat_count_(0),
      weak_ptr_factory_(this) {
  InferThresholds();
  StartObserving();
}

MemoryPressureMonitor::MemoryPressureMonitor(int moderate_threshold_mb,
                                             int critical_threshold_mb)
    : moderate_threshold_mb_(moderate_threshold_mb),
      critical_threshold_mb_(critical_threshold_mb),
      current_memory_pressure_level_(
          MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE),
      moderate_pressure_repeat_count_(0),
      weak_ptr_factory_(this) {
  DCHECK_GE(moderate_threshold_mb_, critical_threshold_mb_);
  DCHECK_LE(0, critical_threshold_mb_);
  StartObserving();
}

MemoryPressureMonitor::~MemoryPressureMonitor() {
  StopObserving();
}

void MemoryPressureMonitor::CheckMemoryPressureSoon() {
  DCHECK(thread_checker_.CalledOnValidThread());

  ThreadTaskRunnerHandle::Get()->PostTask(
      FROM_HERE, Bind(&MemoryPressureMonitor::CheckMemoryPressure,
                      weak_ptr_factory_.GetWeakPtr()));
}

MemoryPressureListener::MemoryPressureLevel
MemoryPressureMonitor::GetCurrentPressureLevel() const {
  return current_memory_pressure_level_;
}

void MemoryPressureMonitor::InferThresholds() {
  // Default to a 'high' memory situation, which uses more conservative
  // thresholds.
  bool high_memory = true;
  MEMORYSTATUSEX mem_status = {};
  if (GetSystemMemoryStatus(&mem_status)) {
    static const DWORDLONG kLargeMemoryThresholdBytes =
        static_cast<DWORDLONG>(kLargeMemoryThresholdMb) * kMBBytes;
    high_memory = mem_status.ullTotalPhys >= kLargeMemoryThresholdBytes;
  }

  if (high_memory) {
    moderate_threshold_mb_ = kLargeMemoryDefaultModerateThresholdMb;
    critical_threshold_mb_ = kLargeMemoryDefaultCriticalThresholdMb;
  } else {
    moderate_threshold_mb_ = kSmallMemoryDefaultModerateThresholdMb;
    critical_threshold_mb_ = kSmallMemoryDefaultCriticalThresholdMb;
  }
}

void MemoryPressureMonitor::StartObserving() {
  DCHECK(thread_checker_.CalledOnValidThread());

  timer_.Start(FROM_HERE,
               TimeDelta::FromMilliseconds(kPollingIntervalMs),
               Bind(&MemoryPressureMonitor::
                        CheckMemoryPressureAndRecordStatistics,
                    weak_ptr_factory_.GetWeakPtr()));
}

void MemoryPressureMonitor::StopObserving() {
  DCHECK(thread_checker_.CalledOnValidThread());

  // If StartObserving failed, StopObserving will still get called.
  timer_.Stop();
  weak_ptr_factory_.InvalidateWeakPtrs();
}

void MemoryPressureMonitor::CheckMemoryPressure() {
  DCHECK(thread_checker_.CalledOnValidThread());

  // Get the previous pressure level and update the current one.
  MemoryPressureLevel old_pressure = current_memory_pressure_level_;
  current_memory_pressure_level_ = CalculateCurrentPressureLevel();

  // |notify| will be set to true if MemoryPressureListeners need to be
  // notified of a memory pressure level state change.
  bool notify = false;
  switch (current_memory_pressure_level_) {
    case MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE:
      break;

    case MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE:
      if (old_pressure != current_memory_pressure_level_) {
        // This is a new transition to moderate pressure so notify.
        moderate_pressure_repeat_count_ = 0;
        notify = true;
      } else {
        // Already in moderate pressure, only notify if sustained over the
        // cooldown period.
        if (++moderate_pressure_repeat_count_ ==
                kModeratePressureCooldownCycles) {
          moderate_pressure_repeat_count_ = 0;
          notify = true;
        }
      }
      break;

    case MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL:
      // Always notify of critical pressure levels.
      notify = true;
      break;
  }

  if (!notify)
    return;

  // Emit a notification of the current memory pressure level. This can only
  // happen for moderate and critical pressure levels.
  DCHECK_NE(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            current_memory_pressure_level_);
  MemoryPressureListener::NotifyMemoryPressure(current_memory_pressure_level_);
}

void MemoryPressureMonitor::CheckMemoryPressureAndRecordStatistics() {
  DCHECK(thread_checker_.CalledOnValidThread());

  CheckMemoryPressure();

  UMA_HISTOGRAM_ENUMERATION(
      "Memory.PressureLevel",
      MemoryPressureLevelToUmaEnumValue(current_memory_pressure_level_),
      UMA_MEMORY_PRESSURE_LEVEL_COUNT);
}

MemoryPressureListener::MemoryPressureLevel
MemoryPressureMonitor::CalculateCurrentPressureLevel() {
  MEMORYSTATUSEX mem_status = {};
  if (!GetSystemMemoryStatus(&mem_status))
    return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE;

  // How much system memory is actively available for use right now, in MBs.
  int phys_free = static_cast<int>(mem_status.ullAvailPhys / kMBBytes);

  // TODO(chrisha): This should eventually care about address space pressure,
  // but the browser process (where this is running) effectively never runs out
  // of address space. Renderers occasionally do, but it does them no good to
  // have the browser process monitor address space pressure. Long term,
  // renderers should run their own address space pressure monitors and act
  // accordingly, with the browser making cross-process decisions based on
  // system memory pressure.

  // Determine if the physical memory is under critical memory pressure.
  if (phys_free <= critical_threshold_mb_)
    return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL;

  // Determine if the physical memory is under moderate memory pressure.
  if (phys_free <= moderate_threshold_mb_)
    return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE;

  // No memory pressure was detected.
  return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE;
}

bool MemoryPressureMonitor::GetSystemMemoryStatus(
    MEMORYSTATUSEX* mem_status) {
  DCHECK(mem_status != nullptr);
  mem_status->dwLength = sizeof(*mem_status);
  if (!::GlobalMemoryStatusEx(mem_status))
    return false;
  return true;
}

}  // namespace win
}  // namespace base
