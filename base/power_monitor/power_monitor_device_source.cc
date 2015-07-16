// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/power_monitor/power_monitor_device_source.h"

#include "base/time/time.h"

namespace base {

#if defined(ENABLE_BATTERY_MONITORING)
// The amount of time (in ms) to wait before running the initial
// battery check.
static int kDelayedBatteryCheckMs = 10 * 1000;
#endif  // defined(ENABLE_BATTERY_MONITORING)

PowerMonitorDeviceSource::PowerMonitorDeviceSource() {
  DCHECK(MessageLoop::current());
#if defined(ENABLE_BATTERY_MONITORING)
  delayed_battery_check_.Start(FROM_HERE,
      base::TimeDelta::FromMilliseconds(kDelayedBatteryCheckMs), this,
      &PowerMonitorDeviceSource::BatteryCheck);
#endif  // defined(ENABLE_BATTERY_MONITORING)
#if defined(OS_MACOSX)
  PlatformInit();
#endif
}

PowerMonitorDeviceSource::~PowerMonitorDeviceSource() {
#if defined(OS_MACOSX)
  PlatformDestroy();
#endif
}

void PowerMonitorDeviceSource::BatteryCheck() {
  ProcessPowerEvent(PowerMonitorSource::POWER_STATE_EVENT);
}

}  // namespace base
