// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MEMORY_MEMORY_PRESSURE_MONITOR_WIN_H_
#define BASE_MEMORY_MEMORY_PRESSURE_MONITOR_WIN_H_

#include "base/base_export.h"
#include "base/memory/memory_pressure_listener.h"
#include "base/memory/memory_pressure_monitor.h"
#include "base/memory/weak_ptr.h"
#include "base/threading/thread_checker.h"
#include "base/timer/timer.h"

// To not pull in windows.h.
typedef struct _MEMORYSTATUSEX MEMORYSTATUSEX;

namespace base {
namespace win {

// Windows memory pressure monitor. Because there is no OS provided signal this
// polls at a low frequency (once per second), and applies internal hysteresis.
class BASE_EXPORT MemoryPressureMonitor : public base::MemoryPressureMonitor {
 public:
  // Constants governing the polling and hysteresis behaviour of the observer.

  // The polling interval, in milliseconds. While under critical pressure, this
  // is also the timer to repeat cleanup attempts.
  static const int kPollingIntervalMs;
  // The time which should pass between 2 successive moderate memory pressure
  // signals, in milliseconds.
  static const int kModeratePressureCooldownMs;
  // The number of cycles that should pass between 2 successive moderate memory
  // pressure signals.
  static const int kModeratePressureCooldownCycles;

  // Constants governing the memory pressure level detection.

  // The amount of total system memory beyond which a system is considered to be
  // a large-memory system.
  static const int kLargeMemoryThresholdMb;
  // Default minimum free memory thresholds for small-memory systems, in MB.
  static const int kSmallMemoryDefaultModerateThresholdMb;
  static const int kSmallMemoryDefaultCriticalThresholdMb;
  // Default minimum free memory thresholds for large-memory systems, in MB.
  static const int kLargeMemoryDefaultModerateThresholdMb;
  static const int kLargeMemoryDefaultCriticalThresholdMb;

  // Default constructor. Will choose thresholds automatically basd on the
  // actual amount of system memory.
  MemoryPressureMonitor();

  // Constructor with explicit memory thresholds. These represent the amount of
  // free memory below which the applicable memory pressure state engages.
  MemoryPressureMonitor(int moderate_threshold_mb, int critical_threshold_mb);

  ~MemoryPressureMonitor() override;

  // Schedules a memory pressure check to run soon. This must be called on the
  // same thread where the monitor was instantiated.
  void CheckMemoryPressureSoon();

  // Get the current memory pressure level. This can be called from any thread.
  MemoryPressureLevel GetCurrentPressureLevel() const override;

  // Returns the moderate pressure level free memory threshold, in MB.
  int moderate_threshold_mb() const { return moderate_threshold_mb_; }

  // Returns the critical pressure level free memory threshold, in MB.
  int critical_threshold_mb() const { return critical_threshold_mb_; }

 protected:
  // Internals are exposed for unittests.

  // Automatically infers threshold values based on system memory. This invokes
  // GetMemoryStatus so it can be mocked in unittests.
  void InferThresholds();

  // Starts observing the memory fill level. Calls to StartObserving should
  // always be matched with calls to StopObserving.
  void StartObserving();

  // Stop observing the memory fill level. May be safely called if
  // StartObserving has not been called. Must be called from the same thread on
  // which the monitor was instantiated.
  void StopObserving();

  // Checks memory pressure, storing the current level, applying any hysteresis
  // and emitting memory pressure level change signals as necessary. This
  // function is called periodically while the monitor is observing memory
  // pressure. This is split out from CheckMemoryPressureAndRecordStatistics so
  // that it may be called by CheckMemoryPressureSoon and not invoke UMA
  // logging. Must be called from the same thread on which the monitor was
  // instantiated.
  void CheckMemoryPressure();

  // Wrapper to CheckMemoryPressure that also records the observed memory
  // pressure level via an UMA enumeration. This is the function that is called
  // periodically by the timer. Must be called from the same thread on which the
  // monitor was instantiated.
  void CheckMemoryPressureAndRecordStatistics();

  // Calculates the current instantaneous memory pressure level. This does not
  // use any hysteresis and simply returns the result at the current moment. Can
  // be called on any thread.
  MemoryPressureLevel CalculateCurrentPressureLevel();

  // Gets system memory status. This is virtual as a unittesting hook. Returns
  // true if the system call succeeds, false otherwise. Can be called on any
  // thread.
  virtual bool GetSystemMemoryStatus(MEMORYSTATUSEX* mem_status);

 private:
  // Threshold amounts of available memory that trigger pressure levels. See
  // memory_pressure_monitor.cc for a discussion of reasonable values for these.
  int moderate_threshold_mb_;
  int critical_threshold_mb_;

  // A periodic timer to check for memory pressure changes.
  base::RepeatingTimer<MemoryPressureMonitor> timer_;

  // The current memory pressure.
  MemoryPressureLevel current_memory_pressure_level_;

  // To slow down the amount of moderate pressure event calls, this gets used to
  // count the number of events since the last event occured. This is used by
  // |CheckMemoryPressure| to apply hysteresis on the raw results of
  // |CalculateCurrentPressureLevel|.
  int moderate_pressure_repeat_count_;

  // Ensures that this object is used from a single thread.
  base::ThreadChecker thread_checker_;

  // Weak pointer factory to ourself used for scheduling calls to
  // CheckMemoryPressure/CheckMemoryPressureAndRecordStatistics via |timer_|.
  base::WeakPtrFactory<MemoryPressureMonitor> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(MemoryPressureMonitor);
};

}  // namespace win
}  // namespace base

#endif  // BASE_MEMORY_MEMORY_PRESSURE_MONITOR_WIN_H_
