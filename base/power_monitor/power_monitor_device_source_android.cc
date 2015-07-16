// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/power_monitor/power_monitor_device_source_android.h"

#include "base/power_monitor/power_monitor.h"
#include "base/power_monitor/power_monitor_device_source.h"
#include "base/power_monitor/power_monitor_source.h"
#include "jni/PowerMonitor_jni.h"

namespace base {

// A helper function which is a friend of PowerMonitorSource.
void ProcessPowerEventHelper(PowerMonitorSource::PowerEvent event) {
  PowerMonitorSource::ProcessPowerEvent(event);
}

namespace android {

// Native implementation of PowerMonitor.java.
void OnBatteryChargingChanged(JNIEnv* env, jclass clazz) {
  ProcessPowerEventHelper(PowerMonitorSource::POWER_STATE_EVENT);
}

void OnMainActivityResumed(JNIEnv* env, jclass clazz) {
  ProcessPowerEventHelper(PowerMonitorSource::RESUME_EVENT);
}

void OnMainActivitySuspended(JNIEnv* env, jclass clazz) {
  ProcessPowerEventHelper(PowerMonitorSource::SUSPEND_EVENT);
}

}  // namespace android

bool PowerMonitorDeviceSource::IsOnBatteryPowerImpl() {
  JNIEnv* env = base::android::AttachCurrentThread();
  return base::android::Java_PowerMonitor_isBatteryPower(env);
}

bool RegisterPowerMonitor(JNIEnv* env) {
  return base::android::RegisterNativesImpl(env);
}

}  // namespace base
