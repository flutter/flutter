// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MEMORY_MEMORY_PRESSURE_MONITOR_CHROMEOS_H_
#define BASE_MEMORY_MEMORY_PRESSURE_MONITOR_CHROMEOS_H_

#include "base/base_export.h"
#include "base/files/scoped_file.h"
#include "base/gtest_prod_util.h"
#include "base/macros.h"
#include "base/memory/memory_pressure_listener.h"
#include "base/memory/memory_pressure_monitor.h"
#include "base/memory/weak_ptr.h"
#include "base/timer/timer.h"

namespace base {
namespace chromeos {

class TestMemoryPressureMonitor;

////////////////////////////////////////////////////////////////////////////////
// MemoryPressureMonitor
//
// A class to handle the observation of our free memory. It notifies the
// MemoryPressureListener of memory fill level changes, so that it can take
// action to reduce memory resources accordingly.
//
class BASE_EXPORT MemoryPressureMonitor : public base::MemoryPressureMonitor {
 public:
  using GetUsedMemoryInPercentCallback = int (*)();

  // There are two memory pressure events:
  // MODERATE - which will mainly release caches.
  // CRITICAL - which will discard tabs.
  // The |MemoryPressureThresholds| enum selects the strategy of firing these
  // events: A conservative strategy will keep as much content in memory as
  // possible (causing the system to swap to zram) and an aggressive strategy
  // will release memory earlier to avoid swapping.
  enum MemoryPressureThresholds {
    // Use the system default.
    THRESHOLD_DEFAULT = 0,
    // Try to keep as much content in memory as possible.
    THRESHOLD_CONSERVATIVE = 1,
    // Discard caches earlier, allowing to keep more tabs in memory.
    THRESHOLD_AGGRESSIVE_CACHE_DISCARD = 2,
    // Discard tabs earlier, allowing the system to get faster.
    THRESHOLD_AGGRESSIVE_TAB_DISCARD = 3,
    // Discard caches and tabs earlier to allow the system to be faster.
    THRESHOLD_AGGRESSIVE = 4
  };

  explicit MemoryPressureMonitor(MemoryPressureThresholds thresholds);
  ~MemoryPressureMonitor() override;

  // Redo the memory pressure calculation soon and call again if a critical
  // memory pressure prevails. Note that this call will trigger an asynchronous
  // action which gives the system time to release memory back into the pool.
  void ScheduleEarlyCheck();

  // Get the current memory pressure level.
  MemoryPressureListener::MemoryPressureLevel GetCurrentPressureLevel() const
      override;

  // Returns a type-casted version of the current memory pressure monitor. A
  // simple wrapper to base::MemoryPressureMonitor::Get.
  static MemoryPressureMonitor* Get();

 private:
  friend TestMemoryPressureMonitor;
  // Starts observing the memory fill level.
  // Calls to StartObserving should always be matched with calls to
  // StopObserving.
  void StartObserving();

  // Stop observing the memory fill level.
  // May be safely called if StartObserving has not been called.
  void StopObserving();

  // The function which gets periodically called to check any changes in the
  // memory pressure. It will report pressure changes as well as continuous
  // critical pressure levels.
  void CheckMemoryPressure();

  // The function periodically checks the memory pressure changes and records
  // the UMA histogram statistics for the current memory pressure level.
  void CheckMemoryPressureAndRecordStatistics();

  // Get the memory pressure in percent (virtual for testing).
  virtual int GetUsedMemoryInPercent();

  // The current memory pressure.
  base::MemoryPressureListener::MemoryPressureLevel
      current_memory_pressure_level_;

  // A periodic timer to check for resource pressure changes. This will get
  // replaced by a kernel triggered event system (see crbug.com/381196).
  base::RepeatingTimer<MemoryPressureMonitor> timer_;

  // To slow down the amount of moderate pressure event calls, this counter
  // gets used to count the number of events since the last event occured.
  int moderate_pressure_repeat_count_;

  // The thresholds for moderate and critical pressure.
  const int moderate_pressure_threshold_percent_;
  const int critical_pressure_threshold_percent_;

  // File descriptor used to detect low memory condition.
  ScopedFD low_mem_file_;

  base::WeakPtrFactory<MemoryPressureMonitor> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(MemoryPressureMonitor);
};

}  // namespace chromeos
}  // namespace base

#endif  // BASE_MEMORY_MEMORY_PRESSURE_MONITOR_CHROMEOS_H_
