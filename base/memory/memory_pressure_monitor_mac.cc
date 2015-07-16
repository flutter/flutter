// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/memory_pressure_monitor_mac.h"

#include <dlfcn.h>
#include <sys/sysctl.h>

#include "base/mac/mac_util.h"

namespace base {
namespace mac {

MemoryPressureListener::MemoryPressureLevel
MemoryPressureMonitor::MemoryPressureLevelForMacMemoryPressure(
    int mac_memory_pressure) {
  switch (mac_memory_pressure) {
    case DISPATCH_MEMORYPRESSURE_NORMAL:
      return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE;
    case DISPATCH_MEMORYPRESSURE_WARN:
      return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE;
    case DISPATCH_MEMORYPRESSURE_CRITICAL:
      return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL;
  }
  return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE;
}

void MemoryPressureMonitor::NotifyMemoryPressureChanged(
    dispatch_source_s* event_source) {
  int mac_memory_pressure = dispatch_source_get_data(event_source);
  MemoryPressureListener::MemoryPressureLevel memory_pressure_level =
      MemoryPressureLevelForMacMemoryPressure(mac_memory_pressure);
  MemoryPressureListener::NotifyMemoryPressure(memory_pressure_level);
}

MemoryPressureMonitor::MemoryPressureMonitor()
  : memory_level_event_source_(nullptr) {
  // _dispatch_source_type_memorypressure is not available prior to 10.9.
  dispatch_source_type_t dispatch_source_memorypressure =
      static_cast<dispatch_source_type_t>
          (dlsym(RTLD_NEXT, "_dispatch_source_type_memorypressure"));
  if (dispatch_source_memorypressure) {
    // The MemoryPressureListener doesn't want to know about transitions to
    // MEMORY_PRESSURE_LEVEL_NONE so don't watch for
    // DISPATCH_MEMORYPRESSURE_NORMAL notifications.
    memory_level_event_source_.reset(
        dispatch_source_create(dispatch_source_memorypressure, 0,
                               DISPATCH_MEMORYPRESSURE_WARN |
                                   DISPATCH_MEMORYPRESSURE_CRITICAL,
                               dispatch_get_global_queue(
                                   DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)));

    dispatch_source_set_event_handler(memory_level_event_source_.get(), ^{
        NotifyMemoryPressureChanged(memory_level_event_source_.get());
    });
    dispatch_retain(memory_level_event_source_.get());
    dispatch_resume(memory_level_event_source_.get());
  }
}

MemoryPressureMonitor::~MemoryPressureMonitor() {
}

MemoryPressureListener::MemoryPressureLevel
MemoryPressureMonitor::GetCurrentPressureLevel() const {
  if (base::mac::IsOSMountainLionOrEarlier()) {
    return MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE;
  }
  int mac_memory_pressure;
  size_t length = sizeof(int);
  sysctlbyname("kern.memorystatus_vm_pressure_level", &mac_memory_pressure,
               &length, nullptr, 0);
  return MemoryPressureLevelForMacMemoryPressure(mac_memory_pressure);
}

}  // namespace mac
}  // namespace base
