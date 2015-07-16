// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/power_monitor_test_base.h"

#include "base/message_loop/message_loop.h"
#include "base/power_monitor/power_monitor.h"
#include "base/power_monitor/power_monitor_source.h"

namespace base {

PowerMonitorTestSource::PowerMonitorTestSource()
    : test_on_battery_power_(false) {
}

PowerMonitorTestSource::~PowerMonitorTestSource() {
}

void PowerMonitorTestSource::GeneratePowerStateEvent(bool on_battery_power) {
  test_on_battery_power_ = on_battery_power;
  ProcessPowerEvent(POWER_STATE_EVENT);
  message_loop_.RunUntilIdle();
}

void PowerMonitorTestSource::GenerateSuspendEvent() {
  ProcessPowerEvent(SUSPEND_EVENT);
  message_loop_.RunUntilIdle();
}

void PowerMonitorTestSource::GenerateResumeEvent() {
  ProcessPowerEvent(RESUME_EVENT);
  message_loop_.RunUntilIdle();
}

bool PowerMonitorTestSource::IsOnBatteryPowerImpl() {
  return test_on_battery_power_;
};

PowerMonitorTestObserver::PowerMonitorTestObserver()
    : last_power_state_(false),
      power_state_changes_(0),
      suspends_(0),
      resumes_(0) {
}

PowerMonitorTestObserver::~PowerMonitorTestObserver() {
}

// PowerObserver callbacks.
void PowerMonitorTestObserver::OnPowerStateChange(bool on_battery_power) {
  last_power_state_ = on_battery_power;
  power_state_changes_++;
}

void PowerMonitorTestObserver::OnSuspend() {
  suspends_++;
}

void PowerMonitorTestObserver::OnResume() {
  resumes_++;
}

}  // namespace base
