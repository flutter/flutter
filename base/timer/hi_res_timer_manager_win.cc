// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/timer/hi_res_timer_manager.h"

#include "base/power_monitor/power_monitor.h"
#include "base/time/time.h"

namespace base {

HighResolutionTimerManager::HighResolutionTimerManager()
    : hi_res_clock_available_(false) {
  base::PowerMonitor* power_monitor = base::PowerMonitor::Get();
  DCHECK(power_monitor != NULL);
  power_monitor->AddObserver(this);
  UseHiResClock(!power_monitor->IsOnBatteryPower());
}

HighResolutionTimerManager::~HighResolutionTimerManager() {
  base::PowerMonitor::Get()->RemoveObserver(this);
  UseHiResClock(false);
}

void HighResolutionTimerManager::OnPowerStateChange(bool on_battery_power) {
  UseHiResClock(!on_battery_power);
}

void HighResolutionTimerManager::UseHiResClock(bool use) {
  if (use == hi_res_clock_available_)
    return;
  hi_res_clock_available_ = use;
  base::Time::EnableHighResolutionTimer(use);
}

}  // namespace base
