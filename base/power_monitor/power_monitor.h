// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_POWER_MONITOR_POWER_MONITOR_H_
#define BASE_POWER_MONITOR_POWER_MONITOR_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/memory/ref_counted.h"
#include "base/observer_list_threadsafe.h"
#include "base/power_monitor/power_observer.h"

namespace base {

class PowerMonitorSource;

// A class used to monitor the power state change and notify the observers about
// the change event.
class BASE_EXPORT PowerMonitor {
 public:
  // Takes ownership of |source|.
  explicit PowerMonitor(scoped_ptr<PowerMonitorSource> source);
  ~PowerMonitor();

  // Get the process-wide PowerMonitor (if not present, returns NULL).
  static PowerMonitor* Get();

  // Add and remove an observer.
  // Can be called from any thread.
  // Must not be called from within a notification callback.
  void AddObserver(PowerObserver* observer);
  void RemoveObserver(PowerObserver* observer);

  // Is the computer currently on battery power.
  bool IsOnBatteryPower();

 private:
  friend class PowerMonitorSource;

  PowerMonitorSource* Source();

  void NotifyPowerStateChange(bool battery_in_use);
  void NotifySuspend();
  void NotifyResume();

  scoped_refptr<ObserverListThreadSafe<PowerObserver> > observers_;
  scoped_ptr<PowerMonitorSource> source_;

  DISALLOW_COPY_AND_ASSIGN(PowerMonitor);
};

}  // namespace base

#endif  // BASE_POWER_MONITOR_POWER_MONITOR_H_
