// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_POWER_MONITOR_POWER_MONITOR_SOURCE_H_
#define BASE_POWER_MONITOR_POWER_MONITOR_SOURCE_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/memory/ref_counted.h"
#include "base/observer_list_threadsafe.h"
#include "base/synchronization/lock.h"

namespace base {

class PowerMonitor;

// Communicates power state changes to the power monitor.
class BASE_EXPORT PowerMonitorSource {
 public:
  PowerMonitorSource();
  virtual ~PowerMonitorSource();

  // Normalized list of power events.
  enum PowerEvent {
    POWER_STATE_EVENT,  // The Power status of the system has changed.
    SUSPEND_EVENT,      // The system is being suspended.
    RESUME_EVENT        // The system is being resumed.
  };

  // Is the computer currently on battery power. Can be called on any thread.
  bool IsOnBatteryPower();

 protected:
  friend class PowerMonitorTest;

  // Friend function that is allowed to access the protected ProcessPowerEvent.
  friend void ProcessPowerEventHelper(PowerEvent);

  // Get the process-wide PowerMonitorSource (if not present, returns NULL).
  static PowerMonitorSource* Get();

  // ProcessPowerEvent should only be called from a single thread, most likely
  // the UI thread or, in child processes, the IO thread.
  static void ProcessPowerEvent(PowerEvent event_id);

  // Platform-specific method to check whether the system is currently
  // running on battery power.  Returns true if running on batteries,
  // false otherwise.
  virtual bool IsOnBatteryPowerImpl() = 0;

 private:
  bool on_battery_power_;
  bool suspended_;

  // This lock guards access to on_battery_power_, to ensure that
  // IsOnBatteryPower can be called from any thread.
  Lock battery_lock_;

  DISALLOW_COPY_AND_ASSIGN(PowerMonitorSource);
};

}  // namespace base

#endif  // BASE_POWER_MONITOR_POWER_MONITOR_SOURCE_H_
