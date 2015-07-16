// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_POWER_MONITOR_POWER_MONITOR_DEVICE_SOURCE_ANDROID_H_
#define BASE_POWER_MONITOR_POWER_MONITOR_DEVICE_SOURCE_ANDROID_H_

#include <jni.h>

namespace base {

// Registers the JNI bindings for PowerMonitorDeviceSource.
bool RegisterPowerMonitor(JNIEnv* env);

}  // namespace base

#endif  // BASE_POWER_MONITOR_POWER_MONITOR_DEVICE_SOURCE_ANDROID_H_
