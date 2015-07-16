// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/power_monitor/power_monitor.h"
#include "base/power_monitor/power_monitor_device_source.h"
#include "base/power_monitor/power_monitor_source.h"

namespace base {

namespace {

// The most-recently-seen power source.
bool g_on_battery = false;

}  // namespace

// static
void PowerMonitorDeviceSource::SetPowerSource(bool on_battery) {
  if (on_battery != g_on_battery) {
    g_on_battery = on_battery;
    ProcessPowerEvent(POWER_STATE_EVENT);
  }
}

// static
void PowerMonitorDeviceSource::HandleSystemSuspending() {
  ProcessPowerEvent(SUSPEND_EVENT);
}

// static
void PowerMonitorDeviceSource::HandleSystemResumed() {
  ProcessPowerEvent(RESUME_EVENT);
}

bool PowerMonitorDeviceSource::IsOnBatteryPowerImpl() {
  return g_on_battery;
}

}  // namespace base
